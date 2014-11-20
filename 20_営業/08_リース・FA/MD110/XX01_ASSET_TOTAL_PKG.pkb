create or replace
PACKAGE BODY      XX01_ASSET_TOTAL_PKG
/*****************************************************************************
 * $ Header: XX01_ASSET_TOTAL_PKG.pkb 11.5.1 0.0.0.0 2010/12/20 $
 * 成果物の全ての知的財産権は弊社に帰属します。
 * 成果物の使用、複製、改変・翻案は、日本オラクル社との契約に記された制約条件に従うものとします。
 * ORACLEはOracle Corporationの登録商標です。
 * Copyright (c) 2001 Oracle Corporation Japan All Rights Reserved
 * パッケージ名 :		XX01_ASSET_TOTAL_PKG
 * 機能概要     :		資産増減総括表出力ワークテーブル作成
 * バージョン   :		11.5.1
 * 作成者       :
 * 作成日       :		2001-10-31
 * 変更者       :
 * 最終変更日   :		2010-12-20
 * 変更履歴     :
 * ------------- -------- ------------- -------------------------------------
 *  Date          Ver.     Editor        Description
 * ------------- -------- ------------- -------------------------------------
 *  2010-12-20    11.5.1   SCS 渡辺      [E_本稼動_05184]
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
		gv_book_type_code							fa_books.book_type_code%type;		--資産台帳名
		gv_asset_type_code						VARCHAR2(80);			--資産タイプコード
		gv_account_periods_from				VARCHAR2(15);			--自：会計期間名称
		gv_account_periods_to					VARCHAR2(15);			--至：会計期間名称
		gv_account_unit_code_from			VARCHAR2(150);		--自：会計単位
		gv_account_unit_code_to				VARCHAR2(150);		--至：会計単位

		gn_period_counter_before			NUMBER(15);				--前：会計期間
		gd_period_date_before					DATE;							--前：ＣＬＯＳＥ日時
		gn_period_counter_from				NUMBER(15);				--自：会計期間
		gd_period_date_from						DATE;							--自：ＣＬＯＳＥ日時
		gn_period_counter_to					NUMBER(15);				--至：会計期間
		gd_period_date_to							DATE;							--至：ＣＬＯＳＥ日時
		gv_asset_type									VARCHAR2(80);			--資産タイプ
		gn_accounting_flex_structure	NUMBER(15);				--会計単位取得情報

		gv_adjustment_type_cost				VARCHAR2(15);
		gv_adjustment_type_resrv			VARCHAR2(15);
		gv_source_type_code_add				VARCHAR2(15);
		gv_source_type_code_adjust		VARCHAR2(15);
		gv_source_type_code_trans			VARCHAR2(15);
		gv_source_type_code_retire		VARCHAR2(15);

		USER_EXPT											EXCEPTION;				--例外処理

--- ****************
--- コンスタント定義
--- ****************
		--行種別
		gc_units				CONSTANT NUMBER(1) := 1;
		gc_cost					CONSTANT NUMBER(1) := 2;
		gc_resrv				CONSTANT NUMBER(1) := 3;
		gc_deprn				CONSTANT NUMBER(1) := 4;
		gc_net_book			CONSTANT NUMBER(1) := 5;

		--列種別
		gc_begin				CONSTANT NUMBER(1) := 1;
		gc_add					CONSTANT NUMBER(1) := 2;
		gc_trans_incre	CONSTANT NUMBER(1) := 3;
		gc_adjust_incre	CONSTANT NUMBER(1) := 4;
		gc_trans_decre	CONSTANT NUMBER(1) := 5;
		gc_adjust_decre	CONSTANT NUMBER(1) := 6;
		gc_retire				CONSTANT NUMBER(1) := 7;
		gc_end					CONSTANT NUMBER(1) := 8;
		gc_change				CONSTANT NUMBER(1) := 9;
		--建設仮勘定から資産計上用資産タイプ
		gc_change_source_type	CONSTANT VARCHAR2(8) := 'ADDITION';
		gc_change_asset_type	CONSTANT VARCHAR2(11) := 'CAPITALIZED';
--- ****************
--- システム管理情報
--- ****************
		g_control_rec			fa_system_controls%rowtype;

--- **************
--- 出力ＲＯＷ定義
--- **************
		g_total_wk_rec		xx01_asset_total_wk%rowtype;
--
-- ************ 2010-12-20 11.5.1 M.Watanabe ADD START ************ --
    g_total_wk_category_id  fa_categories.category_id%type;
    g_total_wk_deprn_ccid   fa_distribution_history.code_combination_id%type;
-- ************ 2010-12-20 11.5.1 M.Watanabe ADD END   ************ --
--
--- ****************
--- 出力件数カウンタ
--- ****************
		gn_count	NUMBER(38,0)		:=	0;

--- **************
--- 修正履歴を抽出
--- **************
		CURSOR		g_all_asset_cur IS
			--- ************
			--- カーソル定義
			--- ************
			--- 行種別
			--- 列種別
			--- ＣＣＩＤ（会計単位取得時使用）
			--- カテゴリーＩＤ（主カテゴリー取得時使用）
			--- 資産ＩＤ
			--- トランザクションＩＤ（期末残高取得時は不要）
			--- 金額もしくは数量
			--- **********************
			--- 取得価額前期末残高取得
			--- **********************
			SELECT	gc_cost										row_type,
							gc_begin									column_type,
							fdh.code_combination_id		c_code_combination_id,
							fah.category_id						c_category_id,
							fdh.asset_id							c_asset_id,
							0													c_transaction_id,
							fdd.cost									c_asset_values
			FROM		fa_distribution_history 	fdh,
							fa_asset_history 					fah,
							fa_deprn_detail						fdd
			WHERE		fdh.book_type_code			=	gv_book_type_code
			AND			gd_period_date_before		BETWEEN	fdh.date_effective
																		AND		NVL(fdh.date_ineffective,SYSDATE)
			AND			fdd.asset_id						=	fdh.asset_id
			AND			fdd.book_type_code			= gv_book_type_code
			AND			fdd.distribution_id			= fdh.distribution_id
			AND			fdd.period_counter 			<= gn_period_counter_before
			AND			fdd.period_counter			=
							(SELECT	MAX(fdd1.period_counter)
								FROM	fa_deprn_detail	fdd1
								WHERE	fdd1.book_type_code		= gv_book_type_code
								AND		fdd1.distribution_id	=	fdh.distribution_id
								AND		fdd1.period_counter		<= gn_period_counter_before)
			AND			fah.asset_id						=	fdh.asset_id
			AND			gd_period_date_before		BETWEEN fah.date_effective
																		AND		NVL(fah.date_ineffective, SYSDATE)
			AND			fah.asset_type					=	gv_asset_type_code
			--- **********************
			--- 償却累計前期末残高取得
			--- **********************
			UNION ALL
			SELECT	gc_resrv									row_type,
							gc_begin									column_type,
							fdh.code_combination_id		c_code_combination_id,
							fah.category_id						c_category_id,
							fdh.asset_id							c_asset_id,
							0													c_transaction_id,
							fdd.deprn_reserve					c_asset_values
			FROM		fa_distribution_history 	fdh,
							fa_asset_history 					fah,
							fa_deprn_detail						fdd
			WHERE		fdh.book_type_code			=	gv_book_type_code
			AND			gd_period_date_before		BETWEEN	fdh.date_effective
																		AND		NVL(fdh.date_ineffective,SYSDATE)
			AND			fdd.asset_id						=	fdh.asset_id
			AND			fdd.book_type_code			= gv_book_type_code
			AND			fdd.distribution_id			= fdh.distribution_id
			AND			fdd.period_counter 			<= gn_period_counter_before
			AND			fdd.period_counter			=
							(SELECT	MAX(fdd1.period_counter)
								FROM	fa_deprn_detail	fdd1
								WHERE	fdd1.book_type_code		= gv_book_type_code
								AND		fdd1.distribution_id	=	fdh.distribution_id
								AND		fdd1.period_counter		<= gn_period_counter_before)
			AND			fah.asset_id						=	fdh.asset_id
			AND			gd_period_date_before		BETWEEN fah.date_effective
																		AND		NVL(fah.date_ineffective, SYSDATE)
			AND			fah.asset_type					=	gv_asset_type_code
			--- **********************
			--- 取得価額当期末残高取得
			--- **********************
			UNION ALL
			SELECT	gc_cost										row_type,
							gc_end										column_type,
							fdh.code_combination_id		c_code_combination_id,
							fah.category_id						c_category_id,
							fdh.asset_id							c_asset_id,
							0													c_transaction_id,
							fdd.cost									c_asset_values
			FROM		fa_distribution_history 	fdh,
							fa_asset_history 					fah,
							fa_deprn_detail						fdd
			WHERE		fdh.book_type_code			=	gv_book_type_code
			AND			gd_period_date_to				BETWEEN	fdh.date_effective
																		AND		NVL(fdh.date_ineffective,SYSDATE)
			AND			fdd.asset_id						=	fdh.asset_id
			AND			fdd.book_type_code			= gv_book_type_code
			AND			fdd.distribution_id			= fdh.distribution_id
			AND			fdd.period_counter 			<= gn_period_counter_to
			AND			fdd.period_counter			=
							(SELECT	MAX(fdd1.period_counter)
								FROM	fa_deprn_detail	fdd1
								WHERE	fdd1.book_type_code		= gv_book_type_code
								AND		fdd1.distribution_id	=	fdh.distribution_id
								AND		fdd1.period_counter		<= gn_period_counter_to)
			AND			fah.asset_id						=	fdh.asset_id
			AND			gd_period_date_to				BETWEEN fah.date_effective
																		AND		NVL(fah.date_ineffective, SYSDATE)
			AND			fah.asset_type					=	gv_asset_type_code
			--- **********************
			--- 償却累計当期末残高取得
			--- **********************
			UNION ALL
			SELECT	gc_resrv									row_type,
							gc_end										column_type,
							fdh.code_combination_id		c_code_combination_id,
							fah.category_id						c_category_id,
							fdh.asset_id							c_asset_id,
							0													c_transaction_id,
							fdd.deprn_reserve					c_asset_values
			FROM		fa_distribution_history 	fdh,
							fa_asset_history 					fah,
							fa_deprn_detail						fdd
			WHERE		fdh.book_type_code			=	gv_book_type_code
			AND			gd_period_date_to				BETWEEN	fdh.date_effective
																		AND		NVL(fdh.date_ineffective,SYSDATE)
			AND			fdd.asset_id						=	fdh.asset_id
			AND			fdd.book_type_code			= gv_book_type_code
			AND			fdd.distribution_id			= fdh.distribution_id
			AND			fdd.period_counter 			<= gn_period_counter_to
			AND			fdd.period_counter			=
							(SELECT	MAX(fdd1.period_counter)
								FROM	fa_deprn_detail	fdd1
								WHERE	fdd1.book_type_code		= gv_book_type_code
								AND		fdd1.distribution_id	=	fdh.distribution_id
								AND		fdd1.period_counter		<= gn_period_counter_to)
			AND			fah.asset_id						=	fdh.asset_id
			AND			gd_period_date_to				BETWEEN fah.date_effective
																		AND		NVL(fah.date_ineffective, SYSDATE)
			AND			fah.asset_type					=	gv_asset_type_code
			--- **********************
			--- 期間内新規取得取得価額
			--- **********************
			UNION ALL
			SELECT	gc_cost										row_type,
							gc_add										column_type,
							fdh.code_combination_id		c_code_combination_id,
							fah.category_id						c_category_id,
							faj.asset_id							c_asset_id,
							faj.transaction_header_id	c_transaction_id,
							faj.adjustment_amount			c_asset_values
			FROM		fa_distribution_history 	fdh,
							fa_asset_history 					fah,
							fa_adjustments						faj
			WHERE		faj.book_type_code						=	gv_book_type_code
			AND			faj.period_counter_created		BETWEEN gn_period_counter_from
		 																						AND gn_period_counter_to
			AND		 	faj.source_type_code					=	gv_source_type_code_add
			AND			faj.adjustment_type						=	gv_adjustment_type_cost
			AND			faj.debit_credit_flag					=	'DR'
			AND			fdh.distribution_id						=	faj.distribution_id
			AND			fah.asset_id									=	faj.asset_id
			AND			fah.transaction_header_id_in 	=
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= faj.asset_id
								AND		fah2.transaction_header_id_in
										<= faj.transaction_header_id)
			AND			fah.asset_type								=	gv_asset_type_code
			--- ********************************************
			--- 期間内新規取得償却累計額
			--- （新規取得時に既に償却累計が入っている場合）
			--- ********************************************
			UNION ALL
			SELECT	gc_resrv									row_type,
							gc_add										column_type,
							fdh.code_combination_id		c_code_combination_id,
							fah.category_id						c_category_id,
							fdh.asset_id							c_asset_id,
							fdh.transaction_header_id_in	c_transaction_id,
							fdd.deprn_reserve					c_asset_values
			FROM		fa_deprn_detail						fdd,
							fa_distribution_history 	fdh,
							fa_asset_history 					fah
			WHERE		fdd.book_type_code						=	gv_book_type_code
			AND			fdd.period_counter		BETWEEN gn_period_counter_before
		 																		AND gn_period_counter_to - 1
			AND		 	fdd.deprn_source_code					=	'B'
			AND		 (fdd.deprn_reserve							> 0
							OR
							fdd.deprn_reserve							< 0)
			AND			fdh.distribution_id						=	fdd.distribution_id
			AND			fah.asset_id									=	fdd.asset_id
			AND			fah.transaction_header_id_in 	=
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= fdh.asset_id
								AND		fah2.transaction_header_id_in
										<= fdh.transaction_header_id_in)
			AND			fah.asset_type								=	gv_asset_type_code
			--- **********
			--- 期間内修正
			--- **********
			UNION ALL
			SELECT	DECODE(faj.adjustment_type,
											gv_adjustment_type_cost,gc_cost,
														gc_resrv)		row_type,
							DECODE(faj.adjustment_type,
											gv_adjustment_type_cost,
								DECODE(faj.debit_credit_flag,'DR',
														gc_adjust_incre,
														gc_adjust_decre),
								DECODE(faj.debit_credit_flag,'CR',
														gc_adjust_incre,
														gc_adjust_decre))	column_type,
							fdh.code_combination_id		c_code_combination_id,
							fah.category_id						c_category_id,
							faj.asset_id							c_asset_id,
							faj.transaction_header_id	c_transaction_id,
							faj.adjustment_amount			c_asset_values
			FROM		fa_distribution_history 	fdh,
							fa_asset_history 					fah,
							fa_adjustments						faj
			WHERE		faj.book_type_code						=	gv_book_type_code
			AND			faj.period_counter_created		BETWEEN gn_period_counter_from
		 																						AND gn_period_counter_to
			AND			faj.source_type_code					=	gv_source_type_code_adjust
			AND		 (faj.adjustment_type						=	gv_adjustment_type_cost
							OR
							faj.adjustment_type						=	gv_adjustment_type_resrv)
			AND			fdh.distribution_id						=	faj.distribution_id
			AND			fah.asset_id									=	faj.asset_id
			AND			fah.transaction_header_id_in 	=
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= faj.asset_id
								AND		fah2.transaction_header_id_in
										<= faj.transaction_header_id)
			AND			fah.asset_type								=	gv_asset_type_code
			--- **********
			--- 期間内振替
			--- **********
			UNION ALL
			SELECT	DECODE(faj.adjustment_type,
											gv_adjustment_type_cost,gc_cost,
														gc_resrv)		row_type,
							DECODE(faj.adjustment_type,
											gv_adjustment_type_cost,
								DECODE(faj.debit_credit_flag,'DR',
													gc_trans_incre,
													gc_trans_decre),
								DECODE(faj.debit_credit_flag,'CR',
													gc_trans_incre,
													gc_trans_decre))	column_type,
							fdh.code_combination_id		c_code_combination_id,
							fah.category_id						c_category_id,
							faj.asset_id							c_asset_id,
							faj.transaction_header_id	c_transaction_id,
							faj.adjustment_amount			c_asset_values
			FROM		fa_distribution_history 	fdh,
							fa_asset_history 					fah,
							fa_adjustments						faj
			WHERE		faj.book_type_code						=	gv_book_type_code
			AND			faj.period_counter_created		BETWEEN gn_period_counter_from
		 																						AND gn_period_counter_to
			AND			faj.source_type_code					=	gv_source_type_code_trans
			AND		 (faj.adjustment_type						=	gv_adjustment_type_cost
							OR
							faj.adjustment_type						=	gv_adjustment_type_resrv)
			AND			fdh.distribution_id						=	faj.distribution_id
			AND			fah.asset_id									=	faj.asset_id
			AND			fah.transaction_header_id_in 	=
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= faj.asset_id
								AND		fah2.transaction_header_id_in
										<= faj.transaction_header_id)
			AND			fah.asset_type								=	gv_asset_type_code
			--- ************
			--- 期間内除売却
			--- ************
			UNION ALL
			SELECT	DECODE(faj.adjustment_type,
											gv_adjustment_type_cost,gc_cost,
														gc_resrv)		row_type,
							gc_retire									column_type,
							fdh.code_combination_id		c_code_combination_id,
							fah.category_id						c_category_id,
							faj.asset_id							c_asset_id,
							faj.transaction_header_id	c_transaction_id,
							DECODE(faj.adjustment_type,gv_adjustment_type_cost,
								DECODE(faj.debit_credit_flag,'CR',
											 faj.adjustment_amount,
											 faj.adjustment_amount * -1),
								DECODE(faj.debit_credit_flag,'DR',
											 faj.adjustment_amount,
											 faj.adjustment_amount * -1))	c_asset_values
			FROM		fa_distribution_history 	fdh,
							fa_asset_history 					fah,
							fa_adjustments						faj
			WHERE		faj.book_type_code						=	gv_book_type_code
			AND			faj.period_counter_created		BETWEEN gn_period_counter_from
		 																						AND gn_period_counter_to
			AND			faj.source_type_code					=	gv_source_type_code_retire
			AND		 (faj.adjustment_type						=	gv_adjustment_type_cost
							OR
							faj.adjustment_type						=	gv_adjustment_type_resrv)
			AND			fdh.distribution_id						=	faj.distribution_id
			AND			fah.asset_id									=	faj.asset_id
			AND			fah.transaction_header_id_in 	=
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= faj.asset_id
								AND		fah2.transaction_header_id_in
										<= faj.transaction_header_id)
			AND			fah.asset_type								=	gv_asset_type_code
			--- **********************
			--- 建設仮勘定から資産計上
			--- **********************
			UNION ALL
			SELECT	gc_cost										row_type,
							gc_change									column_type,
							fdh.code_combination_id		c_code_combination_id,
							fah.category_id						c_category_id,
							faj.asset_id							c_asset_id,
							faj.transaction_header_id	c_transaction_id,
							faj.adjustment_amount			c_asset_values
			FROM		fa_distribution_history fdh,
							fa_asset_history 				fah,
							fa_adjustments					faj
			WHERE		faj.book_type_code					=	gv_book_type_code
			AND			faj.period_counter_created	BETWEEN gn_period_counter_from
		 																					AND gn_period_counter_to
			AND			faj.source_type_code				=	gc_change_source_type
			AND			faj.adjustment_type					=	gv_adjustment_type_cost
			AND			faj.debit_credit_flag				=	'CR'
			AND			faj.asset_id								=	fah.asset_id
			AND			fah.transaction_header_id_in =
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= faj.asset_id
								AND		fah2.transaction_header_id_in
										<= faj.transaction_header_id)
			AND			faj.distribution_id					=	fdh.distribution_id
			AND 		fah.asset_type							=	gc_change_asset_type
			--- ******************
			--- 期間内新規取得数量
			--- ******************
			UNION ALL
			SELECT	gc_units									row_type,
							gc_add										column_type,
							fdh.code_combination_id		c_code_combination_id,
							fah.category_id						c_category_id,
							faj.asset_id							c_asset_id,
							faj.transaction_header_id	c_transaction_id,
							fdh.units_assigned				c_asset_values
			FROM		fa_distribution_history 	fdh,
							fa_asset_history 					fah,
							fa_adjustments						faj
			WHERE		faj.book_type_code						=	gv_book_type_code
			AND			faj.period_counter_created		BETWEEN gn_period_counter_from
		 																						AND gn_period_counter_to
			AND		 	faj.source_type_code					=	gv_source_type_code_add
			AND		  faj.adjustment_type						=	gv_adjustment_type_cost
			AND			faj.debit_credit_flag					=	'DR'
			AND			fdh.distribution_id						=	faj.distribution_id
			AND			fah.asset_id									=	faj.asset_id
			AND			fah.transaction_header_id_in 	=
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= faj.asset_id
								AND		fah2.transaction_header_id_in
										<= faj.transaction_header_id)
			AND			fah.asset_type								=	gv_asset_type_code
			--- **************
			--- 期間内振替数量
			--- **************
			UNION ALL
			SELECT	gc_units									row_type,
							DECODE(faj.debit_credit_flag,'DR',
													gc_trans_incre,
													gc_trans_decre)		column_type,
							fdh.code_combination_id		c_code_combination_id,
							fah.category_id						c_category_id,
							faj.asset_id							c_asset_id,
							faj.transaction_header_id	c_transaction_id,
							fdh.units_assigned				c_asset_values
			FROM		fa_distribution_history 	fdh,
							fa_asset_history 					fah,
							fa_adjustments						faj
			WHERE		faj.book_type_code						=	gv_book_type_code
			AND			faj.period_counter_created		BETWEEN gn_period_counter_from
		 																						AND gn_period_counter_to
			AND			faj.source_type_code					=	gv_source_type_code_trans
			AND		  faj.adjustment_type						=	gv_adjustment_type_cost
			AND			fdh.distribution_id						=	faj.distribution_id
			AND			fah.asset_id									=	faj.asset_id
			AND			fah.transaction_header_id_in 	=
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= faj.asset_id
								AND		fah2.transaction_header_id_in
										<= faj.transaction_header_id)
			AND			fah.asset_type								=	gv_asset_type_code
			--- ****************
			--- 期間内除売却数量
			--- ****************
			UNION ALL
			SELECT	gc_units									row_type,
							gc_retire									column_type,
							fdh.code_combination_id		c_code_combination_id,
							fah.category_id						c_category_id,
							faj.asset_id							c_asset_id,
							faj.transaction_header_id	c_transaction_id,
							NVL(frt.units,0)					c_asset_values
			FROM		fa_distribution_history 	fdh,
							fa_asset_history 					fah,
							fa_retirements						frt,
							fa_adjustments						faj
			WHERE		faj.book_type_code						=	gv_book_type_code
			AND			faj.period_counter_created		BETWEEN gn_period_counter_from
		 																						AND gn_period_counter_to
			AND			faj.source_type_code					=	gv_source_type_code_retire
			AND		 	faj.adjustment_type						=	gv_adjustment_type_cost
			AND			faj.debit_credit_flag					=	'CR'
			AND			fdh.distribution_id						=	faj.distribution_id
			AND			fah.asset_id									=	faj.asset_id
			AND			fah.transaction_header_id_in 	=
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= faj.asset_id
								AND		fah2.transaction_header_id_in
										<= faj.transaction_header_id)
			AND			fah.asset_type								=	gv_asset_type_code
			AND			frt.asset_id									=	faj.asset_id
			AND			frt.transaction_header_id_in	=	faj.transaction_header_id
			--- ****************
			--- 期間内再稼動数量
			--- ****************
			UNION ALL
			SELECT	gc_units									row_type,
							gc_retire									column_type,
							fdh.code_combination_id		c_code_combination_id,
							fah.category_id						c_category_id,
							faj.asset_id							c_asset_id,
							faj.transaction_header_id	c_transaction_id,
							NVL((-1 * frt.units),0)		c_asset_values
			FROM		fa_distribution_history 	fdh,
							fa_asset_history 					fah,
							fa_retirements						frt,
							fa_adjustments						faj
			WHERE		faj.book_type_code						=	gv_book_type_code
			AND			faj.period_counter_created		BETWEEN gn_period_counter_from
		 																						AND gn_period_counter_to
			AND			faj.source_type_code					=	gv_source_type_code_retire
			AND		 	faj.adjustment_type						=	gv_adjustment_type_cost
			AND			faj.debit_credit_flag					=	'DR'
			AND			fdh.distribution_id						=	faj.distribution_id
			AND			fah.asset_id									=	faj.asset_id
			AND			fah.transaction_header_id_in 	=
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= faj.asset_id
								AND		fah2.transaction_header_id_in
										<= faj.transaction_header_id)
			AND			fah.asset_type								=	gv_asset_type_code
			AND			frt.asset_id									=	faj.asset_id
			AND			frt.transaction_header_id_out	=	faj.transaction_header_id
			--- **************************
			--- 建設仮勘定から資産計上数量
			--- **************************
			UNION ALL
			SELECT	gc_units									row_type,
							gc_change									column_type,
							fdh.code_combination_id		c_code_combination_id,
							fah.category_id						c_category_id,
							faj.asset_id							c_asset_id,
							faj.transaction_header_id	c_transaction_id,
							fdh.units_assigned				c_asset_values
			FROM		fa_distribution_history 	fdh,
							fa_asset_history 					fah,
							fa_adjustments						faj
			WHERE		faj.book_type_code						=	gv_book_type_code
			AND			faj.period_counter_created		BETWEEN gn_period_counter_from
		 																						AND gn_period_counter_to
			AND		 	faj.source_type_code					=	gc_change_source_type
			AND		  faj.adjustment_type						=	gv_adjustment_type_cost
			AND			faj.debit_credit_flag					=	'CR'
			AND			fdh.distribution_id						=	faj.distribution_id
			AND			fah.asset_id									=	faj.asset_id
			AND			fah.transaction_header_id_in 	=
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= faj.asset_id
								AND		fah2.transaction_header_id_in
										<= faj.transaction_header_id)
			AND			fah.asset_type								=	gc_change_asset_type
			--- ****************
			--- 償却費期間内累計
			--- ****************
			UNION ALL
		 (SELECT	gc_deprn									row_type,
							gc_end										column_type,
							fdh.code_combination_id		c_code_combination_id,
							fah.category_id						c_category_id,
							fdh.asset_id							c_asset_id,
							0													c_transaction_id,
							SUM(fdd.deprn_amount)			c_asset_values
			FROM		fa_distribution_history 	fdh,
							fa_asset_history 					fah,
							fa_deprn_detail						fdd
			WHERE		fdd.period_counter			BETWEEN gn_period_counter_from
																			AND			gn_period_counter_to
			AND			fdd.book_type_code			= gv_book_type_code
			AND		 	fdd.deprn_source_code		=	'D'
			AND			fdh.asset_id						=	fdd.asset_id
			AND			fdh.distribution_id			= fdd.distribution_id
			AND			fdh.book_type_code			=	gv_book_type_code
			AND			fah.asset_id						=	fdd.asset_id
			AND			fah.transaction_header_id_in 	=
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= fdd.asset_id
								AND		fah2.transaction_header_id_in
										<= fdh.transaction_header_id_in)
			AND			fah.asset_type					=	gv_asset_type_code
			AND			gv_asset_type_code		 !=	'CIP'
			GROUP BY gc_deprn,gc_end,fdh.code_combination_id
							,fah.category_id,fdh.asset_id)
			ORDER BY c_code_combination_id,c_category_id,c_asset_id
			;
		g_all_asset_rec	g_all_asset_cur%rowtype;
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
 * 作成日       :		2001-11-07
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
  	xx01_conc_util_pkg.conc_log_put( '資産増減明細表（総括表）抽出ログ' );
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
		gn_period_counter_before := gn_period_counter_from - 1;
--- ****************
--- クローズ日時取得
--- ****************
		get_period_date(lv_errbuf,
									  ln_retcode,
										gv_book_type_code,
										gn_period_counter_before,
                    gd_period_date_before);
		IF ln_retcode != 0 THEN
				RAISE USER_EXPT;
		END IF;
		get_period_date(lv_errbuf,
									  ln_retcode,
										gv_book_type_code,
										gn_period_counter_from,
                    gd_period_date_from);
		IF ln_retcode != 0 THEN
				RAISE USER_EXPT;
		END IF;
		get_period_date(lv_errbuf,
									  ln_retcode,
										gv_book_type_code,
										gn_period_counter_to,
                    gd_period_date_to);
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
			gv_adjustment_type_cost			:= 'CIP COST';
			gv_adjustment_type_resrv		:= 'CIP RESERVE';	--発生しないはずだが念の為
			gv_source_type_code_add 		:= 'CIP ADDITION';
			gv_source_type_code_retire 	:= 'CIP RETIREMENT';
			gv_source_type_code_adjust 	:= 'CIP ADJUSTMENT';
		ELSE
			gv_adjustment_type_cost			:= 'COST';
			gv_adjustment_type_resrv		:= 'RESERVE';
			gv_source_type_code_add 		:= 'ADDITION';
			gv_source_type_code_retire 	:= 'RETIREMENT';
			gv_source_type_code_adjust 	:= 'ADJUSTMENT';
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
									( 'xx01_asset_total_pkg.initialize' ) ;
		on_retcode	:= 2;
	END initialize_proc;
------------------------------------------------------------------------------
	PROCEDURE set_wk(	ov_errbuf					OUT	VARCHAR2,
										on_retcode				OUT	NUMBER)
	IS
/*****************************************************************************
 * PROCEDURE名	:		set_wk
 * 機能概要			:		出力ワーク格納処理
 * バージョン		:		1.0.0
 * 戻り値				:		ov_errbuf   				エラーバッファ
 * 　　　				:		on_retcode					エラーコード(成功:0,警告:1,エラー:2)
 * 注意事項			:		特に無し
 * 作成者       :
 * 作成日       :		2001-11-07
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
--- 出力ワーク格納
--- **************
		IF g_all_asset_rec.row_type	=	gc_cost THEN
			IF g_all_asset_rec.column_type = gc_begin THEN
				g_total_wk_rec.bring_balance_cost :=
				g_total_wk_rec.bring_balance_cost + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_end THEN
				g_total_wk_rec.carry_balance_cost :=
				g_total_wk_rec.carry_balance_cost + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_add THEN
				g_total_wk_rec.addition_cost :=
				g_total_wk_rec.addition_cost + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_trans_incre THEN
				g_total_wk_rec.incre_transfer_cost :=
				g_total_wk_rec.incre_transfer_cost + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_trans_decre THEN
				g_total_wk_rec.decre_transfer_cost :=
				g_total_wk_rec.decre_transfer_cost + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_change THEN
				g_total_wk_rec.decre_transfer_cost :=
				g_total_wk_rec.decre_transfer_cost + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_adjust_incre THEN
				g_total_wk_rec.incre_transfer_cost :=
				g_total_wk_rec.incre_transfer_cost + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_adjust_decre THEN
				g_total_wk_rec.decre_transfer_cost :=
				g_total_wk_rec.decre_transfer_cost + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_retire THEN
				g_total_wk_rec.retirement_cost :=
				g_total_wk_rec.retirement_cost + g_all_asset_rec.c_asset_values;
			END IF;
		ELSIF g_all_asset_rec.row_type = gc_resrv THEN
			IF g_all_asset_rec.column_type = gc_begin THEN
				g_total_wk_rec.bring_balance_resrv :=
				g_total_wk_rec.bring_balance_resrv + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_end THEN
				g_total_wk_rec.carry_balance_resrv :=
				g_total_wk_rec.carry_balance_resrv + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_add THEN
				g_total_wk_rec.addition_resrv :=
				g_total_wk_rec.addition_resrv + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_trans_incre THEN
				g_total_wk_rec.incre_transfer_resrv :=
				g_total_wk_rec.incre_transfer_resrv + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_trans_decre THEN
				g_total_wk_rec.decre_transfer_resrv :=
				g_total_wk_rec.decre_transfer_resrv + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_adjust_incre THEN
				g_total_wk_rec.incre_transfer_resrv :=
				g_total_wk_rec.incre_transfer_resrv + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_adjust_decre THEN
				g_total_wk_rec.decre_transfer_resrv :=
				g_total_wk_rec.decre_transfer_resrv + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_retire THEN
				g_total_wk_rec.retirement_resrv :=
				g_total_wk_rec.retirement_resrv + g_all_asset_rec.c_asset_values;
			END IF;
		ELSIF g_all_asset_rec.row_type = gc_units THEN
			IF g_all_asset_rec.column_type = gc_add THEN
				g_total_wk_rec.addition_units :=
				g_total_wk_rec.addition_units + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_trans_incre THEN
				g_total_wk_rec.incre_transfer_units :=
				g_total_wk_rec.incre_transfer_units + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_trans_decre THEN
				g_total_wk_rec.decre_transfer_units :=
				g_total_wk_rec.decre_transfer_units + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_change THEN
				g_total_wk_rec.decre_transfer_units :=
				g_total_wk_rec.decre_transfer_units + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_adjust_incre THEN
				g_total_wk_rec.incre_transfer_units :=
				g_total_wk_rec.incre_transfer_units + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_adjust_decre THEN
				g_total_wk_rec.decre_transfer_units :=
				g_total_wk_rec.decre_transfer_units + g_all_asset_rec.c_asset_values;
			ELSIF g_all_asset_rec.column_type = gc_retire THEN
				g_total_wk_rec.retirement_units :=
				g_total_wk_rec.retirement_units + g_all_asset_rec.c_asset_values;
			END IF;
		ELSIF g_all_asset_rec.row_type = gc_deprn THEN
				g_total_wk_rec.deprn_reserve := g_all_asset_rec.c_asset_values;
		END IF;
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
										( 'xx01_asset_total_pkg.set_wk' );
		on_retcode	:= 2;
	END set_wk;
------------------------------------------------------------------------------
	PROCEDURE insert_total_wk(	ov_errbuf					OUT	VARCHAR2,
															on_retcode				OUT	NUMBER)
	IS
/*****************************************************************************
 * PROCEDURE名	:		insert_total_wk
 * 機能概要			:		ワークＤＢ出力処理
 * バージョン		:		1.0.0
 * 戻り値				:		ov_errbuf   				エラーバッファ
 * 　　　				:		on_retcode					エラーコード(成功:0,警告:1,エラー:2)
 * 注意事項			:		特に無し
 * 作成者       :
 * 作成日       :		2001-11-07
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
--- 帳簿価額計算
--- ************
		g_total_wk_rec.bring_balance_net :=
			g_total_wk_rec.bring_balance_cost - g_total_wk_rec.bring_balance_resrv;
		g_total_wk_rec.addition_net :=
			g_total_wk_rec.addition_cost - g_total_wk_rec.addition_resrv;
		g_total_wk_rec.incre_transfer_net :=
			g_total_wk_rec.incre_transfer_cost
			 - g_total_wk_rec.incre_transfer_resrv;
		g_total_wk_rec.decre_transfer_net :=
			g_total_wk_rec.decre_transfer_cost
			 - g_total_wk_rec.decre_transfer_resrv;
		g_total_wk_rec.retirement_net :=
			g_total_wk_rec.retirement_cost - g_total_wk_rec.retirement_resrv;
		g_total_wk_rec.carry_balance_net :=
			g_total_wk_rec.carry_balance_cost - g_total_wk_rec.carry_balance_resrv;
--- **************
--- ワークＤＢ出力
--- **************
		INSERT INTO xx01_asset_total_wk(
								asset_total_wk_id,
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
								asset_id,
								addition_units,
								incre_transfer_units,
								decre_transfer_units,
								retirement_units,
								bring_balance_cost,
								addition_cost,
								incre_transfer_cost,
								decre_transfer_cost,
								retirement_cost,
								carry_balance_cost,
								bring_balance_resrv,
								addition_resrv,
								incre_transfer_resrv,
								decre_transfer_resrv,
								retirement_resrv,
								carry_balance_resrv,
								deprn_reserve,
								bring_balance_net,
								addition_net,
								incre_transfer_net,
								decre_transfer_net,
								retirement_net,
								carry_balance_net)
				VALUES
							 (
								xx01_asset_total_wk_s.nextval,
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
								g_total_wk_rec.account_unit_code,
								g_total_wk_rec.account_unit_name,
								g_total_wk_rec.category,
								g_total_wk_rec.asset_id,
								g_total_wk_rec.addition_units,
								g_total_wk_rec.incre_transfer_units,
								g_total_wk_rec.decre_transfer_units,
								g_total_wk_rec.retirement_units,
								g_total_wk_rec.bring_balance_cost,
								g_total_wk_rec.addition_cost,
								g_total_wk_rec.incre_transfer_cost,
								g_total_wk_rec.decre_transfer_cost,
								g_total_wk_rec.retirement_cost,
								g_total_wk_rec.carry_balance_cost,
								g_total_wk_rec.bring_balance_resrv,
								g_total_wk_rec.addition_resrv,
								g_total_wk_rec.incre_transfer_resrv,
								g_total_wk_rec.decre_transfer_resrv,
								g_total_wk_rec.retirement_resrv,
								g_total_wk_rec.carry_balance_resrv,
								g_total_wk_rec.deprn_reserve,
								g_total_wk_rec.bring_balance_net,
								g_total_wk_rec.addition_net,
								g_total_wk_rec.incre_transfer_net,
								g_total_wk_rec.decre_transfer_net,
								g_total_wk_rec.retirement_net,
								g_total_wk_rec.carry_balance_net
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
										( 'xx01_asset_total_pkg.insert_total_wk' );
		on_retcode	:= 2;
	END insert_total_wk;

------------------------------------------------------------------------------
	PROCEDURE get_asset_total(	ov_errbuf						OUT	VARCHAR2,
															on_retcode					OUT	NUMBER)
	IS
/*****************************************************************************
 * PROCEDURE名	:		get_asset_total
 * 機能概要			:		総括データ取得処理
 * バージョン		:		1.0.0
 * 戻り値				:		ov_errbuf   				エラーバッファ
 * 　　　				:		on_retcode					エラーコード(成功:0,警告:1,エラー:2)
 * 注意事項			:		特に無し
 * 作成者       :
 * 作成日       :		2001-11-07
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
		WHERE		faj.transaction_header_id	=	g_all_asset_rec.c_transaction_id
		AND			faj.source_type_code	=	gv_source_type_code_trans
		AND			faj.adjustment_type		=	DECODE(g_all_asset_rec.row_type,
																				gc_resrv,gv_adjustment_type_resrv,
																								 gv_adjustment_type_cost)
		AND			faj.debit_credit_flag	=	DECODE(g_all_asset_rec.row_type,
																							gc_resrv,
																			DECODE(g_all_asset_rec.column_type,
																							gc_trans_incre,'DR','CR'),
																			DECODE(g_all_asset_rec.column_type,
																							gc_trans_incre,'CR','DR'))
		AND			faj.distribution_id		=	fdh.distribution_id;
		l_cr_ccid_rec	l_cr_ccid_cur%rowtype;

	BEGIN
--- **************
--- 変更データ取得
--- **************
	OPEN	g_all_asset_cur;
	LOOP
		lb_write_flag := TRUE;
		FETCH	g_all_asset_cur	INTO	g_all_asset_rec;
			EXIT	WHEN	g_all_asset_cur%notfound;
--- ****************
--- ＣＣＩＤチェック
--- ****************
			IF g_all_asset_rec.c_code_combination_id != ln_sv_ccid THEN
				lb_range_flag := TRUE;
				--会計単位取得
				BEGIN
					lv_account_unit_code	:=	fa_rx_flex_pkg.get_value(
																			g_control_rec.gl_application_id,
																			'GL#',
																			gn_accounting_flex_structure,
																			'GL_BALANCING',
																			g_all_asset_rec.c_code_combination_id
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
				--会計単位名称取得処理
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
				ln_sv_ccid := g_all_asset_rec.c_code_combination_id;
			END IF;
--- **************************
--- 振替対象チェック
--- （貸借一致セグメント比較）
--- **************************
--
-- ************ 2010-12-20 11.5.1 M.Watanabe DEL START ************ --
--			IF (g_all_asset_rec.column_type = gc_trans_incre OR
--					g_all_asset_rec.column_type = gc_trans_decre) AND
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
-- ************ 2010-12-20 11.5.1 M.Watanabe DEL END   ************ --
--
--- **********************
--- カテゴリーＩＤチェック
--- **********************
			IF g_all_asset_rec.c_category_id != ln_sv_catid AND
				 lb_range_flag	= TRUE AND
				 lb_write_flag	= TRUE THEN
				--主カテゴリー取得
				BEGIN
					lv_category	:=	fa_rx_flex_pkg.get_value(
														g_control_rec.fa_application_id,
														'CAT#',
														g_control_rec.category_flex_structure,
														'BASED_CATEGORY',
														g_all_asset_rec.c_category_id
															) ;
				EXCEPTION
				WHEN OTHERS THEN
					lv_errbuf := xx01_conc_util_pkg.get_message('APP_XX01_00032');
					RAISE USER_EXPT;
				END;
				ln_sv_catid := g_all_asset_rec.c_category_id;
			END IF;
--- ****************
--- 出力ＲＯＷセット
--- ****************
			IF lb_range_flag	= TRUE AND
				 lb_write_flag	= TRUE THEN
				IF g_total_wk_rec.asset_id IS NULL THEN
					--- ****************
					--- 出力ワーククリア
					--- ****************
					g_total_wk_rec.account_unit_code 			:= lv_account_unit_code;
					g_total_wk_rec.account_unit_name 			:= lv_account_unit_name;
					g_total_wk_rec.category 							:= lv_category;
					g_total_wk_rec.asset_id 							:= g_all_asset_rec.c_asset_id;
					g_total_wk_rec.addition_units 				:= 0;
					g_total_wk_rec.incre_transfer_units		:= 0;
					g_total_wk_rec.decre_transfer_units		:= 0;
					g_total_wk_rec.retirement_units				:= 0;
					g_total_wk_rec.bring_balance_cost			:= 0;
					g_total_wk_rec.addition_cost	 				:= 0;
					g_total_wk_rec.incre_transfer_cost		:= 0;
					g_total_wk_rec.decre_transfer_cost		:= 0;
					g_total_wk_rec.retirement_cost				:= 0;
					g_total_wk_rec.carry_balance_cost			:= 0;
					g_total_wk_rec.bring_balance_resrv		:= 0;
					g_total_wk_rec.addition_resrv	 				:= 0;
					g_total_wk_rec.incre_transfer_resrv		:= 0;
					g_total_wk_rec.decre_transfer_resrv		:= 0;
					g_total_wk_rec.retirement_resrv				:= 0;
					g_total_wk_rec.carry_balance_resrv		:= 0;
					g_total_wk_rec.deprn_reserve					:= 0;
-- ************ 2010-12-20 11.5.1 M.Watanabe ADD START ************ --
          g_total_wk_category_id                := g_all_asset_rec.c_category_id;
          g_total_wk_deprn_ccid                 := g_all_asset_rec.c_code_combination_id;
-- ************ 2010-12-20 11.5.1 M.Watanabe ADD END   ************ --
					--- ******************
					--- 初回出力ワーク格納
					--- ******************
					set_wk(	ln_retcode,lv_errbuf);
					IF ln_retcode != 0 THEN
							RAISE USER_EXPT;
					END IF;
-- ************ 2010-12-20 11.5.1 M.Watanabe MOD START ************ --
--				ELSIF g_total_wk_rec.account_unit_code	=	lv_account_unit_code AND
--					 g_total_wk_rec.category					= lv_category AND
          ELSIF g_all_asset_rec.c_code_combination_id = g_total_wk_deprn_ccid   AND
                g_all_asset_rec.c_category_id         = g_total_wk_category_id  AND
-- ************ 2010-12-20 11.5.1 M.Watanabe MOD END   ************ --
					 g_total_wk_rec.asset_id					= g_all_asset_rec.c_asset_id THEN
					--- **************
					--- 出力ワーク格納
					--- **************
					set_wk(	ln_retcode,lv_errbuf);
					IF ln_retcode != 0 THEN
							RAISE USER_EXPT;
					END IF;
				ELSE
					--- **************
					--- ワークＤＢ出力
					--- **************
					insert_total_wk(	ln_retcode,
														lv_errbuf);
					IF ln_retcode != 0 THEN
							RAISE USER_EXPT;
					END IF;
					--- ****************
					--- 出力ワーククリア
					--- ****************
					g_total_wk_rec.account_unit_code 			:= lv_account_unit_code;
					g_total_wk_rec.account_unit_name 			:= lv_account_unit_name;
					g_total_wk_rec.category 							:= lv_category;
					g_total_wk_rec.asset_id 							:= g_all_asset_rec.c_asset_id;
					g_total_wk_rec.addition_units 				:= 0;
					g_total_wk_rec.incre_transfer_units		:= 0;
					g_total_wk_rec.decre_transfer_units		:= 0;
					g_total_wk_rec.retirement_units				:= 0;
					g_total_wk_rec.bring_balance_cost			:= 0;
					g_total_wk_rec.addition_cost	 				:= 0;
					g_total_wk_rec.incre_transfer_cost		:= 0;
					g_total_wk_rec.decre_transfer_cost		:= 0;
					g_total_wk_rec.retirement_cost				:= 0;
					g_total_wk_rec.carry_balance_cost			:= 0;
					g_total_wk_rec.bring_balance_resrv		:= 0;
					g_total_wk_rec.addition_resrv	 				:= 0;
					g_total_wk_rec.incre_transfer_resrv		:= 0;
					g_total_wk_rec.decre_transfer_resrv		:= 0;
					g_total_wk_rec.retirement_resrv				:= 0;
					g_total_wk_rec.carry_balance_resrv		:= 0;
					g_total_wk_rec.deprn_reserve					:= 0;
-- ************ 2010-12-20 11.5.1 M.Watanabe ADD START ************ --
          g_total_wk_category_id                := g_all_asset_rec.c_category_id;
          g_total_wk_deprn_ccid                 := g_all_asset_rec.c_code_combination_id;
-- ************ 2010-12-20 11.5.1 M.Watanabe ADD END   ************ --
					--- **************
					--- 出力ワーク格納
					--- **************
					set_wk(	ln_retcode,lv_errbuf);
					IF ln_retcode != 0 THEN
							RAISE USER_EXPT;
					END IF;
				END IF;
			END IF;

	END	LOOP;
	--- ********************
	--- ワークＤＢ最終行出力
	--- ********************
	IF gn_count != 0 THEN
		insert_total_wk(	ln_retcode,
											lv_errbuf);
		IF ln_retcode != 0 THEN
				RAISE USER_EXPT;
		END IF;
	END IF;

	CLOSE	g_all_asset_cur;

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
		IF g_all_asset_cur%ISOPEN THEN
			CLOSE	g_all_asset_cur;
		END IF;
		IF l_cr_ccid_cur%ISOPEN THEN
			CLOSE	l_cr_ccid_cur;
		END IF;
		ov_errbuf		:= lv_errbuf;
		on_retcode	:= 2;
	WHEN OTHERS THEN
		IF g_all_asset_cur%ISOPEN THEN
			CLOSE	g_all_asset_cur;
		END IF;
		IF l_cr_ccid_cur%ISOPEN THEN
			CLOSE	l_cr_ccid_cur;
		END IF;
		ov_errbuf		:= xx01_conc_util_pkg.get_message_others
										( 'xx01_asset_decre_pkg.get_asset_total' );
		on_retcode	:= 2;
	END get_asset_total;
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
										( 'xx01_asset_total_pkg.get_period_counter' );
		on_retcode	:= 2;
	END get_period_counter;
------------------------------------------------------------------------------
	PROCEDURE get_period_date(	ov_errbuf					OUT	VARCHAR2,
															on_retcode				OUT	NUMBER,
															iv_book_type_code IN  VARCHAR2,
															in_period_counter	IN	NUMBER,
															od_period_date 		OUT DATE )
	IS
/*****************************************************************************
 * PROCEDURE名	:		get_period_date
 * 機能概要			:		会計期間クローズ日時取得処理
 * バージョン		:		1.0.0
 * 引数					:		iv_book_type_code		台帳
 *   						:		in_period_counter		会計期間
 * 戻り値				:		ov_errbuf   				エラーバッファ
 * 　　　				:		on_retcode					エラーコード(成功:0,警告:1,エラー:2)
 * 　　　				:		od_period_date			会計期間クローズ日時
 * 注意事項			:		特に無し
 * 作成者       :
 * 作成日       :		2001-11-08
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
		SELECT 	period_close_date
		INTO		od_period_date
		FROM		fa_deprn_periods
		WHERE		book_type_code = iv_book_type_code
		AND			period_counter = in_period_counter;
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
										( 'xx01_asset_total_pkg.get_period_date' );
		on_retcode	:= 2;
	END get_period_date;
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
										( 'xx01_asset_incre_pkg.conv_asset_type' );
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
 * 機能概要			:		資産増減明細表（総括表）に必要なデータを抽出し、
 * 									ワークテーブルに出力します。
 * バージョン		:		1.0.0
 * 引数					:		IN	iv_book_type_code							資産台帳名
 *									IN	in_accounting_flex_structure	会計ＦＦ体系（非表示）
 *									IN	iv_asset_type									資産タイプ
 *									IN	iv_account_periods_from				自：会計期間
 *									IN	iv_account_periods_to					至：会計期間
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
		get_asset_total(lv_errbuf,
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
																( 'XX01_ASSET_TOTAL_PKG.MAIN_PROC' ) ;
				retcode	:= 2 ;
  			xx01_conc_util_pkg.conc_log_param( 'errbuf', errbuf );
	END	main_proc;
END;
/
