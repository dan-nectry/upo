open Bootstrap4

type t1 (full :: {Type}) (p :: (Type * {Type} * {Type} * {{Unit}} * Type * Type * Type)) =
     {Title : string,
      Extra : transaction xbody,
      Table : sql_table p.2 p.4,
      Insert : $p.2 -> p.7 -> transaction unit,
      Update : p.1 -> $p.2 -> p.7 -> transaction unit,
      Delete : p.1 -> transaction unit,
      List : sql_exp [Tab = p.2] [] [] bool -> transaction (list p.1),
      KeyIs : nm :: Name -> p.1 -> sql_exp [nm = p.2] [] [] bool,
      Show : show p.1,
      Config : transaction p.5,
      Auxiliary : p.1 -> $p.2 -> transaction p.7,
      Render : (variant full -> string -> xbody) -> p.7 -> $p.2 -> xtable,
      FreshWidgets : p.5 -> transaction p.6,
      WidgetsFrom : p.5 -> $p.2 -> p.7 -> transaction p.6,
      RenderWidgets : p.5 -> p.6 -> xbody,
      ReadWidgets : p.6 -> signal ($p.3 * p.7 * option string (* Error message, if something is amiss *)),
      KeyOf : $p.2 -> p.1,
      ForIndex : transaction (list (p.1 * xbody))}

type t (full :: {Type}) (tables :: {(Type * {Type} * {Type} * {{Unit}} * Type * Type * Type)}) =
    $(map (t1 full) tables)

type base1 = unit
type base2 = unit
type base3 = unit

val none [full ::: {Type}] = {}

datatype index_style exp row =
         Default of exp
       | Custom of transaction (list row)

fun one [full ::: {Type}]
        [tname :: Name] [key :: Name] [keyT ::: Type] [rest ::: {Type}] [cstrs ::: {{Unit}}]
        [old ::: {(Type * {Type} * {Type} * {{Unit}} * Type * Type * Type)}]
        [[key] ~ rest] [[tname] ~ old]
        (tab : sql_table ([key = keyT] ++ rest) cstrs) (title : string) (extra : transaction xbody)
        (isty : index_style (sql_exp [Tab = [key = keyT] ++ rest] [] [] bool) (keyT * xbody))
        (sh : show keyT) (inj : sql_injectable keyT) (injs : $(map sql_injectable rest))
        (fl : folder rest) (ofl : folder old) (old : t full old) =
    {tname = {Title = title,
              Extra = extra,
              Table = tab,
              Insert = fn r () => @@Sql.easy_insert [[key = _] ++ rest] [_] ({key = inj} ++ injs) (@Folder.cons [_] [_] ! fl) tab r,
              Update = fn k r () => @@Sql.easy_update' [[key = _]] [rest] [_] ! {key = inj} injs _ fl tab {key = k} r (WHERE TRUE),
              Delete = fn _ => return (),
              List = fn wher => List.mapQuery (SELECT tab.{key}
                                               FROM tab
                                               WHERE {wher}
                                               ORDER BY tab.{key})
                                              (fn {Tab = r} => r.key),
              KeyIs = fn [nm ::_] v => (WHERE {{nm}}.{key} = {[v]}),
              Show = sh,
              Config = return (),
              Auxiliary = fn _ _ => return (),
              Render = fn _ _ _ => <xml></xml>,
              FreshWidgets = fn () => return (),
              WidgetsFrom = fn () _ _ => return (),
              RenderWidgets = fn () () => <xml></xml>,
              ReadWidgets = fn () => return ((), (), None),
              KeyOf = fn r => r.key,
              ForIndex = case isty of
                             Default fltr => List.mapQuery (SELECT tab.{key}
                                                            FROM tab
                                                            WHERE {fltr}
                                                            ORDER BY tab.{key})
                                                           (fn {Tab = r} => (r.key, txt r.key))
                           | Custom xa => xa}} ++ old

fun two [full ::: {Type}]
        [tname :: Name] [key1 :: Name] [key2 :: Name] [keyT1 ::: Type] [keyT2 ::: Type]
        [rest ::: {Type}] [cstrs ::: {{Unit}}] [old ::: {(Type * {Type} * {Type} * {{Unit}} * Type * Type * Type)}]
        [[key1] ~ [key2]] [[key1, key2] ~ rest] [[tname] ~ old]
        (tab: sql_table ([key1 = keyT1, key2 = keyT2] ++ rest) cstrs) (title : string) (extra : transaction xbody)
        (isty : index_style (sql_exp [Tab = [key1 = keyT1, key2 = keyT2] ++ rest] [] [] bool) (keyT1 * keyT2 * xbody))
        (sh : show (keyT1 * keyT2)) (inj1 : sql_injectable keyT1) (inj2 : sql_injectable keyT2)
        (injs : $(map sql_injectable rest)) (fl : folder rest) (ofl : folder old)
        (old : t full old) =
    {tname = {Title = title,
              Extra = extra,
              Table = tab,
              Insert = fn r () => @@Sql.easy_insert [[key1 = _, key2 = _] ++ rest] [_] ({key1 = inj1, key2 = inj2} ++ injs) (@Folder.cons [_] [_] ! (@Folder.cons [_] [_] ! fl)) tab r,
              Update = fn (k1, k2) r () => @@Sql.easy_update' [[key1 = _, key2 = _]] [rest] [_] ! {key1 = inj1, key2 = inj2} injs _ fl tab {key1 = k1, key2 = k2} r (WHERE TRUE),
              Delete = fn _ => return (),
              List = fn wher => List.mapQuery (SELECT tab.{key1}, tab.{key2}
                                               FROM tab
                                               WHERE {wher}
                                               ORDER BY tab.{key1}, tab.{key2})
                                   (fn {Tab = r} => (r.key1, r.key2)),
              KeyIs = fn [nm ::_] (v1, v2) => (WHERE {{nm}}.{key1} = {[v1]}
                                                 AND {{nm}}.{key2} = {[v2]}),
              Show = sh,
              Config = return (),
              Auxiliary = fn _ _ => return (),
              Render = fn _ _ _ => <xml></xml>,
              FreshWidgets = fn () => return (),
              WidgetsFrom = fn () _ _ => return (),
              RenderWidgets = fn () () => <xml></xml>,
              ReadWidgets = fn () => return ((), (), None),
              KeyOf = fn r => (r.key1, r.key2),
              ForIndex = case isty of
                             Default fltr => List.mapQuery (SELECT tab.{key1}, tab.{key2}
                                                            FROM tab
                                                            WHERE {fltr}
                                                            ORDER BY tab.{key1}, tab.{key2})
                                                           (fn {Tab = r} => ((r.key1, r.key2), txt (r.key1, r.key2)))
                           | Custom xa =>
                             ls <- xa;
                             return (List.mp (fn (k1, k2, b) => ((k1, k2), b)) ls)}} ++ old

type text1 t = t
type text2 t = source string * t
type text3 t = t

fun text [full ::: {Type}]
         [tname :: Name] [key ::: Type] [col :: Name] [colT ::: Type]
         [cols ::: {Type}] [colsDone ::: {Type}] [cstrs ::: {{Unit}}]
         [impl1 ::: Type] [impl2 ::: Type] [impl3 ::: Type] [old ::: {(Type * {Type} * {Type} * {{Unit}} * Type * Type * Type)}]
         [[col] ~ cols] [[col] ~ colsDone] [[tname] ~ old]
         (lab : string) (_ : show colT) (_ : read colT)
         (old : t full ([tname = (key, [col = colT] ++ cols, colsDone, cstrs, impl1, impl2, impl3)] ++ old)) =
    old -- tname
        ++ {tname = old.tname
                        -- #Render -- #FreshWidgets -- #WidgetsFrom -- #RenderWidgets -- #ReadWidgets
                        ++ {Render = fn entry aux r =>
                                        <xml>
                                          {old.tname.Render entry aux r}
                                          <tr>
                                            <th>{[lab]}</th>
                                            <td>{[r.col]}</td>
                                          </tr>
                                        </xml>,
                            FreshWidgets = fn cfg =>
                               s <- source "";
                               ws <- old.tname.FreshWidgets cfg;
                               return (s, ws),
                            WidgetsFrom = fn cfg r aux =>
                               s <- source (show r.col);
                               ws <- old.tname.WidgetsFrom cfg r aux;
                               return (s, ws),
                            RenderWidgets = fn cfg (s, ws) =>
                                               <xml>
                                                 {old.tname.RenderWidgets cfg ws}
                                                 <div class="form-group">
                                                   <label class="control-label">{[lab]}</label>
                                                   <ctextbox class="form-control" source={s}/>
                                                 </div>
                                               </xml>,
                            ReadWidgets = fn (s, ws) =>
                                             v <- signal s;
                                             (wsv, aux, err) <- old.tname.ReadWidgets ws;
                                             return ({col = readError v} ++ wsv, aux, err)}}

fun hyperref [full ::: {Type}]
             [tname :: Name] [key ::: Type] [col :: Name] [colT ::: Type]
             [cols ::: {Type}] [colsDone ::: {Type}] [cstrs ::: {{Unit}}]
             [impl1 ::: Type] [impl2 ::: Type] [impl3 ::: Type] [old ::: {(Type * {Type} * {Type} * {{Unit}} * Type * Type * Type)}]
             [[col] ~ cols] [[col] ~ colsDone] [[tname] ~ old]
             (lab : string) (_ : show colT) (_ : read colT)
             (old : t full ([tname = (key, [col = colT] ++ cols, colsDone, cstrs, impl1, impl2, impl3)] ++ old)) =
    old -- tname
        ++ {tname = old.tname
                        -- #Render -- #FreshWidgets -- #WidgetsFrom -- #RenderWidgets -- #ReadWidgets
                        ++ {Render = fn entry aux r =>
                                        <xml>
                                          {old.tname.Render entry aux r}
                                          {case checkUrl (show r.col) of
                                               None => <xml></xml>
                                             | Some url => <xml><tr>
                                               <th>{[lab]}</th>
                                               <td><a href={url}><tt>{[r.col]}</tt></a></td>
                                             </tr></xml>}
                                        </xml>,
                            FreshWidgets = fn cfg =>
                               s <- source "";
                               ws <- old.tname.FreshWidgets cfg;
                               return (s, ws),
                            WidgetsFrom = fn cfg r aux =>
                               s <- source (show r.col);
                               ws <- old.tname.WidgetsFrom cfg r aux;
                               return (s, ws),
                            RenderWidgets = fn cfg (s, ws) =>
                                               <xml>
                                                 {old.tname.RenderWidgets cfg ws}
                                                 <div class="form-group">
                                                   <label class="control-label">{[lab]}</label>
                                                   <ctextbox class="form-control" source={s}/>
                                                 </div>
                                               </xml>,
                            ReadWidgets = fn (s, ws) =>
                                             v <- signal s;
                                             (wsv, aux, err) <- old.tname.ReadWidgets ws;
                                             return ({col = readError v} ++ wsv, aux, err)}}

