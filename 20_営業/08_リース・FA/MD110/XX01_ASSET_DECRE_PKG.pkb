create or replace
PACKAGE BODY      XX01_ASSET_DECRE_PKG
/*****************************************************************************
 * $ Header: XX01_ASSET_DECRE_PKG.pkb 11.5.0 0.0.0.0 2001/12/28 $
 * 成果物の全ての知的財産権は弊社に帰属します。
 * 成果物の使用、複製、改変・翻案は、日本オラクル社との契約に記された制約条件に従うものとします。
 * ORACLEはOracle Corporationの登録商標です。
 * Copyright (c) 2001 Oracle Corporation Japan All Rights Reserved
 * パッケージ名 :		XX01_ASSET_DECRE_PKG
 * 機能概要     :		資産増減減少表出力ワークテーブル作成
 * バージョン   :		11.5.1
 * 作成者       :
 * 作成日       :		2001-10-22
 * 変更者       :
 * 最終変更日   :		2010-12-29
 * 変更履歴     :
 * ------------- -------- ------------- -------------------------------------
 *  Date          Ver.     Editor        Description
 * ------------- -------- ------------- -------------------------------------
 *  2010-12-29    11.5.1   SCS 渡辺      [E_本稼動_05184]
 *                                       帳票ワーク出力へのブレイク条件修正
 *                                       振替対象チェック(貸借一致セグメント比較)削除
 ****************************************************************************/
IS
--- ******************
--- グローバル変数定義
--- ******************
		gn_sequence_id								NUMBER(15);				--シーケンス番号
		gn_created_by									NUMBER(15);				--作成者のユーザＩＤ
		gd_creation_date							DATE;							--作成日時
		gn_last_updated_by						NUMBER(15);				--最終変更者のユーザＩＤ
		gd_last_update_date						DATE;							--最終変更日時
		gn_last_update_login					NUMBER(15);				--最終ログイン
		gn_request_id									NUMBER(15);				--要求ＩＤ
		gn_program_application_id			NUMBER(15);				--ＡＰのＩＤ
		gn_program_id									NUMBER(15);				--ＰＧのＩＤ
		gd_program_update_date				DATE;							--最終変更日時

		gv_company_name								VARCHAR2(30);			--会社名
		gv_book_type_code							fa_books.book_type_code%type;		--台帳名
		gv_asset_type_code						VARCHAR2(80);			--資産タイプコード
		gv_account_periods_from				VARCHAR2(15);			--自：会計期間名称
		gv_account_periods_to					VARCHAR2(15);			--至：会計期間名称
		gv_account_unit_code_from			VARCHAR2(150);		--自：会計単位
		gv_account_unit_code_to				VARCHAR2(150);		--至：会計単位

		gn_period_counter_from				NUMBER(15);				--自：会計期間
		gn_period_counter_to					NUMBER(15);				--至：会計期間
		gv_asset_type									VARCHAR2(80);			--資産タイプ
		gn_accounting_flex_structure	NUMBER(15);				--会計単位取得情報

		gv_adjustment_type						VARCHAR2(15);
		gv_source_type_code_retire		VARCHAR2(15);
		gv_source_type_code_adjust		VARCHAR2(15);
		gv_source_type_code_trans			VARCHAR2(15);

		USER_EXPT											EXCEPTION;				--例外処理

--- ****************
--- コンスタント定義
--- ****************
		--データ種別
		gc_adjustment							CONSTANT NUMBER(1) := 2;
		gc_transfer								CONSTANT NUMBER(1) := 3;
		gc_sale										CONSTANT NUMBER(1) := 4;
		gc_retirement							CONSTANT NUMBER(1) := 5;
		gc_sale_reinstate					CONSTANT NUMBER(1) := 6;
		gc_retirement_reinstate		CONSTANT NUMBER(1) := 7;
		gc_change_cip_cost				CONSTANT NUMBER(1) := 8;
		--減少事由
		gc_adjustment_n						CONSTANT VARCHAR2(8) := '修正';
		gc_transfer_n							CONSTANT VARCHAR2(8) := '振替';
		gc_sale_n									CONSTANT VARCHAR2(8) := '売却';
		gc_retirement_n						CONSTANT VARCHAR2(8) := '除却';
		--建設仮勘定から資産計上用資産タイプ
		gc_change_source_type			CONSTANT VARCHAR2(8) := 'ADDITION';
		gc_change_asset_type			CONSTANT VARCHAR2(11) := 'CAPITALIZED';
--- ****************
--- システム管理情報
--- ****************
		g_control_rec			fa_system_controls%rowtype;

--- **************
--- 出力ＲＯＷ定義
--- **************
		g_decre_wk_rec		xx01_asset_decrease_wk%rowtype;

--- ****************
--- 出力件数カウンタ
--- ****************
		gn_count	NUMBER(38,0)		:=	0;

