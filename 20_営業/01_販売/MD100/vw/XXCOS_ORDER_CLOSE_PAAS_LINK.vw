/*************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 * 
 * View Name       : xxcos_order_close_paas_link
 * Description     : �A�h�I���󒍃N���[�Y�r���[
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------   -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- ------------   -------------------------------------
 *  2024/01/17    1.0   S.Kato         ST�s�No.0066�Ή��B�V�K�쐬
 *  2024/01/22    1.1   T.Nishikawa    ST�s�No.0043�Ή�
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_order_close_paas_link
AS
  SELECT
      xoc.order_line_id
    , ooha.global_attribute6        AS order_number
    , oola.global_attribute8        AS order_line_number
    , xoc.created_by
    , xoc.creation_date
    , xoc.last_updated_by
    , xoc.last_update_date
    , xoc.last_update_login
    , xoc.request_id
    , xoc.program_application_id
    , xoc.program_id
    , xoc.program_update_date
  FROM
      xxcos_order_close                                    xoc     -- �󒍃N���[�Y�Ώۏ��
    , oe_order_lines_all                                   oola    -- �󒍖���
    , oe_order_headers_all                                 ooha    -- �󒍃w�b�_
    , oicuser.xxccd_if_process_mng@ebs_paas3.itoen.master  xipm    -- �A�g�����Ǘ��e�[�u���iebs�󒍔ԍ���paas�捞�j
  WHERE 
        oola.line_id      =  xoc.order_line_id
  AND   ooha.header_id    =  oola.header_id
  AND   xipm.function_id  =  'XXCOS005A21C'
-- Ver1.1 Mod Start
--  AND   xoc.creation_date >= xipm.pre_process_date
  AND   xoc.creation_date >= xipm.pre_process_date - 2/24
-- Ver1.1 Mod End
  ;
