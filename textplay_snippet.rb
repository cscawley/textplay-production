#!/usr/bin/ruby

# This script is based on Textplay [http://olivertaylor.net/textplay]
# But instead of outputting a full HTML file, this outputs just the marked-up text.


# Textplay -- A plain-text conversion tool for screenwriters
#
# Version 0.5
# Copyright (c) 2006 Oliver Taylor
# <http://olivertaylor.net/textplay/>
#
# Textplay was build and tested by Oliver using Ruby 1.8.7
# on Mac OS X 10.7 and Final Draft 8.0. It works for me, but I can't
# promise it won't delete your documents or worse; use at your own risk,
# be careful with your data, backup regularly, etc.

# TEXTPLAY LICENCE
#
# Textplay is free software, available under a BSD-style
# open source license.
#
# Copyright 2006, Oliver Taylor http://olivertaylor.net/ All rights
# reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# * Neither the name "Textplay" nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# This software is provided by the copyright holders and contributors
# "as is" and any express or implied warranties, including, but not
# limited to, the implied warranties of merchantability and fitness for
# a particular purpose are disclaimed. In no event shall the copyright
# owner or contributors be liable for any direct, indirect, incidental,
# special, exemplary, or consequential damages (including, but not
# limited to, procurement of substitute goods or services; loss of use,
# data, or profits; or business interruption) however caused and on any
# theory of liability, whether in contract, strict liability, or tort
# (including negligence or otherwise) arising in any way out of the use
# of this software, even if advised of the possibility of such damage.
#
# ---------------------------------------------------------------------


# Add a "screenplay" wrapper so it looks good when styled.
head = '<div id="screenplay">'
tail = '</div><!--screenplay-->'

# Load input to "text"
text = ARGF.read

# ----- MARKUP -----------------------------------------------------

# Misc Encoding
text = text.gsub(/^[ \t]*([=-]{3,})[ \t]*$/, '<page-break />')
text = text.gsub(/&/, '&#38;')
text = text.gsub(/([^-])--([^-])/, '\1&#8209;&#8209;\2')

# -------- fountain escapes
# Transitions enting in {to:} with a space after
text = text.gsub(/^(.+ )TO: +$/, "\n"+'<action>\1TO:</action>')

# Caps lines => action - two spaces at end of line
text = text.gsub(/^[\ \t]*\n([\ \t]*[^\na-z]+)  $/, "\n"+'<action>\1</action>')

# Boneyard and notes
text = text.gsub(/\/\*(.|\n)+?\*\//, '<secret />')
# Perhaps secrets shouldn't be removed completely but programmatically it is too difficult to prevent further xml transformations within these blocks.
text = text.gsub(/\[{2}([^\]\n]+?)\]{2}/,'<note>\1</note>')

# Fountain Rules
text = text.gsub(/^[\ \t]*>[ ]*(.+?)[ ]*<[\ \t]*$/, '<center>\1</center>')
text = text.gsub(/^[\ \t]*\>[ \t]*(.*)$/,'<transition>\1</transition>')

text = text.gsub(/^\.(?!\.)[\ \t]*(.*)$/, '<slug>\1</slug>')
text = text.gsub(/\\\*/, '&#42;')

# Strip-out Fountain Sections and Synopses
text = text.gsub(/^#+[ \t]+(.*)/,'<secret>\1</secret>')
text = text.gsub(/^=[ \t]+(.*)/,'<secret>\1</secret>')
# these need not be completely removed simply because they do not span multiple lines

# Textplay/Screenbundle comments
text = text.gsub(/^[ \t]*\/\/\s?(.*)$/, '<note>\1</note>')


# -------- Transitions
# Left-Transitions
text = text.gsub(/
  # Require preceding empty line or beginning of document
  (^[\ \t]* \n | \A)
  # 1 or more words, a space
  ^[\ \t]* (  \w+(?:\ \w+)* [\ ]
  # One of these words
  (UP|IN|OUT|BLACK|WITH)  (\ ON)?
  # Ending with transition punctuation
  ([\.\:][\ ]*)    )\n
  # trailing empty line
  ^[\ \t]*$
/x, "\n"+'<transition>\2</transition>'+"\n")

# Right-Transitions
text = text.gsub(/
# Require preceding empty line or beginning of document
  (^[\ \t]* \n | \A)
# 1 or more words, a space
  ^[\ \t]* (  \w+(?:\ \w+)* [\ ]
# The word "TO"
  (TO)
# Ending in a colon
  (\:)$)\n
  # trailing empty line
  ^[\ \t]*$
/x, "\n"+'<transition>\2</transition>'+"\n")


# ------- Dialogue
# IDENTIFY AND TAG A DIALOGUE-BLOCK
text = text.gsub(/
# Require preceding empty line
^[\ \t]* \n
# Character Name
^[\ \t]* [^a-z\n\t]+ \n
# Dialogue
(^[\ \t]* .+ \n)+
# Require trailing empty line
^[\ \t]*$
/x, "\n"+'<dialogue>'+'\0'+'</dialogue>'+"\n")

# SEARCH THE DIALOGUE-BLOCK FOR CHARACTERS
text = text.gsub(/<dialogue>\n(.|\n)+?<\/dialogue>/x){|character|
	character.gsub(/(<dialogue>\n)[ \t]*([^a-z\n]+)(?=\n)/, '\1<character>\2</character>')
}

# SEARCH THE DIALOGUE-BLOCK FOR PARENTHETICALS
text = text.gsub(/<dialogue>\n(.|\n)+?<\/dialogue>/x){|paren|
	paren.gsub(/^[ \t]*(\([^\)]+\))[ \t]*(?=\n)/, '<paren>\1</paren>')
}