--- **************
--- 修正履歴を抽出
--- **************
		CURSOR		g_adjust_cur IS
			--- ****
			--- 売却
			--- ****
			SELECT	--データ種フラグ
							gc_sale											data_type_flag,
							--ＣＣＩＤ（会計単位取得時使用）
							fdh.code_combination_id			c_code_combination_id,
							--カテゴリーＩＤ（主カテゴリー取得時使用）
							fah.category_id							category_id,
							fb1.deprn_method_code				deprn_method_code,	--償却方法
							fab.asset_number						asset_number,				--資産番号
							fat.description							asset_description,	--資産摘要
							faj.period_counter_created	period_counter,			--会計期間
							fdp.period_name							period_name,				--会計期間名称
							faj.transaction_header_id		transaction_id,			--トランＩＤ
							fab.attribute2							acquisition_date,		--取得日
							fb1.date_placed_in_service	placed_in_service,	--事業供用日
							frt.units										decrease_units,			--減少数量
							gc_sale_n										decrease_reason,		--減少事由
							fb2.cost										before_cost,				--減少前取得価額
							0														decrease_cost,			--修正金額
							0														retirement_cost,		--除却価額
							faj.adjustment_amount - NVL(fa2.adjustment_amount,0)
																					sale_cost,					--売却価額
							fb1.cost										after_cost					--減少後取得価額
			FROM		fa_additions_tl					fat,
							fa_additions_b					fab,
							fa_books								fb1,		--減少後情報取得用
							fa_books								fb2,		--減少前情報取得用
							fa_distribution_history fdh,
							fa_deprn_periods 				fdp,
							fa_asset_history 				fah,
							fa_retirements 					frt,
							fa_adjustments					fa2,
							fa_adjustments					faj
			WHERE		faj.book_type_code					=	gv_book_type_code
			AND			faj.period_counter_created	BETWEEN gn_period_counter_from
		 																					AND gn_period_counter_to
			AND			faj.source_type_code				=	gv_source_type_code_retire
			AND			faj.adjustment_type					=	gv_adjustment_type
			AND			faj.debit_credit_flag				=	'CR'
			AND			faj.asset_id								=	fat.asset_id
			AND			faj.asset_id								=	fab.asset_id
			AND			faj.asset_id								=	fb1.asset_id
			AND			faj.transaction_header_id 	= fb1.transaction_header_id_in
			AND			faj.asset_id								=	fb2.asset_id
			AND			faj.transaction_header_id 	= fb2.transaction_header_id_out
			AND			faj.asset_id								=	fah.asset_id
			AND			fah.transaction_header_id_in =
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= faj.asset_id
								AND		fah2.transaction_header_id_in
										<= faj.transaction_header_id)
			AND			faj.distribution_id					=	fdh.distribution_id
			AND			faj.period_counter_created	=	fdp.period_counter
			AND  		fdp.book_type_code					=	gv_book_type_code
			AND			fat.language								=	userenv('LANG')
			AND 		fah.asset_type							=	gv_asset_type_code
			AND			faj.asset_id								= fa2.asset_id(+)
			AND			faj.transaction_header_id 	= fa2.transaction_header_id(+)
			AND			fa2.source_type_code(+)			=	gv_source_type_code_retire
			AND			fa2.adjustment_type(+)			=	gv_adjustment_type
			AND			fa2.debit_credit_flag(+)		= 'DR'
			AND			faj.asset_id								=	frt.asset_id
			AND			faj.transaction_header_id 	= frt.transaction_header_id_in
			AND     EXISTS(
								SELECT		*
								FROM			xx01_lookup_codes	 xlc
								WHERE			frt.retirement_type_code	=	xlc.meaning
								AND				lookup_type	=	'SALE_TYPE'
										)
			--- **************
			--- 再稼動（売却）
			--- **************
			UNION ALL
			SELECT	gc_sale_reinstate						data_type_flag,
							fdh.code_combination_id			c_code_combination_id,
							fah.category_id							category_id,
							fb1.deprn_method_code				deprn_method_code,
							fab.asset_number						asset_number,
							fat.description							asset_description,
							faj.period_counter_created	period_counter,
							fdp.period_name							period_name,
							faj.transaction_header_id		transaction_id,
							fab.attribute2							acquisition_date,
							fb1.date_placed_in_service	placed_in_service,
							-1 * frt.units							decrease_units,
							gc_sale_n										decrease_reason,
							fb2.cost										before_cost,
							0														decrease_cost,
							0														retirement_cost,
							-1 * faj.adjustment_amount + NVL(fa2.adjustment_amount,0)
																					sale_cost,
							fb1.cost										after_cost
			FROM		fa_additions_tl					fat,
							fa_additions_b					fab,
							fa_books								fb1,		--減少後情報取得用
							fa_books								fb2,		--減少前情報取得用
							fa_distribution_history fdh,
							fa_deprn_periods 				fdp,
							fa_asset_history 				fah,
							fa_retirements 					frt,
							fa_adjustments					fa2,
							fa_adjustments					faj
			WHERE		faj.book_type_code					=	gv_book_type_code
			AND			faj.period_counter_created	BETWEEN gn_period_counter_from
		 																					AND gn_period_counter_to
			AND			faj.source_type_code				=	gv_source_type_code_retire
			AND			faj.adjustment_type					=	gv_adjustment_type
			AND			faj.debit_credit_flag				=	'DR'
			AND			faj.asset_id								=	fat.asset_id
			AND			faj.asset_id								=	fab.asset_id
			AND			faj.asset_id								=	fb1.asset_id
			AND			faj.transaction_header_id 	= fb1.transaction_header_id_in
			AND			faj.asset_id								=	fb2.asset_id
			AND			faj.transaction_header_id 	= fb2.transaction_header_id_out
			AND			faj.asset_id								=	fah.asset_id
			AND			fah.transaction_header_id_in =
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= faj.asset_id
								AND		fah2.transaction_header_id_in
										<= faj.transaction_header_id)
			AND			faj.distribution_id					=	fdh.distribution_id
			AND			faj.period_counter_created	=	fdp.period_counter
			AND  		fdp.book_type_code					=	gv_book_type_code
			AND			fat.language								=	userenv('LANG')
			AND 		fah.asset_type							=	gv_asset_type_code
			AND			faj.asset_id								= fa2.asset_id(+)
			AND			faj.transaction_header_id 	= fa2.transaction_header_id(+)
			AND			fa2.source_type_code(+)			=	gv_source_type_code_retire
			AND			fa2.adjustment_type(+)			=	gv_adjustment_type
			AND			fa2.debit_credit_flag(+)		= 'CR'
			AND			faj.asset_id								=	frt.asset_id
			AND			faj.transaction_header_id 	= frt.transaction_header_id_out
			AND			frt.status									= 'DELETED'
			AND     EXISTS(
								SELECT		*
								FROM			xx01_lookup_codes	 xlc
								WHERE			frt.retirement_type_code	=	xlc.meaning
								AND				lookup_type	=	'SALE_TYPE'
										)
			--- ****
			--- 除却
			--- ****
			UNION ALL
			SELECT	gc_retirement								data_type_flag,
							fdh.code_combination_id			c_code_combination_id,
							fah.category_id							category_id,
							fb1.deprn_method_code				deprn_method_code,
							fab.asset_number						asset_number,
							fat.description							asset_description,
							faj.period_counter_created	period_counter,
							fdp.period_name							period_name,
							faj.transaction_header_id		transaction_id,
							fab.attribute2							acquisition_date,
							fb1.date_placed_in_service	placed_in_service,
							frt.units										decrease_units,
							gc_retirement_n							decrease_reason,
							fb2.cost										before_cost,
							0														decrease_cost,
							faj.adjustment_amount - NVL(fa2.adjustment_amount,0)
																					retirement_cost,
							0														sale_cost,
							fb1.cost										after_cost
			FROM		fa_additions_tl					fat,
							fa_additions_b					fab,
							fa_books								fb1,		--減少後情報取得用
							fa_books								fb2,		--減少前情報取得用
							fa_distribution_history fdh,
							fa_deprn_periods 				fdp,
							fa_asset_history 				fah,
							fa_retirements 					frt,
							fa_adjustments					fa2,
							fa_adjustments					faj
			WHERE		faj.book_type_code					=	gv_book_type_code
			AND			faj.period_counter_created	BETWEEN gn_period_counter_from
		 																					AND gn_period_counter_to
			AND			faj.source_type_code				=	gv_source_type_code_retire
			AND			faj.adjustment_type					=	gv_adjustment_type
			AND			faj.debit_credit_flag				=	'CR'
			AND			faj.asset_id								=	fat.asset_id
			AND			faj.asset_id								=	fab.asset_id
			AND			faj.asset_id								=	fb1.asset_id
			AND			faj.transaction_header_id 	= fb1.transaction_header_id_in
			AND			faj.asset_id								=	fb2.asset_id
			AND			faj.transaction_header_id 	= fb2.transaction_header_id_out
			AND			faj.asset_id								=	fah.asset_id
			AND			fah.transaction_header_id_in =
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= faj.asset_id
								AND		fah2.transaction_header_id_in
										<= faj.transaction_header_id)
			AND			faj.distribution_id					=	fdh.distribution_id
			AND			faj.period_counter_created	=	fdp.period_counter
			AND  		fdp.book_type_code					=	gv_book_type_code
			AND			fat.language								=	userenv('LANG')
			AND 		fah.asset_type							=	gv_asset_type_code
			AND			faj.asset_id								= fa2.asset_id(+)
			AND			faj.transaction_header_id 	= fa2.transaction_header_id(+)
			AND			fa2.source_type_code(+)			=	gv_source_type_code_retire
			AND			fa2.adjustment_type(+)			=	gv_adjustment_type
			AND			fa2.debit_credit_flag(+)		= 'DR'
			AND			faj.asset_id								=	frt.asset_id
			AND			faj.transaction_header_id 	= frt.transaction_header_id_in
			AND     NOT EXISTS(
								SELECT		*
								FROM			xx01_lookup_codes	 xlc
								WHERE			frt.retirement_type_code	=	xlc.meaning
								AND				lookup_type	=	'SALE_TYPE'
										)
			--- **************
			--- 再稼動（除却）
			--- **************
			UNION ALL
			SELECT	gc_retirement_reinstate			data_type_flag,
							fdh.code_combination_id			c_code_combination_id,
							fah.category_id							category_id,
							fb1.deprn_method_code				deprn_method_code,
							fab.asset_number						asset_number,
							fat.description							asset_description,
							faj.period_counter_created	period_counter,
							fdp.period_name							period_name,
							faj.transaction_header_id		transaction_id,
							fab.attribute2							acquisition_date,
							fb1.date_placed_in_service	placed_in_service,
							-1 * frt.units							decrease_units,
							gc_retirement_n							decrease_reason,
							fb2.cost										before_cost,
							0														decrease_cost,
							-1 * faj.adjustment_amount + NVL(fa2.adjustment_amount,0)
																					retirement_cost,
							0														sale_cost,
							fb1.cost										after_cost
			FROM		fa_additions_tl					fat,
							fa_additions_b					fab,
							fa_books								fb1,		--減少後情報取得用
							fa_books								fb2,		--減少前情報取得用
							fa_distribution_history fdh,
							fa_deprn_periods 				fdp,
							fa_asset_history 				fah,
							fa_retirements 					frt,
							fa_adjustments					fa2,
							fa_adjustments					faj
			WHERE		faj.book_type_code					=	gv_book_type_code
			AND			faj.period_counter_created	BETWEEN gn_period_counter_from
		 																					AND gn_period_counter_to
			AND			faj.source_type_code				=	gv_source_type_code_retire
			AND			faj.adjustment_type					=	gv_adjustment_type
			AND			faj.debit_credit_flag				=	'DR'
			AND			faj.asset_id								=	fat.asset_id
			AND			faj.asset_id								=	fab.asset_id
			AND			faj.asset_id								=	fb1.asset_id
			AND			faj.transaction_header_id 	= fb1.transaction_header_id_in
			AND			faj.asset_id								=	fb2.asset_id
			AND			faj.transaction_header_id 	= fb2.transaction_header_id_out
			AND			faj.asset_id								=	fah.asset_id
			AND			fah.transaction_header_id_in =
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= faj.asset_id
								AND		fah2.transaction_header_id_in
										<= faj.transaction_header_id)
			AND			faj.distribution_id					=	fdh.distribution_id
			AND			faj.period_counter_created	=	fdp.period_counter
			AND  		fdp.book_type_code					=	gv_book_type_code
			AND			fat.language								=	userenv('LANG')
			AND 		fah.asset_type							=	gv_asset_type_code
			AND			faj.asset_id								= fa2.asset_id(+)
			AND			faj.transaction_header_id 	= fa2.transaction_header_id(+)
			AND			fa2.source_type_code(+)			=	gv_source_type_code_retire
			AND			fa2.adjustment_type(+)			=	gv_adjustment_type
			AND			fa2.debit_credit_flag(+)		= 'CR'
			AND			faj.asset_id								=	frt.asset_id
			AND			faj.transaction_header_id 	= frt.transaction_header_id_out
			AND			frt.status									= 'DELETED'
			AND     NOT EXISTS(
								SELECT		*
								FROM			xx01_lookup_codes	 xlc
								WHERE			frt.retirement_type_code	=	xlc.meaning
								AND				lookup_type	=	'SALE_TYPE'
										)
			--- ********
			--- 修正減少
			--- ********
			UNION ALL
			SELECT	gc_adjustment								data_type_flag,
							fdh.code_combination_id			c_code_combination_id,
							fah.category_id							category_id,
							fb1.deprn_method_code				deprn_method_code,
							fab.asset_number						asset_number,
							fat.description							asset_description,
							faj.period_counter_created	period_counter,
							fdp.period_name							period_name,
							faj.transaction_header_id		transaction_id,
							fab.attribute2							acquisition_date,
							fb1.date_placed_in_service	placed_in_service,
							0														decrease_units,
							gc_adjustment_n							decrease_reason,
							fb2.cost										before_cost,
							faj.adjustment_amount				decrease_cost,
							0														retirement_cost,
							0														sale_cost,
							fb1.cost										after_cost
			FROM		fa_additions_tl					fat,
							fa_additions_b					fab,
							fa_books								fb1,		--減少後情報取得
							fa_books								fb2,		--減少前情報取得
							fa_distribution_history fdh,
							fa_deprn_periods 				fdp,
							fa_asset_history 				fah,
							fa_adjustments					faj
			WHERE		faj.book_type_code					=	gv_book_type_code
			AND			faj.period_counter_created	BETWEEN gn_period_counter_from
		 																					AND gn_period_counter_to
			AND			faj.source_type_code				=	gv_source_type_code_adjust
			AND			faj.adjustment_type					=	gv_adjustment_type
			AND			faj.debit_credit_flag				=	'CR'
			AND			faj.asset_id								=	fat.asset_id
			AND			faj.asset_id								=	fab.asset_id
			AND			faj.asset_id								=	fb1.asset_id
			AND			faj.transaction_header_id 	= fb1.transaction_header_id_in
			AND			faj.asset_id								=	fah.asset_id
			AND			fah.transaction_header_id_in =
     					(SELECT	MAX (fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= faj.asset_id
								AND		fah2.transaction_header_id_in
										<= faj.transaction_header_id)
			AND			faj.distribution_id					=	fdh.distribution_id
			AND			faj.period_counter_created	=	fdp.period_counter
			AND  		fdp.book_type_code					=	gv_book_type_code
			AND			fat.language								=	userenv('LANG')
			AND			faj.asset_id								=	fb2.asset_id
			AND			faj.transaction_header_id 	= fb2.transaction_header_id_out
			AND 		fah.asset_type							=	gv_asset_type_code
			--- ********
			--- 振替減少
			--- ********
			UNION ALL
			SELECT	gc_transfer									data_type_flag,
							fdh.code_combination_id			c_code_combination_id,
							fah.category_id							category_id,
							fb1.deprn_method_code				deprn_method_code,
							fab.asset_number						asset_number,
							fat.description							asset_description,
							faj.period_counter_created	period_counter,
							fdp.period_name							period_name,
							faj.transaction_header_id		transaction_id,
							fab.attribute2							acquisition_date,
							fb1.date_placed_in_service	placed_in_service,
							-1 * fdh.transaction_units	decrease_units,
							gc_transfer_n								decrease_reason,
							faj.adjustment_amount				before_cost,
							faj.adjustment_amount				decrease_cost,
							0														retirement_cost,
							0														sale_cost,
							0														after_cost
			FROM		fa_additions_tl					fat,
							fa_additions_b					fab,
							fa_books								fb1,
							fa_distribution_history fdh,
							fa_deprn_periods 				fdp,
							fa_asset_history 				fah,
							fa_adjustments					faj
			WHERE		faj.book_type_code					=	gv_book_type_code
			AND			faj.period_counter_created	BETWEEN gn_period_counter_from
		 																					AND gn_period_counter_to
			AND			faj.source_type_code				=	gv_source_type_code_trans
			AND			faj.adjustment_type					=	gv_adjustment_type
			AND			faj.debit_credit_flag				=	'CR'
			AND			faj.asset_id								=	fat.asset_id
			AND			faj.asset_id								=	fab.asset_id
			AND			faj.asset_id								=	fb1.asset_id
			AND			faj.book_type_code					=	fb1.book_type_code
			AND			faj.transaction_header_id 	>= fb1.transaction_header_id_in
			AND			faj.transaction_header_id   < nvl(fb1.transaction_header_id_out,
																															999999999999999)
			AND			faj.asset_id								=	fah.asset_id
			AND			fah.transaction_header_id_in =
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= faj.asset_id
								AND		fah2.transaction_header_id_in
										<= faj.transaction_header_id)
			AND			faj.distribution_id					=	fdh.distribution_id
			AND			faj.period_counter_created	=	fdp.period_counter
			AND  		fdp.book_type_code					=	gv_book_type_code
			AND			fat.language								=	userenv('LANG')
			AND 		fah.asset_type							=	gv_asset_type_code
			--- **********************
			--- 建設仮勘定から資産計上
			--- **********************
			UNION ALL
			SELECT	gc_change_cip_cost					data_type_flag,
							fdh.code_combination_id			c_code_combination_id,
							fah.category_id							category_id,
							fb1.deprn_method_code				deprn_method_code,
							fab.asset_number						asset_number,
							fat.description							asset_description,
							faj.period_counter_created	period_counter,
							fdp.period_name							period_name,
							faj.transaction_header_id		transaction_id,
							fab.attribute2							acquisition_date,
							fb1.date_placed_in_service	placed_in_service,
							fdh.units_assigned					decrease_units,
							gc_transfer_n								decrease_reason,
							faj.adjustment_amount				before_cost,
							faj.adjustment_amount				decrease_cost,
							0														retirement_cost,
							0														sale_cost,
							0														after_cost
			FROM		fa_additions_tl					fat,
			    		fa_additions_b					fab,
							fa_books								fb1,
							fa_distribution_history fdh,
							fa_deprn_periods 				fdp,
							fa_asset_history 				fah,
							fa_adjustments					faj
			WHERE		faj.book_type_code					=	gv_book_type_code
			AND			faj.period_counter_created	BETWEEN gn_period_counter_from
		 																					AND gn_period_counter_to
			AND			faj.source_type_code				=	gc_change_source_type
			AND			faj.adjustment_type					=	gv_adjustment_type
			AND			faj.debit_credit_flag				=	'CR'
			AND			faj.asset_id								=	fat.asset_id
			AND			faj.asset_id								=	fab.asset_id
			AND			faj.asset_id								=	fb1.asset_id
			AND			faj.transaction_header_id 	= fb1.transaction_header_id_in
			AND			faj.asset_id								=	fah.asset_id
			AND			fah.transaction_header_id_in =
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= faj.asset_id
								AND		fah2.transaction_header_id_in
										<= faj.transaction_header_id)
			AND			faj.distribution_id					=	fdh.distribution_id
			AND			faj.period_counter_created	=	fdp.period_counter
			AND  		fdp.book_type_code					=	gv_book_type_code
			AND			fat.language								=	userenv('LANG')
			AND 		fah.asset_type							=	gc_change_asset_type
			ORDER BY c_code_combination_id,category_id;

		g_adjust_rec	g_adjust_cur%rowtype;

