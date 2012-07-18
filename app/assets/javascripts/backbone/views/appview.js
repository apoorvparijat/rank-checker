$(function(){
	Ranks = new RankList.Collections.Ranks;
	RankList.Views.RankView = Backbone.View.extend({
		tagName: "li",
		events: {},
		template: _.template('<li> <%= domain %>  -  <%= keyword %> - <%= rank %> </li>'),
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
		createRank: function(e){
			e.preventDefault();
			var params = this.newAttributes(e);
			$.getJSON("/rank-checker",params,function(data){
				r = new RankList.Models.Rank(data);
				Ranks.add(r);
				
			});
			
			//r.save();
			//Ranks.create(params);
		}
	});
});