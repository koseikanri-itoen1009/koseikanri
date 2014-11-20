CREATE OR REPLACE PACKAGE BODY xxccp_ifcommon_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxccp_ifcommon_pkg(body)
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
 *  2009-02-10    1.1  Shinya.Kayahara  ���t�t�H�[�}�b�g�C��
 *****************************************************************************************/
--  
  /**********************************************************************************
   * Procedure Name   : add_edi_header_footer
   * Description      : EDI�w�b�_�E�t�b�^�t�^
   ***********************************************************************************/
  PROCEDURE add_edi_header_footer(iv_add_area       IN VARCHAR2  --�t�^�敪
                                 ,iv_from_series    IN VARCHAR2  --IF���Ɩ��n��R�[�h
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
                                 )
  IS
  --
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxccp_ifcommon_pkg.add_edi_header_footer';
    -- ================                                                           -- �v���O������
    -- ���[�J���ϐ���`
    -- ================
    lv_out_put         VARCHAR2(1000);                          --�o�͒l�i�[�p�ϐ�
    ln_length_val      NUMBER := LENGTH(in_num_of_records) - 7; --��8�����o�͂���ۂɎg�p����ϐ�
    lv_error_parameter VARCHAR2(1000);                          --�g�[�N���p�ϐ�
    -- ================
    -- ���[�U�[��`��O
    -- ================
    in_parameter_expt   EXCEPTION; --�K�{���ڂ�NULL�̏ꍇ
    parameter_over_expt EXCEPTION; --IN�p�����[�^���w�茅���𒴂���ꍇ
    add_area_expt       EXCEPTION; --�t�^�敪��'H'�ł�'F'�ł�NULL�ł��Ȃ��ꍇ
  --
  BEGIN
    --
    --�t�^�敪��NULL�`�F�b�N
    IF (iv_add_area IS NULL) THEN
      lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_ADD_AREA');
      RAISE in_parameter_expt;
    END IF;
    --�t�^�敪��'H'�̏ꍇ
    IF (iv_add_area = 'H') THEN
      --�K�{���ڂ�NULL�`�F�b�N
      IF (iv_from_series  IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_FROM_SERIES');
        RAISE in_parameter_expt;
      ELSIF (iv_base_code  IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_BASE_CODE');
        RAISE in_parameter_expt;
      ELSIF (iv_base_name  IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_BASE_NAME');
        RAISE in_parameter_expt;
      ELSIF (iv_chain_code IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_CHAIN_CODE');
        RAISE in_parameter_expt;
      ELSIF (iv_chain_name IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_CHAIN_NAME');
        RAISE in_parameter_expt;
      ELSIF (iv_data_kind  IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_DATA_KIND');
        RAISE in_parameter_expt;
      ELSIF (iv_row_number IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_ROW_NUMBER');
        RAISE in_parameter_expt;
      ELSIF (LENGTHB(iv_from_series) > 2) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_FROM_SERIES');
        RAISE parameter_over_expt;
      ELSIF (LENGTHB(iv_base_code) > 4) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_BASE_CODE');
        RAISE parameter_over_expt;
      ELSIF (LENGTHB(iv_base_name) > 40) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_BASE_NAME');
        RAISE parameter_over_expt;
      ELSIF (LENGTHB(iv_chain_code) > 4) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_CHAIN_CODE');
        RAISE parameter_over_expt;
      ELSIF (LENGTHB(iv_chain_name) > 40) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_CHAIN_NAME');
        RAISE parameter_over_expt;
      ELSIF (LENGTHB(iv_data_kind) > 2) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_DATA_KIND');
        RAISE parameter_over_expt;
      ELSIF (LENGTHB(iv_row_number) > 2) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_ROW_NUMBER');
        RAISE parameter_over_expt;
      END IF;
      --
      --�o�͒l��ϐ��Ɋi�[
      lv_out_put := FND_PROFILE.VALUE('XXCCP1_IF_HEADER')                    --���R�[�h�敪:H
                 || RPAD(iv_from_series,2,' ')                               --IF���Ɩ��n��R�[�h
                 || FND_PROFILE.VALUE('XXCCP1_IF_TO_EDI_SERIES') --IF��Ɩ��n��R�[�h
                 || RPAD(iv_base_code,4,' ')                     --���_(����)�R�[�h
                 || RPAD(iv_base_name,40,' ')                    --���_��
                 || RPAD(iv_chain_code,4,' ')                    --�`�F�[���X�R�[�h
                 || RPAD(iv_chain_name,40,' ')                   --�`�F�[���X��
                 || RPAD(iv_data_kind,2,' ')                     --�f�[�^��R�[�h
                 || iv_row_number                                --���񏈗��ԍ�
                 || TO_CHAR(SYSDATE,'YYYYMMDD')                  --�f�[�^�쐬��
--20090210 �C��_���� start--
--                 || TO_CHAR(SYSDATE,'HHMMSS')                    --�f�[�^�쐬����
                 || TO_CHAR(SYSDATE,'HH24MISS')                  --�f�[�^�쐬����
--20090210 �C��_���� end--
                 ;
      --
    --�t�^�敪��'F'�̏ꍇ
    ELSIF (iv_add_area = 'F') THEN
      --
      --�f�[�^������NULL�`�F�b�N
      IF (in_num_of_records IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_NUM_OF_RECORDS');
        RAISE in_parameter_expt;
      END IF;
      --
      --�o�͒l��ϐ��Ɋi�[
      --�f�[�^������8���ȉ��̏ꍇ
      IF (LENGTH(in_num_of_records) <= 8) THEN
        --8���ɑ����Ċi�[
        lv_out_put := FND_PROFILE.VALUE('XXCCP1_IF_FOOTER')     --���R�[�h�敪:F
                   || LPAD(in_num_of_records,8,'0')            --�f�[�^����
                   ;
      --�f�[�^������8�����傫���ꍇ
      ELSIF (LENGTH(in_num_of_records) > 8) THEN
        --��8�����i�[
        lv_out_put := FND_PROFILE.VALUE('XXCCP1_IF_FOOTER')     --���R�[�h�敪:F
                   || SUBSTR(in_num_of_records,ln_length_val)  --�f�[�^����
                   ;
      END IF;
      --
    ELSE
      RAISE add_area_expt;
    END IF;
    --
    --����I����
    ov_retcode := xxccp_common_pkg.set_status_normal;
    ov_output  := lv_out_put; --�A�E�g�p�����[�^�ɏo�͒l���i�[
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    --
  EXCEPTION
    --�K�{���ڂ�NULL�̏ꍇ
    WHEN in_parameter_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_output  := NULL;
      ov_errbuf  := cv_prg_name;
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application => 'XXCCP'
                      ,iv_name        => 'APP-XXCCP1-10004'
                      ,iv_token_name1  => 'ITEM'
                      ,iv_token_value1 => lv_error_parameter
                    );
    --IN�p�����[�^���w�茅���𒴂��Ă���ꍇ
    WHEN parameter_over_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_output  := NULL;
      ov_errbuf  := cv_prg_name;
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => 'XXCCP'
                      ,iv_name         => 'APP-XXCCP1-10006'
                      ,iv_token_name1  => 'ITEM'
                      ,iv_token_value1 => lv_error_parameter
                    );
    --�t�^�敪��'H'�A'F'�ANULL�̂�����ł��Ȃ��ꍇ
    WHEN add_area_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_output  := NULL; --�A�E�g�p�����[�^�ɏo�͒l���i�[
      ov_errbuf  := cv_prg_name;
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application => 'XXCCP'
                      ,iv_name        => 'APP-XXCCP1-10005'
                    );
    --�ُ�I����
    WHEN OTHERS THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_output  := NULL;
      ov_errbuf  := SUBSTRB(cv_prg_name||SQLERRM,1,5000);
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application => 'XXCCP'
                      ,iv_name        => 'APP-XXCCP1-10003'
                    );
    --
  END add_edi_header_footer;
  --
--
  /**********************************************************************************
   * Procedure Name   : add_chohyo_header_footer
   * Description      : ���[�w�b�_�E�t�b�^�t�^
   ***********************************************************************************/
  PROCEDURE add_chohyo_header_footer(iv_add_area       IN VARCHAR2  --�t�^�敪
                                    ,iv_from_series    IN VARCHAR2  --IF���Ɩ��n��R�[�h
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
                                    )
  IS
  --
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxccp_ifcommon_pkg.add_chohyo_header_footer';
    cv_knot_str   CONSTANT VARCHAR2(1)   := '"';                                     -- �v���O������
    cv_dlim_str   CONSTANT VARCHAR2(1)   := ',';
    -- ================
    -- ���[�J���ϐ���`
    -- ================
    lv_out_put         VARCHAR2(1000);                          --�o�͒l�i�[�p�ϐ�
    lv_error_parameter VARCHAR2(1000);                          --�g�[�N���p�ϐ�
    -- ================
    -- ���[�U�[��`��O
    -- ================
    in_parameter_expt EXCEPTION; --�K�{���ڂ�NULL�̏ꍇ
    add_area_expt     EXCEPTION; --�t�^�敪��'H'�A'F'�ANULL�̂�����ł��Ȃ��ꍇ
  --
  BEGIN
    --
    --�t�^�敪��NULL�`�F�b�N
    IF (iv_add_area IS NULL) THEN
      lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_ADD_AREA');
      RAISE in_parameter_expt;
    END IF;
    --�t�^�敪��'H'�̏ꍇ
    IF (iv_add_area = 'H') THEN
      --�K�{���ڂ�NULL�`�F�b�N
      IF (iv_from_series  IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_FROM_SERIES');
        RAISE in_parameter_expt;
      ELSIF (iv_base_code  IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_BASE_CODE');
        RAISE in_parameter_expt;
      ELSIF (iv_base_name  IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_BASE_NAME');
        RAISE in_parameter_expt;
      ELSIF (iv_chain_code IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_CHAIN_CODE');
        RAISE in_parameter_expt;
      ELSIF (iv_chain_name IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_CHAIN_NAME');
        RAISE in_parameter_expt;
      ELSIF (iv_data_kind  IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_DATA_KIND');
        RAISE in_parameter_expt;
      ELSIF (iv_chohyo_code IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_CHOHYO_CODE');
        RAISE in_parameter_expt;
      ELSIF (iv_chohyo_name IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_CHOHYO_NAME');
        RAISE in_parameter_expt;
      ELSIF (in_num_of_item IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_NUM_OF_ITEM');
        RAISE in_parameter_expt;
      END IF;
      --�o�͒l��ϐ��Ɋi�[
      lv_out_put := cv_knot_str || FND_PROFILE.VALUE('XXCCP1_IF_HEADER') || cv_knot_str
                 || cv_dlim_str                                               --���R�[�h�敪:"H"
                 || cv_knot_str || FND_PROFILE.VALUE('XXCCP1_IF_TO_CHOHYO_SERIES') || cv_knot_str
                 || cv_dlim_str                                               --IF��Ɩ��n��R�[�h
                 || cv_knot_str || iv_from_series || cv_knot_str
                 || cv_dlim_str                                               --IF���Ɩ��n��R�[�h
                 || cv_knot_str || iv_base_code || cv_knot_str
                 || cv_dlim_str                                               --���_(����)�R�[�h
                 || cv_knot_str || iv_base_name || cv_knot_str
                 || cv_dlim_str                                               --���_��
                 || cv_knot_str || iv_chain_code || cv_knot_str
                 || cv_dlim_str                                               --�`�F�[���X�R�[�h
                 || cv_knot_str || iv_chain_name || cv_knot_str
                 || cv_dlim_str                                               --�`�F�[���X��
                 || cv_knot_str || iv_data_kind || cv_knot_str
                 || cv_dlim_str                                               --�f�[�^��R�[�h
                 || cv_knot_str || iv_chohyo_code || cv_knot_str
                 || cv_dlim_str                                               --���[�R�[�h
                 || cv_knot_str || iv_chohyo_name || cv_knot_str
                 || cv_dlim_str                                               --���[�\����
                 || TO_CHAR(SYSDATE,'YYYYMMDD')
                 || cv_dlim_str                                               --�f�[�^�쐬��
--20090210 �C��_���� start--
--                 || TO_CHAR(SYSDATE,'HHMMSS')
                 || TO_CHAR(SYSDATE,'HH24MISS')
--20090210 �C��_���� end--
                 || cv_dlim_str                                               --�f�[�^�쐬����
                 || in_num_of_item                                            --���ڐ�
                 ;
    --
    --�t�^�敪��'F'�̏ꍇ
    ELSIF (iv_add_area = 'F') THEN
      --�f�[�^������NULL�̏ꍇ
      IF (in_num_of_records IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_NUM_OF_RECORDS');
        RAISE in_parameter_expt;
      END IF;
      --�o�͒l��ϐ��Ɋi�[
      lv_out_put := cv_knot_str || FND_PROFILE.VALUE('XXCCP1_IF_FOOTER') || cv_knot_str
                 || cv_dlim_str                                                  --���R�[�h�敪:"F"
                 || in_num_of_records                                                  --�f�[�^����
                 ;
    ELSE
      RAISE add_area_expt;
    END IF;
    --����I����
    ov_retcode := xxccp_common_pkg.set_status_normal;
    ov_output  := lv_out_put;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    --
  EXCEPTION
    --�K�{���ڂ�NULL�̏ꍇ
    WHEN in_parameter_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_output  := NULL;
      ov_errbuf  := cv_prg_name;
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application => 'XXCCP'
                      ,iv_name        => 'APP-XXCCP1-10004'
                      ,iv_token_name1  => 'ITEM'
                      ,iv_token_value1 => lv_error_parameter
                    );
    --�t�^�敪��'H'�A'F'�ANULL�̂�����ł��Ȃ��ꍇ
    WHEN add_area_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_output  := NULL; --�A�E�g�p�����[�^�ɏo�͒l���i�[
      ov_errbuf  := cv_prg_name;
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application => 'XXCCP'
                      ,iv_name        => 'APP-XXCCP1-10005'
                    );
    --�ُ�I����
    WHEN OTHERS THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_output  := NULL;
      ov_errbuf  := SUBSTRB(cv_prg_name||SQLERRM,1,5000);
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application => 'XXCCP'
                      ,iv_name        => 'APP-XXCCP1-10003'
                    );
    --
  END add_chohyo_header_footer;
  --
END xxccp_ifcommon_pkg;
/