------------------------------------------------------------------------------
	PROCEDURE initialize_proc(	ov_errbuf			OUT		VARCHAR2,
															on_retcode		OUT		NUMBER)
	IS
/*****************************************************************************
 * PROCEDURE名	:		initialize_proc
 * 機能概要			:		初期化処理
 * バージョン		:		1.0.0
 * 引数					:		errbuf			エラーバッファ
 * 戻り値				:		retcode			エラーコード(成功: 0,警告: 1,エラー: 2)
 * 注意事項			:		特に無し
 * 作成者       :
 * 作成日       :		2001-10-23
 * 変更者       :
 * 最終変更日   :		YYYY-MM-DD
 * 変更履歴     :		YYYY-MM-DD
 *								Ｎ--------------------------------------------------------Ｎ
 *								Ｎ--------------------------------------------------------Ｎ
 ****************************************************************************/
		lv_errbuf		VARCHAR2(2000)	:= NULL;
		ln_retcode	NUMBER(1)				:= 0;
	BEGIN
		ov_errbuf			:=		NULL;
		on_retcode		:=		0;
--- ************************************
--- コンカレントログファイル出力初期処理
--- ************************************
		xx01_conc_util_pkg.conc_log_start;
--- ********************************
--- コンカレントログ出力（題名出力）
--- ********************************
  	xx01_conc_util_pkg.conc_log_put( '資産増減明細表（減少分）抽出ログ' );
		xx01_conc_util_pkg.conc_log_line( '=' );
