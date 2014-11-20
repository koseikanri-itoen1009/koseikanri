CREATE OR REPLACE PACKAGE xxccp_ifcommon_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxccp_ifcommon_pkg(spec)
 * Description            : 
 * MD.070                 : MD070_IPO_CCP_���ʊ֐�
 * Version                : 1.0
 *
 * Program List
 *  --------------------      ---- -----   --------------------------------------------------
 *   Name                     Type  Ret     Description
 *  --------------------      ---- -----   --------------------------------------------------
 *  add_edi_header_footer     P     VAR    EDI�w�b�_�E�t�b�^�t�^
 *  add_chohyo_header_footer  P     VAR    ���[�w�b�_�E�t�b�^�t�^
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008-10-16    1.0  Naoki.Watanabe   �V�K�쐬
 *  2008-10-21    1.0  Naoki.Watanabe   �ǉ��쐬
 *****************************************************************************************/
--
  --EDI�w�b�_�E�t�b�^�t�^
  PROCEDURE add_edi_header_footer(iv_add_area       IN VARCHAR2  --�t�^�敪
                                 ,iv_from_series    IN VARCHAR2  --�h�e���Ɩ��n��R�[�h
                                 ,iv_base_code      IN VARCHAR2  --���_�R�[�h
                                 ,iv_base_name      IN VARCHAR2  --���_����
                                 ,iv_chain_code     IN VARCHAR2  --�`�F�[���X�R�[�h
                                 ,iv_chain_name     IN VARCHAR2  --�`�F�[���X����
                                 ,iv_data_kind      IN VARCHAR2  --�f�[�^��R�[�h
                                 ,iv_row_number     IN VARCHAR2  --���񏈗��ԍ�
                                 ,in_num_of_records IN NUMBER    --���R�[�h����
                                 ,ov_retcode        OUT VARCHAR2 --���^�[���R�[�h
                                 ,ov_output         OUT VARCHAR2 --�o�͒l
                                 ,ov_errbuf         OUT VARCHAR2 --�G���[���b�Z�[�W
                                 ,ov_errmsg         OUT VARCHAR2 --���[�U�[�E�G���[���b�Z�[�W
                                 );
  --
  --���[�w�b�_�E�t�b�^�t�^
  PROCEDURE add_chohyo_header_footer(iv_add_area       IN VARCHAR2  --�t�^�敪
                                    ,iv_from_series    IN VARCHAR2  --�h�e���Ɩ��n��R�[�h
                                    ,iv_base_code      IN VARCHAR2  --���_�R�[�h
                                    ,iv_base_name      IN VARCHAR2  --���_����
                                    ,iv_chain_code     IN VARCHAR2  --�`�F�[���X�R�[�h
                                    ,iv_chain_name     IN VARCHAR2  --�`�F�[���X����
                                    ,iv_data_kind      IN VARCHAR2  --�f�[�^��R�[�h
                                    ,iv_chohyo_code    IN VARCHAR2  --���[�R�[�h
                                    ,iv_chohyo_name    IN VARCHAR2  --���[�\����
                                    ,in_num_of_item    IN NUMBER    --���ڐ�
                                    ,in_num_of_records IN NUMBER    --�f�[�^����
                                    ,ov_retcode        OUT VARCHAR2 --���^�[���R�[�h
                                    ,ov_output         OUT VARCHAR2 --�o�͒l
                                    ,ov_errbuf         OUT VARCHAR2 --�G���[���b�Z�[�W
                                    ,ov_errmsg         OUT VARCHAR2 --���[�U�[�E�G���[���b�Z�[�W
                                    );
  --
END xxccp_ifcommon_pkg;
/
