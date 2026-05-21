package com.example.floatingn_note.overlay

import android.animation.Animator
import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Color
import android.graphics.ColorFilter
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.text.Editable
import android.text.TextWatcher
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.view.inputmethod.InputMethodManager
import android.widget.Button
import android.widget.CheckBox
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import com.example.floatingn_note.services.OverlayService
import java.util.UUID

// Data models on native side
data class NoteData(
    val id: String,
    var title: String,
    var content: String,
    val type: String,
    var color: String,
    val icon: String,
    var opacity: Float,
    var posX: Float,
    var posY: Float,
    var width: Float,
    var height: Float,
    var isDocked: Boolean,
    var isLocked: Boolean,
    var bubbleSize: Int = 60,
    var bubbleShape: String = "circle",
    var checklist: MutableList<ChecklistItemData> = mutableListOf()
)

data class ChecklistItemData(
    val id: String,
    val noteId: String,
    val text: String,
    var checked: Boolean,
    var indent: Int = 0
)

class FloatingNoteView(
    context: Context,
    val note: NoteData,
    private val windowManager: WindowManager,
    private val onUpdate: (NoteData) -> Unit,
    private val onDelete: (String) -> Unit
) : FrameLayout(context) {

    val params: WindowManager.LayoutParams
    var isExpanded = !note.isDocked
    private var isEditing = false

    // Draggable coordinates
    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f
    private var interceptTouchDownX = 0f
    private var interceptTouchDownY = 0f
    private var lastClickTime: Long = 0

    // Core layout references (Open View Note card)
    private lateinit var mainCard: LinearLayout
    private lateinit var headerLayout: LinearLayout
    private lateinit var titleView: TextView
    private lateinit var titleEdit: EditText
    private lateinit var contentScrollView: ScrollView
    private lateinit var contentTextView: TextView
    private lateinit var contentEdit: EditText
    private lateinit var dockBubble: TextView
    private lateinit var viewMoreBtn: TextView
    private lateinit var editBarPalette: TextView
    private lateinit var editBarCheck: TextView
    private lateinit var editColorPicker: LinearLayout
    private lateinit var checklistContainer: LinearLayout

    init {
        // Build the standard window layout parameters
        params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = note.posX.toInt()
            y = note.posY.toInt()
            width = if (isExpanded) dpToPx(note.width.toInt()) else dpToPx(note.bubbleSize)
            height = if (isExpanded) WindowManager.LayoutParams.WRAP_CONTENT else dpToPx(note.bubbleSize)
        }

        setBackgroundColor(Color.TRANSPARENT)

        setupViews()
        applyTheme()
        updateLayoutState()
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        if (note.title.isEmpty() && note.content.isEmpty() && note.checklist.isEmpty()) {
            postDelayed({
                enableFocusAndEditing()
            }, 150)
        }
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        var wSpec = widthMeasureSpec
        if (isExpanded) {
            val maxW = dpToPx(320)
            val minW = dpToPx(160)
            val mode = View.MeasureSpec.getMode(widthMeasureSpec)
            val size = View.MeasureSpec.getSize(widthMeasureSpec)
            
            val targetSize = if (mode == View.MeasureSpec.EXACTLY || mode == View.MeasureSpec.AT_MOST) {
                Math.min(size, maxW)
            } else {
                maxW
            }
            val finalSize = Math.max(targetSize, minW)
            wSpec = View.MeasureSpec.makeMeasureSpec(finalSize, View.MeasureSpec.AT_MOST)
        }
        super.onMeasure(wSpec, heightMeasureSpec)
    }

    private fun setupViews() {
        // 1. DOCKED BUBBLE VIEW (Minimized Mode)
        dockBubble = TextView(context).apply {
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
            gravity = Gravity.CENTER
            textSize = when (note.bubbleSize) {
                45 -> 22f
                75 -> 34f
                else -> 28f
            }
            text = note.icon
            visibility = if (isExpanded) View.GONE else View.VISIBLE
        }
        addView(dockBubble)

        // 2. MAIN CARD VIEW (Expanded Mode)
        mainCard = LinearLayout(context).apply {
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
            orientation = LinearLayout.VERTICAL
            val padding = dpToPx(10)
            val shadowOffset = dpToPx(6)
            setPadding(padding, padding, padding + shadowOffset, padding + shadowOffset)
            visibility = if (isExpanded) View.VISIBLE else View.GONE
        }
        addView(mainCard)

        // Header Row
        headerLayout = LinearLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        mainCard.addView(headerLayout)

        // Pin/Icon (Leftmost)
        val headerIcon = TextView(context).apply {
            layoutParams = LinearLayout.LayoutParams(dpToPx(34), dpToPx(34))
            gravity = Gravity.CENTER
            textSize = 18f
            text = note.icon
            setOnClickListener {
                collapseToDock()
            }
        }
        headerLayout.addView(headerIcon)

        // Palette button next to Pin (Only visible in edit mode)
        editBarPalette = TextView(context).apply {
            layoutParams = LinearLayout.LayoutParams(dpToPx(34), dpToPx(34))
            gravity = Gravity.CENTER
            textSize = 18f
            text = "🎨"
            visibility = if (isEditing) View.VISIBLE else View.GONE
            setOnClickListener {
                editColorPicker.visibility = if (editColorPicker.visibility == View.VISIBLE) View.GONE else View.VISIBLE
            }
        }
        headerLayout.addView(editBarPalette)

        // Title View (Read-only mode)
        titleView = TextView(context).apply {
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply {
                marginStart = dpToPx(6)
                marginEnd = dpToPx(6)
            }
            textSize = 14f
            text = if (note.title.isNotEmpty()) note.title else "Sticky Note"
            setTextColor(Color.BLACK)
            typeface = Typeface.create("sans-serif-black", Typeface.BOLD)
            visibility = if (isEditing) View.GONE else View.VISIBLE
            setOnClickListener {
                enableFocusAndEditing(focusTitle = true)
            }
        }
        headerLayout.addView(titleView)

        // Title Edit (Edit mode)
        titleEdit = EditText(context).apply {
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply {
                marginStart = dpToPx(6)
                marginEnd = dpToPx(6)
            }
            textSize = 14f
            setTextColor(Color.BLACK)
            typeface = Typeface.create("sans-serif-black", Typeface.BOLD)
            background = null
            isSingleLine = true
            hint = "Title..."
            setHintTextColor(Color.parseColor("#80000000"))
            visibility = if (isEditing) View.VISIBLE else View.GONE
        }
        headerLayout.addView(titleEdit)

        // Three Dots menu
        viewMoreBtn = TextView(context).apply {
            layoutParams = LinearLayout.LayoutParams(dpToPx(34), dpToPx(34))
            gravity = Gravity.CENTER
            textSize = 18f
            text = "⋮"
            setOnClickListener {
                val popup = android.widget.PopupMenu(context, this)
                popup.menu.add("Edit Note")
                popup.menu.add("Dock Note")
                popup.menu.add("Delete Note")
                popup.setOnMenuItemClickListener { menuItem ->
                    when (menuItem.title) {
                        "Edit Note" -> {
                            enableFocusAndEditing()
                            true
                        }
                        "Dock Note" -> {
                            collapseToDock()
                            true
                        }
                        "Delete Note" -> {
                            onDelete(note.id)
                            true
                        }
                        else -> false
                    }
                }
                popup.show()
            }
        }
        headerLayout.addView(viewMoreBtn)

        // Check/Tick button next to Three Dots (Only visible in edit mode)
        editBarCheck = TextView(context).apply {
            layoutParams = LinearLayout.LayoutParams(dpToPx(34), dpToPx(34))
            gravity = Gravity.CENTER
            textSize = 18f
            text = "✓"
            visibility = if (isEditing) View.VISIBLE else View.GONE
            setOnClickListener {
                saveInlineEdits()
            }
        }
        headerLayout.addView(editBarCheck)

        // Color Picker Tray (Stripe below Header, above Content)
        editColorPicker = LinearLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(40)
            ).apply {
                topMargin = dpToPx(4)
                bottomMargin = dpToPx(4)
            }
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            visibility = View.GONE
        }
        mainCard.addView(editColorPicker)

        val colors = listOf("yellow", "pink", "mint", "blue", "lavender", "orange", "charcoal")
        for (c in colors) {
            val colorView = View(context).apply {
                layoutParams = LinearLayout.LayoutParams(dpToPx(24), dpToPx(24)).apply {
                    marginEnd = dpToPx(8)
                }
                setOnClickListener {
                    note.color = c
                    applyTheme()
                    onUpdate(note)
                }
            }
            val shape = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(getHexColor(c))
                setStroke(dpToPx(2f), Color.BLACK)
            }
            colorView.background = shape
            editColorPicker.addView(colorView)
        }

        // Content Area (Scrollable)
        contentScrollView = ScrollView(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dpToPx(4)
                bottomMargin = dpToPx(4)
                marginStart = dpToPx(10)
                marginEnd = dpToPx(10)
            }
        }
        mainCard.addView(contentScrollView)

        // Single child container for ScrollView
        val scrollContainer = LinearLayout(context).apply {
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
            orientation = LinearLayout.VERTICAL
        }
        contentScrollView.addView(scrollContainer)

        // Content Text View (Read-only mode)
        contentTextView = TextView(context).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
            textSize = 13f
            text = if (note.content.isNotEmpty()) note.content else "Click to edit..."
            setTextColor(Color.parseColor("#DE000000"))
            typeface = Typeface.create("sans-serif", Typeface.NORMAL)
            visibility = if (isEditing) View.GONE else View.VISIBLE
            setOnClickListener {
                enableFocusAndEditing(focusTitle = false)
            }
        }
        scrollContainer.addView(contentTextView)

        // Content Edit Text (Edit mode)
        contentEdit = EditText(context).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
            textSize = 13f
            setTextColor(Color.parseColor("#DE000000"))
            typeface = Typeface.create("sans-serif", Typeface.NORMAL)
            background = null
            isSingleLine = false
            inputType = android.text.InputType.TYPE_CLASS_TEXT or android.text.InputType.TYPE_TEXT_FLAG_MULTI_LINE
            maxLines = 8
            hint = "Write a note..."
            setHintTextColor(Color.parseColor("#80000000"))
            visibility = if (isEditing) View.VISIBLE else View.GONE
        }
        scrollContainer.addView(contentEdit)

        // Checklist Container
        checklistContainer = LinearLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            orientation = LinearLayout.VERTICAL
            visibility = if (note.type == "checklist") View.VISIBLE else View.GONE
        }
        scrollContainer.addView(checklistContainer)
    }



    private fun applyTheme() {
        val stickyBg = getHexColor(note.color)
        val isDarkNote = note.color.equals("charcoal", true) || 
                         note.color.equals("indigo", true) || 
                         note.color.equals("maroon", true) || 
                         note.color.equals("dark_mint", true)
        val textHex = if (isDarkNote) "#FFFFFF" else "#000000"
        val descHex = if (isDarkNote) "#E2E8F0" else "#2D2D2D"

        // Set card rounded background
        mainCard.background = BrutalistCardDrawable(
            fillColor = stickyBg,
            borderColor = Color.BLACK,
            borderWidth = dpToPx(2.5f).toFloat(),
            cornerRadius = dpToPx(16f).toFloat(),
            shadowColor = Color.BLACK,
            shadowOffset = dpToPx(6f).toFloat()
        )

        // Update text colors
        titleView.setTextColor(Color.parseColor(textHex))
        titleEdit.setTextColor(Color.parseColor(textHex))
        titleEdit.setHintTextColor(Color.parseColor(if (isDarkNote) "#80FFFFFF" else "#80000000"))
        contentTextView.setTextColor(Color.parseColor(descHex))
        contentEdit.setTextColor(Color.parseColor(descHex))
        contentEdit.setHintTextColor(Color.parseColor(if (isDarkNote) "#80E2E8F0" else "#802D2D2D"))

        if (note.type == "checklist") {
            populateChecklist()
        }

        // Set mini-dock bubble background (without shadow effect, normal black border)
        dockBubble.background = BubbleShapeDrawable(
            shapeType = note.bubbleShape,
            fillColor = stickyBg,
            strokeColor = Color.BLACK,
            strokeWidth = dpToPx(2.5f).toFloat(),
            cornerRadius = dpToPx(12f).toFloat(), // cornerRadius for squircle
            shadowColor = Color.BLACK,
            shadowOffset = 0f
        )

        editBarPalette.setTextColor(Color.parseColor(textHex))
        editBarCheck.setTextColor(Color.parseColor(textHex))
        viewMoreBtn.setTextColor(Color.parseColor(textHex))

        // Apply dynamic opacity
        alpha = note.opacity
    }

    private fun updateLayoutState() {
        if (isExpanded) {
            dockBubble.visibility = View.GONE
            mainCard.visibility = View.VISIBLE
            if (isEditing) {
                titleView.visibility = View.GONE
                titleEdit.visibility = View.VISIBLE
                editBarPalette.visibility = View.VISIBLE
                editBarCheck.visibility = View.VISIBLE
                
                if (note.type == "checklist") {
                    contentTextView.visibility = View.GONE
                    contentEdit.visibility = View.GONE
                    checklistContainer.visibility = View.VISIBLE
                    populateChecklist()
                } else {
                    contentTextView.visibility = View.GONE
                    contentEdit.visibility = View.VISIBLE
                    checklistContainer.visibility = View.GONE
                }
                
                params.width = dpToPx(300)
                params.height = WindowManager.LayoutParams.WRAP_CONTENT
            } else {
                titleView.visibility = View.VISIBLE
                titleEdit.visibility = View.GONE
                editBarPalette.visibility = View.GONE
                editBarCheck.visibility = View.GONE
                
                if (note.type == "checklist") {
                    contentTextView.visibility = View.GONE
                    contentEdit.visibility = View.GONE
                    checklistContainer.visibility = View.VISIBLE
                    populateChecklist()
                } else {
                    contentTextView.visibility = View.VISIBLE
                    contentEdit.visibility = View.GONE
                    checklistContainer.visibility = View.GONE
                }
                
                editColorPicker.visibility = View.GONE
                params.width = WindowManager.LayoutParams.WRAP_CONTENT
                params.height = WindowManager.LayoutParams.WRAP_CONTENT
            }
        } else {
            titleView.visibility = View.GONE
            titleEdit.visibility = View.GONE
            editBarPalette.visibility = View.GONE
            editBarCheck.visibility = View.GONE
            contentTextView.visibility = View.GONE
            contentEdit.visibility = View.GONE
            checklistContainer.visibility = View.GONE
            editColorPicker.visibility = View.GONE
            
            mainCard.visibility = View.GONE
            dockBubble.visibility = View.VISIBLE
            
            params.width = dpToPx(note.bubbleSize)
            params.height = dpToPx(note.bubbleSize)
        }
        if (isAttachedToWindow) {
            windowManager.updateViewLayout(this, params)
        }
    }

    fun updateNoteData(newNote: NoteData) {
        note.title = newNote.title
        note.content = newNote.content
        note.color = newNote.color
        note.opacity = newNote.opacity
        note.isDocked = newNote.isDocked
        note.bubbleSize = newNote.bubbleSize
        note.bubbleShape = newNote.bubbleShape
        note.checklist = newNote.checklist

        params.x = newNote.posX.toInt()
        params.y = newNote.posY.toInt()

        isExpanded = !note.isDocked

        if (!isExpanded) {
            snapToEdges(dpToPx(note.bubbleSize))
        } else {
            updateLayoutState()
            applyTheme()
        }
    }

    fun expandFromDock() {
        isExpanded = true
        isEditing = false
        note.isDocked = false

        // 1. Calculate center coordinates of the screen
        val displayMetrics = context.resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels

        val viewWidth = dpToPx(240) // Default centering width
        val expandedCount = OverlayService.instance?.activeOverlays?.values?.count { it.isExpanded } ?: 0
        val staggerOffset = dpToPx((expandedCount % 5) * 20)
        val targetX = (screenWidth - viewWidth) / 2 + staggerOffset
        val targetY = (screenHeight - dpToPx(200)) / 2 + staggerOffset

        note.posX = targetX.toFloat()
        note.posY = targetY.toFloat()

        // 2. Animate the coordinates to center
        val startX = params.x
        val startY = params.y

        val animatorX = ValueAnimator.ofInt(startX, targetX)
        val animatorY = ValueAnimator.ofInt(startY, targetY)

        animatorX.duration = 250
        animatorY.duration = 250

        animatorX.addUpdateListener { animation ->
            params.x = animation.animatedValue as Int
            try {
                windowManager.updateViewLayout(this, params)
            } catch (e: Exception) {}
        }

        animatorY.addUpdateListener { animation ->
            params.y = animation.animatedValue as Int
            try {
                windowManager.updateViewLayout(this, params)
            } catch (e: Exception) {}
        }

        animatorX.addListener(object : Animator.AnimatorListener {
            override fun onAnimationStart(animation: Animator) {}
            override fun onAnimationEnd(animation: Animator) {
                onUpdate(note)
            }
            override fun onAnimationCancel(animation: Animator) {}
            override fun onAnimationRepeat(animation: Animator) {}
        })

        animatorX.start()
        animatorY.start()

        updateLayoutState()
        applyTheme()
    }

    fun collapseToDock() {
        isExpanded = false
        isEditing = false
        note.isDocked = true
        disableFocus()
        updateLayoutState()
        applyTheme()
        snapToEdges(dpToPx(note.bubbleSize))
        onUpdate(note)
    }

    private fun enableFocusAndEditing(focusTitle: Boolean = false) {
        if (isEditing || note.isLocked) return
        isEditing = true

        // Modify window manager flags to receive keystrokes
        params.flags = params.flags and WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE.inv()
        windowManager.updateViewLayout(this, params)

        updateLayoutState()
        applyTheme()

        // Sync text from note model
        titleEdit.setText(note.title)
        if (note.type != "checklist") {
            contentEdit.setText(note.content)
            val focusTarget = if (focusTitle) titleEdit else contentEdit
            focusTarget.requestFocus()
            focusTarget.setSelection(focusTarget.text.length)
        } else {
            val focusTarget = if (focusTitle) titleEdit else {
                var firstEdit: EditText? = null
                for (i in 0 until checklistContainer.childCount) {
                    val row = checklistContainer.getChildAt(i) as? LinearLayout ?: continue
                    for (j in 0 until row.childCount) {
                        val child = row.getChildAt(j)
                        if (child is EditText) {
                            firstEdit = child
                            break
                        }
                    }
                    if (firstEdit != null) break
                }
                firstEdit
            }
            if (focusTarget != null) {
                focusTarget.requestFocus()
                focusTarget.setSelection(focusTarget.text.length)
            } else {
                titleEdit.requestFocus()
            }
        }

        // Show keyboard
        val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        imm.toggleSoftInput(InputMethodManager.SHOW_FORCED, 0)
    }

    private fun disableFocus() {
        isEditing = false
        params.flags = params.flags or WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
        windowManager.updateViewLayout(this, params)

        updateLayoutState()
        applyTheme()

        // Hide keyboard
        val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        imm.hideSoftInputFromWindow(windowToken, 0)
    }

    private fun saveInlineEdits() {
        val newTitle = titleEdit.text.toString().trim()
        note.title = newTitle.ifEmpty { "Sticky Note" }
        titleView.text = note.title

        if (note.type == "checklist") {
            val newChecklist = mutableListOf<ChecklistItemData>()
            var childCount = checklistContainer.childCount
            if (isEditing) {
                childCount-- // exclude the "Add Item" row
            }
            for (i in 0 until childCount) {
                val row = checklistContainer.getChildAt(i) as? LinearLayout ?: continue
                var checked = false
                var textVal = ""
                for (j in 0 until row.childCount) {
                    val child = row.getChildAt(j)
                    if (child is CheckBox) {
                        checked = child.isChecked
                    } else if (child is EditText) {
                        textVal = child.text.toString().trim()
                    } else if (child is TextView && child.text != "+" && child.text != "Add Item" && textVal.isEmpty()) {
                        textVal = child.text.toString().trim()
                    }
                }
                val originalItem = note.checklist.getOrNull(i)
                val itemId = originalItem?.id ?: UUID.randomUUID().toString()
                val itemIndent = originalItem?.indent ?: 0
                newChecklist.add(ChecklistItemData(itemId, note.id, textVal, checked, itemIndent))
            }
            note.checklist = newChecklist
        } else {
            val newContent = contentEdit.text.toString().trim()
            note.content = newContent
            contentTextView.text = if (note.content.isNotEmpty()) note.content else "Click to edit..."
        }

        disableFocus()
        onUpdate(note)
    }

    private fun isTouchInsideView(view: View, ev: MotionEvent): Boolean {
        if (view.visibility != View.VISIBLE) return false
        val location = IntArray(2)
        view.getLocationOnScreen(location)
        val rect = android.graphics.Rect(
            location[0],
            location[1],
            location[0] + view.width,
            location[1] + view.height
        )
        return rect.contains(ev.rawX.toInt(), ev.rawY.toInt())
    }

    private fun getStatusBarHeight(context: Context): Int {
        var result = 0
        val resourceId = context.resources.getIdentifier("status_bar_height", "dimen", "android")
        if (resourceId > 0) {
            result = context.resources.getDimensionPixelSize(resourceId)
        }
        return if (result > 0) result else dpToPx(24)
    }

    private fun getNavigationBarHeight(context: Context): Int {
        var result = 0
        val resourceId = context.resources.getIdentifier("navigation_bar_height", "dimen", "android")
        if (resourceId > 0) {
            result = context.resources.getDimensionPixelSize(resourceId)
        }
        return if (result > 0) result else dpToPx(48)
    }

    // GESTURES & INTERPOLATED TOUCH INTERCEPTIONS
    override fun onInterceptTouchEvent(ev: MotionEvent): Boolean {
        if (!isExpanded) return true

        when (ev.action) {
            MotionEvent.ACTION_DOWN -> {
                interceptTouchDownX = ev.rawX
                interceptTouchDownY = ev.rawY
                if (isEditing) {
                    val touchingInteractive = isTouchInsideView(titleEdit, ev) ||
                            isTouchInsideView(contentEdit, ev) ||
                            isTouchInsideView(editBarPalette, ev) ||
                            isTouchInsideView(viewMoreBtn, ev) ||
                            isTouchInsideView(editBarCheck, ev) ||
                            (editColorPicker.visibility == View.VISIBLE && isTouchInsideView(editColorPicker, ev))
                    return !touchingInteractive
                }
                return false
            }
            MotionEvent.ACTION_MOVE -> {
                if (isEditing) {
                    val touchingInteractive = isTouchInsideView(titleEdit, ev) ||
                            isTouchInsideView(contentEdit, ev) ||
                            isTouchInsideView(editBarPalette, ev) ||
                            isTouchInsideView(viewMoreBtn, ev) ||
                            isTouchInsideView(editBarCheck, ev) ||
                            (editColorPicker.visibility == View.VISIBLE && isTouchInsideView(editColorPicker, ev))
                    return !touchingInteractive
                }
                val dx = ev.rawX - interceptTouchDownX
                val dy = ev.rawY - interceptTouchDownY
                // Intercept the touch stream to drag the window ONLY if travel exceeds threshold
                return Math.abs(dx) > dpToPx(8) || Math.abs(dy) > dpToPx(8)
            }
            else -> return false
        }
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                initialX = params.x
                initialY = params.y
                initialTouchX = event.rawX
                initialTouchY = event.rawY
                if (!isExpanded) {
                    OverlayService.showDeleteZone()
                }
                return true
            }
            MotionEvent.ACTION_MOVE -> {
                val dx = event.rawX - initialTouchX
                val dy = event.rawY - initialTouchY

                val displayMetrics = android.util.DisplayMetrics()
                windowManager.defaultDisplay.getRealMetrics(displayMetrics)
                val screenWidth = displayMetrics.widthPixels
                val screenHeight = displayMetrics.heightPixels

                val viewWidth = if (isExpanded) {
                    if (width > 0) width else dpToPx(note.width.toInt())
                } else {
                    dpToPx(note.bubbleSize)
                }
                val viewHeight = if (isExpanded) {
                    if (height > 0) height else dpToPx(100)
                } else {
                    dpToPx(note.bubbleSize)
                }

                val topMarginPx = getStatusBarHeight(context)
                val bottomMarginPx = getNavigationBarHeight(context)
                val safetyBottomMargin = if (isExpanded) 0 else dpToPx(20)

                // Constrain X coordinate to prevent going off-screen horizontally
                var newX = initialX + dx.toInt()
                val maxX = screenWidth - viewWidth
                if (newX < 0) newX = 0
                if (newX > maxX) newX = maxX

                // Constrain Y coordinate to top/bottom restricted areas
                var newY = initialY + dy.toInt()
                val maxY = screenHeight - viewHeight - bottomMarginPx - safetyBottomMargin
                if (newY < topMarginPx) newY = topMarginPx
                if (newY > maxY) newY = maxY

                params.x = newX
                params.y = newY
                windowManager.updateViewLayout(this, params)

                // Check for overlapping the bottom delete trash can zone
                val overTrash = if (!isExpanded) OverlayService.isOverDeleteZone(this) else false
                if (!isExpanded) {
                    OverlayService.updateDeleteZoneHover(this, overTrash)
                }

                // Visual "getting sucked into trash" scaling and opacity effect
                if (overTrash) {
                    alpha = 0.4f
                    scaleX = 0.8f
                    scaleY = 0.8f
                } else {
                    alpha = note.opacity
                    scaleX = 1.0f
                    scaleY = 1.0f
                }
                return true
            }

            MotionEvent.ACTION_UP -> {
                val dx = event.rawX - initialTouchX
                val dy = event.rawY - initialTouchY

                // Check overlap first before the delete zone is hidden
                val overTrash = if (!isExpanded) OverlayService.isOverDeleteZone(this) else false

                if (!isExpanded) {
                    OverlayService.hideDeleteZone()
                }

                // Reset view scale and opacity to normal
                scaleX = 1.0f
                scaleY = 1.0f
                alpha = note.opacity

                // If released over the trash can, perform an instant deletion!
                if (overTrash) {
                    onDelete(note.id)
                    return true
                }

                // Check for single / double tap (if dragged less than 5 pixels)
                if (Math.abs(dx) < dpToPx(5) && Math.abs(dy) < dpToPx(5)) {
                    val clickTime = System.currentTimeMillis()
                    if (clickTime - lastClickTime < 300) {
                         // Double Tap
                         if (!isExpanded) {
                             expandFromDock()
                         }
                    } else {
                         // Single Tap
                         if (!isExpanded) {
                             expandFromDock()
                         }
                    }
                    lastClickTime = clickTime
                } else {
                    // Update positions in note data
                    note.posX = params.x.toFloat()
                    note.posY = params.y.toFloat()
                    onUpdate(note)

                    // Snapping physics! Magnet snap to screen edges only if it is a bubble
                    if (!isExpanded) {
                        snapToEdges()
                    }
                }
                return true
            }
        }

        return super.onTouchEvent(event)
    }

    private fun snapToEdges(customWidth: Int? = null) {
        val displayMetrics = android.util.DisplayMetrics()
        windowManager.defaultDisplay.getRealMetrics(displayMetrics)
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels
        val viewWidth = customWidth ?: width
        val viewHeight = if (isExpanded) {
            if (height > 0) height else dpToPx(100)
        } else {
            dpToPx(note.bubbleSize)
        }

        val topMarginPx = getStatusBarHeight(context)
        val bottomMarginPx = getNavigationBarHeight(context)
        val safetyBottomMargin = if (isExpanded) 0 else dpToPx(20)
        val maxY = screenHeight - viewHeight - bottomMarginPx - safetyBottomMargin

        var targetY = params.y
        val bubbleHeight = dpToPx(note.bubbleSize)
        val safetyBottom = screenHeight - bottomMarginPx - safetyBottomMargin - bubbleHeight

        val targetX = if (params.x + viewWidth / 2 < screenWidth / 2) {
            0 // Snap to left edge
        } else {
            screenWidth - viewWidth // Snap to right edge
        }

        // Collision detection for docked notes on the same side
        val otherDockedViews = OverlayService.instance?.activeOverlays?.values
            ?.filter { it != this && !it.isExpanded && it.note.isDocked && it.params.x == targetX }
            ?.sortedBy { it.params.y } ?: emptyList()

        var attempts = 0
        var foundPosition = false
        while (attempts < 50 && !foundPosition) {
            var overlap = false
            for (other in otherDockedViews) {
                val otherY = other.params.y
                if (Math.abs(targetY - otherY) < bubbleHeight) {
                    overlap = true
                    targetY = otherY + bubbleHeight + dpToPx(4)
                    break
                }
            }
            if (!overlap) {
                foundPosition = true
            } else {
                if (targetY > safetyBottom) {
                    targetY = topMarginPx
                }
                attempts++
            }
        }

        if (targetY < topMarginPx) targetY = topMarginPx
        if (targetY > safetyBottom) targetY = safetyBottom

        note.posX = targetX.toFloat()
        note.posY = targetY.toFloat()

        val startX = params.x
        val startY = params.y

        val animatorX = ValueAnimator.ofInt(startX, targetX)
        val animatorY = ValueAnimator.ofInt(startY, targetY)

        animatorX.duration = 200
        animatorY.duration = 200

        animatorX.addUpdateListener { animation ->
            params.x = animation.animatedValue as Int
            try {
                windowManager.updateViewLayout(this@FloatingNoteView, params)
            } catch (e: Exception) {}
        }

        animatorY.addUpdateListener { animation ->
            params.y = animation.animatedValue as Int
            try {
                windowManager.updateViewLayout(this@FloatingNoteView, params)
            } catch (e: Exception) {}
        }

        animatorX.addListener(object : Animator.AnimatorListener {
            override fun onAnimationStart(animation: Animator) {}
            override fun onAnimationEnd(animation: Animator) {
                onUpdate(note)
            }
            override fun onAnimationCancel(animation: Animator) {}
            override fun onAnimationRepeat(animation: Animator) {}
        })

        animatorX.start()
        animatorY.start()
    }

    private fun dpToPx(dp: Int): Int {
        val density = context.resources.displayMetrics.density
        return (dp * density).toInt()
    }

    private fun dpToPx(dp: Float): Int {
        val density = context.resources.displayMetrics.density
        return (dp * density).toInt()
    }


    private fun getHexColor(colorName: String): Int {
        val name = colorName.lowercase().trim()
        if (name.startsWith("#")) {
            try {
                return Color.parseColor(name)
            } catch (e: Exception) {}
        }
        return when (name) {
            "yellow" -> Color.parseColor("#FFE853")
            "pink" -> Color.parseColor("#FF85C2")
            "mint" -> Color.parseColor("#5EFFAD")
            "blue" -> Color.parseColor("#6BE5FF")
            "lavender" -> Color.parseColor("#D69CFF")
            "orange" -> Color.parseColor("#FF9D42")
            "rose" -> Color.parseColor("#FF7A82")
            "purple" -> Color.parseColor("#A58EFF")
            "teal" -> Color.parseColor("#42FFD2")
            "green" -> Color.parseColor("#88FF5E")
            "lime" -> Color.parseColor("#D4FF5E")
            "cream" -> Color.parseColor("#FFF8BD")
            "amber" -> Color.parseColor("#FFCE3A")
            "coral" -> Color.parseColor("#FF7A5E")
            "clay" -> Color.parseColor("#D9BBA9")
            "grey" -> Color.parseColor("#C5D1D6")
            "cotton" -> Color.parseColor("#FFC6FA")
            "sky" -> Color.parseColor("#B5FAFF")
            "emerald" -> Color.parseColor("#8CFFB7")
            "pistachio" -> Color.parseColor("#D4FFA6")
            "sand" -> Color.parseColor("#FFF2C2")
            "plum" -> Color.parseColor("#FFC0DB")
            "cocoa" -> Color.parseColor("#E5D5CD")
            "charcoal" -> Color.parseColor("#2B2F3A")
            "indigo" -> Color.parseColor("#4856FF")
            "maroon" -> Color.parseColor("#FF5252")
            "dark_mint" -> Color.parseColor("#00C292")
            "glass" -> Color.parseColor("#E2E8F0")
            else -> {
                try {
                    Color.parseColor("#$name")
                } catch (e: Exception) {
                    Color.parseColor("#FFE853")
                }
            }
        }
    }

    private fun populateChecklist() {
        checklistContainer.removeAllViews()
        
        val isDarkNote = note.color.equals("charcoal", true) || 
                         note.color.equals("indigo", true) || 
                         note.color.equals("maroon", true) || 
                         note.color.equals("dark_mint", true)
        val textHex = if (isDarkNote) "#FFFFFF" else "#000000"
        val descHex = if (isDarkNote) "#E2E8F0" else "#2D2D2D"
        val textColor = Color.parseColor(descHex)
        val titleColor = Color.parseColor(textHex)
        val checkedColor = Color.parseColor(if (isDarkNote) "#60E2E8F0" else "#602D2D2D")

        for ((index, item) in note.checklist.withIndex()) {
            val row = LinearLayout(context).apply {
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dpToPx(1)
                    bottomMargin = dpToPx(1)
                }
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
            }

            // Checkbox
            val checkbox = CheckBox(context).apply {
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    setPadding(0, 0, 0, 0)
                }
                isChecked = item.checked
                
                // Style button tint with premium color tokens
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                    buttonTintList = android.content.res.ColorStateList.valueOf(
                        if (item.checked) checkedColor else textColor
                    )
                }
            }
            row.addView(checkbox)

            if (isEditing) {
                val itemEdit = EditText(context).apply {
                    layoutParams = LinearLayout.LayoutParams(
                        0,
                        LinearLayout.LayoutParams.WRAP_CONTENT,
                        1f
                    ).apply {
                        marginStart = dpToPx(4)
                        marginEnd = dpToPx(4)
                    }
                    setText(item.text)
                    textSize = 13f
                    setTextColor(textColor)
                    typeface = Typeface.create("sans-serif", Typeface.NORMAL)
                    background = null
                    hint = "Item..."
                    setHintTextColor(Color.parseColor(if (isDarkNote) "#50E2E8F0" else "#502D2D2D"))
                }
                
                checkbox.setOnCheckedChangeListener { _, isChecked ->
                    if (item.checked != isChecked) {
                        item.checked = isChecked
                        if (isChecked) {
                            itemEdit.setTextColor(checkedColor)
                            itemEdit.paintFlags = itemEdit.paintFlags or android.graphics.Paint.STRIKE_THRU_TEXT_FLAG
                        } else {
                            itemEdit.setTextColor(textColor)
                            itemEdit.paintFlags = itemEdit.paintFlags and android.graphics.Paint.STRIKE_THRU_TEXT_FLAG.inv()
                        }
                    }
                }
                
                if (item.checked) {
                    itemEdit.paintFlags = itemEdit.paintFlags or android.graphics.Paint.STRIKE_THRU_TEXT_FLAG
                    itemEdit.setTextColor(checkedColor)
                } else {
                    itemEdit.paintFlags = itemEdit.paintFlags and android.graphics.Paint.STRIKE_THRU_TEXT_FLAG.inv()
                    itemEdit.setTextColor(textColor)
                }
                
                row.addView(itemEdit)

                // Delete button for this item
                val deleteItemBtn = TextView(context).apply {
                    layoutParams = LinearLayout.LayoutParams(dpToPx(24), dpToPx(24))
                    gravity = Gravity.CENTER
                    text = "×"
                    textSize = 18f
                    setTextColor(textColor)
                    setOnClickListener {
                        note.checklist.removeAt(index)
                        populateChecklist()
                    }
                }
                row.addView(deleteItemBtn)
            } else {
                val itemText = TextView(context).apply {
                    layoutParams = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT
                    ).apply {
                        marginStart = dpToPx(4)
                        marginEnd = dpToPx(4)
                    }
                    text = item.text
                    textSize = 13f
                    setTextColor(if (item.checked) checkedColor else textColor)
                    typeface = Typeface.create("sans-serif", Typeface.NORMAL)
                    if (item.checked) {
                        paintFlags = paintFlags or android.graphics.Paint.STRIKE_THRU_TEXT_FLAG
                    } else {
                        paintFlags = paintFlags and android.graphics.Paint.STRIKE_THRU_TEXT_FLAG.inv()
                    }
                }
                
                checkbox.setOnCheckedChangeListener { _, isChecked ->
                    if (item.checked != isChecked) {
                        item.checked = isChecked
                        onUpdate(note)
                        if (isChecked) {
                            itemText.setTextColor(checkedColor)
                            itemText.paintFlags = itemText.paintFlags or android.graphics.Paint.STRIKE_THRU_TEXT_FLAG
                            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                                checkbox.buttonTintList = android.content.res.ColorStateList.valueOf(checkedColor)
                            }
                        } else {
                            itemText.setTextColor(textColor)
                            itemText.paintFlags = itemText.paintFlags and android.graphics.Paint.STRIKE_THRU_TEXT_FLAG.inv()
                            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                                checkbox.buttonTintList = android.content.res.ColorStateList.valueOf(textColor)
                            }
                        }
                    }
                }
                
                row.addView(itemText)
            }

            checklistContainer.addView(row)
        }

        // Add item button in edit mode
        if (isEditing) {
            val addItemRow = LinearLayout(context).apply {
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dpToPx(6)
                    bottomMargin = dpToPx(4)
                    marginStart = dpToPx(6)
                }
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setOnClickListener {
                    note.checklist.add(ChecklistItemData(
                        id = UUID.randomUUID().toString(),
                        noteId = note.id,
                        text = "",
                        checked = false,
                        indent = 0
                    ))
                    populateChecklist()
                    post {
                        val newCount = checklistContainer.childCount
                        if (newCount > 1) {
                            val newRow = checklistContainer.getChildAt(newCount - 2) as? LinearLayout
                            if (newRow != null) {
                                for (i in 0 until newRow.childCount) {
                                    val child = newRow.getChildAt(i)
                                    if (child is EditText) {
                                        child.requestFocus()
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
            }
            val plusIcon = TextView(context).apply {
                text = "+ "
                textSize = 14f
                setTextColor(titleColor)
                typeface = Typeface.create("sans-serif-black", Typeface.BOLD)
            }
            addItemRow.addView(plusIcon)
            
            val addText = TextView(context).apply {
                text = "Add Item"
                textSize = 13f
                setTextColor(textColor)
                typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            }
            addItemRow.addView(addText)
            checklistContainer.addView(addItemRow)
        }
    }
}

class BubbleShapeDrawable(
    private val shapeType: String,
    private val fillColor: Int,
    private val strokeColor: Int,
    private val strokeWidth: Float,
    private val cornerRadius: Float = 0f,
    private val shadowColor: Int = Color.BLACK,
    private val shadowOffset: Float = 0f
) : Drawable() {

    private val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = fillColor
    }

    private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        color = strokeColor
        strokeWidth = this@BubbleShapeDrawable.strokeWidth
    }

    private val shadowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = shadowColor
    }

    private fun getPathForRect(rect: RectF): Path {
        val path = Path()
        val w = rect.width()
        val h = rect.height()
        val strokeHalf = strokeWidth / 2f
        val left = rect.left + strokeHalf
        val top = rect.top + strokeHalf
        val right = rect.right - strokeHalf
        val bottom = rect.bottom - strokeHalf

        when (shapeType.lowercase()) {
            "square" -> {
                path.addRect(left, top, right, bottom, Path.Direction.CW)
            }
            "squircle" -> {
                val r = if (cornerRadius > 0f) cornerRadius else w * 0.25f
                path.addRoundRect(left, top, right, bottom, r, r, Path.Direction.CW)
            }
            "hexagon" -> {
                val cx = rect.left + w / 2f
                val cy = rect.top + h / 2f
                val r = Math.min(w, h) / 2f - strokeHalf
                for (i in 0 until 6) {
                    val angle = i * Math.PI / 3
                    val x = (cx + r * Math.cos(angle)).toFloat()
                    val y = (cy + r * Math.sin(angle)).toFloat()
                    if (i == 0) {
                        path.moveTo(x, y)
                    } else {
                        path.lineTo(x, y)
                    }
                }
                path.close()
            }
            else -> { // circle
                path.addOval(left, top, right, bottom, Path.Direction.CW)
            }
        }
        return path
    }

    override fun draw(canvas: Canvas) {
        val bounds = bounds
        val w = bounds.width().toFloat()
        val h = bounds.height().toFloat()
        if (w <= 0 || h <= 0) return

        if (shadowOffset > 0f) {
            val shadowRect = RectF(shadowOffset, shadowOffset, w, h)
            val shadowPath = getPathForRect(shadowRect)
            canvas.drawPath(shadowPath, shadowPaint)
        }

        val cardRect = RectF(0f, 0f, w - shadowOffset, h - shadowOffset)
        val cardPath = getPathForRect(cardRect)
        canvas.drawPath(cardPath, fillPaint)
        canvas.drawPath(cardPath, strokePaint)
    }

    override fun setAlpha(alpha: Int) {
        fillPaint.alpha = alpha
        val strokeAlpha = (alpha * (Color.alpha(strokeColor) / 255.0)).toInt()
        strokePaint.alpha = strokeAlpha
        shadowPaint.alpha = alpha
        invalidateSelf()
    }

    override fun setColorFilter(colorFilter: ColorFilter?) {
        fillPaint.colorFilter = colorFilter
        strokePaint.colorFilter = colorFilter
        shadowPaint.colorFilter = colorFilter
        invalidateSelf()
    }

    override fun getOpacity(): Int {
        return PixelFormat.TRANSLUCENT
    }
}