--- ********************
--- グローバル変数セット
--- ********************
		gn_created_by							:= fnd_global.user_id;
		gd_creation_date					:= SYSDATE;
		gn_last_updated_by				:= fnd_global.user_id;
		gd_last_update_date				:= SYSDATE;
		gn_last_update_login			:= fnd_global.conc_login_id;
		gn_request_id							:= fnd_global.conc_request_id;
		gn_program_application_id	:= fnd_global.prog_appl_id;
		gn_program_id							:= fnd_global.conc_program_id;
		gd_program_update_date		:= SYSDATE;
--- **************************
--- ＦＡシステム管理値取り込み
--- **************************
		SELECT	*
		INTO		g_control_rec
		FROM		fa_system_controls;
		gv_company_name := g_control_rec.company_name;
--- ************
--- 会計期間取得
--- ************
		get_period_counter(lv_errbuf,
											 ln_retcode,
											 gv_book_type_code,
											 gv_account_periods_from,
                       gn_period_counter_from);
		IF ln_retcode != 0 THEN
				RAISE USER_EXPT;
		END IF;
		get_period_counter(lv_errbuf,
											 ln_retcode,
											 gv_book_type_code,
											 gv_account_periods_to,
                       gn_period_counter_to);
		IF ln_retcode != 0 THEN
				RAISE USER_EXPT;
		END IF;
