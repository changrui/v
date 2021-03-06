// Copyright (c) 2019-2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module table
// import (
// v.ast
// )
pub struct Table {
	// struct_fields map[string][]string
pub mut:
	types       []Type
	// type_idxs Hashmap
	type_idxs   map[string]int
	local_vars  []Var
	scope_level int
	var_idx     int
	// fns Hashmap
	fns         map[string]Fn
	consts      map[string]Var
	tmp_cnt     int
	imports     []string
}

pub struct Fn {
pub:
	name        string
	args        []Var
	return_type TypeRef
	is_c        bool
}

pub struct Var {
pub:
	name        string
	idx         int
	is_mut      bool
	is_const    bool
	is_global   bool
	scope_level int
mut:
	typ         TypeRef
}

pub fn new_table() &Table {
	mut t := &Table{
		types: make(0, 400, sizeof(Type))
	}
	t.register_builtin_types()
	return t
}

pub fn (t &Table) find_var_idx(name string) int {
	for i, var in t.local_vars {
		if var.name == name {
			return i
		}
	}
	return -1
}

pub fn (t &Table) find_var(name string) ?Var {
	for i in 0 .. t.var_idx {
		if t.local_vars[i].name == name {
			return t.local_vars[i]
		}
	}
	/*
	// println(t.names)
	for var in t.local_vars {
		if var.name == name {
			return var
		}
	}
	*/

	return none
}

pub fn (t mut Table) register_const(v Var) {
	t.consts[v.name] = v
}

pub fn (t mut Table) register_global(name string, typ TypeRef) {
	t.consts[name] = Var{
		name: name
		typ: typ
		is_const: true
		is_global: true
		// mod: p.mod
		// is_mut: true
		// idx: -1
		
	}
}

pub fn (t mut Table) register_var(v Var) {
	println('register_var: $v.name - $v.typ.typ.name')
	new_var := {
		v |
		idx:t.var_idx,
		scope_level:t.scope_level
	}
	// t.local_vars << v
	/*
	if v.line_nr == 0 {
		new_var.token_idx = p.cur_tok_index()
		new_var.line_nr = p.cur_tok().line_nr
	}
	*/
	// Expand the array
	if t.var_idx >= t.local_vars.len {
		t.local_vars << new_var
	}
	else {
		t.local_vars[t.var_idx] = new_var
	}
	t.var_idx++
}

pub fn (t mut Table) open_scope() {
	t.scope_level++
}

pub fn (t mut Table) close_scope() {
	// println('close_scope level=$f.scope_level var_idx=$f.var_idx')
	// Move back `var_idx` (pointer to the end of the array) till we reach
	// the previous scope level.  This effectivly deletes (closes) current
	// scope.
	mut i := t.var_idx - 1
	for ; i >= 0; i-- {
		var := t.local_vars[i]
		/*
		if p.pref.autofree && (v.is_alloc || (v.is_arg && v.typ == 'string')) {
			// && !p.pref.is_test {
			p.free_var(v)
		}
		*/

		// if p.fileis('mem.v') {
		// println(v.name + ' $v.is_arg scope=$v.scope_level cur=$p.cur_fn.scope_level')}
		if var.scope_level != t.scope_level {
			// && !v.is_arg {
			break
		}
	}
	/*
	if p.cur_fn.defer_text.last() != '' {
		p.genln(p.cur_fn.defer_text.last())
		// p.cur_fn.defer_text[f] = ''
	}
	*/

	t.scope_level--
	// p.cur_fn.defer_text = p.cur_fn.defer_text[..p.cur_fn.scope_level + 1]
	t.var_idx = i + 1
	// println('close_scope new var_idx=$f.var_idx\n')
}

pub fn (p mut Table) clear_vars() {
	// shared a := [1, 2, 3]
	p.var_idx = 0
	if p.local_vars.len > 0 {
		// ///if p.pref.autofree {
		// p.local_vars.free()
		// ///}
		p.local_vars = []
	}
}

pub fn (t &Table) find_fn(name string) ?Fn {
	f := t.fns[name]
	if f.name.str != 0 {
		// TODO
		return f
	}
	return none
}

pub fn (t &Table) find_const(name string) ?Var {
	f := t.consts[name]
	if f.name.str != 0 {
		// TODO
		return f
	}
	return none
}

