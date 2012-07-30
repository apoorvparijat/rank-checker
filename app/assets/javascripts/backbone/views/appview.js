$(function(){
	Ranks = new RankList.Collections.Ranks;
	RankList.Views.RankView = Backbone.View.extend({
		tagName: "li",
		events: {},
		template: _.template('<li id="progress-<%= Ranks.Count %>"> <%= domain %>  -  <%= keyword %> - <span class="rank"><%= rank %></span> - <span class="progress">0</span></li>'),
		render: function (){
			var rank = this.model.toJSON();
			//alert("render: " + JSON.stringify(todo));
			return this.template(rank);
		}
	});
	RankView = RankList.Views.RankView;
	RankList.Views.AppView = Backbone.View.extend({
		el: $("#ranklist-app"),
		events: {
			"submit form#new_rank" : "createRank"
		},
		initialize: function(){
			Ranks.Count = 0
			_.bindAll(this, 'addOne', 'addAll','render');
			Ranks.bind("add", this.addOne);
			Ranks.bind("reset", this.addAll);
			Ranks.bind("all", this.render);
			Ranks.fetch();
		},
		addOne: function(rank){
			var view = new RankView({model: rank});
			this.$("#ranks").append(view.render());
		},

		addAll: function(){
			Ranks.each(this.addOne);
		},
		
		newAttributes: function(event){
			var rank_form_data = $(event.currentTarget).serializeObject();
			return {
				domain: rank_form_data["rank[domain]"],
				keyword: rank_form_data["rank[keyword]"]
			};
		},
		updateResult: function(r){
			var t = this
			Ranks.interval = setInterval(function(){
				$.getJSON("/rank-checker/"+r.thread_str,function(data){
					data = jQuery.parseJSON(data);
					$("#progress-"+r.progress_id+" > span.progress").text(data.progress);
					if(data.progress >= 100){
						r.rank = data.rank;
						t.updateRank(r);
						clearInterval(Ranks.interval);
					}
				})
			},500);
		},
		updateRank: function(r){
			$("#progress-"+r.progress_id+" > span.rank").text(r.rank);
			//r.save();
		},
		createRank: function(e){
			e.preventDefault();
			Ranks.Count++;
			var params = this.newAttributes(e);
			params["thread_str"] = Ranks.Count;
			params["rank"] = 0;
			var t = this;
			r = new RankList.Models.Rank(params);
			r.progress_id = Ranks.Count;
			Ranks.add(r);
			$.getJSON("/rank-checker",params,function(data){
				r.thread_str = data.thread_str;
				t.updateResult(r)
			});
			
			//r.save();
			//Ranks.create(params);
		}
	});
	
	
});