(($) ->
  count = 0 # for associating an element with its cratingPicker

  $.cratingPicker = (element, options) ->
    $element = $(element)
    plugin = this
    $all = undefined
    $wrap = undefined
    bc = undefined
    bg = undefined
    $bg = undefined
    activeClass = undefined
    closeSpeed = undefined
    defaults =
      trigger: "click" # what event should trigger the cratingPicker; http://api.jquery.com/bind/#bind1
      closeHTML: "&#215;" # the text that gets displayed
      appearUnder: element # accepts any jQuery selector
      baseClass: "cratingPicker" # the string which prepends all CSS classes; make sure to change the CSS, too!
      escape: true # enable using the escape button to close the cratingPicker
      clickOff: true # enables closing the cratingPicker by clicking anywhere but the cratingPicker itself
      maskOpacity: 0 # the opacity of the background mask
      animationSpeed: 370 # the speed of the animation

      onTrigger: -> # function to run when the cratingPicker is triggered
      onDisplay: -> # function to run when the cratingPicker is displayed
      onClose: -> # function to run when the cratingPicker is closed

    plugin.settings = {}

    plugin.init = ->
      plugin.settings = $.extend({}, defaults, options)
      bc = plugin.settings.baseClass
      bg = "." + bc + "-bg"
      $bg = $(bg)
      activeClass = bc + "-active"
      closeSpeed = plugin.settings.animationSpeed / 2.5
      buildHTML()
      setPickerHandler()
      close = "." + bc + "-wrap a." + bc + "-close"
      close += (if (plugin.settings.clickOff) then ", " + bg else "")
      $element.bind plugin.settings.trigger, (e) ->
        window.current_input = $(this)
        plugin.settings.onTrigger.call this
        plugin.colorizeTable()
        plugin.showcratingPicker()
        e.preventDefault()

      if plugin.settings.escape
        $("body").keyup (e) ->
          if e.which is 27
            speed = (if (e.shiftKey) then closeSpeed * 7 else closeSpeed)
            plugin.hidecratingPicker speed

      $(close).click (e) ->
        speed = (if (e.shiftKey) then closeSpeed * 7 else closeSpeed)
        plugin.hidecratingPicker speed
        e.preventDefault()

      plugin

    plugin.destroy = ->
    
    # Trimmer function to cut quotes
    plugin.trim = (str) ->
      str.replace(/"/g, "")
    
    # Attach grey css background values to the tables tds after table opening
    plugin.colorizeTable = ->
      $input = window.current_input
      ratingsString = $input.val()
      # Clearing
      jTable = $(".ratings-list")
      jTable.find("td").css("background-color", "white")
      # Dehumanizing
      dehRatings = dehumanizeStrings(ratingsString)
      unless $.isEmptyObject(dehRatings)
        ratingsList = JSON.parse(dehRatings)
        # Colorizing
        jTable.find("td").each (i, el) ->
          if ratingsList[$(el).attr("class")] == $(el).text()
            $(el).css("background-color", "grey")
      return false

    plugin.showcratingPicker = (speed) ->
      speed = (if typeof (speed) isnt "undefined" then speed else plugin.settings.animationSpeed)
      plugin.hidecratingPicker()
      plugin.settings.onDisplay.call this
      $bg.css("opacity", plugin.settings.maskOpacity).show()
      $element.addClass activeClass
      $under = $(plugin.settings.appearUnder)
      parentField = $under.position()
      pos = $under.offset()
      width = $under.width()
      height = $under.height()
      pop = $wrap.width()

      if parentField.left > ($(window).width() / 2) && pos.top > ($(window).height() / 2)
        $wrap.css(
          left: (pos.left + (width / 2) - pop) + "px"
          top: (pos.top - 310) + "px"
        ).fadeIn speed
      else if parentField.left < ($(window).width() / 2) && pos.top > ($(window).height() / 2)
        $wrap.css(
          left: (pos.left) + "px"
          top: (pos.top - 310) + "px"
        ).fadeIn speed
      else if parentField.left > ($(window).width() / 2) && pos.top < ($(window).height() / 2)
        $wrap.css(
          left: (pos.left + (width / 2) - pop) + "px"
          top: (pos.top + height + 14) + "px"
        ).fadeIn speed
      else
        $wrap.css(
          left: (pos.left) + "px"
          top: (pos.top + height + 14) + "px"
        ).fadeIn speed

    plugin.hidecratingPicker = (speed) ->
      speed = (if typeof (speed) isnt "undefined" then speed else closeSpeed)
      plugin.settings.onClose.call this
      $bg.hide()
      $("." + activeClass).removeClass activeClass
      $all.fadeOut speed

    dehumanizeStrings = (ratingsString) ->
      # ratingsString = input_val
      if ratingsString == ""
        ratings = {}
      else
        splitResult = {}
        splitString = ratingsString.split(",")
        part = undefined
        i = 0
        while i < splitString.length
          part = splitString[i].split(":")
          splitResult[plugin.trim(part[0])] = plugin.trim(part[1])
          i++
        dehumanized = {'Rating Name': 'js-name', 'Moody\'s Long-term': 'js-moodys-lt', 'Moody\'s Short-term': 'js-moodys-st', 'S&P Long-term': 'js-sp-lt', 'S&P Short-term': 'js-sp-st', 'Fitch Long-term': 'js-fitch-lt', 'Fitch Short-term': 'js-fitch-st'}
        dehRatings = {}
        $.each splitResult, (key, value) ->
          dehRatings[dehumanized[key]] = value
        dehRatings = JSON.stringify(dehRatings)

    setPickerHandler = ->
      $wrap.find(".ratings-list td").live "click", ->
        $input = window.current_input
        ratingsString = $input.val()
        # Dehumanizing
        dehRatings = dehumanizeStrings(ratingsString)
        unless $.isEmptyObject(dehRatings)
          ratings = JSON.parse(dehRatings)
        else
          ratings = {}
        
        jTd = $(this)
        if jTd.css("background-color") == "rgb(128, 128, 128)"
          jTd.css("background-color", "white")
          delete ratings[jTd.attr("class")]
        else
          if jTd.attr("class") == "js-name"
            ratings = {}
            jTd.parent("tr").find("td").not("js-name").each (i, el) ->
              ratings[$(el).attr("class")] = $(el).text()
              $(".ratings-list td").css("background-color", "white")
              jTd.closest("tr").find("td").css("background-color", "grey")

            headClasses = ["js-name",
                          "js-moodys-lt", "js-moodys-st",
                          "js-sp-lt", "js-sp-st",
                          "js-fitch-lt", "js-fitch-st"].sort()
            ratingsArray = []
            $.each ratings, (key) ->
              ratingsArray.push(key)
            ratingsArray.sort()
            diffItems = []
            diffItems = $.grep(headClasses, (item) ->
              $.inArray(item, ratingsArray) < 0
            )
            findRowspan = jTd.parent("tr").prevAll()
            $.each diffItems, (index, value) ->
              rowSpanned = jTd.parent("tr").prevAll().find("." + value).eq(0)
              rowSpanned.css("background-color", "grey")
              ratings[value] = rowSpanned.text()
          else
            ratings[jTd.attr("class")] = jTd.text()
            $("table").find('.' + jTd.attr("class")).css("background-color", "white")
            jTd.css("background-color", "grey")
       
        # Human readable ratings
        humanized = {"js-name": "Rating Name", "js-moodys-lt": "Moody\'s Long-term", "js-moodys-st": "Moody\'s Short-term", "js-sp-lt": "S&P Long-term", "js-sp-st": "S&P Short-term", "js-fitch-lt": "Fitch Long-term", "js-fitch-st": "Fitch Short-term"}
        hrRatings = {}
        $.each ratings, (key, value) ->
          hrRatings[humanized[key]] = value
        $input.prop('value', JSON.stringify(hrRatings).match(/\{(.*?)\}/)["1"]).change()
        
    buildHTML = ->
      $("body").append "<div class=\"" + bc + "-bg\" />"  unless $bg.length
      $bg = $(bg)
      markup = "<div class=\"" + bc + "-wrap\"><div class=\"" + bc + "\">"
      markup += "<a href=\"#\" class=\"" + bc + "-close\">" + plugin.settings.closeHTML + "</a>"
      markup += "<table class='ratings-list'>
        <thead>
          <th rowspan='2'>Name</th>
          <th colspan='2'>Moody\'s</th>
          <th colspan='2'>Standard and Poor\'s</th>
          <th colspan='2'>Fitch</th>
          <tr>
            <th>Long Term</th>
            <th>Short Term</th>
            <th>Long Term</th>
            <th>Short Term</th>
            <th>Long Term</th>
            <th>Short Term</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td class='js-name'>Prime</td>
            <td class='js-moodys-lt'>Aaa</td>
            <td class='js-moodys-st' rowspan=6>P-1</td>
            <td class='js-sp-lt'>AAA</td>
            <td class='js-sp-st' rowspan=4>A-1+</td>
            <td class='js-fitch-lt'>AAA</td>
            <td class='js-fitch-st' rowspan=4>F1+</td>
          </tr>
          <tr>
            <td rowspan=3 class='js-name'>High grade</td>
            <td class='js-moodys-lt'>Aa1</td>
            <td class='js-sp-lt'>AA+</td>
            <td class='js-fitch-lt'>AA+</td>
          </tr>
          <tr>
            <td class='js-moodys-lt'>Aa2</td>
            <td class='js-sp-lt'>AA</td>
            <td class='js-fitch-lt'>AA</td>
          </tr>
          <tr>
            <td class='js-moodys-lt'>Aa3</td>
            <td class='js-sp-lt'>AA-</td>
            <td class='js-fitch-lt'>AA-</td>
          </tr>
          <tr>
            <td class='js-name' rowspan=3>Upper medium grade</td>
            <td class='js-moodys-lt'>A1</td>
            <td class='js-sp-lt'>A+</td>
            <td rowspan=2 class='js-sp-st'>A-1</td>
            <td class='js-fitch-lt'>A+</td>
            <td rowspan=2 class='js-fitch-st'>F1</td>
          </tr>
          <tr>
            <td class='js-moodys-lt'>A2</td>
            <td class='js-sp-lt'>A</td>
            <td class='js-fitch-lt'>A</td>
          </tr>
          <tr>
            <td class='js-moodys-lt'>A3</td>
            <td class='js-moodys-st' rowspan=2>P-2</td>
            <td class='js-sp-lt'>A-</td>
            <td class='js-sp-st' rowspan=2>A-2</td>
            <td class='js-fitch-lt'>A-</td>
            <td class='js-fitch-st' rowspan=2>F2</td>
          </tr>
          <tr>
            <td class='js-name' rowspan=3>Lower medium grade</td>
            <td class='js-moodys-lt'>Baa1</td>
            <td class='js-sp-lt'>BBB+</td>
            <td class='js-fitch-lt'>BBB+</td>
          </tr>
          <tr>
            <td class='js-moodys-lt'>Baa2</td>
            <td class='js-moodys-st' rowspan=2>P-3</td>
            <td class='js-sp-lt'>BBB</td>
            <td class='js-sp-st' rowspan=2>A-3</td>
            <td class='js-fitch-lt'>BBB</td>
            <td class='js-fitch-st' rowspan=2>F3</td>
          </tr>
          <tr>
            <td class='js-moodys-lt'>Baa3</td>
            <td class='js-sp-lt'>BBB-</td>
            <td class='js-fitch-lt'>BBB-</td>
          </tr>
          <tr>
            <td class='js-name' rowspan=3>Non-investment grade speculative</td>
            <td class='js-moodys-lt'>Ba1</td>
            <td class='js-moodys-st' rowspan=14>Not prime</td>
            <td class='js-sp-lt'>BB+</td>
            <td class='js-sp-st' rowspan=6>B</td>
            <td class='js-fitch-lt'>BB+</td>
            <td class='js-fitch-st' rowspan=6>B</td>
          </tr>
          <tr>
            <td class='js-moodys-lt'>Ba2</td>
            <td class='js-sp-lt'>BB</td>
            <td class='js-fitch-lt'>BB</td>
          </tr>
          <tr>
            <td class='js-moodys-lt'>Ba3</td>
            <td class='js-sp-lt'>BB-</td>
            <td class='js-fitch-lt'>BB-</td>
          </tr>
          <tr>
            <td class='js-name' rowspan=3>Highly speculative</td>
            <td class='js-moodys-lt'>B1</td>
            <td class='js-sp-lt'>B+</td>
            <td class='js-fitch-lt'>B+</td>
          </tr>
          <tr>
            <td class='js-moodys-lt'>B2</td>
            <td class='js-sp-lt'>B</td>
            <td class='js-fitch-lt'>B</td>
          </tr>
          <tr>
            <td class='js-moodys-lt'>B3</td>
            <td class='js-sp-lt'>B-</td>
            <td class='js-fitch-lt'>B-</td>
          </tr>
          <tr>
            <td class='js-name'>Substantial risks</td>
            <td class='js-moodys-lt'>Caa1</td>
            <td class='js-sp-lt'>CCC+</td>
            <td class='js-sp-st' rowspan=5>C</td>
            <td class='js-fitch-lt' rowspan=5>CCC</td>
            <td class='js-fitch-st' rowspan=5>C</td>
          </tr>
          <tr>
            <td class='js-name'>Extremely speculative</td>
            <td class='js-moodys-lt'>Caa2</td>
            <td class='js-sp-lt'>CCC</td>
          </tr>
          <tr>
            <td class='js-name' rowspan=3>In default with little prospect for recovery</td>
            <td class='js-moodys-lt'>Caa3</td>
            <td class='js-sp-lt'>CCC-</td>
          </tr>
          <tr>
            <td class='js-moodys-lt'>Ca</td>
            <td class='js-sp-lt'>CC</td>
          </tr>
          <tr>
            <td class='js-moodys-lt'>Ca</td>
            <td class='js-sp-lt'>C</td>
          </tr>
          <tr>
            <td class='js-name' rowspan=3>In default</td>
            <td class='js-moodys-lt'>C</td>
            <td class='js-sp-lt' rowspan=3>D</td>
            <td class='js-sp-st' rowspan=3>/</td>
            <td class='js-fitch-lt'>DDD</td>
            <td class='js-fitch-st' rowspan=3>/</td>
          </tr>
          <tr>
            <td class='js-moodys-lt'>/</td>
            <td class='js-fitch-lt'>DD</td>
          </tr>
          <tr>
            <td class='js-moodys-lt'>/</td>
            <td class='js-fitch-lt'>D</td>
          </tr>
        </tbody>
      </table>"

      markup += "<div class=\"clear\" /></div></div>"
      $("body").append markup
      $all = $("." + bc + "-wrap")
      $wrap = $($all[count])

    plugin.init()

  $.fn.cratingPicker = (options) ->
    @each ->
      $this = $(this)
      return if $this.data("cratingPicker")
      plugin = new $.cratingPicker(this, options)
      $this.data "cratingPicker", plugin
      count++

) jQuery