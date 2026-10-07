file_path = "/Users/ruju4a/Documents/Expertiza/reimplementation-front-end/src/pages/Questionnaires/QuestionnaireUtils.tsx"
content = File.read(file_path)

# Update transformQuestionnaireRequest
content.gsub!(
  /if \(item.question_type === 'Text area' \|\| item.question_type === 'Criterion'\) \{\s*sizeStr = `\$\{item.textarea_width \|\| ''\},\$\{item.textarea_height \|\| ''\}`;/,
  "if (item.question_type === 'Text area' || item.question_type === 'Criterion') {\n            sizeStr = `\${item.textarea_width || ''},\${item.textarea_height || ''}`;\n          } else if (item.question_type === 'Grid') {\n            sizeStr = `\${item.col_names || ''},\${item.row_names || ''}`;"
)

# Update transformQuestionnaireResponse
content.gsub!(
  /else if \(item.question_type === "Text field" \|\| item.question_type === "TextField"\) \{\s*textbox_width = parts\[0\] \|\| "";\s*\}/,
  "else if (item.question_type === \"Text field\" || item.question_type === \"TextField\") {\n          textbox_width = parts[0] || \"\";\n        } else if (item.question_type === \"Grid\") {\n          item.col_names = parts[0] || \"\";\n          item.row_names = parts[1] || \"\";\n        }"
)

File.write(file_path, content)
