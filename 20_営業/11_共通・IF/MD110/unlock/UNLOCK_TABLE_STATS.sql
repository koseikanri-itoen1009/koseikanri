/*************************************************************************
 * 
 * VIEW Name       : UNLOCK_TABLE_STATS
 * Description     : �e�[�u�����b�N����
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2011/02/03    1.0  T.Yoshimoto    ����쐬
 ************************************************************************/
--exec dbms_stats.unlock_table_stats('table_owner','table_name'); 
-- 2011/02/03 T.Yoshimoto START
exec dbms_stats.unlock_table_stats('APPLSYS','FND_CP_GSM_OPP_AQTBL');
-- 2011/02/03 T.Yoshimoto END
