CREATE OR REPLACE PACKAGE BODY apps.xxccp_oiccommon_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name           : xxccp_oiccommon_pkg(body)
 * Description            : 
 * MD.070                 : MD070_IPO_CCP_���ʊ֐�
 * Version                : 1.2
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
 *  2022-11-07    1.0  Ryo.Kikuchi      �V�K�쐬
 *  2023-02-07    1.1  Y.Ooyama         �ڍs��QNo.11�Ή�
 *  2023-02-21    1.2  F.Hasebe         �ڍs��QNo.29�Ή�
 *****************************************************************************************/
--
  -- ===============================
  -- �O���[�o���萔
  -- ===============================
  cv_pkg_name CONSTANT VARCHAR2(50) := 'XXCCP_OICCOMMON_PKG';
  cv_period   CONSTANT VARCHAR2(1)  := '.';
  cv_msg_part CONSTANT VARCHAR2(3)  := ' : ';
--
  /**********************************************************************************
   * Function Name    : to_csv_string
   * Description      : CSV�t�@�C���p������ϊ�
   ***********************************************************************************/
  FUNCTION to_csv_string(
              iv_string       IN VARCHAR2                   -- �Ώە�����
             ,iv_lf_replace   IN VARCHAR2 DEFAULT NULL      -- LF�u���P��
           )
    RETURN VARCHAR2
  IS
  --
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'to_csv_string';
    lv_changed_string   VARCHAR2(3000);           -- �ϊ��㕶����(�߂�l)
  --
  BEGIN
    -- �ϊ��㕶�����������
    lv_changed_string := iv_string;
--
    -- ���ׂĂ�LF���s�R�[�h�uCHR(10)�v��IN�p�����[�^�uLF�u���P��v�ɒu��
    lv_changed_string := REPLACE( lv_changed_string , CHR(10) , iv_lf_replace );
--
-- Ver 1.2 Add Start
    -- ���ׂĂ�CR���s�R�[�h�uCHAR(13)�v��IN�p�����[�^�uLF�u���P��v�ɒu��
    lv_changed_string := REPLACE( lv_changed_string , CHR(13) , iv_lf_replace );
--
-- Ver 1.2 Add End
    -- ���ׂẴ_�u���N�H�[�g�u"�v��A���l�u""�v�ɒu��
    lv_changed_string := REPLACE( lv_changed_string , '"' , '""' );
--
    -- �擪�Ɩ����Ƀ_�u���N�H�[�g�u"�v��ǉ������l��߂�
    RETURN ('"' || lv_changed_string || '"');
    --
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END to_csv_string;
--
--
-- Ver1.1 Add Start
  /**********************************************************************************
   * Function Name    : trim_space_tab
   * Description      : ������̑O�㔼�p�X�y�[�X/�^�u�폜
   ***********************************************************************************/
  FUNCTION trim_space_tab(
              iv_string       IN VARCHAR2                   -- �Ώە�����
           )
    RETURN VARCHAR2
  IS
  --
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'trim_space_tab';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_changed_string   VARCHAR2(3000);           -- �ϊ��㕶����(�߂�l)
    ln_length           NUMBER;
  --
  BEGIN
    -- NULL�̏ꍇ��NULL��ԋp
    IF (iv_string IS NULL) THEN
      RETURN NULL;
    END IF;
    --
    -- �ϊ��㕶�����������
    lv_changed_string := iv_string;
    --
    -- ������̒������擾
    ln_length := LENGTH(lv_changed_string);
    --
    FOR i IN 1..ln_length LOOP
      -- ������̑O��ɔ��p�X�y�[�X�A�^�u�����݂��邩�m�F
      IF ( REGEXP_LIKE(lv_changed_string, '^' || ' ') OR 
           REGEXP_LIKE(lv_changed_string, ' ' || '$') OR
           REGEXP_LIKE(lv_changed_string, '^' || CHR(9)) OR
           REGEXP_LIKE(lv_changed_string, CHR(9) || '$') ) THEN
        --
        -- ���p�X�y�[�X�A�^�u�����݂���ꍇ
        -- ������̑O��̔��p�X�y�[�X�A�^�u���폜
        lv_changed_string := REGEXP_REPLACE(lv_changed_string, '^' || ' ', NULL);
        lv_changed_string := REGEXP_REPLACE(lv_changed_string, ' ' || '$', NULL);
        lv_changed_string := REGEXP_REPLACE(lv_changed_string, '^' || CHR(9), NULL);
        lv_changed_string := REGEXP_REPLACE(lv_changed_string, CHR(9) || '$', NULL);
      ELSE
        -- ���p�X�y�[�X�A�^�u�����݂��Ȃ��ꍇ
        EXIT;
      END IF;
    END LOOP;
    --
    RETURN lv_changed_string;
    --
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END trim_space_tab;
  --
-- Ver1.1 Add End
--
END xxccp_oiccommon_pkg;
/
