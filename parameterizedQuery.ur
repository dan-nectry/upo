open Bootstrap4

signature S = sig
    con params :: {(Type * Type * Type)}
    val widgets : $(map Widget.t' params)
    val paramsFl : folder params
    val paramLabels : $(map (fn _ => string) params)

    val authorized : transaction bool
end

functor Html(M : sig
                 include S

                 con results :: {(Type * Type * Type)}
                 val resultsFl : folder results
                 val resultLabels : $(map (fn _ => string) results)
                 val query : $(map fst3 params) -> transaction (sql_query [] [] [] (map fst3 results))
                 val resultWidgets : $(map Widget.t' results)

                 con buttons :: {Unit}
                 val buttonsFl : folder buttons

                 val onResult : option ($(map fst3 results) -> transaction unit)
             end) = struct
    open M

    (* We put the button-function record in a source to ease server-to-client embedding. *)
    type a = {Buttons : source $(mapU ($(map fst3 params) -> $(map fst3 results) -> string (* label *) * url) buttons),
              Ids : $(map (fn _ => id) params),
              Widgets : $(map snd3 params),
              Results : source (list $(map fst3 results)),
              RunningAction : source bool}

    fun create bs =
        bs <- source bs;
        ids <- @Monad.mapR0 _ [fn _ => id]
                (fn [nm ::_] [p ::_] => fresh)
                paramsFl;
        ws <- @Monad.mapR _ [Widget.t'] [snd3]
               (fn [nm ::_] [p ::_] (w : Widget.t' p) =>
                   cfg <- @Widget.configure w;
                   @Widget.create w cfg)
               paramsFl widgets;
        rs <- (case @Row.isEmpty' [fn r => $(map fst3 r)] paramsFl of
                   None => return []
                 | Some cast => q <- query (cast ()); queryL q);
        rs <- source rs;
        ra <- source False;
        return {Buttons = bs,
                Ids = ids,
                Widgets = ws,
                Results = rs,
                RunningAction = ra}

    fun onload _ = return ()

    fun runQuery vs =
        b <- authorized;
        if b then
            q <- query vs;
            queryL q
        else
            error <xml>Access denied</xml>

    val runAction =
        case onResult of
            None => fn _ => return ()
          | Some f => fn rs =>
            b <- authorized;
            if b then
                List.app (fn v => case onResult of
                                      None => return ()
                                    | Some f => f v) rs
            else
                error <xml>Access denied</xml>

    fun render _ self = <xml>
      <table class="bs-table">
        {@mapX4 [fn _ => string] [Widget.t'] [fn _ => id] [snd3] [tabl]
          (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (s : string) (w : Widget.t' p) (id : id) (c : p.2) =>
              <xml><tr class="form-group">
                <th><label class="control-label" for={id}>{[s]}</label></th>
                <td>{@Widget.asWidget w c (Some id)}</td>
              </tr></xml>)
            paramsFl paramLabels widgets self.Ids self.Widgets}
      </table>

      {if @Row.isEmpty paramsFl then
           <xml></xml>
       else <xml>
         <button class="btn btn-primary"
                 value="Search"
                 onclick={fn _ =>
                             vs <- @Monad.mapR2 _ [Widget.t'] [snd3] [fst3]
                                   (fn [nm ::_] [p ::_] (w : Widget.t' p) (c : p.2) =>
                                       current (@Widget.value w c))
                                   paramsFl widgets self.Widgets;
                             rs <- rpc (runQuery vs);
                             set self.Results rs}/>
       </xml>}

      <hr/>

      {case onResult of
           None => <xml></xml>
         | _ => <xml>
           <dyn signal={rs <- signal self.Results;
                        case rs of
                            [] => return <xml></xml>
                          | _ =>
                            ra <- signal self.RunningAction;
                            return (if ra then
                                        <xml>
                                          <button class="btn btn-secondary disabled"
                                                  value="Running action..."/>
                                          <hr/>
                                        </xml>
                                    else
                                        <xml>
                                          <button class="btn btn-secondary"
                                                  value="Run action on these results"
                                                  onclick={fn _ =>
                                                              sure <- confirm "Are you sure you want to run the action?";
                                                              if sure then
                                                                  set self.RunningAction True;
                                                                  rpc (runAction rs);
                                                                  set self.RunningAction False
                                                              else
                                                                  return ()}/>
                                          <hr/>
                                        </xml>)}/>
         </xml>}

      <table class="bs-table">
        <thead>
          <tr>
            <dyn signal={bs <- signal self.Buttons;
                         return (@mapX [fn _ => $(map fst3 params) -> $(map fst3 results) -> string * url] [tr]
                                  (fn [nm ::_] [u ::_] [r ::_] [[nm] ~ r] _ =>
                                      <xml><th/></xml>)
                                  buttonsFl bs)}/>
              {@mapX [fn _ => string] [tr]
                (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (s : string) =>
                    <xml><th>{[s]}</th></xml>)
                resultsFl resultLabels}
          </tr>
        </thead>

        <tbody>
          <dyn signal={vs <- @Monad.mapR2 _ [Widget.t'] [snd3] [fst3]
                              (fn [nm ::_] [p ::_] (w : Widget.t' p) (c : p.2) =>
                                  @Widget.value w c)
                              paramsFl widgets self.Widgets;
                       bs <- signal self.Buttons;
                       rs <- signal self.Results;
                       return (List.mapX (fn row => <xml><tr>
                         {@mapX [fn _ => $(map fst3 params) -> $(map fst3 results) -> string * url] [tr]
                           (fn [nm ::_] [u ::_] [r ::_] [[nm] ~ r] f =>
                               let
                                   val (label, link) = f vs row
                               in
                                   <xml><td class="col-sm-1"><a class="btn btn-info" href={link}>{[label]}</a></td></xml>
                               end)
                           buttonsFl bs}
                         {@mapX2 [Widget.t'] [fst3] [tr]
                           (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (w : Widget.t' p) (v : p.1) =>
                               <xml><td>{@Widget.asValue w v}</td></xml>)
                           resultsFl resultWidgets row}
                       </tr></xml>) rs)}/>
        </tbody>
      </table>
    </xml>

    fun notification _ _ = <xml></xml>
    fun buttons _ _ = <xml></xml>

    type input = _
    fun ui bs = {Create = create bs,
                 Onload = onload,
                 Render = render,
                 Notification = notification,
                 Buttons = buttons}
end

functor Csv(M : sig
                include S

                con results :: {Type}
                val resultsFl : folder results
                val resultLabels : $(map (fn _ => string) results)
                val query : $(map fst3 params) -> transaction (sql_query [] [] [] results)
                val shows : $(map show results)

                val filename : string
            end) = struct
    open M

    type a = {Ids : $(map (fn _ => id) params),
              Widgets : $(map snd3 params)}

    fun generate ps () : transaction page =
        q <- query ps;
        csv <- @@Csv.buildComputed [results] resultsFl #"," shows resultLabels q;
        setHeader (blessResponseHeader "Content-Disposition")
                  ("attachment; filename=" ^ filename);
        returnBlob (textBlob csv) (blessMime "text/csv")

    val create =
        ids <- @Monad.mapR0 _ [fn _ => id]
                (fn [nm ::_] [p ::_] => fresh)
                paramsFl;
        ws <- @Monad.mapR _ [Widget.t'] [snd3]
               (fn [nm ::_] [p ::_] (w : Widget.t' p) =>
                   cfg <- @Widget.configure w;
                   @Widget.create w cfg)
               paramsFl widgets;
        return {Ids = ids,
                Widgets = ws}

    fun onload _ = return ()

    fun runQuery vs =
        q <- query vs;
        queryL q

    fun render _ self = <xml>
      <table class="bs-table">
        {@mapX4 [fn _ => string] [Widget.t'] [fn _ => id] [snd3] [tabl]
          (fn [nm ::_] [p ::_] [r ::_] [[nm] ~ r] (s : string) (w : Widget.t' p) (id : id) (c : p.2) =>
              <xml><tr class="form-group">
                <th><label class="control-label" for={id}>{[s]}</label></th>
                <td>{@Widget.asWidget w c (Some id)}</td>
              </tr></xml>)
            paramsFl paramLabels widgets self.Ids self.Widgets}
      </table>

      <dyn signal={vs <- @Monad.mapR2 _ [Widget.t'] [snd3] [fst3]
                          (fn [nm ::_] [p ::_] (w : Widget.t' p) (c : p.2) =>
                              @Widget.value w c)
                          paramsFl widgets self.Widgets;
                   return <xml><form>
                     <submit class="btn btn-primary"
                             value="Search"
                             action={generate vs}/>
                   </form></xml>}/>
    </xml>

    fun notification _ _ = <xml></xml>
    fun buttons _ _ = <xml></xml>

    val ui = {Create = create,
              Onload = onload,
              Render = render,
              Notification = notification,
              Buttons = buttons}
end
