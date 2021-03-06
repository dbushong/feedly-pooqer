scheduleUpdater = ->
    period = +localStorage.getItem 'fetch_timeout'
    period = 1 if period < 1

    chrome.alarms.create 'pooque', { periodInMinutes: period }

    # schedule markers events
    chrome.webRequest.onBeforeRequest.addListener markersCallback,
            urls: ['*://feedly.com/v3/markers?*']
            types: ['xmlhttprequest']
        , ['requestBody']

markersCallback = (details) ->
    if not localStorage.getItem('oauth') or not details.hasOwnProperty('requestBody') or not details.requestBody.hasOwnProperty 'raw'
        return false

    array = new Uint8Array details.requestBody.raw[0].bytes
    requestData = JSON.parse String.fromCharCode.apply null, array

    if requestData.action == 'markAsRead'
        # looks awful :)
        setTimeout sendRequest, 1500

sendRequest = ->
    if not localStorage.getItem 'oauth'
        setBadge()
        return false

    # do not send request too quickly
    return false unless reduceFrequency()

    xhr = new XMLHttpRequest()
    xhr.open 'GET', 'http://feedly.com/v3/markers/counts'
    xhr.onreadystatechange = xhrReadyListener
    xhr.setRequestHeader 'Authorization', localStorage.getItem 'oauth'
    xhr.send()

xhrReadyListener = ->
    return unless @readyState == 4

    if @status == 200
        try
          response = JSON.parse @response
          text = calculateUnread response.unreadcounts
          text = '' if text == 0
        setBadge text
    else if @status == 401
        localStorage.removeItem 'oauth'
        setBadge()

setBadge = (badgeText) ->
    if badgeText != undefined
        imgPath = '/img/ba_38.png'
        badgeColor = [208, 0, 24, 255]
    else
        imgPath = '/img/ba_38g.png'
        badgeColor = [190, 190, 190, 230]
        badgeText = '?'

    chrome.browserAction.setIcon path: 38: imgPath
    chrome.browserAction.setBadgeBackgroundColor color: badgeColor
    chrome.browserAction.setBadgeText text: badgeText.toString()

onInit = ->
    sendRequest()
    scheduleUpdater()

authCallback = (details) ->
    for header in details.requestHeaders
        continue unless header.name == 'X-Feedly-Access-Token'
        localStorage.setItem 'oauth', header.value
        sendRequest()

    chrome.webRequest.onBeforeSendHeaders.removeListener authCallback

openFeedly = ->
    # update counter immediately
    sendRequest()

    # listen feedly headers for saving oauth token
    unless localStorage.getItem 'oauth'
        chrome.webRequest.onBeforeSendHeaders.addListener authCallback,
            urls: ['*://feedly.com/v3/subscriptions*']
        , ["requestHeaders"]

    chrome.tabs.query { url: '*://feedly.com/*' }, (tabs) ->
        if tabs[0]
            chrome.tabs.update tabs[0].id, active: true unless tabs[0].active
            chrome.tabs.reload tabs[0].id unless localStorage.getItem 'oauth'
        else
            chrome.tabs.create { url: 'http://feedly.com/' }

chrome.alarms.onAlarm.addListener (alarm) ->
    sendRequest() if alarm.name == 'pooque'

chrome.runtime.onInstalled.addListener onInit
chrome.runtime.onStartup.addListener onInit
chrome.browserAction.onClicked.addListener openFeedly