fun image [full ::: {Type}]
          [tname :: Name] [key ::: Type] [col :: Name] [colT ::: Type]
          [cols ::: {Type}] [colsDone ::: {Type}] [cstrs ::: {{Unit}}]
          [impl1 ::: Type] [impl2 ::: Type] [impl3 ::: Type] [old ::: {(Type * {Type} * {Type} * {{Unit}} * Type * Type * Type)}]
          [[col] ~ cols] [[col] ~ colsDone] [[tname] ~ old]
          (lab : string) (_ : show colT) (_ : read colT) (cls : css_class)
          (old : t full ([tname = (key, [col = colT] ++ cols, colsDone, cstrs, impl1, impl2, impl3)] ++ old)) =
    old -- tname
        ++ {tname = old.tname
                        -- #Render -- #FreshWidgets -- #WidgetsFrom -- #RenderWidgets -- #ReadWidgets
                        ++ {Render = fn entry aux r =>
                                        <xml>
                                          {old.tname.Render entry aux r}
                                          {case checkUrl (show r.col) of
                                               None => <xml></xml>
                                             | Some url => <xml><tr>
                                               <th>{[lab]}</th>
                                               <td><img src={url} class={cls}/></td>
                                             </tr></xml>}
                                        </xml>,
                            FreshWidgets = fn cfg =>
                               s <- source "";
                               ws <- old.tname.FreshWidgets cfg;
                               return (s, ws),
                            WidgetsFrom = fn cfg r aux =>
                               s <- source (show r.col);
                               ws <- old.tname.WidgetsFrom cfg r aux;
                               return (s, ws),
                            RenderWidgets = fn cfg (s, ws) =>
                                               <xml>
                                                 {old.tname.RenderWidgets cfg ws}
                                                 <div class="form-group">
                                                   <label class="control-label">{[lab]}</label>
                                                   <ctextbox class="form-control" source={s}/>
                                                 </div>
                                               </xml>,
                            ReadWidgets = fn (s, ws) =>
                                             v <- signal s;
                                             (wsv, aux, err) <- old.tname.ReadWidgets ws;
                                             return ({col = readError v} ++ wsv, aux, err)}}

fun textOpt [full ::: {Type}]
            [tname :: Name] [key ::: Type] [col :: Name] [colT ::: Type]
            [cols ::: {Type}] [colsDone ::: {Type}] [cstrs ::: {{Unit}}]
            [impl1 ::: Type] [impl2 ::: Type] [impl3 ::: Type] [old ::: {(Type * {Type} * {Type} * {{Unit}} * Type * Type * Type)}]
            [[col] ~ cols] [[col] ~ colsDone] [[tname] ~ old]
            (lab : string) (_ : show colT) (_ : read colT)
            (old : t full ([tname = (key, [col = option colT] ++ cols, colsDone, cstrs, impl1, impl2, impl3)] ++ old)) =
    old -- tname
        ++ {tname = old.tname
                        -- #Render -- #FreshWidgets -- #WidgetsFrom -- #RenderWidgets -- #ReadWidgets
                        ++ {Render = fn entry aux r =>
                                        <xml>
                                          {old.tname.Render entry aux r}
                                          <tr>
                                            <th>{[lab]}</th>
                                            <td>{[r.col]}</td>
                                          </tr>
                                        </xml>,
                            FreshWidgets = fn cfg =>
                               s <- source "";
                               ws <- old.tname.FreshWidgets cfg;
                               return (s, ws),
                            WidgetsFrom = fn cfg r aux =>
                               s <- source (show r.col);
                               ws <- old.tname.WidgetsFrom cfg r aux;
                               return (s, ws),
                            RenderWidgets = fn cfg (s, ws) =>
                                               <xml>
                                                 {old.tname.RenderWidgets cfg ws}
                                                 <div class="form-group">
                                                   <label class="control-label">{[lab]}</label>
                                                   <ctextbox class="form-control" source={s}/>
                                                 </div>
                                               </xml>,
                            ReadWidgets = fn (s, ws) =>
                                             v <- signal s;
                                             (wsv, aux, err) <- old.tname.ReadWidgets ws;
                                             return ({col = case v of
                                                                "" => None
                                                              | _ => Some (readError v)} ++ wsv, aux, err)}}

type checkbox1 t = t
type checkbox2 t = source bool * t
type checkbox3 t = t

fun checkbox [full ::: {Type}]
         [tname :: Name] [key ::: Type] [col :: Name]
         [cols ::: {Type}] [colsDone ::: {Type}] [cstrs ::: {{Unit}}]
         [impl1 ::: Type] [impl2 ::: Type] [impl3 ::: Type] [old ::: {(Type * {Type} * {Type} * {{Unit}} * Type * Type * Type)}]
         [[col] ~ cols] [[col] ~ colsDone] [[tname] ~ old]
         (lab : string)
         (old : t full ([tname = (key, [col = bool] ++ cols, colsDone, cstrs, impl1, impl2, impl3)] ++ old)) =
    old -- tname
        ++ {tname = old.tname
                        -- #Render -- #FreshWidgets -- #WidgetsFrom -- #RenderWidgets -- #ReadWidgets
                        ++ {Render = fn entry aux r =>
                                        <xml>
                                          {old.tname.Render entry aux r}
                                          <tr>
                                            <th>{[lab]}</th>
                                            <td>{[r.col]}</td>
                                          </tr>
                                        </xml>,
                            FreshWidgets = fn cfg =>
                               s <- source False;
                               ws <- old.tname.FreshWidgets cfg;
                               return (s, ws),
                            WidgetsFrom = fn cfg r aux =>
                               s <- source r.col;
                               ws <- old.tname.WidgetsFrom cfg r aux;
                               return (s, ws),
                            RenderWidgets = fn cfg (s, ws) =>
                                               <xml>
                                                 {old.tname.RenderWidgets cfg ws}
                                                 <div class="form-group">
                                                   <label class="control-label">{[lab]}</label>
                                                   <ccheckbox class="form-control" source={s}/>
                                                 </div>
                                               </xml>,
                            ReadWidgets = fn (s, ws) =>
                                             v <- signal s;
                                             (wsv, aux, err) <- old.tname.ReadWidgets ws;
                                             return ({col = v} ++ wsv, aux, err)}}

type htmlbox1 t = t
type htmlbox2 t = Widget.htmlbox * t
type htmlbox3 t = t

fun htmlbox [full ::: {Type}]
            [tname :: Name] [key ::: Type] [col :: Name]
            [cols ::: {Type}] [colsDone ::: {Type}] [cstrs ::: {{Unit}}]
            [impl1 ::: Type] [impl2 ::: Type] [impl3 ::: Type] [old ::: {(Type * {Type} * {Type} * {{Unit}} * Type * Type * Type)}]
            [[col] ~ cols] [[col] ~ colsDone] [[tname] ~ old]
            (lab : string)
            (old : t full ([tname = (key, [col = string] ++ cols, colsDone, cstrs, impl1, impl2, impl3)] ++ old)) =
       old -- tname
           ++ {tname = old.tname
                           -- #Render -- #FreshWidgets -- #WidgetsFrom -- #RenderWidgets -- #ReadWidgets
                           ++ {Render = fn entry aux r =>
                                           <xml>
                                             {old.tname.Render entry aux r}
                                             <tr>
                                               <th>{[lab]}</th>
                                               <td>{Widget.html r.col}</td>
                                             </tr>
                                           </xml>,
                               FreshWidgets = fn cfg =>
                                  s <- @Widget.create Widget.htmlbox ();
                                  ws <- old.tname.FreshWidgets cfg;
                                  return (s, ws),
                               WidgetsFrom = fn cfg r aux =>
                                  s <- @Widget.initialize Widget.htmlbox () r.col;
                                  ws <- old.tname.WidgetsFrom cfg r aux;
                                  return (s, ws),
                               RenderWidgets = fn cfg (s, ws) =>
                                                  <xml>
                                                    {old.tname.RenderWidgets cfg ws}
                                                    <div class="form-group">
                                                      <label class="control-label">{[lab]}</label>
                                                      {@Widget.asWidget Widget.htmlbox s None}
                                                    </div>
                                                  </xml>,
                               ReadWidgets = fn (s, ws) =>
                                                v <- @Widget.value Widget.htmlbox s;
                                                (wsv, aux, err) <- old.tname.ReadWidgets ws;
                                                return ({col = v} ++ wsv, aux, err)}}

type foreign1 t key colT = list colT * t
type foreign2 t key colT = source string * t
type foreign3 t key colT = list key * t

