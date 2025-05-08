
rec {
  hutil = rec {

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
    himport_mut = post_import: files:
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

    himport = args: files:
      himport_mut (fn: fn args) files;

    fimport = args: files:
      fimport_mut (fn: fn args) files;

  };

  # dem2 = hutil.files_to_named_attr (a: a) [
  #   ./demo.nix
  #   ./demo2.nix
  # ];
  # dem3 = hutil.unname_named_attr dem2;
  # dem4 = hutil.files_to_attr (a: a) [
  #   ./demo.nix
  #   ./demo2.nix
  # ];
  # dem5 = hutil.himport 4 [
  #   ./hdem1.nix
  #   ./hdem2.nix
  # ];
  # dem6 = hutil.attr_list_to_attr [
  #   {a.b.c = [2];}
  #   {a.b.c = [2];}
  #   {a.f.c = 4;}
  # ];
  # dem7 = builtins.zipAttrsWith (n: v: {n=n;v=v;}) [ {a=1;} {b=2;} ];
  dem8 = hutil.fimport 3 [
    ./hdem1.nix
    ./hdem2.nix
  ];
  dem9 = hutil.himport 3 [
    ./hdem1.nix
    ./hdem2.nix
  ];
  dem10 = hutil.attr_list_to_attr [dem8 dem9];
}