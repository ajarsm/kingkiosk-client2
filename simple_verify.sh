#!/bin/bash
echo "1. Testing blue outline removal:"
grep -r "border: Border.all(color: Colors.transparent" --include="*.dart" . 
echo "----"

echo "2. Testing WebView scroll settings:"
grep -r "verticalScrollBarEnabled: true" --include="*.dart" .
echo "----"

echo "3. Testing touch event handling:"
grep -r "touchstart" --include="*.dart" .
echo "----"

echo "4. Testing onLoadStop duplication fix:"
echo "Number of onLoadStop occurrences:"
grep -c "onLoadStop" lib/app/modules/home/widgets/web_view_tile.dart
echo "----"
