/* Filing cabinets!
 * Contains:
 *		Filing Cabinets
 *		Security Record Cabinets
 *		Medical Record Cabinets
 */

/*
 * Filing Cabinets
 */
/obj/structure/filingcabinet
	name = "filing cabinet"
	desc = "A large cabinet with drawers."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "filingcabinet"
	density = 1
	anchored = 1
	atom_flags = ATOM_FLAG_NO_TEMP_CHANGE | ATOM_FLAG_CLIMBABLE
	obj_flags = OBJ_FLAG_ANCHORABLE
	var/list/can_hold = list(
		/obj/item/weapon/paper,
		/obj/item/weapon/folder,
		/obj/item/weapon/photo,
		/obj/item/weapon/paper_bundle,
		/obj/item/weapon/sample)

	var/filing_id = ""
	//Like with noticeboards, this should be set at authortime in map instances or code subtypes. must be unique

	var/max_contents = 50 	//Maximum number of paper sheets this filing cabinet can contain
		//Folders and bundles count as the sum of their contents, not including themselves

	var/current_contents = 0

/obj/structure/filingcabinet/chestdrawer
	name = "chest drawer"
	icon_state = "chestdrawer"

/obj/structure/filingcabinet/wallcabinet
	name = "wall-mounted filing cabinet"
	desc = "A filing cabinet installed into a cavity in the wall to save space. Wow!"
	icon_state = "wallcabinet"
	density = 0
	obj_flags = 0


/obj/structure/filingcabinet/filingcabinet	//not changing the path to avoid unecessary map issues, but please don't name stuff like this in the future -Pete
	icon_state = "tallcabinet"


/obj/structure/filingcabinet/Initialize()
	//Fallback behaviour.deterministically autogenerate a board ID based on coordinates.
	//This is not ideal and will cause persistent things to break if moved elsewhere.
	if (!filing_id)
		filing_id = "x[x]y[y]z[z]"


	//Add ourselves to the noticeboards list in the persistence subsystem. This allows documents being loaded to find this board
	SSpersistence.filing_cabinets[filing_id] = src

	for(var/obj/item/I in loc)
		if(is_type_in_list(I, can_hold))
			I.forceMove(src)
	. = ..()

/obj/structure/filingcabinet/attackby(obj/item/P as obj, mob/user as mob)
	if(is_type_in_list(P, can_hold))
		insert_item(P, user, TRUE)

	else
		..()

/obj/structure/filingcabinet/attack_hand(mob/user as mob)
	if(contents.len <= 0)
		to_chat(user, "<span class='notice'>\The [src] is empty.</span>")
		return

	user.set_machine(src)
	var/dat = list("Capacity: [current_contents]/[max_contents]")
	dat += list("<center><table>")
	for(var/obj/item/P in src)
		dat += "<tr><td><a href='?src=\ref[src];retrieve=\ref[P]'>[P.name]</a></td></tr>"
	dat += "</table></center>"
	user << browse("<html><head><title>[name]</title></head><body>[jointext(dat,null)]</body></html>", "window=filingcabinet;size=350x300")

/obj/structure/filingcabinet/Topic(href, href_list)
	if(href_list["retrieve"])
		usr << browse("", "window=filingcabinet") // Close the menu

		//var/retrieveindex = text2num(href_list["retrieve"])
		var/obj/item/P = locate(href_list["retrieve"])//contents[retrieveindex]
		if(istype(P) && (P.loc == src) && src.Adjacent(usr))
			remove_item(P, usr, TRUE)




/obj/structure/filingcabinet/proc/insert_item(var/atom/movable/A, var/mob/user, var/animate = FALSE)
	var/newsize = get_content_size(A)
	if (current_contents + newsize > max_contents)
		to_chat(user, "You can't seem to fit [A] inside \the [src], it is too full. Remove some other things first!")
		return

	if(user)
		if (A.loc == user && !user.unEquip(A, src))
			return
		add_fingerprint(user)
		user.visible_message("[user] puts [A] into \the [src]")

	A.forceMove(src)
	SSpersistence.track_value(A, /datum/persistent/paper/filing)
	current_contents += newsize
	if (animate)
		flick("[initial(icon_state)]-open",src)

/obj/structure/filingcabinet/proc/remove_item(var/atom/movable/A, var/mob/user, var/animate = FALSE)

	var/newsize = get_content_size(A)

	current_contents -= newsize
	A.forceMove(get_turf(src))
	if(user)
		add_fingerprint(user)
		user.put_in_hands(A)
		user.visible_message("[user] takes [A] out of \the [src]")

	SSpersistence.forget_value(A, /datum/persistent/paper/filing)
	if (animate)
		flick("[initial(icon_state)]-open",src)


/obj/structure/filingcabinet/proc/get_content_size(var/atom/movable/A)
	if (istype(A, /obj/item/weapon/paper))
		return 1 //A sheet of paper is one

	//For containers, everything inside is 1 each. The container itself isn't counted, so as not to discourage players from using folders
	//Nonpaper contents are counted too, although those won't be saved persistently
	else if (istype(A, /obj/item/weapon/folder/) || istype(A, /obj/item/weapon/paper_bundle))
		.=0
		for (var/atom/B in A.contents)
			.++

	else return 1

/obj/structure/filingcabinet/proc/update_content_size()
	current_contents = 0

	for (var/atom/A in contents)
		current_contents += get_content_size(A)