--- **************
--- 資産タイプ変換
--- **************
		conv_asset_type(lv_errbuf,
										ln_retcode,
										gv_asset_type,
                    gv_asset_type_code);
		IF ln_retcode != 0 THEN
				RAISE USER_EXPT;
		END IF;
		--ＣＩＰ対応
		IF gv_asset_type_code = 'CIP' THEN
			gv_adjustment_type := 'CIP COST';
			gv_source_type_code_retire := 'CIP RETIREMENT';
			gv_source_type_code_adjust := 'CIP ADJUSTMENT';
		ELSE
			gv_adjustment_type := 'COST';
			gv_source_type_code_retire := 'RETIREMENT';
			gv_source_type_code_adjust := 'ADJUSTMENT';
		END IF;
		gv_source_type_code_trans := 'TRANSFER';
--- ********
--- 例外処理
--- ********
	EXCEPTION
	WHEN USER_EXPT THEN
		ov_errbuf	:= lv_errbuf ;
		on_retcode	:= ln_retcode ;
	WHEN OTHERS THEN
		ov_errbuf	:= xx01_conc_util_pkg.get_message_others
									( 'xx01_asset_decre_pkg.initialize' ) ;
		on_retcode	:= 2;
	END initialize_proc;
------------------------------------------------------------------------------
	PROCEDURE insert_decre_wk(	ov_errbuf					OUT	VARCHAR2,
															on_retcode				OUT	NUMBER)
	IS
/*****************************************************************************
 * PROCEDURE名	:		insert_decre_wk
 * 機能概要			:		ワークＤＢ出力処理
 * バージョン		:		1.0.0
 * 戻り値				:		ov_errbuf   				エラーバッファ
 * 　　　				:		on_retcode					エラーコード(成功:0,警告:1,エラー:2)
 * 注意事項			:		特に無し
 * 作成者       :
 * 作成日       :		2001-10-19
 * 変更者       :
 * 最終変更日   :		YYYY-MM-DD
 * 変更履歴     :		YYYY-MM-DD
 *								Ｎ--------------------------------------------------------Ｎ
 *								Ｎ--------------------------------------------------------Ｎ
 ****************************************************************************/
		lv_errbuf	VARCHAR2(2000)	:= NULL;
		ln_retcode	NUMBER(1)				:= 0;
	BEGIN
--- **************
--- ワークＤＢ出力
--- **************
		INSERT INTO xx01_asset_decrease_wk(
								asset_decrease_wk_id,
								sequence_id,
								created_by,
								creation_date,
								last_updated_by,
								last_update_date,
								last_update_login,
								request_id,
								program_application_id,
								program_id,
								program_update_date,
								company_name,
								book_type_code,
								asset_type,
								account_periods_from,
								account_periods_to,
								account_unit_code,
								account_unit_name,
								category,
								asset_number,
								asset_description,
								period_counter,
								period_name,
								transaction_id,
								deprn_method_code,
								life,
								acquisition_date,
								date_placed_in_service,
								decrease_units,
								decrease_reason,
								before_cost,
								decrease_cost,
								retirement_cost,
								sale_cost,
								after_cost)
				VALUES
							 (
								xx01_asset_decre_wk_s.nextval,
								gn_sequence_id,
								gn_created_by,
								gd_creation_date,
								gn_last_updated_by,
								gd_last_update_date,
								gn_last_update_login,
								gn_request_id,
								gn_program_application_id,
								gn_program_id,
								gd_program_update_date,
								gv_company_name,
								gv_book_type_code,
								gv_asset_type,
								gv_account_periods_from,
								gv_account_periods_to,
								g_decre_wk_rec.account_unit_code,
								g_decre_wk_rec.account_unit_name,
								g_decre_wk_rec.category,
								g_decre_wk_rec.asset_number,
								g_decre_wk_rec.asset_description,
								g_decre_wk_rec.period_counter,
								g_decre_wk_rec.period_name,
								g_decre_wk_rec.transaction_id,
								g_decre_wk_rec.deprn_method_code,
								g_decre_wk_rec.life,
								g_decre_wk_rec.acquisition_date,
								g_decre_wk_rec.date_placed_in_service,
								g_decre_wk_rec.decrease_units,
								g_decre_wk_rec.decrease_reason,
								g_decre_wk_rec.before_cost,
								g_decre_wk_rec.decrease_cost,
								g_decre_wk_rec.retirement_cost,
								g_decre_wk_rec.sale_cost,
								g_decre_wk_rec.after_cost
							 );

		gn_count		:= gn_count	+	1;

--- ********
--- 正常終了
--- ********
		on_retcode	:= 0;
		ov_errbuf		:= NULL;
--- ********
--- 例外処理
--- ********
	EXCEPTION
	WHEN OTHERS THEN
		ov_errbuf		:= xx01_conc_util_pkg.get_message_others
										( 'xx01_asset_decre_pkg.insert_decre_wk' );
		on_retcode	:= 2;
	END insert_decre_wk;
