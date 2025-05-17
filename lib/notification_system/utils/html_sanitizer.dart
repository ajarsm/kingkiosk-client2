// lib/notification_system/utils/html_sanitizer.dart

class HtmlSanitizer {
  static String sanitize(String html) {
    // Remove script tags and their content
    html = html.replaceAll(RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>'), '');
    
    // Remove dangerous attributes from all tags
    final dangerousAttributes = [
      'onclick', 'onload', 'onunload', 'onabort', 'onerror', 'onblur', 'onchange', 
      'onfocus', 'onreset', 'onsubmit', 'javascript:', 'eval', 'expression'
    ];
    
    for (final attr in dangerousAttributes) {
      html = html.replaceAll(RegExp(' $attr="[^"]*"'), '');
      html = html.replaceAll(RegExp(" $attr='[^']*'"), '');
      html = html.replaceAll(RegExp(' $attr=[^ >]*'), '');
    }
    
    // Remove dangerous tags and their content
    final dangerousTags = [
      'iframe', 'object', 'embed', 'form', 'input', 'button',
      'textarea', 'select', 'option', 'applet', 'xml', 'meta'
    ];
    
    for (final tag in dangerousTags) {
      html = html.replaceAll(RegExp('<$tag\\b[^<]*(?:(?!<\\/$tag>)<[^<]*)*<\\/$tag>'), '');
      html = html.replaceAll(RegExp('<$tag\\b[^>]*>'), '');
      html = html.replaceAll(RegExp('<\\/$tag>'), '');
    }
    
    return html;
  }
}