fun foreign [full ::: {Type}]
            [tname :: Name] [key ::: Type] [col :: Name] [colT ::: Type]
            [cols ::: {Type}] [colsDone ::: {Type}] [cstrs ::: {{Unit}}]
            [impl1 ::: Type] [impl2 ::: Type] [impl3 ::: Type]
            [ftname :: Name] [fcol :: Name]
            [fcols ::: {Type}] [fcolsDone ::: {Type}] [fcstrs ::: {{Unit}}]
            [fimpl1 ::: Type] [fimpl2 ::: Type] [fimpl3 ::: Type]
            [old ::: {(Type * {Type} * {Type} * {{Unit}} * Type * Type * Type)}]
            [[col] ~ cols] [[col] ~ colsDone] [[tname] ~ old]
            [[fcol] ~ fcols] [[ftname] ~ old]
            [[tname] ~ [ftname]] [[tname, ftname] ~ full]
            (lab : string) (clab : string) (_ : show colT) (_ : read colT) (_ : sql_injectable colT)
            (old : t ([tname = key, ftname = colT] ++ full)
                     ([tname = (key, [col = colT] ++ cols, colsDone, cstrs, impl1, impl2, impl3),
                       ftname = (colT, [fcol = colT] ++ fcols, fcolsDone, fcstrs, fimpl1, fimpl2, fimpl3)] ++ old)) =
    old -- tname -- ftname
        ++ {tname = old.tname
                        -- #Config -- #Render -- #FreshWidgets -- #WidgetsFrom -- #RenderWidgets -- #ReadWidgets
                        ++ {Config =
                            let
                                val tab = old.ftname.Table
                            in
                                keys <- List.mapQuery (SELECT DISTINCT tab.{fcol}
                                                       FROM tab
                                                       ORDER BY tab.{fcol})
                                                      (fn r => r.Tab.fcol);
                                cfg <- old.tname.Config;
                                return (keys, cfg)
                            end,
                            Render = fn entry aux r =>
                                        <xml>
                                          {old.tname.Render entry aux r}
                                          <tr>
                                            <th>{[lab]}</th>
                                            <td>{entry (make [ftname] r.col) (show r.col)}</td>
                                          </tr>
                                        </xml>,
                            FreshWidgets = fn (_, cfg) =>
                               s <- source "";
                               ws <- old.tname.FreshWidgets cfg;
                               return (s, ws),
                            WidgetsFrom = fn (_, cfg) r aux =>
                               s <- source (show r.col);
                               ws <- old.tname.WidgetsFrom cfg r aux;
                               return (s, ws),
                            RenderWidgets = fn (cfg1, cfg2) (s, ws) =>
                                               <xml>
                                                 {old.tname.RenderWidgets cfg2 ws}
                                                 <div class="form-group">
                                                   <label class="control-label">{[lab]}</label>
                                                   <cselect class="form-control" source={s}>
                                                     {List.mapX (fn s => <xml><coption>{[s]}</coption></xml>) cfg1}
                                                   </cselect>
                                                 </div>
                                               </xml>,
                            ReadWidgets = fn (s, ws) =>
                                             v <- signal s;
                                             (wsv, aux, err) <- old.tname.ReadWidgets ws;
                                             return ({col = readError v} ++ wsv, aux, err)},
           ftname = old.ftname
                        -- #Insert -- #Update -- #Auxiliary -- #Render -- #ReadWidgets -- #WidgetsFrom
                        ++ {Insert = fn r (_, aux) => old.ftname.Insert r aux,
                            Update = fn k r (_, aux) => old.ftname.Update k r aux,
                            Auxiliary = fn fkey row =>
                                           let
                                               val tab = old.tname.Table
                                           in
                                               keys <- old.tname.List (WHERE tab.{col} = {[fkey]});
                                               aux <- old.ftname.Auxiliary fkey row;
                                               return (keys, aux)
                                           end,
                           Render = fn entry (children, aux) r =>
                                       let
                                           val _ : show key = old.tname.Show
                                       in
                                           <xml>
                                             {old.ftname.Render entry aux r}
                                             <tr>
                                               <th>{[clab]}</th>
                                               <td>{List.mapX (fn key => <xml>{entry (make [tname] key) (show key)}<br/></xml>) children}</td>
                                             </tr>
                                           </xml>
                                       end,
                            ReadWidgets = fn w =>
                                             (v, aux, err) <- old.ftname.ReadWidgets w;
                                             return (v, ([], aux), err),
                            WidgetsFrom = fn cfg r (_, aux) => old.ftname.WidgetsFrom cfg r aux}}

type manyToMany11 t key1 key2 others = $(map thd3 others) * list key2 * t
type manyToMany12 t key1 key2 others = source string * $(map snd3 others) * source (list (key2 * source ($(map fst3 others)) * source (option ($(map snd3 others))))) * source bool (* dropdown changed since last button push? *) * t
type manyToMany13 t key1 key2 others = list (key2 * $(map fst3 others)) * t
type manyToMany21 t key1 key2 others = $(map thd3 others) * list key1 * t
type manyToMany22 t key1 key2 others = source string * $(map snd3 others) * source (list (key1 * source ($(map fst3 others)) * source (option ($(map snd3 others))))) * source bool * t
type manyToMany23 t key1 key2 others = list (key1 * $(map fst3 others)) * t

