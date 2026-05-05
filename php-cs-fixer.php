<?php

// PHP-CS-Fixer configuration based on Early Access Care coding standards
// Implements rules from WEB01 (Organization) and WEB02 (Backend) standards

$finder = PhpCsFixer\Finder::create()
 ->in(__DIR__ . '/../')
 ->exclude(['vendor', 'node_modules', 'storage', 'bootstrap/cache'])
 ->name('*.php')
 ->notName('*.blade.php')
 ->ignoreDotFiles(true)
 ->ignoreVCS(true);

$config = new PhpCsFixer\Config();

return $config
 ->setRules([
  // WEB01 - Organization Standards
  '@PSR12' => true,
  'indentation_type' => true, // Spaces only, no tabs
  'line_ending' => true, // Unix line endings
  'encoding' => true, // UTF-8 encoding

  // WEB02 - Backend Standards
  'class_attributes_separation' => [
   'elements' => [
    'method' => 'one',
    'property' => 'one',
    'trait_import' => 'none',
   ]
  ],

  // PSR-4 compliance
  'psr_autoloading' => true,

  // Naming conventions
  'class_definition' => [
   'single_line' => true,
   'single_item_single_line' => true,
  ],
  'method_argument_space' => [
   'on_multiline' => 'ensure_fully_multiline',
  ],

  // Type declarations
  'declare_strict_types' => false, // Optional based on project needs
  'return_type_declaration' => [
   'space_before' => 'none',
  ],
  'type_declaration_spaces' => [
   'elements' => ['function', 'property'],
  ],

  // Object-oriented design
  'visibility_required' => [
   'elements' => ['method', 'property'],
  ],
  'ordered_class_elements' => [
   'order' => [
    'use_trait',
    'constant_public',
    'constant_protected',
    'constant_private',
    'property_public',
    'property_protected',
    'property_private',
    'construct',
    'destruct',
    'magic',
    'phpunit',
    'method_public',
    'method_protected',
    'method_private',
   ],
  ],

  // Security and best practices
  'no_php_storm_generated_comment' => true,
  'no_unused_imports' => true,
  'ordered_imports' => [
   'imports_order' => ['class', 'function', 'const'],
   'sort_algorithm' => 'alpha',
  ],

  // Formatting rules
  'array_syntax' => ['syntax' => 'short'],
  'binary_operator_spaces' => [
   'default' => 'single_space',
  ],
  'blank_line_after_namespace' => true,
  'blank_line_after_opening_tag' => true,
  'blank_line_before_statement' => [
   'statements' => ['return', 'throw', 'try'],
  ],
  'braces' => [
   'allow_single_line_closure' => true,
   'position_after_functions_and_oop_constructs' => 'same', // One True Brace style
  ],
  'cast_spaces' => ['space' => 'single'],
  'concat_space' => ['spacing' => 'one'],
  'function_declaration' => [
   'closure_function_spacing' => 'one',
  ],
  'include' => true,
  'lowercase_cast' => true,
  'magic_constant_casing' => true,
  'method_chaining_indentation' => true,
  'native_function_casing' => true,
  'new_with_braces' => true,
  'no_blank_lines_after_class_opening' => true,
  'no_blank_lines_after_phpdoc' => true,
  'no_empty_phpdoc' => true,
  'no_empty_statement' => true,
  'no_extra_blank_lines' => [
   'tokens' => [
    'curly_brace_block',
    'extra',
    'parenthesis_brace_block',
    'square_brace_block',
    'throw',
    'use',
   ],
  ],
  'no_leading_import_slash' => true,
  'no_leading_namespace_whitespace' => true,
  'no_mixed_echo_print' => ['use' => 'echo'],
  'no_multiline_whitespace_around_double_arrow' => true,
  'no_short_bool_cast' => true,
  'no_singleline_whitespace_before_semicolons' => true,
  'no_spaces_around_offset' => true,
  'no_trailing_comma_in_list_call' => true,
  'no_trailing_comma_in_singleline_array' => true,
  'no_unneeded_control_parentheses' => true,
  'no_unused_imports' => true,
  'no_whitespace_before_comma_in_array' => true,
  'no_whitespace_in_blank_line' => true,
  'normalize_index_brace' => true,
  'object_operator_without_whitespace' => true,
  'php_unit_fqcn_annotation' => true,
  'phpdoc_align' => true,
  'phpdoc_annotation_without_dot' => true,
  'phpdoc_indent' => true,
  'phpdoc_inline_tag_normalizer' => true,
  'phpdoc_no_access' => true,
  'phpdoc_no_alias_tag' => true,
  'phpdoc_no_empty_return' => true,
  'phpdoc_no_package' => true,
  'phpdoc_no_useless_inheritdoc' => true,
  'phpdoc_return_self_reference' => true,
  'phpdoc_scalar' => true,
  'phpdoc_separation' => true,
  'phpdoc_single_line_var_spacing' => true,
  'phpdoc_summary' => true,
  'phpdoc_to_comment' => true,
  'phpdoc_trim' => true,
  'phpdoc_types' => true,
  'phpdoc_var_without_name' => true,
  'return_type_declaration' => true,
  'semicolon_after_instruction' => true,
  'short_scalar_cast' => true,
  'single_blank_line_before_namespace' => true,
  'single_class_element_per_statement' => true,
  'single_line_comment_style' => true,
  'single_quote' => false, // Allow double quotes as per WEB01
  'space_after_semicolon' => ['remove_in_empty_for_expressions' => true],
  'standardize_not_equals' => true,
  'ternary_operator_spaces' => true,
  'trailing_comma_in_multiline' => true,
  'trim_array_spaces' => true,
  'unary_operator_spaces' => true,
  'whitespace_after_comma_in_array' => true,

  // Constants naming
  'constant_case' => ['case' => 'upper'],

  // Error handling
  'no_unneeded_curly_braces' => true,
  'no_useless_else' => true,
  'no_useless_return' => true,
 ])
 ->setFinder($finder)
 ->setUsingCache(true)
 ->setRiskyAllowed(true);
