(* Metaprogramming helpers for variants in general *)

val eq : ts ::: {Type} -> $(map eq ts) -> folder ts -> eq (variant ts)

val withAll : K --> r ::: {K} -> folder r
              -> (variant (map (fn _ => unit) r) -> transaction unit) -> transaction unit

val withAllX : K --> r ::: {K} -> ctx ::: {Unit} -> inp ::: {Type} -> folder r
               -> (variant (map (fn _ => unit) r) -> xml ctx inp []) -> xml ctx inp []

val withAllFold : K --> r ::: {K} -> folder r -> t ::: Type
                  -> (variant (map (fn _ => unit) r) -> t -> t) -> t -> t

val erase : r ::: {Type} -> folder r
            -> variant r -> variant (map (fn _ => unit) r)

val test : nm :: Name -> t ::: Type -> ts ::: {Type} -> [[nm] ~ ts] => folder ([nm = t] ++ ts)
                                                                    -> variant ([nm = t] ++ ts) -> option t

val weaken : r1 ::: {Type} -> r2 ::: {Type} -> [r1 ~ r2] => folder r1
             -> variant r1 -> variant (r1 ++ r2)

val fromString : r ::: {Unit} -> folder r -> $(mapU string r) -> string -> option (variant (mapU unit r))

val mp : r ::: {Unit} -> t ::: Type -> folder r -> (variant (mapU {} r) -> t) -> $(mapU t r)

val destrR : K --> f :: (K -> Type) -> fr :: (K -> Type) -> t ::: Type
             -> (p :: K -> f p -> fr p -> t)
             -> r ::: {K} -> folder r -> variant (map f r) -> $(map fr r) -> t

val destrR' : K --> f :: (K -> Type) -> fr :: (K -> Type) -> t ::: Type
              -> r ::: {K}
              -> (p :: K
                  -> (tf :: (K -> Type) -> tf p -> variant (map tf r))
                  -> (tf :: (K -> Type) -> variant (map tf r) -> option (tf p))
                  -> f p -> fr p -> t)
              -> folder r -> variant (map f r) -> $(map fr r) -> t

val eqU : ts ::: {Unit} -> folder ts -> eq (variant (map (fn _ => unit) ts))

val proj : t ::: Type -> r ::: {Unit} -> folder r -> $(mapU t r) -> variant (mapU unit r) -> t