------------------------------------------------------------------------------
	PROCEDURE get_adjustment(	ov_errbuf						OUT	VARCHAR2,
														on_retcode					OUT	NUMBER)
	IS
/*****************************************************************************
 * PROCEDURE名	:		get_adjustment
 * 機能概要			:		変更データ取得処理
 * バージョン		:		1.0.0
 * 戻り値				:		ov_errbuf   				エラーバッファ
 * 　　　				:		on_retcode					エラーコード(成功:0,警告:1,エラー:2)
 * 注意事項			:		特に無し
 * 作成者       :
 * 作成日       :		2001-10-18
 * 変更者       :
 * 最終変更日   :		YYYY-MM-DD
 * 変更履歴     :		YYYY-MM-DD
 *								Ｎ--------------------------------------------------------Ｎ
 *								Ｎ--------------------------------------------------------Ｎ
 ****************************************************************************/
  	lv_errbuf								VARCHAR2(2000)	:= NULL;
  	ln_retcode							NUMBER(1)				:= 0;
		ln_sv_ccid							NUMBER(15)			:= 0;
		ln_sv_catid  						NUMBER(15)			:= 0;
		lb_range_flag 					BOOLEAN					:= TRUE;
		lb_write_flag 					BOOLEAN 				:= TRUE;
		lv_account_unit_code		VARCHAR2(150);
		lv_account_unit_name		VARCHAR2(240);
		lv_category							VARCHAR2(30);
		ln_life									NUMBER(3);
		ln_cr_ccid							NUMBER(15);
		lv_cr_account_unit_code	VARCHAR2(150);
--- ******************************
--- 振替対象チェック用カーソル定義
--- ******************************
	CURSOR l_cr_ccid_cur IS
		SELECT	fdh.code_combination_id
		FROM		fa_distribution_history fdh,
						fa_adjustments					faj
		WHERE		faj.transaction_header_id	=	g_adjust_rec.transaction_id
		AND			faj.source_type_code			=	gv_source_type_code_trans
		AND			faj.adjustment_type				=	gv_adjustment_type
		AND			faj.debit_credit_flag			=	'DR'
		AND			faj.distribution_id				=	fdh.distribution_id;
		l_cr_ccid_rec	l_cr_ccid_cur%rowtype;

	BEGIN
--- **************
--- 変更データ取得
--- **************
	OPEN	g_adjust_cur;
	LOOP
		lb_write_flag := TRUE;
		FETCH	g_adjust_cur	INTO	g_adjust_rec;
			EXIT	WHEN	g_adjust_cur%notfound;
--- ****************
--- ＣＣＩＤチェック
--- ****************
			IF g_adjust_rec.c_code_combination_id != ln_sv_ccid THEN
				lb_range_flag := TRUE;
				--会計単位取得
				BEGIN
					lv_account_unit_code	:=	fa_rx_flex_pkg.get_value(
																			g_control_rec.gl_application_id,
																			'GL#',
																			gn_accounting_flex_structure,
																			'GL_BALANCING',
																			g_adjust_rec.c_code_combination_id
																				);
				EXCEPTION
				WHEN OTHERS THEN
					lv_errbuf := xx01_conc_util_pkg.get_message('APP_XX01_00062');
					RAISE USER_EXPT;
				END;
				IF gv_account_unit_code_from IS NOT NULL THEN
					IF gv_account_unit_code_from > lv_account_unit_code THEN
						lb_range_flag := FALSE;
						lb_write_flag := FALSE;
					END IF;
				END IF;
				IF gv_account_unit_code_to IS NOT NULL AND
					 lb_write_flag	= TRUE	THEN
					IF gv_account_unit_code_to < lv_account_unit_code THEN
						lb_range_flag := FALSE;
						lb_write_flag := FALSE;
					END IF;
				END IF;
				--会計単位名称取得処理挿入場所
				IF lb_range_flag	= TRUE AND
					 lb_write_flag	= TRUE THEN
					BEGIN
						lv_account_unit_name := xx01_util_pkg.get_segdata(
																			g_control_rec.gl_application_id,
																			'GL#',
																			gn_accounting_flex_structure,
																			'GL_BALANCING',
																			lv_account_unit_code
																				);
					EXCEPTION
					WHEN OTHERS THEN
						lv_errbuf := xx01_conc_util_pkg.get_message('APP_XX01_00063');
						RAISE USER_EXPT;
					END;
				END IF;
				ln_sv_ccid := g_adjust_rec.c_code_combination_id;
			END IF;
--- **************************
--- 振替対象チェック
--- （貸借一致セグメント比較）
--- **************************
--
-- ************ 2010-12-29 11.5.1 M.Watanabe DEL START ************ --
--			IF g_adjust_rec.data_type_flag = gc_transfer AND
--				 lb_range_flag	= TRUE AND
--				 lb_write_flag	= TRUE THEN
--				--１資産複数割当資産については保証できません。
--				OPEN l_cr_ccid_cur;
--				FETCH	l_cr_ccid_cur	INTO	l_cr_ccid_rec;
--					EXIT	WHEN	l_cr_ccid_cur%notfound;
--				ln_cr_ccid := l_cr_ccid_rec.code_combination_id;
--				CLOSE l_cr_ccid_cur;
--				--振替前会計単位取得
--				BEGIN
--					lv_cr_account_unit_code	:=	fa_rx_flex_pkg.get_value(
--																				g_control_rec.gl_application_id,
--																				'GL#',
--																				gn_accounting_flex_structure,
--																				'GL_BALANCING',
--																				ln_cr_ccid
--																				);
--				EXCEPTION
--				WHEN OTHERS THEN
--					lv_errbuf := xx01_conc_util_pkg.get_message('APP_XX01_00064');
--					RAISE USER_EXPT;
--				END;
--				--貸借一致セグメントが同じなら対象外
--				IF lv_account_unit_code = lv_cr_account_unit_code THEN
--					lb_write_flag := FALSE;
--				END IF;
--			END IF;
-- ************ 2010-12-29 11.5.1 M.Watanabe DEL END   ************ --
--
--- **********************
--- カテゴリーＩＤチェック
--- **********************
			IF g_adjust_rec.category_id != ln_sv_catid AND
				 lb_range_flag	= TRUE AND
				 lb_write_flag	= TRUE THEN
				--主カテゴリー取得
				BEGIN
					lv_category	:=	fa_rx_flex_pkg.get_value(
														g_control_rec.fa_application_id,
														'CAT#',
														g_control_rec.category_flex_structure,
														'BASED_CATEGORY',
														g_adjust_rec.category_id
															) ;
				EXCEPTION
				WHEN OTHERS THEN
					lv_errbuf := xx01_conc_util_pkg.get_message('APP_XX01_00032');
					RAISE USER_EXPT;
				END;
				ln_sv_catid := g_adjust_rec.category_id;
			END IF;
