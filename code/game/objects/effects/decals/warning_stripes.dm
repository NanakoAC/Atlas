/obj/effect/decal/warning_stripes
	icon = 'icons/effects/warning_stripes.dmi'

/obj/effect/decal/warning_stripes/New()
	. = ..()
	var/turf/T=get_turf(src)
	var/image/I=image(icon, icon_state = icon_state, dir = dir)
	I.color=color
	I.layer = DECAL_PLATING_LAYER
	T.overlays += I
	LAZYADD(T.decals,I)
	qdel(src)