class BrutalistCardDrawable(
    private val fillColor: Int,
    private val borderColor: Int,
    private val borderWidth: Float,
    private val cornerRadius: Float,
    private val shadowColor: Int,
    private val shadowOffset: Float
) : Drawable() {

    private val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = fillColor
    }

    private val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        color = borderColor
        strokeWidth = this@BrutalistCardDrawable.borderWidth
    }

    private val shadowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = shadowColor
    }

    override fun draw(canvas: Canvas) {
        val bounds = bounds
        val w = bounds.width().toFloat()
        val h = bounds.height().toFloat()
        if (w <= 0 || h <= 0) return

        val shadowRect = RectF(
            shadowOffset,
            shadowOffset,
            w,
            h
        )

        val cardRect = RectF(
            0f,
            0f,
            w - shadowOffset,
            h - shadowOffset
        )

        canvas.drawRoundRect(shadowRect, cornerRadius, cornerRadius, shadowPaint)
        canvas.drawRoundRect(cardRect, cornerRadius, cornerRadius, fillPaint)
        canvas.drawRoundRect(cardRect, cornerRadius, cornerRadius, borderPaint)
    }

    override fun setAlpha(alpha: Int) {
        fillPaint.alpha = alpha
        borderPaint.alpha = alpha
        shadowPaint.alpha = alpha
        invalidateSelf()
    }

    override fun setColorFilter(colorFilter: ColorFilter?) {
        fillPaint.colorFilter = colorFilter
        borderPaint.colorFilter = colorFilter
        shadowPaint.colorFilter = colorFilter
        invalidateSelf()
    }

    override fun getOpacity(): Int {
        return PixelFormat.TRANSLUCENT
    }
}