--- ************
--- 耐用年数取得
--- ************
			IF lb_range_flag	= TRUE AND
				 lb_write_flag	= TRUE THEN
				xx01_util_pkg.get_life(lv_errbuf,
															 ln_retcode,
															 ln_life,
															 g_adjust_rec.deprn_method_code
																);
				IF ln_retcode != 0 THEN
						lv_errbuf := xx01_conc_util_pkg.get_message('APP_XX01_00065');
						RAISE USER_EXPT;
				END IF;
			END IF;
--- ****************
--- 出力ＲＯＷセット
--- ****************
			IF lb_range_flag	= TRUE AND
				 lb_write_flag	= TRUE THEN
				g_decre_wk_rec.account_unit_code 			:= lv_account_unit_code;
				g_decre_wk_rec.account_unit_name 			:= lv_account_unit_name;
				g_decre_wk_rec.category 							:= lv_category;
				g_decre_wk_rec.asset_number 					:= g_adjust_rec.asset_number;
				g_decre_wk_rec.asset_description 			:=
																					g_adjust_rec.asset_description;
				g_decre_wk_rec.period_counter 				:= g_adjust_rec.period_counter;
				g_decre_wk_rec.period_name 						:= g_adjust_rec.period_name;
				g_decre_wk_rec.transaction_id 				:= g_adjust_rec.transaction_id;
				g_decre_wk_rec.deprn_method_code 			:=
																					g_adjust_rec.deprn_method_code;
				g_decre_wk_rec.life 									:= ln_life;
				g_decre_wk_rec.acquisition_date 			:=
																					g_adjust_rec.acquisition_date;
				g_decre_wk_rec.date_placed_in_service :=
																					g_adjust_rec.placed_in_service;
				g_decre_wk_rec.decrease_units 				:= g_adjust_rec.decrease_units;
				g_decre_wk_rec.decrease_reason 				:= g_adjust_rec.decrease_reason;
				g_decre_wk_rec.before_cost 						:= g_adjust_rec.before_cost;
				g_decre_wk_rec.decrease_cost 					:= g_adjust_rec.decrease_cost;
				g_decre_wk_rec.retirement_cost 				:= g_adjust_rec.retirement_cost;
				g_decre_wk_rec.sale_cost 							:= g_adjust_rec.sale_cost;
				g_decre_wk_rec.after_cost 						:= g_adjust_rec.after_cost;
			END IF;
--- **************
--- ワークＤＢ出力
--- **************
			IF lb_range_flag	= TRUE AND
				 lb_write_flag	= TRUE THEN
				insert_decre_wk(	ln_retcode,
													lv_errbuf);
				IF ln_retcode != 0 THEN
						RAISE USER_EXPT;
				END IF;
			END IF;
	END	LOOP;
	CLOSE	g_adjust_cur;

--- ********
--- 正常終了
--- ********
		on_retcode	:= 0;
		ov_errbuf		:= NULL;
--- ********
--- 例外処理
--- ********
	EXCEPTION
	WHEN	USER_EXPT	THEN
		IF g_adjust_cur%ISOPEN THEN
			CLOSE	g_adjust_cur;
		END IF;
		IF l_cr_ccid_cur%ISOPEN THEN
			CLOSE	l_cr_ccid_cur;
		END IF;
		ov_errbuf		:= lv_errbuf;
		on_retcode	:= 2;
	WHEN OTHERS THEN
		IF g_adjust_cur%ISOPEN THEN
			CLOSE	g_adjust_cur;
		END IF;
		IF l_cr_ccid_cur%ISOPEN THEN
			CLOSE	l_cr_ccid_cur;
		END IF;
		ov_errbuf		:= xx01_conc_util_pkg.get_message_others
										( 'xx01_asset_decre_pkg.get_adjustment' );
		on_retcode	:= 2;
	END get_adjustment;
------------------------------------------------------------------------------
	PROCEDURE get_period_counter(	ov_errbuf					OUT	VARCHAR2,
																on_retcode				OUT	NUMBER,
																iv_book_type_code IN  VARCHAR2,
																iv_period_name		IN	VARCHAR2,
																on_period_counter OUT NUMBER )
	IS
/*****************************************************************************
 * PROCEDURE名	:		get_period_counter
 * 機能概要			:		会計期間取得処理
 * バージョン		:		1.0.0
 * 引数					:		iv_book_type_code		台帳
 *   						:		iv_period_name			会計期間名称
 * 戻り値				:		ov_errbuf   				エラーバッファ
 * 　　　				:		on_retcode					エラーコード(成功:0,警告:1,エラー:2)
 * 　　　				:		on_period_counter		会計期間
 * 注意事項			:		特に無し
 * 作成者       :
 * 作成日       :		2001-10-15
 * 変更者       :
 * 最終変更日   :		YYYY-MM-DD
 * 変更履歴     :		YYYY-MM-DD
 *								Ｎ--------------------------------------------------------Ｎ
 *								Ｎ--------------------------------------------------------Ｎ
 ****************************************************************************/
		lv_errbuf	VARCHAR2(2000)	:= NULL;
		ln_retcode	NUMBER(1)				:= 0;
	BEGIN
--- ************
--- 会計期間取得
--- ************
		SELECT 	period_counter
		INTO		on_period_counter
		FROM		fa_deprn_periods
		WHERE		book_type_code = iv_book_type_code
		AND			period_name = iv_period_name;
--- ********
--- 正常終了
--- ********
		on_retcode	:= 0;
		ov_errbuf		:= NULL;
--- ********
--- 例外処理
--- ********
	EXCEPTION
	WHEN OTHERS THEN
		ov_errbuf		:= xx01_conc_util_pkg.get_message_others
										( 'xx01_asset_decre_pkg.get_period_counter' );
		on_retcode	:= 2;
	END get_period_counter;
------------------------------------------------------------------------------
	PROCEDURE conv_asset_type(	ov_errbuf						OUT	VARCHAR2,
															on_retcode					OUT	NUMBER,
															ov_asset_type				OUT VARCHAR2,
															iv_asset_type_code	IN VARCHAR2 )
	IS
