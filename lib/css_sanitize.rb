# Include this module into your ActiveRecord model.
module CssSanitize

  def custom_css=(text)
    # Mostly stolen from http://code.sixapart.com/svn/CSS-Cleaner/trunk/lib/CSS/Cleaner.pm
    text = "Error: invalid/disallowed characters in CSS" if text =~ /\w\/\/*/ # a comment immediately following a letter
    text = "Error: invalid/disallowed characters in CSS" if text =~ /\/\*\// # /*/ --> hack attempt, IMO

    # Now, strip out any comments, and do some parsing.
    no_comments = text.gsub(/(\/\*.*?\*\/)/, "") # filter out any /* ... */
    no_comments.gsub!("\n", "")
    # No backslashes allowed
    evil = [
      /(\bdata:\b|eval|cookie|\bwindow\b|\bparent\b|\bthis\b)/i, # suspicious javascript-type words
      /behaviou?r|expression|moz-binding|@import|@charset|(java|vb)?script|[\<]|\\\w/i,
      /[\<>]/, # back slash, html tags,
      /[\x7f-\xff]/, # high bytes -- suspect
      /[\x00-\x08\x0B\x0C\x0E-\x1F]/, #low bytes -- suspect
      /&\#/, # bad charset
    ]
    evil.each { |regex| text = "Error: invalid/disallowed characters in CSS" and break if no_comments =~ regex }

    write_attribute :custom_css, text
  end
end