fun manyToMany [full ::: {Type}] [tname1 :: Name] [key1 ::: Type] [col1 :: Name] [colR1 :: Name]
               [cols1 ::: {Type}] [colsDone1 ::: {Type}] [cstrs1 ::: {{Unit}}]
               [impl11 ::: Type] [impl12 ::: Type] [impl13 ::: Type]
               [tname2 :: Name] [key2 ::: Type] [col2 :: Name] [colR2 :: Name]
               [cols2 ::: {Type}] [colsDone2 ::: {Type}] [cstrs2 ::: {{Unit}}]
               [impl21 ::: Type] [impl22 ::: Type] [impl23 ::: Type]
               [cstrs ::: {{Unit}}]
               [old ::: {(Type * {Type} * {Type} * {{Unit}} * Type * Type * Type)}]
               [others ::: {(Type * Type * Type)}]
               [[tname1] ~ [tname2]] [[tname1, tname2] ~ old] [[tname1, tname2] ~ full]
               [[col1] ~ cols1] [[col2] ~ cols2] [[col1] ~ [col2]] [[colR1] ~ [colR2]]
               [others ~ [colR1, colR2]]
               (rel : sql_table ([colR1 = key1, colR2 = key2] ++ map fst3 others) cstrs)
               (lab1 : string) (lab2 : string)
               (_ : eq key1) (_ : ord key1) (_ : show key1) (_ : read key1) (_ : sql_injectable key1)
               (_ : eq key2) (_ : ord key2) (_ : show key2) (_ : read key2) (_ : sql_injectable key2)
               (fl : folder others) (ws : $(map Widget.t' others)) (injs : $(map (fn p => sql_injectable p.1) others)) (labels : $(map (fn _ => string) others))
               (old : t ([tname1 = key1, tname2 = key2] ++ full)
                        ([tname1 = (key1, [col1 = key1] ++ cols1, colsDone1, cstrs1, impl11, impl12, impl13),
                          tname2 = (key2, [col2 = key2] ++ cols2, colsDone2, cstrs2, impl21, impl22, impl23)] ++ old)) =
    old -- tname1 -- tname2
        ++ {tname1 = old.tname1
                         -- #Insert -- #Update -- #Delete -- #Config -- #Auxiliary -- #Render -- #FreshWidgets -- #WidgetsFrom -- #RenderWidgets -- #ReadWidgets
                         ++ {Insert =
                             fn r (k2s, aux) =>
                                old.tname1.Insert r aux;
                                List.app (fn (k2, others) =>
                                             @Sql.easy_insert ({colR1 = _, colR2 = _} ++ injs)
                                              (@Folder.cons [colR1] [_] !
                                                (@Folder.cons [colR2] [_] !
                                                  (@Folder.mp fl)))
                                              rel ({colR1 = r.col1, colR2 = k2} ++ others)) k2s,
                             Update =
                             fn k r (k2s, aux) =>
                                old.tname1.Update k r aux;
                                dml (DELETE FROM rel
                                     WHERE t.{colR1} = {[r.col1]});
                                List.app (fn (k2, others) =>
                                             @Sql.easy_insert ({colR1 = _, colR2 = _} ++ injs)
                                              (@Folder.cons [colR1] [_] !
                                                (@Folder.cons [colR2] [_] !
                                                  (@Folder.mp fl)))
                                              rel ({colR1 = r.col1, colR2 = k2} ++ others)) k2s,
                             Delete = fn k1 => dml (DELETE FROM rel WHERE t.{colR1} = {[k1]}),
                             Config =
                             let
                                 val tab = old.tname2.Table
                             in
                                 keys <- List.mapQuery (SELECT DISTINCT tab.{col2}
                                                        FROM tab
                                                        ORDER BY tab.{col2})
                                                       (fn r => r.Tab.col2);
                                 wcfg <- @Monad.mapR _ [Widget.t'] [thd3]
                                          (fn [nm ::_] [p ::_] (w : Widget.t' p) => @Widget.configure w)
                                          fl ws;
                                 cfg <- old.tname1.Config;
                                 return (wcfg, keys, cfg)
                             end,
                             Auxiliary = fn k1 row =>
                                 keys <- List.mapQuery (SELECT rel.{colR2}, rel.{{map fst3 others}}
                                                        FROM rel
                                                        WHERE rel.{colR1} = {[k1]}
                                                        ORDER BY rel.{colR2})
                                                       (fn r => (r.Rel.colR2, r.Rel -- colR2));
                                 aux <- old.tname1.Auxiliary k1 row;
                                 return (keys, aux),
                             Render = fn entry (k2s, aux) r =>
                                         <xml>
                                           {old.tname1.Render entry aux r}
                                           <tr>
                                             <th>{[lab1]}</th>
                                             <td>{List.mapX (fn (k2, others) => <xml>{entry (make [tname2] k2) (show k2)}
                                               {@mapX3 [fn _ => string] [Widget.t'] [fst3] [body]
                                                 (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (label : string) (w : Widget.t' p) (v : p.1) =>
                                                     <xml>- {[label]}: {[@Widget.asValue w v]}</xml>) fl labels ws others}
                                               <br/></xml>) k2s}</td>
                                           </tr>
                                         </xml>,
                             FreshWidgets = fn (cfg0, _, cfg) =>
                                s <- source "";
                                ws0 <- @Monad.mapR2 _ [Widget.t'] [thd3] [snd3]
                                        (fn [nm ::_] [p ::_] (w : Widget.t' p) (cfg : p.3) => @Widget.create w cfg)
                                        fl ws cfg0;
                                sl <- source [];
                                changed <- source False;
                                ws <- old.tname1.FreshWidgets cfg;
                                return (s, ws0, sl, changed, ws),
                             WidgetsFrom = fn (cfg0, _, cfg) r (keys, aux) =>
                                s <- source "";
                                ws0 <- @Monad.mapR2 _ [Widget.t'] [thd3] [snd3]
                                        (fn [nm ::_] [p ::_] (w : Widget.t' p) (cfg : p.3) => @Widget.create w cfg)
                                        fl ws cfg0;
                                keys <- List.mapM (fn (k, vs) => vs <- source vs; notEditing <- source None; return (k, vs, notEditing)) keys;
                                sl <- source keys;
                                changed <- source False;
                                ws <- old.tname1.WidgetsFrom cfg r aux;
                                return (s, ws0, sl, changed, ws),
                             RenderWidgets = fn (cfgs, cfg1, cfg2) (s, ws0, sl, changed, wso) =>
                                                <xml>
                                                  {old.tname1.RenderWidgets cfg2 wso}
                                                  <div class="form-group">
                                                    <label class="control-label">{[lab1]}</label>
                                                    <div class="input-group">
                                                      {@mapX3 [fn _ => string] [Widget.t'] [snd3] [body]
                                                        (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (label : string) (w : Widget.t' p) (s : p.2) =>
                                                            <xml>{[label]}: {@Widget.asWidget w s None}</xml>)
                                                        fl labels ws ws0}
                                                    </div>
                                                    <div class="input-group">
                                                      <span class="input-group-btn">
                                                        <button class="btn"
                                                                onclick={fn _ =>
                                                                            sv <- get s;
                                                                            if sv = "" then
                                                                                return ()
                                                                            else
                                                                                set changed False;
                                                                                sv <- return (readError sv);
                                                                                slv <- get sl;
                                                                                if List.exists (fn (sv', _, _) => sv' = sv) slv then
                                                                                    return ()
                                                                                else
                                                                                    vs <- @Monad.mapR2 _ [Widget.t'] [snd3] [fst3]
                                                                                           (fn [nm ::_] [p ::_] (w : Widget.t' p) (s : p.2) =>
                                                                                               current (@Widget.value w s))
                                                                                           fl ws ws0;
                                                                                    vs <- source vs;
                                                                                    notEditing <- source None;
                                                                                    set sl (List.sort (fn x y => x.1 > y.1) ((sv, vs, notEditing) :: slv))}>Select:</button>
                                                      </span>
                                                      <cselect class="form-control" source={s} onchange={set changed True}>
                                                        <coption/>
                                                        {List.mapX (fn s => <xml><coption>{[s]}</coption></xml>) cfg1}
                                                      </cselect> 
                                                    </div>
                                                    <table>
                                                      <tr><td/>
                                                        {@mapX [fn _ => string] [tr]
                                                          (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (label : string) =>
                                                              <xml><th>{[label]}</th></xml>)
                                                          fl labels}
                                                      <td/></tr>
                                                      <dyn signal={slv <- signal sl;
                                                                   return (List.mapX (fn (k2, vs, ws0) => <xml>
                                                                     <dyn signal={vals <- signal vs;
                                                                                  wids <- signal ws0;
                                                                                  case wids of
                                                                                      None => return <xml>
                                                                                        <tr>
                                                                                          <td>{[k2]}</td>
                                                                                          {@mapX2 [Widget.t'] [fst3] [tr]
                                                                                            (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (w : Widget.t' p) (v : p.1) =>
                                                                                                <xml><td>{[@Widget.asValue w v]}</td></xml>)
                                                                                            fl ws vals}
                                                                                          <td><button class="btn"
                                                                                                      onclick={fn _ =>
                                                                                                                  wids <- @Monad.mapR3 _ [Widget.t'] [thd3] [fst3] [snd3]
                                                                                                                           (fn [nm ::_] [p ::_] (w : Widget.t' p) (cfg : p.3) (v : p.1) =>
                                                                                                                               @Widget.initialize w cfg v)
                                                                                                                           fl ws cfgs vals;
                                                                                                                  set ws0 (Some wids)}>
                                                                                            <span class="glyphicon glyphicon-pencil"/>
                                                                                          </button></td>
                                                                                          <td><button class="btn"
                                                                                                      onclick={fn _ => set sl (List.filter (fn (k2', _, _) => k2' <> k2) slv)}>
                                                                                            <span class="glyphicon glyphicon-remove"/>
                                                                                          </button></td>
                                                                                        </tr>
                                                                                      </xml>
                                                                                    | Some wids => return <xml>
                                                                                      <tr>
                                                                                        <td>{[k2]}</td>
                                                                                        {@mapX2 [Widget.t'] [snd3] [tr]
                                                                                          (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (w : Widget.t' p) (s : p.2) =>
                                                                                              <xml><td>{@Widget.asWidget w s None}</td></xml>)
                                                                                          fl ws wids}
                                                                                        <td><button class="btn"
                                                                                                    onclick={fn _ =>
                                                                                                                vsv <- @Monad.mapR2 _ [Widget.t'] [snd3] [fst3]
                                                                                                                        (fn [nm ::_] [p ::_] (w : Widget.t' p) (s : p.2) =>
                                                                                                                            current (@Widget.value w s))
                                                                                                                        fl ws wids;
                                                                                                                set vs vsv;
                                                                                                                set ws0 None}>
                                                                                          <span class="glyphicon glyphicon-check"/>
                                                                                        </button></td>
                                                                                        <td><button class="btn"
                                                                                                    onclick={fn _ => set ws0 None}>
                                                                                          <span class="glyphicon glyphicon-remove"/>
                                                                                        </button></td>
                                                                                      </tr>
                                                                                    </xml>}/>
                                                                   </xml>) slv)}/>
                                                    </table>
                                                </div>
                                              </xml>,
                           ReadWidgets = fn (s, _, sl, changed, ws) =>
                                            slv <- signal sl;
                                            slv <- List.mapM (fn (k2, vs, _) => vs <- signal vs; return (k2, vs)) slv;
                                            chd <- signal changed;
                                            (wsv, aux, err) <- old.tname1.ReadWidgets ws;
                                            return (wsv, (slv, aux),
                                                    if chd then
                                                        let
                                                            val msg = "The dropdown for \"" ^ lab1 ^ "\" has changed, but the new value hasn't been selected by pushing the adjacent button."
                                                        in
                                                            case err of
                                                                None => Some msg
                                                              | Some err => Some (err ^ "\n" ^ msg)
                                                        end
                                                    else
                                                        err)},
          tname2 = old.tname2
                       -- #Insert -- #Update -- #Delete -- #Config -- #Auxiliary -- #Render -- #FreshWidgets -- #WidgetsFrom -- #RenderWidgets -- #ReadWidgets
                       ++ {Insert =
                             fn r (k1s, aux) =>
                                old.tname2.Insert r aux;
                                List.app (fn (k1, others) =>
                                             @Sql.easy_insert ({colR1 = _, colR2 = _} ++ injs)
                                              (@Folder.cons [colR1] [_] !
                                                (@Folder.cons [colR2] [_] !
                                                  (@Folder.mp fl)))
                                              rel ({colR1 = k1, colR2 = r.col2} ++ others)) k1s,
                             Update =
                             fn k r (k1s, aux) =>
                                old.tname2.Update k r aux;
                                dml (DELETE FROM rel
                                     WHERE t.{colR2} = {[r.col2]});
                                List.app (fn (k1, others) =>
                                             @Sql.easy_insert ({colR1 = _, colR2 = _} ++ injs)
                                              (@Folder.cons [colR1] [_] !
                                                (@Folder.cons [colR2] [_] !
                                                  (@Folder.mp fl)))
                                              rel ({colR1 = k1, colR2 = r.col2} ++ others)) k1s,
                             Delete = fn k2 => dml (DELETE FROM rel WHERE t.{colR2} = {[k2]}),
                             Config =
                             let
                                 val tab = old.tname1.Table
                             in
                                 keys <- List.mapQuery (SELECT DISTINCT tab.{col1}
                                                        FROM tab
                                                        ORDER BY tab.{col1})
                                                       (fn r => r.Tab.col1);
                                 wcfg <- @Monad.mapR _ [Widget.t'] [thd3]
                                          (fn [nm ::_] [p ::_] (w : Widget.t' p) => @Widget.configure w)
                                          fl ws;
                                 cfg <- old.tname2.Config;
                                 return (wcfg, keys, cfg)
                             end,
                             Auxiliary = fn k2 row =>
                                 keys <- List.mapQuery (SELECT rel.{colR1}, rel.{{map fst3 others}}
                                                        FROM rel
                                                        WHERE rel.{colR2} = {[k2]}
                                                        ORDER BY rel.{colR1})
                                                       (fn r => (r.Rel.colR1, r.Rel -- colR1));
                                 aux <- old.tname2.Auxiliary k2 row;
                                 return (keys, aux),
                             Render = fn entry (k1s, aux) r =>
                                         <xml>
                                           {old.tname2.Render entry aux r}
                                           <tr>
                                             <th>{[lab2]}</th>
                                             <td>{List.mapX (fn (k1, others) => <xml>{entry (make [tname1] k1) (show k1)}
                                               {@mapX3 [fn _ => string] [Widget.t'] [fst3] [body]
                                                 (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (label : string) (w : Widget.t' p) (v : p.1) =>
                                                     <xml>- {[label]}: {[@Widget.asValue w v]}</xml>) fl labels ws others}
                                               <br/></xml>) k1s}</td>
                                           </tr>
                                         </xml>,
                             FreshWidgets = fn (cfg0, _, cfg) =>
                                s <- source "";
                                ws0 <- @Monad.mapR2 _ [Widget.t'] [thd3] [snd3]
                                        (fn [nm ::_] [p ::_] (w : Widget.t' p) (cfg : p.3) => @Widget.create w cfg)
                                        fl ws cfg0;
                                sl <- source [];
                                changed <- source False;
                                ws <- old.tname2.FreshWidgets cfg;
                                return (s, ws0, sl, changed, ws),
                             WidgetsFrom = fn (cfg0, _, cfg) r (keys, aux) =>
                                s <- source "";
                                ws0 <- @Monad.mapR2 _ [Widget.t'] [thd3] [snd3]
                                        (fn [nm ::_] [p ::_] (w : Widget.t' p) (cfg : p.3) => @Widget.create w cfg)
                                        fl ws cfg0;
                                keys <- List.mapM (fn (k, vs) => vs <- source vs; notEditing <- source None; return (k, vs, notEditing)) keys;
                                sl <- source keys;
                                changed <- source False;
                                ws <- old.tname2.WidgetsFrom cfg r aux;
                                return (s, ws0, sl, changed, ws),
                             RenderWidgets = fn (cfgs, cfg1, cfg2) (s, ws0, sl, changed, wso) =>
                                                <xml>
                                                  {old.tname2.RenderWidgets cfg2 wso}
                                                  <div class="form-group">
                                                    <label class="control-label">{[lab2]}</label>
                                                    <div class="input-group">
                                                      {@mapX3 [fn _ => string] [Widget.t'] [snd3] [body]
                                                        (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (label : string) (w : Widget.t' p) (s : p.2) =>
                                                            <xml>{[label]}: {@Widget.asWidget w s None}</xml>)
                                                        fl labels ws ws0}
                                                    </div>
                                                    <div class="input-group">
                                                      <span class="input-group-btn">
                                                        <button class="btn"
                                                                onclick={fn _ =>
                                                                            sv <- get s;
                                                                            if sv = "" then
                                                                                return ()
                                                                            else
                                                                                set changed False;
                                                                                sv <- return (readError sv);
                                                                                slv <- get sl;
                                                                                if List.exists (fn (sv', _, _) => sv' = sv) slv then
                                                                                    return ()
                                                                                else
                                                                                    vs <- @Monad.mapR2 _ [Widget.t'] [snd3] [fst3]
                                                                                           (fn [nm ::_] [p ::_] (w : Widget.t' p) (s : p.2) =>
                                                                                               current (@Widget.value w s))
                                                                                           fl ws ws0;
                                                                                    vs <- source vs;
                                                                                    notEditing <- source None;
                                                                                    set sl (List.sort (fn x y => x.1 > y.1) ((sv, vs, notEditing) :: slv))}>Select:</button>
                                                      </span>
                                                      <cselect class="form-control" source={s} onchange={set changed True}>
                                                        <coption/>
                                                        {List.mapX (fn s => <xml><coption>{[s]}</coption></xml>) cfg1}
                                                      </cselect> 
                                                    </div>
                                                    <table>
                                                      <tr><td/>
                                                        {@mapX [fn _ => string] [tr]
                                                          (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (label : string) =>
                                                              <xml><th>{[label]}</th></xml>)
                                                          fl labels}
                                                      <td/></tr>
                                                      <dyn signal={slv <- signal sl;
                                                                   return (List.mapX (fn (k2, vs, ws0) => <xml>
                                                                     <dyn signal={vals <- signal vs;
                                                                                  wids <- signal ws0;
                                                                                  case wids of
                                                                                      None => return <xml>
                                                                                        <tr>
                                                                                          <td>{[k2]}</td>
                                                                                          {@mapX2 [Widget.t'] [fst3] [tr]
                                                                                            (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (w : Widget.t' p) (v : p.1) =>
                                                                                                <xml><td>{[@Widget.asValue w v]}</td></xml>)
                                                                                            fl ws vals}
                                                                                          <td><button class="btn"
                                                                                                      onclick={fn _ =>
                                                                                                                  wids <- @Monad.mapR3 _ [Widget.t'] [thd3] [fst3] [snd3]
                                                                                                                           (fn [nm ::_] [p ::_] (w : Widget.t' p) (cfg : p.3) (v : p.1) =>
                                                                                                                               @Widget.initialize w cfg v)
                                                                                                                           fl ws cfgs vals;
                                                                                                                  set ws0 (Some wids)}>
                                                                                            <span class="glyphicon glyphicon-pencil"/>
                                                                                          </button></td>
                                                                                          <td><button class="btn"
                                                                                                      onclick={fn _ => set sl (List.filter (fn (k2', _, _) => k2' <> k2) slv)}>
                                                                                            <span class="glyphicon glyphicon-remove"/>
                                                                                          </button></td>
                                                                                        </tr>
                                                                                      </xml>
                                                                                    | Some wids => return <xml>
                                                                                      <tr>
                                                                                        <td>{[k2]}</td>
                                                                                        {@mapX2 [Widget.t'] [snd3] [tr]
                                                                                          (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (w : Widget.t' p) (s : p.2) =>
                                                                                              <xml><td>{@Widget.asWidget w s None}</td></xml>)
                                                                                          fl ws wids}
                                                                                        <td><button class="btn"
                                                                                                    onclick={fn _ =>
                                                                                                                vsv <- @Monad.mapR2 _ [Widget.t'] [snd3] [fst3]
                                                                                                                        (fn [nm ::_] [p ::_] (w : Widget.t' p) (s : p.2) =>
                                                                                                                            current (@Widget.value w s))
                                                                                                                        fl ws wids;
                                                                                                                set vs vsv;
                                                                                                                set ws0 None}>
                                                                                          <span class="glyphicon glyphicon-check"/>
                                                                                        </button></td>
                                                                                        <td><button class="btn"
                                                                                                    onclick={fn _ => set ws0 None}>
                                                                                          <span class="glyphicon glyphicon-remove"/>
                                                                                        </button></td>
                                                                                      </tr>
                                                                                    </xml>}/>
                                                                   </xml>) slv)}/>
                                                    </table>
                                                </div>
                                              </xml>,
                           ReadWidgets = fn (s, _, sl, changed, ws) =>
                                            slv <- signal sl;
                                            slv <- List.mapM (fn (k2, vs, _) => vs <- signal vs; return (k2, vs)) slv;
                                            chd <- signal changed;
                                            (wsv, aux, err) <- old.tname2.ReadWidgets ws;
                                            return (wsv, (slv, aux),
                                                    if chd then
                                                        let
                                                            val msg = "The dropdown for \"" ^ lab1 ^ "\" has changed, but the new value hasn't been selected by pushing the adjacent button."
                                                        in
                                                            case err of
                                                                None => Some msg
                                                              | Some err => Some (err ^ "\n" ^ msg)
                                                        end
                                                    else
                                                        err)}}

fun manyToManyOrdered [full ::: {Type}] [tname1 :: Name] [key1 ::: Type] [col1 :: Name] [colR1 :: Name]
                      [cols1 ::: {Type}] [colsDone1 ::: {Type}] [cstrs1 ::: {{Unit}}]
                      [impl11 ::: Type] [impl12 ::: Type] [impl13 ::: Type]
                      [tname2 :: Name] [key2 ::: Type] [col2 :: Name] [colR2 :: Name]
                      [cols2 ::: {Type}] [colsDone2 ::: {Type}] [cstrs2 ::: {{Unit}}]
                      [impl21 ::: Type] [impl22 ::: Type] [impl23 ::: Type]
                      [cstrs ::: {{Unit}}]
                      [old ::: {(Type * {Type} * {Type} * {{Unit}} * Type * Type * Type)}]
                      [others ::: {(Type * Type * Type)}]
                      [[tname1] ~ [tname2]] [[tname1, tname2] ~ old] [[tname1, tname2] ~ full]
                      [[col1] ~ cols1] [[col2] ~ cols2] [[col1] ~ [col2]] [[col1, col2] ~ [SeqNum]]
                      [[colR1] ~ [colR2]] [[colR1, colR2] ~ [SeqNum]] [others ~ [colR1, colR2, SeqNum]]
                      (rel : sql_table ([colR1 = key1, colR2 = key2, SeqNum = int] ++ map fst3 others) cstrs)
                      (lab1 : string) (lab2 : string)
                      (_ : eq key1) (_ : ord key1) (_ : show key1) (_ : read key1) (_ : sql_injectable key1)
                      (_ : eq key2) (_ : ord key2) (_ : show key2) (_ : read key2) (_ : sql_injectable key2)
                      (fl : folder others) (ws : $(map Widget.t' others)) (injs : $(map (fn p => sql_injectable p.1) others)) (labels : $(map (fn _ => string) others))
                      (old : t ([tname1 = key1, tname2 = key2] ++ full)
                               ([tname1 = (key1, [col1 = key1] ++ cols1, colsDone1, cstrs1, impl11, impl12, impl13),
                                 tname2 = (key2, [col2 = key2] ++ cols2, colsDone2, cstrs2, impl21, impl22, impl23)] ++ old)) =
    old -- tname1 -- tname2
        ++ {tname1 = old.tname1
                         -- #Insert -- #Update -- #Delete -- #Config -- #Auxiliary -- #Render -- #FreshWidgets -- #WidgetsFrom -- #RenderWidgets -- #ReadWidgets
                         ++ {Insert =
                             fn r (k2s, aux) =>
                                old.tname1.Insert r aux;
                                List.appi (fn i (k2, others) =>
                                              @Sql.easy_insert ({colR1 = _, colR2 = _, SeqNum = _} ++ injs)
                                               (@Folder.cons [colR1] [_] !
                                                 (@Folder.cons [colR2] [_] !
                                                   (@Folder.cons [#SeqNum] [_] !
                                                     (@Folder.mp fl))))
                                               rel ({colR1 = r.col1, colR2 = k2, SeqNum = i} ++ others)) k2s,
                             Update =
                             fn k r (k2s, aux) =>
                                old.tname1.Update k r aux;
                                dml (DELETE FROM rel
                                     WHERE t.{colR1} = {[r.col1]});
                                List.appi (fn i (k2, others) =>
                                              @Sql.easy_insert ({colR1 = _, colR2 = _, SeqNum = _} ++ injs)
                                               (@Folder.cons [colR1] [_] !
                                                 (@Folder.cons [colR2] [_] !
                                                   (@Folder.cons [#SeqNum] [_] !
                                                     (@Folder.mp fl))))
                                               rel ({colR1 = r.col1, colR2 = k2, SeqNum = i} ++ others)) k2s,
                             Delete = fn k1 => dml (DELETE FROM rel WHERE t.{colR1} = {[k1]}),
                             Config =
                             let
                                 val tab = old.tname2.Table
                             in
                                 keys <- List.mapQuery (SELECT DISTINCT tab.{col2}
                                                        FROM tab
                                                        ORDER BY tab.{col2})
                                                       (fn r => r.Tab.col2);
                                 wcfg <- @Monad.mapR _ [Widget.t'] [thd3]
                                          (fn [nm ::_] [p ::_] (w : Widget.t' p) => @Widget.configure w)
                                          fl ws;
                                 cfg <- old.tname1.Config;
                                 return (wcfg, keys, cfg)
                             end,
                             Auxiliary = fn k1 row =>
                                 keys <- List.mapQuery (SELECT rel.{colR2}, rel.{{map fst3 others}}
                                                        FROM rel
                                                        WHERE rel.{colR1} = {[k1]}
                                                        ORDER BY rel.{colR2})
                                                       (fn r => (r.Rel.colR2, r.Rel -- colR2));
                                 aux <- old.tname1.Auxiliary k1 row;
                                 return (keys, aux),
                             Render = fn entry (k2s, aux) r =>
                                         <xml>
                                           {old.tname1.Render entry aux r}
                                           <tr>
                                             <th>{[lab1]}</th>
                                             <td>{List.mapX (fn (k2, others) => <xml>{entry (make [tname2] k2) (show k2)}
                                               {@mapX3 [fn _ => string] [Widget.t'] [fst3] [body]
                                                 (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (label : string) (w : Widget.t' p) (v : p.1) =>
                                                     <xml>- {[label]}: {[@Widget.asValue w v]}</xml>) fl labels ws others}
                                               <br/></xml>) k2s}</td>
                                           </tr>
                                         </xml>,
                             FreshWidgets = fn (cfg0, _, cfg) =>
                                s <- source "";
                                ws0 <- @Monad.mapR2 _ [Widget.t'] [thd3] [snd3]
                                        (fn [nm ::_] [p ::_] (w : Widget.t' p) (cfg : p.3) => @Widget.create w cfg)
                                        fl ws cfg0;
                                sl <- source [];
                                changed <- source False;
                                ws <- old.tname1.FreshWidgets cfg;
                                return (s, ws0, sl, changed, ws),
                             WidgetsFrom = fn (cfg0, _, cfg) r (keys, aux) =>
                                s <- source "";
                                ws0 <- @Monad.mapR2 _ [Widget.t'] [thd3] [snd3]
                                        (fn [nm ::_] [p ::_] (w : Widget.t' p) (cfg : p.3) => @Widget.create w cfg)
                                        fl ws cfg0;
                                keys <- List.mapM (fn (k, vs) => vs <- source vs; notEditing <- source None; return (k, vs, notEditing)) keys;
                                sl <- source keys;
                                changed <- source False;
                                ws <- old.tname1.WidgetsFrom cfg r aux;
                                return (s, ws0, sl, changed, ws),
                             RenderWidgets = fn (cfgs, cfg1, cfg2) (s, ws0, sl, changed, wso) =>
                                                <xml>
                                                  {old.tname1.RenderWidgets cfg2 wso}
                                                  <div class="form-group">
                                                    <label class="control-label">{[lab1]}</label>
                                                    <div class="input-group">
                                                      {@mapX3 [fn _ => string] [Widget.t'] [snd3] [body]
                                                        (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (label : string) (w : Widget.t' p) (s : p.2) =>
                                                            <xml>{[label]}: {@Widget.asWidget w s None}</xml>)
                                                        fl labels ws ws0}
                                                    </div>
                                                    <div class="input-group">
                                                      <span class="input-group-btn">
                                                        <button class="btn"
                                                                onclick={fn _ =>
                                                                            sv <- get s;
                                                                            if sv = "" then
                                                                                return ()
                                                                            else
                                                                                set changed False;
                                                                                sv <- return (readError sv);
                                                                                slv <- get sl;
                                                                                if List.exists (fn (sv', _, _) => sv' = sv) slv then
                                                                                    return ()
                                                                                else
                                                                                    vs <- @Monad.mapR2 _ [Widget.t'] [snd3] [fst3]
                                                                                           (fn [nm ::_] [p ::_] (w : Widget.t' p) (s : p.2) =>
                                                                                               current (@Widget.value w s))
                                                                                           fl ws ws0;
                                                                                    vs <- source vs;
                                                                                    notEditing <- source None;
                                                                                    set sl (List.sort (fn x y => x.1 > y.1) ((sv, vs, notEditing) :: slv))}>Select:</button>
                                                      </span>
                                                      <cselect class="form-control" source={s} onchange={set changed True}>
                                                        <coption/>
                                                        {List.mapX (fn s => <xml><coption>{[s]}</coption></xml>) cfg1}
                                                      </cselect> 
                                                    </div>
                                                    <table>
                                                      <tr><td/>
                                                        {@mapX [fn _ => string] [tr]
                                                          (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (label : string) =>
                                                              <xml><th>{[label]}</th></xml>)
                                                          fl labels}
                                                      <td/></tr>
                                                      <dyn signal={slv <- signal sl;
                                                                   len <- return (List.length slv);
                                                                   return (List.mapXi (fn i (k2, vs, ws0) => <xml>
                                                                     <dyn signal={vals <- signal vs;
                                                                                  wids <- signal ws0;
                                                                                  case wids of
                                                                                      None => return <xml><tr>
                                                                                        <td>{[k2]}</td>
                                                                                        {@mapX2 [Widget.t'] [fst3] [tr]
                                                                                          (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (w : Widget.t' p) (v : p.1) =>
                                                                                              <xml><td>{[@Widget.asValue w v]}</td></xml>)
                                                                                          fl ws vals}
                                                                                        <td>{if i = 0 then
                                                                                                 <xml></xml>
                                                                                             else
                                                                                                 <xml><button class="btn"
                                                                                                              onclick={fn _ =>
                                                                                                                          let
                                                                                                                              val (before, after) = List.splitAt (i-1) slv
                                                                                                                          in
                                                                                                                              case after of
                                                                                                                                  prev :: this :: after =>
                                                                                                                                  set sl (List.append before (this :: prev :: after))
                                                                                                                                | _ => error <xml>Explorer: impossible splitAt</xml>
                                                                                                                          end}>
                                                                                                   <span class="glyphicon glyphicon-arrow-up"/>
                                                                                                 </button></xml>}</td>
                                                                                        <td>{if i = len-1 then
                                                                                                 <xml></xml>
                                                                                             else
                                                                                                 <xml><button class="btn"
                                                                                                              onclick={fn _ =>
                                                                                                                          let
                                                                                                                              val (before, after) = List.splitAt i slv
                                                                                                                          in
                                                                                                                              case after of
                                                                                                                                  this :: next :: after =>
                                                                                                                                  set sl (List.append before (next :: this :: after))
                                                                                                                                | _ => error <xml>Explorer: impossible splitAt</xml>
                                                                                                                          end}>
                                                                                                   <span class="glyphicon glyphicon-arrow-down"/>
                                                                                                 </button></xml>}</td>
                                                                                        <td><button class="btn"
                                                                                                    onclick={fn _ =>
                                                                                                                wids <- @Monad.mapR3 _ [Widget.t'] [thd3] [fst3] [snd3]
                                                                                                                         (fn [nm ::_] [p ::_] (w : Widget.t' p) (cfg : p.3) (v : p.1) =>
                                                                                                                             @Widget.initialize w cfg v)
                                                                                                                         fl ws cfgs vals;
                                                                                                                set ws0 (Some wids)}>
                                                                                                      <span class="glyphicon glyphicon-pencil"/>
                                                                                        </button></td>
                                                                                        <td><button class="btn"
                                                                                                    onclick={fn _ => set sl (List.filter (fn (k2', _, _) => k2' <> k2) slv)}>
                                                                                          <span class="glyphicon glyphicon-remove"/>
                                                                                        </button></td>
                                                                                      </tr></xml>
                                                                                    | Some wids => return <xml>
                                                                                      <tr>
                                                                                        <td>{[k2]}</td>
                                                                                        {@mapX2 [Widget.t'] [snd3] [tr]
                                                                                          (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (w : Widget.t' p) (s : p.2) =>
                                                                                              <xml><td>{@Widget.asWidget w s None}</td></xml>)
                                                                                          fl ws wids}
                                                                                        <td><button class="btn"
                                                                                                    onclick={fn _ =>
                                                                                                                vsv <- @Monad.mapR2 _ [Widget.t'] [snd3] [fst3]
                                                                                                                        (fn [nm ::_] [p ::_] (w : Widget.t' p) (s : p.2) =>
                                                                                                                            current (@Widget.value w s))
                                                                                                                        fl ws wids;
                                                                                                                set vs vsv;
                                                                                                                set ws0 None}>
                                                                                          <span class="glyphicon glyphicon-check"/>
                                                                                        </button></td>
                                                                                        <td><button class="btn"
                                                                                                    onclick={fn _ => set ws0 None}>
                                                                                          <span class="glyphicon glyphicon-remove"/>
                                                                                        </button></td>
                                                                                      </tr>
                                                                                    </xml>}/>
                                                                   </xml>) slv)}/>
                                                    </table>
                                                </div>
                                              </xml>,
                           ReadWidgets = fn (s, _, sl, changed, ws) =>
                                            slv <- signal sl;
                                            slv <- List.mapM (fn (k2, vs, _) => vs <- signal vs; return (k2, vs)) slv;
                                            chd <- signal changed;
                                            (wsv, aux, err) <- old.tname1.ReadWidgets ws;
                                            return (wsv, (slv, aux),
                                                    if chd then
                                                        let
                                                            val msg = "The dropdown for \"" ^ lab1 ^ "\" has changed, but the new value hasn't been selected by pushing the adjacent button."
                                                        in
                                                            case err of
                                                                None => Some msg
                                                              | Some err => Some (err ^ "\n" ^ msg)
                                                        end
                                                    else
                                                        err)},
          tname2 = old.tname2
                       -- #Insert -- #Update -- #Delete -- #Config -- #Auxiliary -- #Render -- #FreshWidgets -- #WidgetsFrom -- #RenderWidgets -- #ReadWidgets
                       ++ {Insert =
                             fn r (k1s, aux) =>
                                old.tname2.Insert r aux;
                                List.appi (fn i (k1, others) =>
                                              @Sql.easy_insert ({colR1 = _, colR2 = _, SeqNum = _} ++ injs)
                                               (@Folder.cons [colR1] [_] !
                                                 (@Folder.cons [colR2] [_] !
                                                   (@Folder.cons [#SeqNum] [_] !
                                                     (@Folder.mp fl))))
                                               rel ({colR1 = k1, colR2 = r.col2, SeqNum = i} ++ others)) k1s,
                             Update =
                             fn k r (k1s, aux) =>
                                old.tname2.Update k r aux;
                                dml (DELETE FROM rel
                                     WHERE t.{colR2} = {[r.col2]});
                                List.appi (fn i (k1, others) =>
                                              @Sql.easy_insert ({colR1 = _, colR2 = _, SeqNum = _} ++ injs)
                                               (@Folder.cons [colR1] [_] !
                                                 (@Folder.cons [colR2] [_] !
                                                   (@Folder.cons [#SeqNum] [_] !
                                                     (@Folder.mp fl))))
                                               rel ({colR1 = k1, colR2 = r.col2, SeqNum = i} ++ others)) k1s,
                             Delete = fn k2 => dml (DELETE FROM rel WHERE t.{colR2} = {[k2]}),
                             Config =
                             let
                                 val tab = old.tname1.Table
                             in
                                 keys <- List.mapQuery (SELECT DISTINCT tab.{col1}
                                                        FROM tab
                                                        ORDER BY tab.{col1})
                                                       (fn r => r.Tab.col1);
                                 wcfg <- @Monad.mapR _ [Widget.t'] [thd3]
                                          (fn [nm ::_] [p ::_] (w : Widget.t' p) => @Widget.configure w)
                                          fl ws;
                                 cfg <- old.tname2.Config;
                                 return (wcfg, keys, cfg)
                             end,
                             Auxiliary = fn k2 row =>
                                 keys <- List.mapQuery (SELECT rel.{colR1}, rel.{{map fst3 others}}
                                                        FROM rel
                                                        WHERE rel.{colR2} = {[k2]}
                                                        ORDER BY rel.SeqNum)
                                                       (fn r => (r.Rel.colR1, r.Rel -- colR1));
                                 aux <- old.tname2.Auxiliary k2 row;
                                 return (keys, aux),
                             Render = fn entry (k1s, aux) r =>
                                         <xml>
                                           {old.tname2.Render entry aux r}
                                           <tr>
                                             <th>{[lab2]}</th>
                                             <td>{List.mapX (fn (k1, others) => <xml>{entry (make [tname1] k1) (show k1)}
                                               {@mapX3 [fn _ => string] [Widget.t'] [fst3] [body]
                                                 (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (label : string) (w : Widget.t' p) (v : p.1) =>
                                                     <xml>- {[label]}: {[@Widget.asValue w v]}</xml>) fl labels ws others}
                                               <br/></xml>) k1s}</td>
                                           </tr>
                                         </xml>,
                             FreshWidgets = fn (cfg0, _, cfg) =>
                                s <- source "";
                                ws0 <- @Monad.mapR2 _ [Widget.t'] [thd3] [snd3]
                                        (fn [nm ::_] [p ::_] (w : Widget.t' p) (cfg : p.3) => @Widget.create w cfg)
                                        fl ws cfg0;
                                sl <- source [];
                                changed <- source False;
                                ws <- old.tname2.FreshWidgets cfg;
                                return (s, ws0, sl, changed, ws),
                             WidgetsFrom = fn (cfg0, _, cfg) r (keys, aux) =>
                                s <- source "";
                                ws0 <- @Monad.mapR2 _ [Widget.t'] [thd3] [snd3]
                                        (fn [nm ::_] [p ::_] (w : Widget.t' p) (cfg : p.3) => @Widget.create w cfg)
                                        fl ws cfg0;
                                keys <- List.mapM (fn (k, vs) => vs <- source vs; notEditing <- source None; return (k, vs, notEditing)) keys;
                                sl <- source keys;
                                changed <- source False;
                                ws <- old.tname2.WidgetsFrom cfg r aux;
                                return (s, ws0, sl, changed, ws),
                             RenderWidgets = fn (cfgs, cfg1, cfg2) (s, ws0, sl, changed, wso) =>
                                                <xml>
                                                  {old.tname2.RenderWidgets cfg2 wso}
                                                  <div class="form-group">
                                                    <label class="control-label">{[lab2]}</label>
                                                    <div class="input-group">
                                                      {@mapX3 [fn _ => string] [Widget.t'] [snd3] [body]
                                                        (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (label : string) (w : Widget.t' p) (s : p.2) =>
                                                            <xml>{[label]}: {@Widget.asWidget w s None}</xml>)
                                                        fl labels ws ws0}
                                                    </div>
                                                    <div class="input-group">
                                                      <span class="input-group-btn">
                                                        <button class="btn"
                                                                onclick={fn _ =>
                                                                            sv <- get s;
                                                                            if sv = "" then
                                                                                return ()
                                                                            else
                                                                                set changed False;
                                                                                sv <- return (readError sv);
                                                                                slv <- get sl;
                                                                                if List.exists (fn (sv', _, _) => sv' = sv) slv then
                                                                                    return ()
                                                                                else
                                                                                    vs <- @Monad.mapR2 _ [Widget.t'] [snd3] [fst3]
                                                                                           (fn [nm ::_] [p ::_] (w : Widget.t' p) (s : p.2) =>
                                                                                               current (@Widget.value w s))
                                                                                           fl ws ws0;
                                                                                    vs <- source vs;
                                                                                    notEditing <- source None;
                                                                                    set sl (List.sort (fn x y => x.1 > y.1) ((sv, vs, notEditing) :: slv))}>Select:</button>
                                                      </span>
                                                      <cselect class="form-control" source={s} onchange={set changed True}>
                                                        <coption/>
                                                        {List.mapX (fn s => <xml><coption>{[s]}</coption></xml>) cfg1}
                                                      </cselect> 
                                                    </div>
                                                    <table>
                                                      <tr><td/>
                                                        {@mapX [fn _ => string] [tr]
                                                          (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (label : string) =>
                                                              <xml><th>{[label]}</th></xml>)
                                                          fl labels}
                                                      <td/></tr>
                                                      <dyn signal={slv <- signal sl;
                                                                   return (List.mapX (fn (k2, vs, ws0) => <xml>
                                                                     <dyn signal={vals <- signal vs;
                                                                                  wids <- signal ws0;
                                                                                  case wids of
                                                                                      None => return <xml>
                                                                                        <tr>
                                                                                          <td>{[k2]}</td>
                                                                                          {@mapX2 [Widget.t'] [fst3] [tr]
                                                                                            (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (w : Widget.t' p) (v : p.1) =>
                                                                                                <xml><td>{[@Widget.asValue w v]}</td></xml>)
                                                                                            fl ws vals}
                                                                                          <td><button class="btn"
                                                                                                      onclick={fn _ =>
                                                                                                                  wids <- @Monad.mapR3 _ [Widget.t'] [thd3] [fst3] [snd3]
                                                                                                                           (fn [nm ::_] [p ::_] (w : Widget.t' p) (cfg : p.3) (v : p.1) =>
                                                                                                                               @Widget.initialize w cfg v)
                                                                                                                           fl ws cfgs vals;
                                                                                                                  set ws0 (Some wids)}>
                                                                                            <span class="glyphicon glyphicon-pencil"/>
                                                                                          </button></td>
                                                                                          <td><button class="btn"
                                                                                                      onclick={fn _ => set sl (List.filter (fn (k2', _, _) => k2' <> k2) slv)}>
                                                                                            <span class="glyphicon glyphicon-remove"/>
                                                                                          </button></td>
                                                                                        </tr>
                                                                                      </xml>
                                                                                    | Some wids => return <xml>
                                                                                      <tr>
                                                                                        <td>{[k2]}</td>
                                                                                        {@mapX2 [Widget.t'] [snd3] [tr]
                                                                                          (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (w : Widget.t' p) (s : p.2) =>
                                                                                              <xml><td>{@Widget.asWidget w s None}</td></xml>)
                                                                                          fl ws wids}
                                                                                        <td><button class="btn"
                                                                                                    onclick={fn _ =>
                                                                                                                vsv <- @Monad.mapR2 _ [Widget.t'] [snd3] [fst3]
                                                                                                                        (fn [nm ::_] [p ::_] (w : Widget.t' p) (s : p.2) =>
                                                                                                                            current (@Widget.value w s))
                                                                                                                        fl ws wids;
                                                                                                                set vs vsv;
                                                                                                                set ws0 None}>
                                                                                          <span class="glyphicon glyphicon-check"/>
                                                                                        </button></td>
                                                                                        <td><button class="btn"
                                                                                                    onclick={fn _ => set ws0 None}>
                                                                                          <span class="glyphicon glyphicon-remove"/>
                                                                                        </button></td>
                                                                                      </tr>
                                                                                    </xml>}/>
                                                                   </xml>) slv)}/>
                                                    </table>
                                                </div>
                                              </xml>,
                           ReadWidgets = fn (s, _, sl, changed, ws) =>
                                            slv <- signal sl;
                                            slv <- List.mapM (fn (k2, vs, _) => vs <- signal vs; return (k2, vs)) slv;
                                            chd <- signal changed;
                                            (wsv, aux, err) <- old.tname2.ReadWidgets ws;
                                            return (wsv, (slv, aux),
                                                    if chd then
                                                        let
                                                            val msg = "The dropdown for \"" ^ lab1 ^ "\" has changed, but the new value hasn't been selected by pushing the adjacent button."
                                                        in
                                                            case err of
                                                                None => Some msg
                                                              | Some err => Some (err ^ "\n" ^ msg)
                                                        end
                                                    else
                                                        err)}}

type custom1 stash t = t
type custom2 stash t = source string * t
type custom3 stash t = option stash * t

fun custom [full ::: {Type}]
           [tname :: Name] [key ::: Type] [col :: Name] [colT ::: Type]
           [cols ::: {Type}] [colsDone ::: {Type}] [cstrs ::: {{Unit}}]
           [stash ::: Type]
           [impl1 ::: Type] [impl2 ::: Type] [impl3 ::: Type] [old ::: {(Type * {Type} * {Type} * {{Unit}} * Type * Type * Type)}]
           [[col] ~ cols] [[col] ~ colsDone] [[tname] ~ old]
           (lab : string) (_ : show colT) (_ : read colT)
           (content : colT -> transaction (option stash))
           (render : stash -> xtable)
           (dbchange : colT -> transaction unit)
           (old : t full ([tname = (key, [col = option colT] ++ cols, colsDone, cstrs, impl1, impl2, impl3)] ++ old)) =
    old -- tname
        ++ {tname = old.tname
                        -- #Auxiliary -- #Insert -- #Update -- #Render -- #FreshWidgets -- #WidgetsFrom -- #RenderWidgets -- #ReadWidgets
                        ++ {Auxiliary = fn k row =>
                                           aux1 <- (case row.col of
                                                        None => return None
                                                      | Some v => content v);
                                           aux2 <- old.tname.Auxiliary k row;
                                           return (aux1, aux2),
                            Insert = fn r (sto, aux) => old.tname.Insert r aux; Option.app dbchange r.col,
                            Update = fn k r (sto, aux) => old.tname.Update k r aux; Option.app dbchange r.col,
                            Render = fn entry (aux1, aux2) r => <xml>
                              {old.tname.Render entry aux2 r}
                              {case aux1 of
                                   None => <xml></xml>
                                 | Some aux1 => render aux1}
                            </xml>,
                            FreshWidgets = fn cfg =>
                               s <- source "";
                               ws <- old.tname.FreshWidgets cfg;
                               return (s, ws),
                            WidgetsFrom = fn cfg r (_, aux2) =>
                               s <- source (show r.col);
                               ws <- old.tname.WidgetsFrom cfg r aux2;
                               return (s, ws),
                            RenderWidgets = fn cfg (s, ws) =>
                                               <xml>
                                                 {old.tname.RenderWidgets cfg ws}
                                                 <div class="form-group">
                                                   <label class="control-label">{[lab]}</label>
                                                   <ctextbox class="form-control" source={s}/>
                                                 </div>
                                               </xml>,
                            ReadWidgets = fn (s, ws) =>
                                             v <- signal s;
                                             (wsv, aux, err) <- old.tname.ReadWidgets ws;
                                             return ({col = case v of
                                                                "" => None
                                                              | _ => Some (readError v)} ++ wsv, (None, aux), err)}}

datatype action tab key =
         Read of tab
       | Create of tab
       | Update of key
       | Delete of key

functor Make(M : sig
                 structure Theme : Ui.THEME

                 val title : string
                 con tables :: {(Type * {Type} * {{Unit}} * Type * Type * Type)}
                 val t : t (map (fn p => p.1) tables)
                           (map (fn p => (p.1, p.2, p.2, p.3, p.4, p.5, p.6)) tables)
                 val fl : folder tables

                 val authorize : action (variant (map (fn _ => unit) tables)) (variant (map (fn p => p.1) tables)) -> transaction bool

                 con preTabs :: {Unit}
                 con postTabs :: {Unit}
                 con hiddenTabs :: {Unit}
                 constraint preTabs ~ postTabs
                 constraint (preTabs ++ postTabs) ~ hiddenTabs
                 val preTabs : $(mapU (string * ((variant (mapU unit (preTabs ++ postTabs ++ hiddenTabs)) -> url) -> transaction xbody)) preTabs)
                 val preFl : folder preTabs
                 val postTabs : $(mapU (string * ((variant (mapU unit (preTabs ++ postTabs ++ hiddenTabs)) -> url) -> transaction xbody)) postTabs)
                 val postFl : folder postTabs
                 val hiddenTabs : $(mapU (string * ((variant (mapU unit (preTabs ++ postTabs ++ hiddenTabs)) -> url) -> transaction xbody)) hiddenTabs)
                 val hiddenFl : folder hiddenTabs
                 constraint (preTabs ++ postTabs ++ hiddenTabs) ~ tables
             end) = struct
    open M
    open Ui.Make(Theme)

    type tag = variant (map (fn _ => unit) tables)
    con tabs' = map (fn _ => unit) tables ++ mapU unit (preTabs ++ postTabs)
    con tabs = tabs' ++ mapU unit hiddenTabs
    con tabsU' = map (fn _ => ()) tables ++ preTabs ++ postTabs
    con tabsU = tabsU' ++ hiddenTabs
    type tagPlus = variant tabs
    val eq_tag : eq tag = @Variant.eqU (@@Folder.mp [fn _ => ()] [_] fl)
    val eq_tagPlus : eq (variant tabs') = @Variant.eqU (@Folder.concat ! preFl (@Folder.concat ! (@@Folder.mp [fn _ => ()] [_] fl) postFl))

    con dupF (p :: (Type * {Type} * {{Unit}} * Type * Type * Type)) = (p.1, p.2, p.2, p.3, p.4, p.5, p.6)
    con dup = map dupF tables

    con tables' = map (fn p => p.1) tables

    val titleOf : variant tabs' -> string =
        @@Variant.proj [string] [tabsU']
          (@Folder.concat ! preFl
            (@Folder.concat ! (@Folder.mp fl) postFl))
          (@mp [fn _ => string * _] [fn _ => string]
            (fn [u] (titl, _) => titl) preFl preTabs
            ++ @mp [fn _ => string * _] [fn _ => string]
            (fn [u] (titl, _) => titl) postFl postTabs
            ++ @mp [t1 tables'] [fn _ => string]
            (fn [p] (r : t1 tables' p) => r.Title) (@@Folder.mp [dupF] [_] fl) t)

    val tabsFl = @Folder.concat ! postFl (@Folder.concat ! (@Folder.mp fl) preFl)

    fun tabbed (f : tagPlus -> transaction page)
               (which : option (variant tabs'))
        : (Ui.context -> transaction xbody) -> transaction page =
        @@tabbedStatic [tabsU'] tabsFl
          title
          (@@Variant.mp [tabsU'] [_] tabsFl
             (fn v => (titleOf v,
                       case which of
                           None => False
                         | Some which => @eq eq_tagPlus v which,
                       url (f (@Variant.weaken ! (@Folder.mp tabsFl) v)))))

    datatype editingState row widgets aux =
             NotEditing of row * aux
           | Editing of row * widgets

    fun auth act =
        b <- authorize act;
        if b then
            return ()
        else
            error <xml>Access denied</xml>

    val weakener = @Variant.weaken ! (@Folder.mp fl)

    fun page (which : tagPlus) =
        @match which
        (@@Variant.mp [map (fn _ => ()) tables] [_] (@Folder.mp fl) (fn v () => index v)
          ++ @Variant.mp preFl (fn v () => tabbed page (Some (@Variant.weaken ! (@Folder.mp preFl) v)) (fn _ => (@Variant.proj preFl preTabs v).2 (fn v' => url (page (@Variant.weaken ! (@Folder.mp (@Folder.concat ! hiddenFl (@Folder.concat ! preFl postFl))) v')))))
          ++ @Variant.mp postFl (fn v () => tabbed page (Some (@Variant.weaken ! (@Folder.mp postFl) v)) (fn _ => (@Variant.proj postFl postTabs v).2 (fn v' => url (page (@Variant.weaken ! (@Folder.mp (@Folder.concat ! hiddenFl (@Folder.concat ! preFl postFl))) v')))))
          ++ @Variant.mp hiddenFl (fn v () => tabbed page None (fn _ => (@Variant.proj hiddenFl hiddenTabs v).2 (fn v' => url (page (@Variant.weaken ! (@Folder.mp (@Folder.concat ! hiddenFl (@Folder.concat ! preFl postFl))) v'))))))

    and index (which : tag) =
        auth (Read which);
        mayAdd <- authorize (Create which);
        bod <- @@Variant.destrR' [fn _ => unit] [fn p => t1 tables' (dupF p)] [transaction xbody] [tables]
          (fn [p ::_] (maker : tf :: ((Type * {Type} * {{Unit}} * Type * Type * Type) -> Type) -> tf p -> variant (map tf tables)) () r =>
              extra <- r.Extra;
              rows <- r.ForIndex;
              return <xml>
                {extra}

                <table class="bs-table table-striped">
                  {List.mapX (fn (k, bod) => <xml><tr><td><a link={entry (maker [fn p => p.1] k)}>{bod}</a></td></tr></xml>) rows}
                </table>

                {if mayAdd then
                     <xml><a class="btn btn-primary" link={create which}>New Entry</a></xml>
                 else
                     <xml></xml>}
              </xml>)
          fl which t;
        tabbed page (Some (weakener which)) (fn _ => return bod)

    and create (which : tag) =
        auth (Create which);
        bod <- @@Variant.destrR' [fn _ => unit] [fn p => t1 tables' (dupF p)] [transaction xbody] [tables]
          (fn [p ::_] (maker : tf :: ((Type * {Type} * {{Unit}} * Type * Type * Type) -> Type) -> tf p -> variant (map tf tables)) () r =>
              cfg <- r.Config;
              ws <- r.FreshWidgets cfg;
              return <xml>
                <h1>Create {[r.Title]}</h1>

                {r.RenderWidgets cfg ws}

                <button value="Create" class="btn btn-primary"
                        onclick={fn _ =>
                                    (p1, p2, err) <- current (r.ReadWidgets ws);
                                    proceed <- (case err of
                                                  None => return True
                                                | Some msg => confirm ("Are you sure you want to proceed with creating that entry?  The following issues were noted:\n\n" ^ msg));
                                    if proceed then
                                        rpc (doCreate (maker [fn p => $p.2 * p.6] (p1, p2)));
                                        redirect (url (index which))
                                    else
                                        return ()}/>
              </xml>)
          fl which t;
        tabbed page (Some (weakener which)) (fn _ => return bod)

    and doCreate (which : variant (map (fn p => $p.2 * p.7) dup)) =
        auth (Create (@Variant.erase (@Folder.mp fl) which));
        @@Variant.destrR [fn p => $p.2 * p.7] [t1 tables'] [transaction unit]
          (fn [p ::_] (vs : $p.2, aux : p.7) r =>
              r.Insert vs aux)
          [dup] (@Folder.mp fl) which t

    and entry (which : variant (map (fn p => p.1) tables)) =
        auth (Read (@Variant.erase (@Folder.mp fl) which));
        mayUpdate <- authorize (Update which);
        mayDelete <- authorize (Delete which);
        (ctx : source (option Ui.context)) <- source None;
        bod <- @@Variant.destrR' [fn p => p.1] [fn p => t1 tables' (dupF p)] [transaction xbody] [tables]
          (fn [p ::_] (maker : tf :: ((Type * {Type} * {{Unit}} * Type * Type * Type) -> Type) -> tf p -> variant (map tf tables)) (k : p.1) (r : t1 tables' (dupF p)) =>
              let
                  val tab = r.Table
              in
                  cfg <- r.Config;
                  row <- oneRow1 (SELECT *
                                  FROM tab
                                  WHERE {r.KeyIs [#Tab] k});
                  aux <- r.Auxiliary k row;
                  est <- source (NotEditing (row, aux));
                  return <xml>
                    <dyn signal={esta <- signal est;
                                 case esta of
                                     NotEditing (row, aux) =>
                                     ctx <- signal ctx;
                                     (case ctx of
                                         None => return <xml></xml>
                                       | Some ctx => return <xml>
                                         <p>
                                           {if mayUpdate then
                                                <xml>
                                                  <button class="btn btn-primary"
                                                          onclick={fn _ => ws <- r.WidgetsFrom cfg row aux; set est (Editing (row, ws))}>Edit</button>
                                                </xml>
                                            else
                                                <xml/>}
                                           {if mayDelete then
                                                Ui.modalButton ctx (CLASS "btn") <xml>Delete</xml>
                                                               (return (Ui.modal (rpc (delete which); redirect (url (index (maker [fn _ => unit] ()))))
                                                                                 <xml>Are you sure you want to delete this entry?</xml>
                                                                                 <xml></xml>
                                                                                 <xml>Yes, delete it.</xml>))
                                            else
                                                <xml/>}
                                           </p>

                                         <table class="bs-table table-striped">
                                           {r.Render (fn key text => <xml><a link={entry key}>{[text]}</a></xml>) aux row}
                                         </table>
                                      </xml>)
                                   | Editing (row, ws) => return <xml>
                                     <p>
                                       <button class="btn btn-primary"
                                               onclick={fn _ =>
                                                           (row1, row2, err) <- current (r.ReadWidgets ws);
                                                           proceed <- (case err of
                                                                           None => return True
                                                                         | Some msg => confirm ("Are you sure you want to proceed with saving that entry?  The following issues were noted:\n\n" ^ msg));
                                                           if proceed then
                                                               rpc (save (maker [fn p => p.1 * $p.2 * p.6] (k, row1, row2)));
                                                               set est (NotEditing (row1, row2))
                                                           else
                                                               return ()}>Save</button>
                                       <button class="btn"
                                               onclick={fn _ => set est (NotEditing (row, aux))}>Cancel</button>
                                     </p>

                                     {r.RenderWidgets cfg ws}
                                   </xml>}/>
                  </xml>
              end)
          fl which t;

        tabbed page (Some (weakener (@Variant.erase (@Folder.mp fl) which))) (fn ctxv => return <xml>
          <active code={set ctx (Some ctxv); return <xml></xml>}/>
          {bod}
        </xml>)

    and save (which : variant (map (fn p => p.1 * $p.2 * p.6) tables)) =
        @@Variant.destrR' [fn p => p.1 * $p.2 * p.6] [fn p => t1 tables' (dupF p)] [transaction unit] [tables]
          (fn [p ::_] (mk : tf :: ((Type * {Type} * {{Unit}} * Type * Type * Type) -> Type) -> tf p -> variant (map tf tables)) (k : p.1, vs : $p.2, aux : p.6) r =>
              auth (Update (mk [fn p => p.1] k));
              r.Update k vs aux)
          fl which t

    and delete (which : variant (map (fn p => p.1) tables)) =
        auth (Delete which);
        @@Variant.destrR [fn p => p.1] [fn p => t1 tables' (dupF p)] [transaction unit]
          (fn [p ::_] (k : p.1) (r : t1 tables' (dupF p)) =>
              let
                  val tab = r.Table
              in
                  r.Delete k;
                  dml (DELETE FROM tab
                       WHERE {r.KeyIs [#T] k})
              end)
          [tables] fl which t

    val tableNames = @mp [fn p => t1 tables' (dupF p)] [fn _ => string]
                      (fn [p :::_] (t : t1 tables' (dupF p)) => t.Title)
                      fl t

end