pub fn (t mut Table) register_fn(new_fn Fn) {
	// println('reg fn $new_fn.name nr_args=$new_fn.args.len')
	t.fns[new_fn.name] = new_fn
}

pub fn (t &Table) register_method(typ &Type, new_fn Fn) bool {
	// println('register method `$new_fn.name` type=$typ.name idx=$typ.idx')
	println('register method `$new_fn.name` type=$typ.name')
	mut t1 := typ
	mut methods := typ.methods
	methods << new_fn
	t1.methods = methods
	return true
}

pub fn (t &Type) has_method(name string) bool {
	t.find_method(name) or {
		return false
	}
	return true
}

pub fn (t &Type) find_method(name string) ?Fn {
	for method in t.methods {
		if method.name == name {
			return method
		}
	}
	return none
}

pub fn (t mut Table) new_tmp_var() string {
	t.tmp_cnt++
	return 'tmp$t.tmp_cnt'
}

pub fn (t &Table) struct_has_field(s &Type, name string) bool {
	if !isnil(s.parent) {
		println('struct_has_field($s.name, $name) types.len=$t.types.len s.parent=$s.parent.name')
	}
	else {
		println('struct_has_field($s.name, $name) types.len=$t.types.len s.parent=none')
	}
	// for typ in t.types {
	// println('$typ.idx $typ.name')
	// }
	if _ := t.struct_find_field(s, name) {
		return true
	}
	return false
}

pub fn (t &Table) struct_find_field(s &Type, name string) ?Field {
	if !isnil(s.parent) {
		println('struct_find_field($s.name, $name) types.len=$t.types.len s.parent=$s.parent.name')
	}
	else {
		println('struct_find_field($s.name, $name) types.len=$t.types.len s.parent=none')
	}
	info := s.info as Struct
	for field in info.fields {
		if field.name == name {
			return field
		}
	}
	if !isnil(s.parent) {
		if s.parent.kind == .struct_ {
			parent_info := s.parent.info as Struct
			println('got parent $s.parent.name')
			for field in parent_info.fields {
				if field.name == name {
					return field
				}
			}
		}
	}
	return none
}

[inline]
pub fn (t &Table) find_type_idx(name string) int {
	return t.type_idxs[name]
}

[inline]
pub fn (t &Table) find_type(name string) ?Type {
	idx := t.type_idxs[name]
	if idx > 0 {
		return t.types[idx]
	}
	return none
}

[inline]
pub fn (t mut Table) register_type(typ Type) int {
	existing_idx := t.type_idxs[typ.name]
	if existing_idx > 0 {
		ex_type := t.types[existing_idx]
		match ex_type.kind {
			.placeholder {
				// override placeholder
				println('overriding type placeholder `$typ.name`')
				t.types[existing_idx] = {
					typ |
					methods:ex_type.methods
				}
				return existing_idx
			}
			else {
				if ex_type.kind == typ.kind {
					return existing_idx
				}
				// panic('cannot register type `$typ.name`, another type with this name exists')
				return -1
			}
	}
	}
	typ_idx := t.types.len
	t.types << typ
	t.type_idxs[typ.name] = typ_idx
	return typ_idx
}

pub fn (t &Table) known_type(name string) bool {
	_ = t.find_type(name) or {
		return false
	}
	return true
}

pub fn (t mut Table) find_or_register_map(key_type TypeRef, value_type TypeRef) int {
	name := map_name(&key_type, &value_type)
	// existing
	existing_idx := t.type_idxs[name]
	if existing_idx > 0 {
		return existing_idx
	}
	// register
	map_type := Type{
		parent: &t.types[t.type_idxs['map']]
		kind: .map
		name: name
		info: Map{
			key_type: key_type
			value_type: value_type
		}
	}
	return t.register_type(map_type)
}

pub fn (t mut Table) find_or_register_array(elem_type TypeRef, nr_dims int) int {
	name := array_name(&elem_type, nr_dims)
	// existing
	existing_idx := t.type_idxs[name]
	if existing_idx > 0 {
		return existing_idx
	}
	// register
	array_type := Type{
		parent: &t.types[t.type_idxs['array']]
		kind: .array
		name: name
		info: Array{
			elem_type: elem_type
			nr_dims: nr_dims
		}
	}
	return t.register_type(array_type)
}

