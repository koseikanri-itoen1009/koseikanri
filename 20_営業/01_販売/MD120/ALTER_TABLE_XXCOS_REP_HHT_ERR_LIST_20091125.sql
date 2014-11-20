ALTER TABLE xxcos.xxcos_rep_hht_err_list  ADD ( output_flag VARCHAR2(1) );

COMMENT ON COLUMN xxcos.xxcos_rep_hht_err_list.output_flag         IS 'エラー帳票出力済フラグ';