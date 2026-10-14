// The website's entry point: the small-screen menu, then the theme's other
// scripts. A script of the theme's is a file in app/javascript/starter,
// imported here as "starter/<name>".
import "starter/forms"

const toggle = document.querySelector(".site-header__toggle")
toggle?.addEventListener("click", () => {
  const open = document.body.classList.toggle("menu-open")
  toggle.setAttribute("aria-expanded", open)
})