/*****************************************************************************
 * PROCEDURE名	:		conv_asset_type
 * 機能概要			:		資産タイプ変換処理
 * バージョン		:		1.0.0
 * 引数					:		iv_asset_type_code	資産タイプコード
 * 戻り値				:		ov_errbuf   				エラーバッファ
 * 　　　				:		on_retcode					エラーコード(成功:0,警告:1,エラー:2)
 * 　　　				:		ov_asset_type				資産タイプ
 * 注意事項			:		特に無し
 * 作成者       :
 * 作成日       :		2001-10-16
 * 変更者       :
 * 最終変更日   :		YYYY-MM-DD
 * 変更履歴     :		YYYY-MM-DD
 *								Ｎ--------------------------------------------------------Ｎ
 *								Ｎ--------------------------------------------------------Ｎ
 ****************************************************************************/
		lv_errbuf	VARCHAR2(2000)	:= NULL;
		ln_retcode	NUMBER(1)				:= 0;
	BEGIN
--- **************
--- 資産タイプ取得
--- **************
		SELECT 	meaning
		INTO		ov_asset_type
		FROM		fa_lookups_tl
		WHERE		lookup_type = 'ASSET TYPE'
		AND			lookup_code = iv_asset_type_code
		AND			language = userenv('LANG');
--- ********
--- 正常終了
--- ********
		on_retcode	:= 0;
		ov_errbuf		:= NULL;
--- ********
--- 例外処理
--- ********
	EXCEPTION
	WHEN OTHERS THEN
		ov_errbuf		:= xx01_conc_util_pkg.get_message_others
										( 'xx01_asset_decre_pkg.conv_asset_type' );
		on_retcode	:= 2;
	END conv_asset_type;
------------------------------------------------------------------------------
	PROCEDURE	main_proc(		errbuf												OUT	VARCHAR2,
													retcode												OUT	NUMBER,
													iv_book_type_code							IN	VARCHAR2,
													in_accounting_flex_structure	IN	NUMBER,		--非表示
													iv_asset_type									IN	VARCHAR2,
													iv_account_periods_from				IN	VARCHAR2,
													iv_account_periods_to					IN	VARCHAR2,
													iv_account_unit_code_from			IN	VARCHAR2,
													iv_account_unit_code_to				IN	VARCHAR2,
													in_sequence_id								IN	NUMBER	)

	IS
/*****************************************************************************
 * PROCEDURE名	:		main_proc
 * 機能概要			:		資産増減明細表（増加分）に必要なデータを抽出し、
 * 									ワークテーブルに出力します。
 * バージョン		:		1.0.0
 * 引数					:		IN	iv_book_type_code							資産台帳名
 *									IN	in_accounting_flex_structure	会計ＦＦ体系（非表示）
 *									IN	iv_asset_type									資産タイプ
 *									IN	iv_account_periods_from						自：会計期間
 *									IN	iv_account_periods_to							至：会計期間
 *									IN	iv_account_unit_code_from			自：会計単位
 *									IN	iv_account_unit_code_to				至：会計単位
 * 戻り値				:		OUT	errbuf				エラーバッファ
 *									OUT	retcode				エラーコード(成功: 0,警告: 1,エラー: 2)
 * 注意事項			:		特に無し
 * 作成者       :
 * 作成日       :		2001-10-15
 * 変更者       :
 * 最終変更日   :		YYYY-MM-DD
 * 変更履歴     :		YYYY-MM-DD
 *								Ｎ--------------------------------------------------------Ｎ
 *								Ｎ--------------------------------------------------------Ｎ
 ****************************************************************************/
--
		lv_errbuf	VARCHAR2(2000)	:= NULL;
		ln_retcode	NUMBER(1)				:= 0;
--
	BEGIN
		errbuf		:=		NULL;
		retcode		:=		0;
--- **********************
--- 起動パラメータログ出力
--- **********************
		xx01_conc_util_pkg.conc_log_line('=');
		xx01_conc_util_pkg.conc_log_param('台帳',iv_book_type_code,1);
		xx01_conc_util_pkg.conc_log_param('資産タイプ',iv_asset_type,2);
		xx01_conc_util_pkg.conc_log_param('自：会計期間'
																					,iv_account_periods_from,3);
		xx01_conc_util_pkg.conc_log_param('至：会計期間'
																					,iv_account_periods_to,4);
		xx01_conc_util_pkg.conc_log_param('自：会計単位'
																					,iv_account_unit_code_from,5);
		xx01_conc_util_pkg.conc_log_param('至：会計単位'
																					,iv_account_unit_code_TO,6);
		xx01_conc_util_pkg.conc_log_param('会計・フレックス体系'
																						,in_accounting_flex_structure,7);
		xx01_conc_util_pkg.conc_log_param('シーケンスＩＤ',in_sequence_id,8);
		xx01_conc_util_pkg.conc_log_line('=');
--- ********************
--- 起動パラメータセット
--- ********************
		gn_sequence_id								:=  in_sequence_id;
		gv_book_type_code							:=	iv_book_type_code;
		gn_accounting_flex_structure	:=	in_accounting_flex_structure;
		gv_asset_type_code						:=	iv_asset_type;
		gv_account_periods_from				:=	iv_account_periods_from;
		gv_account_periods_to					:=	iv_account_periods_to;
		gv_account_unit_code_from			:=	iv_account_unit_code_from;
		gv_account_unit_code_to				:=	iv_account_unit_code_to;
--- ********************
--- コンカレント初期処理
--- ********************
		initialize_proc(	lv_errbuf,
											ln_retcode
											);
		IF	ln_retcode != 0 THEN
				RAISE USER_EXPT;
		END IF;
--- ****************
--- 修正履歴抽出処理
--- ****************
		get_adjustment(lv_errbuf,
									 ln_retcode);
		IF	ln_retcode != 0 THEN
				RAISE USER_EXPT;
		END IF;
--- ************************
--- コンカレント終了ログ出力
--- ************************
		xx01_conc_util_pkg.conc_log_put( '抽出件数 ' || gn_count || ' 件');
		xx01_conc_util_pkg.conc_log_end(fnd_global.conc_request_id);
--- ********
--- 例外処理
--- ********
	EXCEPTION
	WHEN	USER_EXPT	THEN
				ROLLBACK;
				errbuf	:= lv_errbuf;
				retcode	:= 2;
  			xx01_conc_util_pkg.conc_log_param( 'errbuf', errbuf );
	WHEN	OTHERS	THEN
				ROLLBACK;
				errbuf	:= xx01_conc_util_pkg.get_message_others
																( 'XX01_ASSET_DECRE_PKG.MAIN_PROC' ) ;
				retcode	:= 2 ;
  			xx01_conc_util_pkg.conc_log_param( 'errbuf', errbuf );
	END	main_proc;
END;
/
