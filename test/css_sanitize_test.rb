require File.dirname(__FILE__) + '/../test_helper'

class Site < ActiveRecord::Base
  include CssSanitize
end

class CssSanitizeTest < Test::Unit::TestCase

  before do
    @site = Site.new(:name => 'Foo', :owner_id => 1)
  end

  it "disallows evil css" do
    bad_strings = [
      "div.foo { width: 500px; behavior: url(http://foo.com); height: 200px; }",
      ".test { color: red; background-image: url('javascript:alert');  border: 1px solid brown; }",
      "div.foo { width: 500px; -moz-binding: foo; height: 200px; }",
      
      # no @import for you
      "\@import url(javascript:alert('Your cookie:'+document.cookie));",
      
      # no behavior either
      "behaviour:expression(function(element){alert(&#39;xss&#39;);}(this));'>",
      
      # case-sensitivity test
      '-Moz-binding: url("http://www.example.comtest.xml");',

      # \uxxrl unicode
      "background:\75rl('javascript:alert(\"\\75rl\")');",
      "background:&#x75;rl(javascript:alert('html &amp;#x75;'))",
      "b\nackground: url(javascript:alert('line-broken background '))",
      "background:&#xff55;rl(javascript:alert('&amp;#xff55;rl(full-width u)'))",
      "background:&#117;rl(javascript:alert(&amp;#117;rl'))",
      "background:&#x75;rl(javascript:alert('&amp;#x75;rl'))",
      "background:\75rl('javascript:alert(\"\\75rl\")')",

      # \\d gets parsed out on ffx and ie
      "background:url(&quot;javascri\\dpt:alert('injected js goes here')&quot;)",

      # http://rt.livejournal.org/Ticket/Display.html?id=436
      '-\4d oz-binding: url("http://localhost/test.xml#foo");',

      # css comments are ignored sometimes
      "xss:expr/*XSS*/ession(alert('XSS'));",
      
      # html comments? fail
      "background:url(java<!-- -->script:alert('XSS'));",
      
      # weird comments
      'color: e/* * / */xpression("r" + "e" + "d");',

      # weird comments to really test that regex
      'color: e/*/**/xpression("r" + "e" + "d");',

      # we're not using a parser, but nonetheless ... if we were..
      <<-STR
      p {
      dummy: '//'; background:url(javascript:alert('XSS'));
      }
STR
    ]
    bad_strings.each do |string|
      @site.custom_css = string
      @site.custom_css.should == "Error: invalid/disallowed characters in CSS"
    end
  end
  
  
  it "allows good css" do
    good_strings = [
      ".test { color: red; border: 1px solid brown; }",
      "h1 { background: url(http://foobar.com/meh.jpg)}",
      "div.foo { width: 500px; height: 200px; }",
      "GI b gkljfl kj { { { ********" # gibberish, but should work.
    ]
    good_strings.each do |string|
      @site.custom_css = string
      @site.custom_css.should == string
    end

  end

  it "does not strip real comments" do
    text = <<STR
a.foo { bar: x }

/* Group: header */
a.bar { x: poo }
STR
    @site.custom_css = text
    @site.custom_css.should == text
  end

  it "does strip suspicious comments" do
          text = <<-STR
    a.foo { ba/* hack */r: x }

    /* Group: header */
    a.bar { x: poo }
STR
    @site.custom_css = text
    @site.custom_css.should == "Error: invalid/disallowed characters in CSS"
    @site.custom_css = "Foo /*/**/ Bar"
    @site.custom_css.should == "Error: invalid/disallowed characters in CSS"
  end

  it "doesn't allow bad css" do
    @site.custom_css = <<STR
test{ width: expression(alert("sux 2 be u")); }
a:link { color: red }
STR
    @site.custom_css.should == "Error: invalid/disallowed characters in CSS"
  end

end