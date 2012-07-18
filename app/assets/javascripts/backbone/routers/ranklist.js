$(function(){
	Rank = new RankList.Models.Rank;
	RankList.Controllers.Ranks = Backbone.Router.extend({
		routes: {
			"" : "index",
			"test": "test"
		},
		
		index: function(){
			window.App = new RankList.Views.AppView;
		},
		
		test: function(){
			alert("ding")
		}
		
	});
	
});