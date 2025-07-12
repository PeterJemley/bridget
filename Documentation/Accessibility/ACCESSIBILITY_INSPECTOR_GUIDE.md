# Xcode Accessibility Inspector Quick Guide

## 🚀 **Getting Started**

### **Step 1: Launch Accessibility Inspector**
```bash
# Method 1: From Xcode (Recommended)
1. Open Bridget project in Xcode
2. Run the app (Cmd + R)
3. Debug → View Debugging → Accessibility Inspector (Cmd + Shift + A)

# Method 2: Direct Launch
/Applications/Xcode.app/Contents/Developer/usr/bin/Accessibility Inspector
```

### **Step 2: Connect to App**
1. In Accessibility Inspector, click the target icon
2. Select "Bridget" from the list of running apps
3. The inspector will now show the app's accessibility tree

---

## 🔍 **Key Inspector Features**

### **Element Selection**
- **Click on elements** in the app to inspect them
- **Use the target tool** to hover and select elements
- **Navigate the accessibility tree** in the left panel

### **Information Panels**
- **General Tab**: Basic accessibility properties
- **Actions Tab**: Available accessibility actions
- **Attributes Tab**: Detailed accessibility attributes
- **Hierarchy Tab**: Parent-child relationships

---

## 📋 **What to Check for Each Element**

### **Essential Properties**
- [ ] **Accessibility Label**: Clear, descriptive text
- [ ] **Accessibility Hint**: Explains what the element does
- [ ] **Accessibility Traits**: Correct trait assignment
- [ ] **Is Accessibility Element**: Should be true for interactive elements

### **HIG Compliance Checks**
- [ ] **Touch Target Size**: ≥44x44 points for interactive elements
- [ ] **Text Size**: ≥17 points by default
- [ ] **Contrast Ratio**: ≥4.5:1 for normal text
- [ ] **Focus Indicators**: Visible when selected

### **VoiceOver Testing**
- [ ] **VoiceOver Announcement**: Clear and helpful
- [ ] **Navigation Flow**: Logical tab order
- [ ] **Action Descriptions**: Understandable actions

---

## 🎯 **Testing Checklist by Screen**

### **Dashboard Screen**
1. **Tab Bar Navigation**
   - [ ] Each tab has clear label
   - [ ] Selected state is announced
   - [ ] Tab order is logical

2. **Map Controls**
   - [ ] Zoom button is accessible
   - [ ] Location button is accessible
   - [ ] Buttons have proper touch targets

3. **Bridge Pins**
   - [ ] Each pin has descriptive label
   - [ ] Tap action is clear
   - [ ] Status information is accessible

### **History Screen**
1. **Sparkline Charts**
   - [ ] Charts have descriptive labels
   - [ ] Data trends are explained
   - [ ] Interactive elements are accessible

2. **Filter Controls**
   - [ ] Time range picker is accessible
   - [ ] Analysis type selector works with VoiceOver
   - [ ] Filter buttons have clear labels

### **Map Screen**
1. **Map View**
   - [ ] Map has descriptive label
   - [ ] Zoom controls are accessible
   - [ ] Bridge annotations are properly labeled

2. **Bridge Details**
   - [ ] Detail sheet is accessible
   - [ ] Information is properly structured
   - [ ] Close action is clear

---

## 🛠️ **Common Issues to Look For**

### **Critical Issues**
- [ ] **Missing Labels**: Interactive elements without accessibility labels
- [ ] **Poor Contrast**: Text that's hard to read
- [ ] **Small Touch Targets**: Buttons smaller than 44x44 points
- [ ] **No Focus Indicators**: Can't tell what's selected

### **Important Issues**
- [ ] **Unclear Hints**: Accessibility hints that don't help
- [ ] **Wrong Traits**: Incorrect accessibility trait assignment
- [ ] **Poor Navigation**: Confusing tab order
- [ ] **Missing Actions**: Interactive elements without proper actions

### **Minor Issues**
- [ ] **Redundant Labels**: Overly verbose accessibility labels
- [ ] **Inconsistent Naming**: Inconsistent terminology
- [ ] **Missing Context**: Elements that need more context

---

## 📊 **Documentation Template**

For each element you inspect, document:

```markdown
### Element: [Element Name]
- **Type**: [Button/Text/Image/etc.]
- **Accessibility Label**: [Current label or "Missing"]
- **Accessibility Hint**: [Current hint or "Missing"]
- **Accessibility Traits**: [Current traits]
- **Touch Target Size**: [Width x Height in points]
- **Text Size**: [Font size in points]
- **HIG Issues**: [List any HIG violations]
- **VoiceOver Test**: [How it sounds with VoiceOver]
- **Action Items**: [What needs to be fixed]
```

---

## 🔧 **Quick Fixes**

### **Add Missing Accessibility Label**
```swift
Button("Refresh") {
    // action
}
.accessibilityLabel("Refresh bridge data")
```

### **Add Accessibility Hint**
```swift
Button("Map") {
    // action
}
.accessibilityLabel("Map")
.accessibilityHint("View interactive map of all bridges")
```

### **Fix Touch Target Size**
```swift
Button("X") {
    // action
}
.frame(minWidth: 44, minHeight: 44)
```

### **Add Proper Traits**
```swift
Text("Bridge Status")
.accessibilityAddTraits(.isHeader)
```

---

## 📱 **Testing with VoiceOver**

### **Enable VoiceOver**
1. Settings → Accessibility → VoiceOver → On
2. Or use Siri: "Hey Siri, turn on VoiceOver"

### **VoiceOver Gestures**
- **Single Tap**: Select element
- **Double Tap**: Activate element
- **Swipe Right/Left**: Navigate between elements
- **Two-finger Rotate**: Change rotor setting

### **What to Listen For**
- [ ] **Clear Announcements**: Elements are clearly described
- [ ] **Logical Flow**: Navigation makes sense
- [ ] **Helpful Hints**: Actions are explained
- [ ] **Context**: Elements have proper context

---

## 🎯 **Success Criteria**

### **Accessibility Compliance**
- [ ] All interactive elements have accessibility labels
- [ ] All complex interactions have accessibility hints
- [ ] VoiceOver navigation is logical and helpful
- [ ] Touch targets meet minimum size requirements

### **HIG Compliance**
- [ ] Text is readable (≥17pt default)
- [ ] Contrast ratios meet standards
- [ ] Interactive elements are properly sized
- [ ] Focus indicators are visible

### **User Experience**
- [ ] App is usable with VoiceOver
- [ ] Navigation is intuitive
- [ ] Information is clearly presented
- [ ] Actions are understandable

---

**Next Steps:**
1. Run the app and open Accessibility Inspector
2. Use the catalog template to document findings
3. Test with VoiceOver enabled
4. Create action items for fixes
5. Update the main checklist with results 