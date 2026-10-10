// The website's one script: the small-screen menu.
const toggle = document.querySelector(".site-header__toggle")
toggle?.addEventListener("click", () => {
  const open = document.body.classList.toggle("menu-open")
  toggle.setAttribute("aria-expanded", open)
})
