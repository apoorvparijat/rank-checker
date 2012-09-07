$(function(){
	Ranks = new RankList.Collections.Ranks;
	Ranks.interval = {};
	RankList.Views.RankView = Backbone.View.extend({
		tagName: "tr",
		template: _.template('<tr id="progress-{{= Ranks.Count }}" class="domains-list"> <td class="table-keyword" colspan="2">{{= keyword }}</td><td class="rank">{{= rank }}</td><td class="progress-num">0</td></tr>'),
		render: function (){
			var rank = this.model.toJSON();
			return this.template(rank);
		}
	});
	RankView = RankList.Views.RankView;

	RankList.Views.RankDetails = Backbone.View.extend({
		tagName: "tr",
		template: _.template($("#details-template").html()),
		showLatest:function(){
			$("#rank-details > .details").hide();
			$("#rank-details > .details:last").show();
		},
		render: function(model){

			var rank = this.model.toJSON();
			return this.template(rank)
			
		},
		// +t+ : context passed to the function
		// +r+ : rank json object
		// +data+ : data return from result
		
		updateResult: function(t,r,data){
			$("#details-update-" + r.progress_id + " .bar").css("width", data.progress+"%");

			if(typeof(data.progress) == "undefined" || data.progress >= 100){
				
				$("#details-update-" + r.progress_id + " .bar").animate({
					backgroundColor: "#558899",
				},1000);
				$("#details-update-" + r.progress_id + " .message").hide();
				setTimeout(function(){$("#details-update-" + r.progress_id + " .progress").removeClass("active");
				},1000);
				if(data.rank  == 0){
					$("#details-progress-" + r.progress_id + " .pane-rank").html("<span class=\"error\">The website is not ranking.</span>").fadeIn("fast");
					return;
				}
				$("#details-progress-" + r.progress_id + " .pane-rank").html("Rank: " + data.rank).fadeIn("fast",function(){
					$("#details-progress-" + r.progress_id + " .pane-page").html("Page: " + data.page).fadeIn("fast",function(){
						
						$("#details-progress-" + r.progress_id + " .pane-path").html("Page: " + data.path).fadeIn("fast",function(){
							$("#details-progress-" + r.progress_id + " .pane-link").html("URI - <a target=\"_blank\" href='http://" + data.url + "'>" + data.url + "</a>").fadeIn("fast");
						});
					});	
				});	
			}
			if(typeof (data.message) != "undefined")
				$("#details-update-" + r.progress_id + " .message").html(data.message);

		}
	});
	RankDetailsView = RankList.Views.RankDetails;
	
	
	RankList.Views.AppView = Backbone.View.extend({
		el: $("#ranklist-app"),
		events: {
			"submit form#new_rank" : "createRank",
			"mouseover .domains-list" : "showDetails",
			"click .domains-list" : "changeActiveTr",
			"mouseout .domains-list" : "returnToActiveTr"
		},
		initialize: function(){
			Ranks.Count = 1;
			Ranks.Domains = {};
			Ranks.DomainAdded = {};
			Ranks.DomainsCount = 1
			Ranks.activeTr = 1;
			var t = this;
			this.detailsUpdater = new RankDetailsView;
			_.bindAll(this, 'addOne', 'addAll','render','updateResult');
			Ranks.bind("add", this.addOne);
			Ranks.bind("reset", this.addAll);
			Ranks.bind("all", this.render);
			Ranks.bind("updateResult",this.updateResult);
			Ranks.bind("updateResult",this.detailsUpdater.updateResult);
			Ranks.fetch();
		},
		addOne: function(rank){
			var t = this;
			rank.set({progress_id: Ranks.Count});
			if(typeof(rank.get("url")) == "undefined"){
				rank.set({url: ""});
				rank.set({path: ""});
				rank.set({message: ""})
			}
			rank.set({message: ""});
			var view = new RankView({model: rank});
			var detailsView = new RankDetailsView({model:rank});
			if(typeof (Ranks.DomainAdded[rank.get("domain")]) == "undefined" || Ranks.DomainAdded[rank.get("domain")] == false){
				Ranks.Domains[rank.get("domain")] = Ranks.DomainsCount;
				t.$("#ranks").prepend("<tbody class='domains-list-body "+ Ranks.Domains[rank.get("domain")] +"'><tr><td colspan='4'>"+ rank.get("domain") +"</td></tr></tbody>");
				t.$("#ranks .domains-list-body." + Ranks.Domains[rank.get("domain")]).append(view.render());
				Ranks.DomainAdded[rank.get("domain")] = true;
				Ranks.DomainsCount++;
			}else{
				t.$("#ranks ." + Ranks.Domains[rank.get("domain")]).append(view.render());
			}
			

			el = $("#rank-details").append(detailsView.render());

			if(rank.get("url") != "")
			{
				data = {};
				data.url = rank.get("url");
				data.progress = 100;
				data.rank = rank.get("rank");
				data.path = rank.get("path");
				data.progress_id = rank.get("progress_id");
				data.page = rank.get("page");
				data.message = rank.get("message");
				detailsView.updateResult(t,data,data);
			}
			
			detailsView.showLatest();
			Ranks.Count++;
		},

		addAll: function(){
			var t = this;
			Ranks.each(this.addOne);
			var r = {progress_id : 1};
			this.changeActiveTrTo(r);
		},
		
		newAttributes: function(event){
			var rank_form_data = $(event.currentTarget).serializeObject();
			return {
				domain: rank_form_data["rank[domain]"],
				keyword: rank_form_data["rank[keyword]"]
			};
		},
		updateResult:function(t,r,data){
			$("#progress-"+r.progress_id+" > td.progress-num").text(data.progress);
			if(data.progress >= 100){
				r.rank = data.rank;
				t.updateRank(r);
				clearInterval(Ranks.interval[r.thread_str]);
			}
		},
		trackProgress: function(r){
			var t = this
			$("#details-update-" + r.progress_id + " .bar").css("width","0%").css("backgroundColor","#149BDF");
			$("#details-update-" + r.progress_id + " .progress").addClass("active");
			Ranks.interval[r.thread_str] = setInterval(function(){
				$.getJSON("/rank-checker/"+r.thread_str,function(data){
					data = jQuery.parseJSON(data);
					Ranks.trigger("updateResult",t,r,data);
				})
			},500);
		},
		updateRank: function(r){
			$("#progress-"+r.progress_id+" > td.rank").text(r.rank);
			//r.save();
		},
		createRank: function(e){
			e.preventDefault();
			var params = this.newAttributes(e);
			params["thread_str"] = Ranks.Count;
			params["rank"] = 0;
			var t = this;
			r = new RankList.Models.Rank(params);
			r.progress_id = Ranks.Count;
			r.id = r.progress_id;
			Ranks.add(r);
			this.blink(r);
			$.getJSON("/rank-checker",params,function(data){
				r.thread_str = data.thread_str;
				t.trackProgress(r)
			});
			//Ranks.Count++;
			//r.save();
			//Ranks.create(params);
		},
		blink: function(r){
			//alert(r.progress_id);
			Ranks.activeTr = r.progress_id;
			var t = this;
			this.clearAllHighlight();
			$("#progress-"+r.progress_id).css("background-color","#6daf5a").animate({
				backgroundColor: "#e8e8e8"
			},400,function(){
				t.highlight(event,r);
				$("#progress-"+r.progress_id).css("background-color","");
			});
			
		},
		highlight: function(event,r){
			$("#progress-"+r.progress_id).addClass("tr-highlighted");
		},
		clearAllHighlight: function(){
			$("tr",this.el).removeClass("tr-highlighted");
		},
		
		showDetails: function(event){
			e = event.target;
			id = $(e).parent().attr("id");
			$(".details").hide();
			$("#details-"+id).show();
		},
		returnToActiveTr:function(event){
			this.clearAllHighlight();
			var r = {};
			r.progress_id = Ranks.activeTr;
			this.highlight(event,r);
			$(".details").hide();
			$("#details-progress-" + Ranks.activeTr).show();
		},
		changeActiveTr:function(event){
			this.clearAllHighlight();
			e = event.target;
			id = $(e).parent().attr("id");
			var r = {};
			r.progress_id = id.split("-")[1];
			this.changeActiveTrTo(r);
		},
		changeActiveTrTo: function(r){
			Ranks.activeTr = r.progress_id;
			this.highlight(event,r);
			$(".details").hide();
			$("#details-progress-"+r.progress_id).show();
		}
	});
	
	
});