//= require stats/excanvas.js
//= require stats/jquery.dateRange.js
//= require stats/jquery.flot.js
//= require_self

$(document).ready(function() {

  var $customSelect = $('#custom_select_control');
  $customSelect.click(function() {
    if ($customSelect.data['expanded'] === true) { hideCustomSelect(); loadData(); }
    else {
      $customSelect.css({height: 'auto'})
      $customSelect.data['expanded'] = true;
    }
  });

  $(document).keydown(function(e) {
    if (e.keyCode == 27) { hideCustomSelect(); }
    else if (e.keyCode == 13 && $customSelect.data['expanded'] === true) {
      hideCustomSelect();
      loadData();
    }
  });

  function hideCustomSelect() {
    $customSelect.css({height: '28px'})
    $customSelect.data.expanded = false;
  }

  $customSelect.children('div').not(':first').click(function(e) {
    var $input = $(this).children('input');
    if (e.target.nodeName == 'INPUT')  {
      if ($input.is(':checked') && selectCustomInputs().length > 5) {
        $input.attr('checked', null);
      }
      e.stopPropagation();
      return true;
    }

    if ($input.is(':checked')) {
      $input.attr('checked', null);
    } else if (selectCustomInputs().length < 5) {
      $input.attr('checked', 'checked');
    }
    return false;
  });

  function selectCustomInputs() {
    return $customSelect.find('input:checked');
  }

  var $graph = $('#graph');
  var $raw = $('#raw tbody');
  var x = new Date();
  var now = new Date(x.getUTCFullYear(), x.getUTCMonth(), x.getUTCDate(),  x.getUTCHours(), x.getUTCMinutes(), x.getUTCSeconds());
  var lastWeek = new Date();
  lastWeek.setDate(now.getDate() - 7);
  $('#date').dateRange({
    startWith: new Array(now, lastWeek),
    minimumDate: new Date(2011, 0, 1),
    maximumDate: now,
    selected: loadData
  });

  var numberOfSeries = parseInt($('#custom').val()) == 1 ? 5 : 3;

  var graphOptions = {
    xaxis: { mode: 'time', timeformat: '%d %b', minTickSize: [1, 'day']  , monthNames: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'June', 'July', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'] },
    legend: {backgroundOpacity: 0, container: $('#legend'), noColumns: numberOfSeries},
    grid: {hoverable: true}
  };

  function loadData() {
    var range = $('#date').dateRange({command: 'getRange'});
    var from = Date.UTC(range[0].getFullYear(), range[0].getMonth(), range[0].getDate());
    var to = Date.UTC(range[1].getFullYear(), range[1].getMonth(), range[1].getDate());
    var data = {id: $('#id').val(), from: Math.round(from/1000), to: Math.round(to/1000), authenticity_token: AUTH_TOKEN};
    if (parseInt($('#custom').val()) == 1) {
      data['custom'] = true;
      data['custom_ids'] = [];
      selectCustomInputs().each(function() {
        data['custom_ids'].push(this.value);
      })
    }
    $.post('/manage/stats/data', data, responseReceived, 'json');
  }

  function responseReceived(r) {
    if (parseInt($('#custom').val()) == 1) {
      var $ths = $('#raw thead tr th').filter(':not(:first)').text('');
      selectCustomInputs().each(function(i) {
        $ths.eq(i).text($(this).siblings('span').text())
      });
      numberOfSeries = selectCustomInputs().length;
    }
    var series = [];
    var from = new Date(r.from * 1000);
    from = new Date(from.getUTCFullYear(), from.getUTCMonth(), from.getUTCDate(), 0, - now.getTimezoneOffset());
    for(var i = 0; i < numberOfSeries; ++i) {
      series[i] = [];
      for(var j = 0; j < r.days; ++j) {
       var value = r.data[i][j] == null ? 0 : r.data[i][j];
       d = new Date(from.getTime() + (j * 86400000))
       d = new Date(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), 0, - now.getTimezoneOffset());
       series[i].push([d, value]);
      }
    }

    var $headers = $raw.siblings('thead').find('th');
    var graphData = []
    for (var i = 0; i < numberOfSeries; ++i) {
      graphData.push({
        label: $headers.eq(i+1).text(),
        lines: {show: true},
        points: {show: true},
        data: series[i]
      });
    }
    $.plot($graph, graphData, graphOptions);

    $raw.empty();
    var indexes = new Array();
    for(var i = 0; i < r.days; ++i) {
      var $row = $('<tr>').appendTo($raw);
      var date = new Date(from.getTime() + (i * 86400000));
      date = new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate())
      $('<td>').attr('nowrap', 'nowrap').text(new Date(date).ymd()).appendTo($row);
      for(var j = 0; j < numberOfSeries; ++j) {
        var value = r.data[j][i] == null ? 0 : r.data[j][i];
        $('<td>').text(value).appendTo($row);
      }
    }
  }
  var $tip = $('<div id="reportTip">').addClass('r').appendTo($('body')).data('meta', {});
  $graph.bind('plothover', function (event, pos, item) {
    if (!item) {return;}
    var meta = {s: item.seriesIndex, d: item.dataIndex};
    var existing = $tip.data('meta');
    if (existing.s == meta.s && existing.d == meta.d) { return; }
    $tip.text(item.datapoint[1]).show().css({top: item.pageY-20, left: item.pageX+10}).data('meta', meta);
  });


  $('<iframe>').attr('id', 'downloadFrame').css('display', 'none').appendTo($('body'));
  //Download stuff
  $('#downloadMenu a').click(function() {
    var frame = $('#downloadFrame')[0];
    frame.src = '/manage/stats/data?id=' + $('#id').val() + '&year=' + $(this).attr('data-year');
    return false;
  });
});
