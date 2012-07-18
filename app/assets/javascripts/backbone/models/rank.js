$(function(){

	RankList.Models.Rank = Backbone.Model.extend({
		url: function () {
			return this.id? '/ranks/' + this.id : '/ranks/';
		},
		initialize: function(){
			
		}
	});
	
	RankList.Collections.Ranks = Backbone.Collection.extend({
		model : RankList.Models.Rank,
		url : "/ranks"
	});
	
});