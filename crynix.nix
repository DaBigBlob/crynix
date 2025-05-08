{
  cimport = rec {
    # [{a=av; ...} {b=bv; ...} ...] -> {a=av; b=bv; ...}
    attr_list_to_attr = attr_list: builtins.zipAttrsWith (
      name: values:
        # only elem -> elem
        if (builtins.length values) == 1 then (
          builtins.head values
        ) else
        # attr + attr -> recursive this
        if (builtins.all builtins.isAttrs values) then ( 
          attr_list_to_attr values
        ) else
        # list + list -> concat
        if (builtins.all builtins.isList values) then (
          builtins.concatLists values
        ) else
        # error
          builtins.throw "hutil: Cannot merge: [${builtins.toString values}]"
    ) attr_list;

    # [./path/file_name1.nix ./path/file_name2.nix ...] -> [{file_name1=?} {file_name2=?;}...]
    files_to_attr_list = post_import: files: builtins.map (
      file: builtins.listToAttrs [{
        name = builtins.head (
          builtins.match "([[:alnum:]_]+).nix" (builtins.baseNameOf file)
        );
        value = post_import (builtins.import file);
      }]
    ) files;

    # [./path/file_name1.nix ./path/file_name2.nix ...] -> {file_name1attr1=?; file_name1attr2=?; ...; file_name2attr1=?; ...}
    nfimport_mut = post_import: files:
      attr_list_to_attr
      (
        builtins.map
        (file: post_import (builtins.import file))
        files
      )
    ;

    # [./path/file_name1.nix ./path/file_name2.nix ...] -> {file_name1={file_name1attr1=?; file_name1attr2=?; ...;}; file_name2={file_name2attr1=?; ...}; ...}
    fimport_mut = post_import: files:
      attr_list_to_attr
        (files_to_attr_list post_import files)
    ;

    nfimport = args: files:
      nfimport_mut (fn: fn args) files;

    fimport = args: files:
      fimport_mut (fn: fn args) files;

  };
}