CREATE OR REPLACE PACKAGE apps.xxccp_oiccommon_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name           : xxccp_oiccommon_pkg(spec)
 * Description            : 
 * MD.070                 : MD070_IPO_CCP_���ʊ֐�
 * Version                : 1.1
 *
 * Program List
 *  --------------------      ---- -----   --------------------------------------------------
 *   Name                     Type  Ret     Description
 *  --------------------      ---- -----   --------------------------------------------------
 *  to_csv_string             F     VAR     CSV�t�@�C���p������ϊ�
 *  trim_space_tab            F     VAR     ������̑O�㔼�p�X�y�[�X/�^�u�폜
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2022-10-21    1.0  Ryo.Kikuchi      �V�K�쐬
 *  2023-02-07    1.1  Y.Ooyama         �ڍs��QNo.11�Ή�
 *****************************************************************************************/
--
  -- CSV�t�@�C���p������ϊ�
  FUNCTION to_csv_string(
              iv_string       IN VARCHAR2                   -- �Ώە�����
             ,iv_lf_replace   IN VARCHAR2 DEFAULT NULL      -- LF�u���P��
           )
    RETURN VARCHAR2;
  --
-- Ver1.1 Add Start
  -- ������̑O�㔼�p�X�y�[�X/�^�u�폜
  FUNCTION trim_space_tab(
              iv_string       IN VARCHAR2                   -- �Ώە�����
           )
    RETURN VARCHAR2;
-- Ver1.1 Add End
  --
END xxccp_oiccommon_pkg;
/
