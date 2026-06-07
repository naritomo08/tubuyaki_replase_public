// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/testsite"
import topbar from "../vendor/topbar"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

const refreshIntervalMs = 5000
const refreshTimers = []

const escapeHtml = value =>
  String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;")

const formatDateTime = value => {
  if (!value) return ""
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ""

  const pad = number => String(number).padStart(2, "0")
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`
}

const fetchJson = async url => {
  const nextUrl = new URL(url, window.location.origin)
  nextUrl.searchParams.set("_", Date.now())

  const response = await fetch(nextUrl, {
    cache: "no-store",
    credentials: "same-origin",
    headers: {"accept": "application/json"},
  })

  if (!response.ok) throw new Error(`Request failed: ${response.status}`)
  return response.json()
}

const stopDynamicRefresh = () => {
  while (refreshTimers.length > 0) {
    window.clearInterval(refreshTimers.pop())
  }
}

const withPolling = callback => {
  const run = () => {
    if (document.visibilityState === "visible") callback().catch(() => {})
  }

  run()
  const timer = window.setInterval(run, refreshIntervalMs)
  refreshTimers.push(timer)
  return timer
}

const renderTweetImages = images => {
  if (!images || images.length === 0) return ""

  return `
    <div class="mt-3 grid grid-cols-2 gap-2 sm:grid-cols-3">
      ${images.map(image => `
        <img class="aspect-square rounded object-cover" src="${escapeHtml(image.url)}" alt="" />
      `).join("")}
    </div>
  `
}

const renderTweetBadges = tweet => {
  const badges = []
  if (tweet.is_secret) badges.push('<span class="badge badge-warning badge-sm">秘密</span>')
  if (tweet.is_protected) badges.push('<span class="badge badge-info badge-sm">保護</span>')
  if (tweet.scheduled_at) {
    badges.push(`<span class="badge badge-outline badge-sm">予約 ${escapeHtml(formatDateTime(tweet.scheduled_at))}</span>`)
  }
  return badges.join("")
}

const renderTweetActions = (feed, tweet) => {
  const authenticated = feed.dataset.authenticated === "true"
  const currentUserId = Number(feed.dataset.currentUserId)
  const isAdmin = feed.dataset.isAdmin === "true"
  const canManage = authenticated && (isAdmin || currentUserId === tweet.user.id)

  const likeButton = authenticated
    ? `
      <form action="/tweet/${tweet.id}/like" method="post">
        <input type="hidden" name="_csrf_token" value="${escapeHtml(csrfToken)}" />
        <button class="btn btn-sm gap-1 ${tweet.liked ? "btn-error" : "btn-ghost"}" type="submit" title="いいね">
          <span aria-hidden="true">♡</span>
          <span data-like-count>${tweet.like_count}</span>
        </button>
      </form>
    `
    : `
      <span class="btn btn-sm btn-ghost gap-1 pointer-events-none">
        <span aria-hidden="true">♡</span>
        <span data-like-count>${tweet.like_count}</span>
      </span>
    `

  const manageButtons = canManage
    ? `
      <a class="btn btn-sm btn-ghost" href="/tweet/${tweet.id}/edit">編集</a>
      <form action="/tweet/${tweet.id}" method="post">
        <input type="hidden" name="_method" value="delete" />
        <input type="hidden" name="_csrf_token" value="${escapeHtml(csrfToken)}" />
        <button class="btn btn-sm btn-ghost text-error" type="submit">削除</button>
      </form>
    `
    : ""

  return `<div class="flex shrink-0 items-center gap-2">${likeButton}${manageButtons}</div>`
}

const renderTweet = (feed, tweet) => `
  <li class="p-4" data-tweet-id="${tweet.id}">
    <div class="flex items-start justify-between gap-4">
      <div class="min-w-0 flex-1">
        <div class="mb-2 flex flex-wrap items-center gap-2">
          <span class="rounded-full bg-base-200 px-2 py-1 text-xs font-semibold">
            ${escapeHtml(tweet.user.name)}
          </span>
          <span class="text-xs text-base-content/50">
            ${escapeHtml(formatDateTime(tweet.inserted_at))}
          </span>
          ${renderTweetBadges(tweet)}
        </div>
        <p class="whitespace-pre-wrap break-words leading-7">${escapeHtml(tweet.content)}</p>
        ${renderTweetImages(tweet.images)}
      </div>
      ${renderTweetActions(feed, tweet)}
    </div>
  </li>
`

const refreshTweetFeed = async feed => {
  const data = await fetchJson(feed.dataset.latestUrl)
  const tweets = data.tweets || []

  if (tweets.length === 0) {
    feed.innerHTML = '<p class="p-8 text-center text-base-content/60" data-tweet-empty>まだ投稿がありません。</p>'
    document.querySelector("[data-tweet-total-count]").textContent = data.total_count || 0
    return
  }

  document.querySelector("[data-tweet-total-count]").textContent = data.total_count ?? tweets.length
  feed.innerHTML = `<ul class="divide-y divide-base-300" data-tweet-list>${tweets.map(tweet => renderTweet(feed, tweet)).join("")}</ul>`
}

const initTweetFeedRefresh = () => {
  const feed = document.querySelector("[data-tweet-feed='true']")
  if (!feed) return

  withPolling(() => refreshTweetFeed(feed))
}

const renderAccountScheduledRows = tweets => {
  if (!tweets || tweets.length === 0) {
    return '<tr><td colspan="3" class="text-base-content/60">予約投稿はありません。</td></tr>'
  }

  return tweets.map(tweet => `
    <tr>
      <td class="max-w-sm truncate">${escapeHtml(tweet.content)}</td>
      <td>${escapeHtml(formatDateTime(tweet.scheduled_at))}</td>
      <td><a class="btn btn-sm btn-ghost" href="${escapeHtml(tweet.edit_url)}">編集</a></td>
    </tr>
  `).join("")
}

const initAccountRefresh = () => {
  const dashboard = document.querySelector("[data-account-dashboard]")
  if (!dashboard) return

  withPolling(async () => {
    const [stats, scheduled] = await Promise.all([
      fetchJson(dashboard.dataset.statsUrl),
      fetchJson(dashboard.dataset.scheduledUrl),
    ])

    document.querySelector("[data-account-tweet-count]").textContent = stats.tweet_count
    document.querySelector("[data-account-like-count]").textContent = stats.like_count

    const scheduledBody = document.querySelector("[data-account-scheduled-body]")
    if (scheduledBody) scheduledBody.innerHTML = renderAccountScheduledRows(scheduled.scheduled_tweets)
  })
}

const renderAdminScheduledRows = tweets => {
  if (!tweets || tweets.length === 0) {
    return '<tr><td colspan="4" class="text-base-content/60">予約投稿はありません。</td></tr>'
  }

  return tweets.map(tweet => `
    <tr>
      <td>${escapeHtml(tweet.user.name)}</td>
      <td class="max-w-md truncate">${escapeHtml(tweet.content)}</td>
      <td>${escapeHtml(formatDateTime(tweet.scheduled_at))}</td>
      <td><a class="btn btn-sm btn-ghost" href="${escapeHtml(tweet.edit_url)}">編集</a></td>
    </tr>
  `).join("")
}

const renderAdminUserRows = users => users.map(user => `
  <tr>
    <td>
      <span class="font-semibold">${escapeHtml(user.name)}</span>
      ${user.is_admin ? '<span class="badge badge-primary ml-2">admin</span>' : ""}
      ${user.deletion_requested ? '<span class="badge badge-warning ml-2">削除予定</span>' : ""}
    </td>
    <td>
      <form action="/admin/users/${user.id}/email" method="post" class="flex min-w-72 gap-2">
        <input type="hidden" name="_method" value="put" />
        <input type="hidden" name="_csrf_token" value="${escapeHtml(csrfToken)}" />
        <input class="input input-sm flex-1" name="user[email]" value="${escapeHtml(user.email)}" />
        <button class="btn btn-sm" type="submit">保存</button>
      </form>
    </td>
    <td>${user.tweet_count}</td>
    <td>${user.like_count}</td>
    <td>
      ${user.is_admin ? "" : `
        <form action="/admin/users/${user.id}" method="post">
          <input type="hidden" name="_method" value="delete" />
          <input type="hidden" name="_csrf_token" value="${escapeHtml(csrfToken)}" />
          <button class="btn btn-sm btn-ghost text-error" type="submit">削除</button>
        </form>
      `}
    </td>
  </tr>
`).join("")

const initAdminRefresh = () => {
  const dashboard = document.querySelector("[data-admin-dashboard]")
  if (!dashboard) return

  withPolling(async () => {
    const [stats, users, scheduled] = await Promise.all([
      fetchJson(dashboard.dataset.statsUrl),
      fetchJson(dashboard.dataset.usersUrl),
      fetchJson(dashboard.dataset.scheduledUrl),
    ])

    document.querySelector("[data-admin-total-tweets]").textContent = stats.totals.tweet_count
    document.querySelector("[data-admin-total-likes]").textContent = stats.totals.like_count

    const scheduledBody = document.querySelector("[data-admin-scheduled-body]")
    if (scheduledBody) scheduledBody.innerHTML = renderAdminScheduledRows(scheduled.scheduled_tweets)

    const usersBody = document.querySelector("[data-admin-users-body]")
    if (usersBody) usersBody.innerHTML = renderAdminUserRows(users.users || [])
  })
}

const initAsyncLikeForms = () => {
  if (window.__tubuyakiAsyncForms) return
  window.__tubuyakiAsyncForms = true

  document.addEventListener("submit", async event => {
    const form = event.target
    if (!(form instanceof HTMLFormElement)) return

    const actionPath = new URL(form.action).pathname
    const methodOverride = form.querySelector("input[name='_method']")?.value?.toLowerCase()
    const isCreateTweet = actionPath === "/tweet" && methodOverride !== "delete"
    const isDeleteTweet = actionPath.match(/^\/tweet\/\d+$/) && methodOverride === "delete"
    const isLikeTweet = actionPath.match(/^\/tweet\/\d+\/like$/)

    if (!isCreateTweet && !isDeleteTweet && !isLikeTweet) return

    event.preventDefault()

    const button = form.querySelector("button[type='submit']")
    if (button) button.disabled = true

    try {
      const response = await fetch(form.action, {
        method: "POST",
        body: new FormData(form),
        cache: "no-store",
        credentials: "same-origin",
        headers: {"accept": "text/html"},
      })

      if (!response.ok) {
        HTMLFormElement.prototype.submit.call(form)
        return
      }

      if (isCreateTweet) form.reset()

      const feed = document.querySelector("[data-tweet-feed='true']")
      if (feed) await refreshTweetFeed(feed)
    } catch (_error) {
      HTMLFormElement.prototype.submit.call(form)
    } finally {
      if (button) button.disabled = false
    }
  })
}

const initDynamicRefresh = () => {
  stopDynamicRefresh()
  initTweetFeedRefresh()
  initAccountRefresh()
  initAdminRefresh()
  initAsyncLikeForms()
}

document.addEventListener("DOMContentLoaded", initDynamicRefresh)
window.addEventListener("pageshow", initDynamicRefresh)
window.addEventListener("phx:page-loading-stop", initDynamicRefresh)

if (document.readyState !== "loading") initDynamicRefresh()

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}
