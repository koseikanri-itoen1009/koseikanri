create or replace PACKAGE xxccp_svfcommon_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxccp_svfcommon_pkg(spec)
 * Description            :
 * MD.070                 : MD070_IPO_CCP_���ʊ֐�
 * Version                : 1.0
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  submit_svf_request        P           SVF���[���ʊ֐�(SVF�R���J�����g�̋N��)
 *  no_data_msg               F    CHAR   SVF���[���ʊ֐�(0���o�̓��b�Z�[�W)
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008-11-11    1.0  Yuuki.Nakamura   �V�K�쐬
 *  2009-03-23    1.1  Shinya.Kayahara  �ŏI�s�ɃX���b�V���ǉ�
 *****************************************************************************************/
--
  -- ===============================
  -- PUBLIC PROCEDURE
  -- ===============================
  --
  --SVF���[���ʊ֐�(SVF�R���J�����g�̋N��)
  PROCEDURE submit_svf_request(ov_retcode      OUT VARCHAR2               --���^�[���R�[�h
                              ,ov_errbuf       OUT VARCHAR2               --�G���[���b�Z�[�W
                              ,ov_errmsg       OUT VARCHAR2               --���[�U�[�E�G���[���b�Z�[�W
                              ,iv_conc_name    IN  VARCHAR2               --�R���J�����g��
                              ,iv_file_name    IN  VARCHAR2               --�o�̓t�@�C����
                              ,iv_file_id      IN  VARCHAR2               --���[ID
                              ,iv_output_mode  IN  VARCHAR2  DEFAULT 1    --�o�͋敪
                              ,iv_frm_file     IN  VARCHAR2               --�t�H�[���l���t�@�C����
                              ,iv_vrq_file     IN  VARCHAR2               --�N�G���[�l���t�@�C����
                              ,iv_org_id       IN  VARCHAR2               --ORG_ID
                              ,iv_user_name    IN  VARCHAR2               --���O�C���E���[�U��
                              ,iv_resp_name    IN  VARCHAR2               --���O�C���E���[�U�̐E�Ӗ�
                              ,iv_doc_name     IN  VARCHAR2  DEFAULT NULL --������
                              ,iv_printer_name IN  VARCHAR2  DEFAULT NULL --�v�����^��
                              ,iv_request_id   IN  VARCHAR2               --�v��ID
                              ,iv_nodata_msg   IN  VARCHAR2               --�f�[�^�Ȃ����b�Z�[�W
                              ,iv_svf_param1   IN  VARCHAR2  DEFAULT NULL --svf�σp�����[�^1
                              ,iv_svf_param2   IN  VARCHAR2  DEFAULT NULL --svf�σp�����[�^2
                              ,iv_svf_param3   IN  VARCHAR2  DEFAULT NULL --svf�σp�����[�^3
                              ,iv_svf_param4   IN  VARCHAR2  DEFAULT NULL --svf�σp�����[�^4
                              ,iv_svf_param5   IN  VARCHAR2  DEFAULT NULL --svf�σp�����[�^5
                              ,iv_svf_param6   IN  VARCHAR2  DEFAULT NULL --svf�σp�����[�^6
                              ,iv_svf_param7   IN  VARCHAR2  DEFAULT NULL --svf�σp�����[�^7
                              ,iv_svf_param8   IN  VARCHAR2  DEFAULT NULL --svf�σp�����[�^8
                              ,iv_svf_param9   IN  VARCHAR2  DEFAULT NULL --svf�σp�����[�^9
                              ,iv_svf_param10  IN  VARCHAR2  DEFAULT NULL --svf�σp�����[�^10
                              ,iv_svf_param11  IN  VARCHAR2  DEFAULT NULL --svf�σp�����[�^11
                              ,iv_svf_param12  IN  VARCHAR2  DEFAULT NULL --svf�σp�����[�^12
                              ,iv_svf_param13  IN  VARCHAR2  DEFAULT NULL --svf�σp�����[�^13
                              ,iv_svf_param14  IN  VARCHAR2  DEFAULT NULL --svf�σp�����[�^14
                              ,iv_svf_param15  IN  VARCHAR2  DEFAULT NULL --svf�σp�����[�^15
                              );
--
  -- ===============================
  -- PUBLIC FUNCTION
  -- ===============================
  --
  --SVF���[���ʊ֐�(0���o�̓��b�Z�[�W)
  FUNCTION no_data_msg
    RETURN VARCHAR2;
  --
END xxccp_svfcommon_pkg;
/