# SEARCH THE DIALOGUE-BLOCK FOR DIALOG
text = text.gsub(/<dialogue>\n(.|\n)+?<\/dialogue>/x){|talk|
	talk.gsub(/^[ \t]*([^<\n]+)$/, '<talk>\1</talk>')
}


# ------- Scene Headings

# FULLY-FORMED SLUGLINES
text = text.gsub(/
# Require leading empty line
^[\ \t]* \n
# Respect leading whitespace
^[\ \t]*
# Standard prefixes, allowing for bold-italic
((?:[\*\_]+)?(i\.?\/e|int\.?\/ext|ext|int|est)
# A separator between prefix and location
(\ +|.\ ?).*) \n
# Require trailing empty line
^[\ \t]* \n
/xi, "\n"+'<sceneheading>\1</sceneheading>'+"\n\n")

# GOLDMAN SLUGLINES
text = text.gsub(/
# Require leading empty line
^[\ \t]* \n
# Any line with all-uppercase
^[ \t]*(?=\S)([^a-z\<\>\n]+)$
/x, "\n"+'<slug>\1</slug>')


# ------- Misc

# Any untagged paragraph gets tagged as 'action'
text = text.gsub(/^([^\n\<].*)/, '<action>\1</action>')

# Bold, Italic, Underline
text = text.gsub(/([ \t\-_:;>])\*{3}([^\*\n]+)\*{3}(?=[ \t\)\]<\-_&;:?!.,])/, '\1<b><i>\2</i></b>')
text = text.gsub(/([ \t\-_:;>])\*{2}([^\*\n]+)\*{2}(?=[ \t\)\]<\-_&;:?!.,])/, '\1<b>\2</b>')
text = text.gsub(/([ \t\-_:;>])\*{1}([^\*\n]+)\*{1}(?=[ \t\)\]<\-_&;:?!.,])/, '\1<i>\2</i>')
text = text.gsub(/([ \t\-\*:;>])\_{1}([^\_\n]+)\_{1}(?=[ \t\)\]<\-\*&;:?!.,])/, '\1<u>\2</u>')

# This cleans up action paragraphs with line-breaks.
text = text.gsub(/<\/action>[ \t]*(\n)[ \t]*<action>/,'\1')

# Convert tabs to spaces within action
text = text.gsub(/<action>(.|\n)+?<\/action>/x){|tabs|
	tabs.gsub(/\t/, '    ')
}

# This cleans up dialogue blocks with line-breaks.
text = text.gsub(/<\/talk>[ \t]*(\n)[ \t]*<talk>/,'\1')

# ----- HTML -----------------------------------------------------

  # default HTML formatting  
  text = text.gsub(/<note>/, '<p class="comment">')
  text = text.gsub(/<\/note>/, '</p>')
  text = text.gsub(/<secret \/>/, '')
  text = text.gsub(/<page-break \/>/, '<div class="page-break"></div>')
  text = text.gsub(/<transition>/, '<h3 class="right-transition">')
  text = text.gsub(/<\/transition>/, '</h3>')
  text = text.gsub(/<sceneheading>/, '<h2 class="full-slugline">')
  text = text.gsub(/<\/sceneheading>/, '</h2>')
  text = text.gsub(/<slug>/, '<h5 class="goldman-slugline">')
  text = text.gsub(/<\/slug>/, '</h5>')
  text = text.gsub(/<center>/, '<p class="center">')
  text = text.gsub(/<\/center>/, '</p>')
  text = text.gsub(/<dialogue>/,'<dl>')
  text = text.gsub(/<\/dialogue>/,'</dl>')
  text = text.gsub(/<character>/, '<dt class="character">')
  text = text.gsub(/<\/character>/, '</dt>')
  text = text.gsub(/<paren>/, '<dd class="parenthetical">')
  text = text.gsub(/<\/paren>/, '</dd>')
  text = text.gsub(/<talk>/, '<dd class="dialogue">')
  text = text.gsub(/<\/talk>/, '</dd>')
  text = text.gsub(/<action>/, '<p class="action">')
  text = text.gsub(/<\/action>/, '</p>')

# ----- OUTPUT -----------------------------------------------------

puts head
puts text
puts tail