pub fn (t mut Table) find_or_register_array_fixed(elem_type TypeRef, size int, nr_dims int) int {
	name := array_fixed_name(&elem_type, size, nr_dims)
	// existing
	existing_idx := t.type_idxs[name]
	if existing_idx > 0 {
		return existing_idx
	}
	// register
	array_fixed_type := Type{
		parent: 0
		kind: .array_fixed
		name: name
		info: ArrayFixed{
			elem_type: elem_type
			size: size
			nr_dims: nr_dims
		}
	}
	return t.register_type(array_fixed_type)
}

pub fn (t mut Table) find_or_register_multi_return(mr_typs []TypeRef) int {
	mut name := 'multi_return'
	for mr_typ in mr_typs {
		name += '_$mr_typ.typ.name'
	}
	// existing
	existing_idx := t.type_idxs[name]
	if existing_idx > 0 {
		return existing_idx
	}
	// register
	mr_type := Type{
		parent: 0
		kind: .multi_return
		name: name
		info: MultiReturn{
			types: mr_typs
		}
	}
	return t.register_type(mr_type)
}

pub fn (t mut Table) find_or_register_variadic(variadic_typ TypeRef) int {
	name := 'variadic_$variadic_typ.typ.name'
	// existing
	existing_idx := t.type_idxs[name]
	if existing_idx > 0 {
		return existing_idx
	}
	// register
	variadic_type := Type{
		parent: 0
		kind: .variadic
		name: name
		info: Variadic{
			typ: variadic_typ
		}
	}
	return t.register_type(variadic_type)
}

pub fn (t mut Table) add_placeholder_type(name string) int {
	ph_type := Type{
		parent: 0
		kind: .placeholder
		name: name
	}
	// println('added placeholder: $name - $ph_type.idx')
	return t.register_type(ph_type)
}

pub fn (t &Table) check(got, expected &TypeRef) bool {
	println('check: $got.typ.name, $expected.typ.name')
	if expected.typ.kind == .voidptr {
		return true
	}
	if expected.typ.kind == .byteptr && got.typ.kind == .voidptr {
		return true
	}
	// if expected.name == 'array' {
	// return true
	// }
	if got.idx != expected.idx && got.typ.name != expected.typ.name {
		return false
	}
	return true
}

/*
[inline]
pub fn (t &Table) get_expr_typ(expr ast.Expr) Type {
	match expr {
		ast.ArrayInit {
			return it.typ
		}
		ast.IndexExpr {
			return t.get_expr_typ(it.left)
		}
		ast.CallExpr {
			func := t.find_fn(it.name) or {
				return void_typ
			}
			return func.return_typ
		}
		ast.MethodCallExpr {
			ti := t.get_expr_typ(it.expr)
			func := t.find_method(typ.idx, it.name) or {
				return void_type
			}
			return func.return_typ
		}
		ast.Ident {
			if it.kind == .variable {
				info := it.info as ast.IdentVar
				if info.typ.kind != .unresolved {
					return info.ti
				}
				return t.get_expr_typ(info.expr)
			}
			return types.void_typ
		}
		ast.StructInit {
			return it.ti
		}
		ast.StringLiteral {
			return types.string_typ
		}
		ast.IntegerLiteral {
			return types.int_typ
		}
		ast.SelectorExpr {
			ti := t.get_expr_typ(it.expr)
			kind := t.types[typ.idx].kind
			if typ.kind == .placeholder {
				println(' ##### PH $typ.name')
			}
			if !(kind in [.placeholder, .struct_]) {
				return types.void_typ
			}
			struct_ := t.types[typ.idx]
			struct_info := struct_.info as types.Struct
			for field in struct_info.fields {
				if field.name == it.field {
					return field.ti
				}
			}
			if struct_.parent_idx != 0 {
				parent := t.types[struct_.parent_idx]
				parent_info := parent.info as types.Struct
				for field in parent_info.fields {
					if field.name == it.field {
						return field.ti
					}
				}
			}
			return types.void_typ
		}
		ast.InfixExpr {
			return t.get_expr_typ(it.left)
		}
		else {
			return types.void_typ
		}
	}
}
*/
