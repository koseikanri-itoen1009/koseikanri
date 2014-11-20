CREATE OR REPLACE
PACKAGE BODY xxinv510001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV510001C(body)
 * Description      : �ړ��`�[
 * MD.050/070       : �ړ����� T_MD050_BPO_510
 *                  : �ړ��`�[ T_MD070_BPO_51A
 * Version          : 1.3
 *
 * Program List
 * ---------------------------- ----------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------
 *  convert_into_xml            �f�[�^�ϊ������t�@���N�V����
 *  output_xml                  XML�f�[�^�o�͏����v���V�[�W��
 *  prc_create_zeroken_xml_data �擾�����O�����w�l�k�f�[�^�쐬
 *  create_xml_head             XML�f�[�^�쐬�����v���V�[�W��(�w�b�_��)
 *  create_xml_line             XML�f�[�^�쐬�����v���V�[�W��(���ו�)
 *  create_xml_sum              XML�f�[�^�쐬�����v���V�[�W��(���v��)
 *  create_xml                  XML�f�[�^�쐬�����v���V�[�W��
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2008/03/05    1.0   Yuki Komikado      ����쐬
 *  2008/05/26    1.1   Kazuo Kumamoto     �����e�X�g��Q�Ή�
 *  2008/05/28    1.2   Yuko Kawano        �����e�X�g��Q�Ή�
 *  2008/05/29    1.3   Yuko Kawano        �����e�X�g��Q�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn   CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error  CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION ;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION ;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  �Œ蕔 END   ############################
--
  -- =====================================================
  -- ���[�U�[��`��O
  -- =====================================================
  data_check_expt           EXCEPTION ;           -- �f�[�^�`�F�b�N�G�N�Z�v�V����
  data_none_expt            EXCEPTION ;           -- �f�[�^�`�F�b�N�G�N�Z�v�V����
  no_data_expt              EXCEPTION ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data IS RECORD 
    (
      product_class       VARCHAR2(2)   -- 01.���i���ʋ敪(���i���j���[:1 ���i���j���[�ȊO:2)
     ,prod_class_code     VARCHAR2(2)   -- 02.���i�敪
     ,target_class        VARCHAR2(3)   -- 03.�w��/���ы敪
     ,move_no             VARCHAR2(12)  -- 04.�ړ��ԍ�
     ,move_instr_post_cd  VARCHAR2(4)   -- 05.�ړ��w������
     ,ship                NUMBER        -- 06.�o�Ɍ�
     ,arrival             NUMBER        -- 07.���ɐ�
     ,ship_date_from      DATE          -- 08.�o�ɓ�FROM
     ,ship_date_to        DATE          -- 09.�o�ɓ�TO
     ,delivery_no         VARCHAR2(12)  -- 10.�z��No.
    ) ;
--
  -- �w�b�_���f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_head_data IS RECORD 
    (
      move_number    xxinv_mov_req_instr_headers.mov_num%TYPE              -- 01.�ړ��ԍ�
     ,base_id        xxinv_mov_req_instr_headers.shipped_locat_code%TYPE   -- 02.�o�Ɍ�(�R�[�h)
     ,base_value     xxcmn_item_locations2_v.description%TYPE              -- 03.�o�Ɍ�
     ,in_id          xxinv_mov_req_instr_headers.ship_to_locat_code%TYPE   -- 04.���ɐ�(�R�[�h)
     ,in_value       xxcmn_item_locations2_v.description%TYPE              -- 05.���ɐ�
     ,out_date       xxinv_mov_req_instr_headers.actual_ship_date%TYPE     -- 06.�o�ɓ�
     ,arrive_date    xxinv_mov_req_instr_headers.actual_arrival_date%TYPE  -- 07.����
     ,fare_code      xxcmn_lookup_values2_v.meaning%TYPE                   -- 08.�^���敪
     ,deliver_code   xxcmn_lookup_values2_v.meaning%TYPE                   -- 09.�^���敪
     ,arr_code       xxinv_mov_req_instr_headers.batch_no%TYPE             -- 10.��zNo
     ,trader_code    xxinv_mov_req_instr_headers.freight_carrier_code%TYPE -- 11.�^���Ǝ�(�R�[�h)
     ,trader_name    xxcmn_carriers2_v.party_name%TYPE                     -- 12.�^���Ǝ�
     ,summary_value  xxinv_mov_req_instr_headers.description%TYPE          -- 13.�E�v
    ) ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gr_param            rec_param_data ;      -- �p�����[�^
  gr_head_data        rec_head_data  ;      -- �w�b�_�p�O���[�o���ϐ�
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'XXINV510001C' ;  -- �p�b�P�[�W��
  gv_report_id        CONSTANT VARCHAR2(12)  := 'XXINV510001T' ;  -- �v���O���������[�o�͗p
  gv_status_out       CONSTANT VARCHAR2(2)   := '04';             -- �X�e�[�^�X 04:�u�o�ɕ񍐗L�v
  gv_status_in_out    CONSTANT VARCHAR2(2)   := '06';             -- �X�e�[�^�X 06:�u���o�ɕ񍐗L�v
  gv_status_irai      CONSTANT VARCHAR2(2)   := '02';             -- �X�e�[�^�X 02:�u�˗��ρv
  gv_status_chosei    CONSTANT VARCHAR2(2)   := '03';             -- �X�e�[�^�X 02:�u�������v
  gv_delete_flg       CONSTANT VARCHAR2(2)   := 'N';              -- ����t���O N:�uOFF�v
  gv_docu_type_mov    CONSTANT VARCHAR2(2)   := '20';             -- �����^�C�v 20:�u�ړ��v
  gv_rec_type_act     CONSTANT VARCHAR2(2)   := '20';             -- ���R�[�h�^�C�v �u�o�Ɏ��сv
  gv_rec_type_si      CONSTANT VARCHAR2(2)   := '10';             -- ���R�[�h�^�C�v �u�w���v
  gv_lookup_ship      CONSTANT VARCHAR2(100) := 'XXCMN_SHIP_METHOD';    
                                                 -- �N�C�b�N�R�[�h.�^�C�v �uXXCMN_SHIP_METHOD�v
  gv_lookup_presence  CONSTANT VARCHAR2(100) := 'XXINV_PRESENCE_CLASS'; 
                                                 -- �N�C�b�N�R�[�h.�^�C�v �uXXINV_PRESENCE_CLASS�v
  gv_actual_kbn       CONSTANT VARCHAR2(2)   := '20';             -- �w��/���ы敪 �u���сv
  gv_indicate_kbn     CONSTANT VARCHAR2(2)   := '10';             -- �w��/���ы敪 �u�w���v
  gv_item_kbn_drink   CONSTANT VARCHAR2(2)   := '2';              -- ���i�敪 1�F���[�t�A2�F�h�����N
  gv_product_class    CONSTANT VARCHAR2(2)   := '1';              
                                                 -- ���i���ʋ敪 1�F���i�A2�F���i�ȊO
  gv_attribute6       CONSTANT VARCHAR2(2)   := '1';              
                                                 -- �z���敪�敪 �����敪(DFF) 1�F�Ώ�
  gv_seihin           CONSTANT VARCHAR2(2)   := '5';              -- �i�ڋ敪 ���i
  gv_hanseihin        CONSTANT VARCHAR2(2)   := '4';              -- �i�ڋ敪 �����i
  gv_genryou          CONSTANT VARCHAR2(2)   := '1';              -- �i�ڋ敪 ����
  gv_shizai           CONSTANT VARCHAR2(2)   := '2';              -- �i�ڋ敪 ����
  gc_application_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN' ;         -- �A�v���P�[�V�����iXXCMN�j
  gc_date_fmt_ymd     CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD' ;    -- �N����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_dept_cd            VARCHAR2(10) ;                             -- �S������
  gv_dept_nm            VARCHAR2(14) ;                             -- �S����
  gv_postal_code        xxcmn_locations_all.zip%TYPE ;             -- �X�֔ԍ�
  gv_address_value      xxcmn_locations_all.address_line1%TYPE ;   -- �Z��
  gv_tel_value          xxcmn_locations_all.phone%TYPE ;           -- �d�b�ԍ�
  gv_fax_value          xxcmn_locations_all.fax%TYPE ;             -- FAX�ԍ�
  gv_cat_value          xxcmn_locations_all.location_name%TYPE ;   -- ��������
--
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gt_xml_data_table         XML_DATA ;                -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx                NUMBER ;                  -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : XML�f�[�^�ϊ������t�@���N�V����
   ***********************************************************************************/
  FUNCTION convert_into_xml(
    iv_name              IN        VARCHAR2,      -- �^�O�l�[��
    iv_value             IN        VARCHAR2,      -- �^�O�f�[�^
    ic_type              IN        CHAR           -- �^�O�^�C�v
  )RETURN VARCHAR2
  IS
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    -- �v���O������
    cv_prg_name    CONSTANT VARCHAR2(100) := 'convert_into_xml' ;
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_convert_data         VARCHAR2(32000) ;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'>'||iv_value||'</'||iv_name||'>' ;
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END convert_into_xml ;
--
  /**********************************************************************************
   * Procedure Name   : output_xml
   * Description      : XML�f�[�^�o�͏����v���V�[�W��
   ***********************************************************************************/
  PROCEDURE output_xml(
    ov_errbuf            OUT       VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT       VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT       VARCHAR2)        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'output_xml' ;  --  �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_xml_string  VARCHAR2(32000) ;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    -- XML�w�b�_�o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<?xml version="1.0" encoding="shift_jis" ?>') ;
--
    -- XML�f�[�^���o��
    <<xml_loop>>
    FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
      lv_xml_string := convert_into_xml(
                         gt_xml_data_table(i).tag_name
                        ,gt_xml_data_table(i).tag_value
                        ,gt_xml_data_table(i).tag_type) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_xml_string) ;
    END LOOP xml_loop ;
--
    -- XML�f�[�^(Temp)�폜
    gt_xml_data_table.DELETE ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  �Œ蕔 END   ##########################################
--
  END output_xml ;
--
  /**********************************************************************************
   * Procedure Name   : create_xml_head
   * Description      : XML�f�[�^�쐬�����v���V�[�W��(�w�b�_��)
   ***********************************************************************************/
  PROCEDURE create_xml_head (
    ov_errbuf            OUT       VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT       VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT       VARCHAR2)        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'create_xml_head' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
    -- =====================================================
    -- ���[�U�[�f�[�^�Z�b�g
    -- =====================================================
--
    -- �f�[�^�O���[�v���J�n�f�[�^�Z�b�g   <g_denpyo>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_denpyo' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- �f�[�^�Z�b�g                     <report_id>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_report_id ;
--
    -- �f�[�^�Z�b�g                     <exec_date>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( SYSDATE, 'YYYY/MM/DD HH24:MI:SS' ) ;
--
    -- �f�[�^�Z�b�g   <address_value>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'address_value' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_address_value;
--
    -- �f�[�^�Z�b�g   <tel_value>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'tel_value' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_tel_value;
--
    -- �f�[�^�Z�b�g   <fax_value>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'fax_value' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_fax_value;
--
    -- �f�[�^�Z�b�g   <cat_id>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'cat_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_dept_cd;
--
    -- �f�[�^�Z�b�g   <cat_value>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'cat_value' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_cat_value;
--
    -- �f�[�^�Z�b�g                     <move_number>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'move_number' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.move_number ;
--
    -- �f�[�^�Z�b�g                     <base_id>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'base_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.base_id ;
--
    -- �f�[�^�Z�b�g   <base_value>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'base_value' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.base_value ;
--
    -- �f�[�^�Z�b�g   <in_id>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'in_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.in_id ;
--
    -- �f�[�^�Z�b�g   <in_value>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'in_value' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.in_value ;
--
    -- �f�[�^�Z�b�g   <out_date>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'out_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( gr_head_data.out_date, 'YYYY/MM/DD' ) ;
--
    -- �f�[�^�Z�b�g   <arrive_date>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'arrive_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( gr_head_data.arrive_date, 'YYYY/MM/DD' ) ;
--
    -- �f�[�^�Z�b�g   <fare_code>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'fare_code' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.fare_code ;
--
    -- �f�[�^�Z�b�g   <deliver_code>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_code' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.deliver_code ;
--
    -- �f�[�^�Z�b�g   <arr_code>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'arr_code' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.arr_code ;
--
    -- �f�[�^�Z�b�g   <trader_code>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'trader_code' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.trader_code ;
--
    -- �f�[�^�Z�b�g   <trader_name>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'trader_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.trader_name ;
--
    -- �f�[�^�Z�b�g   <summary_value>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'summary_value' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.summary_value;
--
    -- =====================================================
    -- ���׃f�[�^�Z�b�g
    -- =====================================================
    -- �f�[�^�O���[�v���J�n�^�O�Z�b�g   <lg_item_info>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
    WHEN data_check_expt THEN
      ov_errmsg  := lv_errmsg ;                                           --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;                                     --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_xml_head ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_zeroken_xml_data
   * Description      : �擾�����O�����w�l�k�f�[�^�쐬
   ***********************************************************************************/
  PROCEDURE prc_create_zeroken_xml_data
    (
      ov_errbuf         OUT VARCHAR2          -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode        OUT VARCHAR2          -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg         OUT VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_zeroken_xml_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
--
  BEGIN
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- -----------------------------------------------------
    -- ���ׂf�J�n�^�O�o��
    -- -----------------------------------------------------
--
    -- �w�b�_�f�[�^�o��
    create_xml_head(
     lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
    ,lv_errmsg) ;           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    ------------------------------
    -- ���b�Z�[�W�o�̓^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'msg';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := xxcmn_common_pkg.get_msg( gc_application_cmn
                                                                        ,'APP-XXCMN-10122'  ) ;
--
    ------------------------------
    -- ���ׂk�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_denpyo';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
  EXCEPTION
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_create_zeroken_xml_data ;
--
  /**********************************************************************************
   * Procedure Name   : create_xml_line
   * Description      : XML�f�[�^�쐬�����v���V�[�W��(���ו�)
   ***********************************************************************************/
  PROCEDURE create_xml_line (
    iv_article_code       IN       VARCHAR2,        -- 01:�i�ځi�R�[�h�j
    iv_article_name       IN       VARCHAR2,        -- 02:�i�ږ���
    iv_lot_number         IN       VARCHAR2,        -- 03:���b�gNo
    iv_make_date          IN       VARCHAR2,        -- 04:������
    iv_sign               IN       VARCHAR2,        -- 05:�ŗL�L��
    in_stock              IN       NUMBER,          -- 06:�݌ɓ���
    in_amount             IN       NUMBER,          -- 07:����
    iv_unit               IN       VARCHAR2,        -- 08:�P��
    ov_errbuf            OUT       VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT       VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT       VARCHAR2)        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'create_xml_line' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    gl_xml_idx           NUMBER      := 0 ;    -- XML�o�̓��C���i�[�p
--
  BEGIN
--
    -- �f�[�^�O���[�v���J�n�^�O�Z�b�g   <g_item>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- �f�[�^�Z�b�g                     <article_code>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'article_code' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := iv_article_code ;
--
    -- �f�[�^�Z�b�g                     <article_name>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'article_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := iv_article_name ;
--
    -- �f�[�^�Z�b�g                     <lot_number>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_number' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := iv_lot_number ;
--
    -- �f�[�^�Z�b�g                     <make_date>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'make_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(TO_DATE(iv_make_date, 
                                                       gc_date_fmt_ymd), gc_date_fmt_ymd) ;
--
    -- �f�[�^�Z�b�g                     <sign>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sign' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := iv_sign ;
--
    -- �f�[�^�Z�b�g                     <stock>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'stock' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := in_stock ;
--
    -- �f�[�^�Z�b�g                     <amount>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'amount' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := in_amount ;
--
    -- �f�[�^�Z�b�g                     <unit>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'unit' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := iv_unit ;
--
    -- �f�[�^�O���[�v���I���^�O�Z�b�g   </g_item>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
    WHEN data_check_expt THEN
      ov_errmsg  := lv_errmsg ;                                           --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;                                     --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_xml_line ;
--
  /**********************************************************************************
   * Procedure Name   : create_xml_sum
   * Description      : XML�f�[�^�쐬�����v���V�[�W��(���v��)
   ***********************************************************************************/
  PROCEDURE create_xml_sum (
    in_amount_sum         IN    NUMBER,          -- 01.���v����
    in_volume_sum         IN    NUMBER,          -- 02.���v�̐�
    in_weight_sum         IN    NUMBER,          -- 03.���v�d��
    ov_errbuf            OUT    VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT    VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT    VARCHAR2)        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'create_xml_sum' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    gl_xml_idx           NUMBER      := 0 ;    -- XML�o�̓��C���i�[�p
--
  BEGIN
  -- =====================================================
  -- �f�[�^�Z�b�g
  -- =====================================================
--
    -- �f�[�^�O���[�v���I���^�O�Z�b�g   </lg_item_info>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  -- �f�[�^�Z�b�g                     <amount_sum>
  gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
  gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_sum' ;
  gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
  gt_xml_data_table(gl_xml_idx).tag_value := in_amount_sum;
--
  -- �f�[�^�Z�b�g                     <volume_sum>
  gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
  gt_xml_data_table(gl_xml_idx).tag_name  := 'volume_sum' ;
  gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
  gt_xml_data_table(gl_xml_idx).tag_value := in_volume_sum;
--
  -- �f�[�^�Z�b�g                     <weight_sum>
  gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
  gt_xml_data_table(gl_xml_idx).tag_name  := 'weight_sum' ;
  gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
  gt_xml_data_table(gl_xml_idx).tag_value := in_weight_sum;
--
    -- �f�[�^�O���[�v���I���^�O�Z�b�g   </g_denpyo>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_denpyo' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
    WHEN data_check_expt THEN
      ov_errmsg  := lv_errmsg ;                                           --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;                                     --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_xml_sum ;
--
  /**********************************************************************************
   * Procedure Name   : create_xml
   * Description      : XML�f�[�^�쐬�����v���V�[�W��
   ***********************************************************************************/
  PROCEDURE create_xml (
    on_xml_data_count    OUT       NUMBER,
    ov_errbuf            OUT       VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT       VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT       VARCHAR2)        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'create_xml' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_summary_value VARCHAR2(60);
    ln_stock         NUMBER;
    ln_amount_sum    NUMBER;
    ln_volume_sum    NUMBER;
    ln_weight_sum    NUMBER;
    xml_data_count   NUMBER;
    lv_move_number   xxinv_mov_req_instr_headers.mov_num%TYPE;  -- �ړ��ԍ�
--
    -- ==================================================
    -- �J�[�\���錾
    -- ==================================================
    -- ����
    CURSOR get_actual_cur
     (
      cur_mov_num                 VARCHAR2
     ,cur_instruction_post_code   VARCHAR2
     ,cur_shipped_locat_id        NUMBER
     ,cur_ship_to_locat_id        NUMBER
     ,cur_delivery_no             VARCHAR2
     ,cur_product_flg             VARCHAR2
     ,cur_item_class              VARCHAR2
     ,cur_actual_ship_dt_from     DATE
     ,cur_actual_ship_dt_to       DATE
     )
    IS
    SELECT xmrih.mov_num                      AS mov_num                      -- 01:�ړ��ԍ�
          ,xmrih.shipped_locat_code           AS shipped_locat_code           -- 02:�o�Ɍ��ۊǏꏊ
          ,xil2v1.description                 AS description1                 -- 03:�E�v
          ,xmrih.ship_to_locat_code           AS ship_to_locat_code           -- 04:���ɐ�ۊǏꏊ
          ,xil2v2.description                 AS description2                 -- 05:�E�v
          ,xmrih.actual_ship_date             AS actual_ship_date             -- 06:�o�Ɏ��ѓ�
          ,xmrih.actual_arrival_date          AS actual_arrival_date          -- 07:���Ɏ��ѓ�
          ,xlv2v2.meaning                     AS freight_charge_class         -- 08:�^���敪
          ,xmrih.actual_freight_carrier_code  AS actual_freight_carrier_code  -- 09:�^���Ǝ�_����
          ,xc2v.party_name                    AS party_name                   -- 10:������
          ,xmrih.actual_shipping_method_code  AS actual_shipping_method_code  -- 11:�z���敪_����
          ,xlv2v1.meaning                     AS meaning                      -- 12:���e
          ,xmrih.description                  AS description3                 -- 13:�E�v
          ,xmril.item_code                    AS item_code                    -- 14:�i��
          ,xim2v.item_short_name              AS item_short_name              -- 15:����
          ,xmld.lot_no                        AS lot_no                       -- 16:���b�gNO
          ,ilm.attribute1                     AS attribute1                   -- 17:DFF1
          ,ilm.attribute2                     AS attribute2                   -- 18:DFF2
          ,xim2v.num_of_cases                 AS num_of_cases                 -- 19:�P�[�X����
          ,xim2v.frequent_qty                 AS frequent_qty                 -- 20:��\����
          ,ilm.attribute6                     AS attribute6                   -- 21:�݌ɓ���
          ,xmld.actual_quantity               AS actual_quantity              -- 22:���ѐ���
          ,xim2v.item_um                      AS uom_code                     -- 23:�P��
          ,xmrih.sum_capacity                 AS sum_capacity                 -- 24:�ύڗe�ύ��v
          ,xmrih.sum_weight                   AS sum_weight                   -- 25:�ύڏd�ʍ��v
          ,xic4v.item_class_code              AS segment1                     -- 26:�Z�O�����g1
          ,xmrih.batch_no                     AS batch_no                     -- 27:��zNo
          ,xmrih.sum_pallet_weight            AS sum_pallet_weight            -- 28:���v�p���b�g�d��
          ,xlv2v1.attribute6                  AS koguchi                      -- 29:�����敪
    FROM   xxinv_mov_req_instr_headers xmrih     -- �ړ��˗�/�w���w�b�_(�A�h�I��)
          ,xxinv_mov_req_instr_lines   xmril     -- �ړ��˗�/�w������(�A�h�I��)
          ,xxinv_mov_lot_details       xmld      -- �ړ����b�g�ڍ�(�A�h�I��)
          ,ic_lots_mst                 ilm       -- OPM���b�g�}�X�^
          ,xxcmn_item_categories4_v    xic4v     -- OPM�i�ڃJ�e�S���������VIEW4
          ,xxcmn_item_mst2_v           xim2v     -- OPM�i�ڃ}�X�^
          ,xxcmn_carriers2_v           xc2v      -- �^���Ǝҏ��VIEW2(�p�[�e�B�T�C�g�A�h�I��)
          ,xxcmn_item_locations2_v     xil2v1    -- OPM�ۊǏꏊ���VIEW
          ,xxcmn_item_locations2_v     xil2v2    -- OPM�ۊǏꏊ���VIEW
          ,xxcmn_lookup_values2_v      xlv2v1    -- �N�C�b�N�R�[�h���VIEW2
          ,xxcmn_lookup_values2_v      xlv2v2    -- �N�C�b�N�R�[�h���VIEW2
    WHERE 
    ------------------------------------------------------------------------
    -- 03:OPM�ۊǏꏊ�}�X�^.�E�v����
          xmrih.shipped_locat_id  = xil2v1.inventory_location_id
    AND   xil2v1.date_from        <= xmrih.actual_ship_date
    AND ( xil2v1.date_to IS NULL 
          OR
          xil2v1.date_to >= xmrih.actual_ship_date
        )
    -- 05:OPM�ۊǏꏊ�}�X�^.�E�v����
    AND   xmrih.ship_to_locat_id  = xil2v2.inventory_location_id
    AND   TRUNC( xil2v2.date_from ) <= TRUNC( xmrih.actual_ship_date )
    AND ( TRUNC( xil2v2.date_to ) IS NULL 
          OR
          TRUNC( xil2v2.date_to ) >= TRUNC( xmrih.actual_ship_date )
        )
    -- 10:�p�[�e�B�T�C�g�A�h�I��.����������
--mod start 1.1
--    AND   xmrih.career_id         = xc2v.party_id
--    AND   TRUNC( xc2v.start_date_active ) <= TRUNC( xmrih.actual_ship_date )
--2008.05.29 modify start
--    AND   xmrih.career_id         = xc2v.party_id(+)
    AND   xmrih.actual_career_id    = xc2v.party_id(+)
--2008.05.29 modify start
    AND   TRUNC( xc2v.start_date_active(+) ) <= TRUNC( xmrih.actual_ship_date )
--mod end 1.1
    AND ( TRUNC( xc2v.end_date_active ) IS NULL
          OR
          TRUNC( xc2v.end_date_active )   >= TRUNC( xmrih.actual_ship_date )
        )
    ------------------------------------------------------------------------
    -- 12:�N�C�b�N�R�[�h.���e����
--mod start 1.1
--    AND   xlv2v1.lookup_code = xmrih.actual_shipping_method_code
--    AND   xlv2v1.lookup_type = gv_lookup_ship                -- �N�C�b�N�R�[�h�uXXCMN_SHIP_METHOD�v
    AND   xlv2v1.lookup_code(+) = xmrih.actual_shipping_method_code
    AND   xlv2v1.lookup_type(+) = gv_lookup_ship                -- �N�C�b�N�R�[�h�uXXCMN_SHIP_METHOD�v
--mod end 1.1
    AND ( TRUNC( xlv2v1.start_date_active ) IS NULL 
          OR
          TRUNC( xlv2v1.start_date_active ) <= TRUNC( xmrih.actual_ship_date )
        )                          
    AND ( TRUNC( xlv2v1.end_date_active ) IS NULL 
          OR
          TRUNC( xlv2v1.end_date_active ) >= TRUNC( xmrih.actual_ship_date )
        )                          
    -------------------------------------------------------------------------
    -- 08:�N�C�b�N�R�[�h.�L���敪
--mod start 1.1
--    AND   xlv2v2.lookup_code = xmrih.freight_charge_class
--    AND   xlv2v2.lookup_type = gv_lookup_presence
    AND   xlv2v2.lookup_code(+) = xmrih.freight_charge_class
    AND   xlv2v2.lookup_type(+) = gv_lookup_presence
--mod end 1.1
                                                           -- �N�C�b�N�R�[�h�uXXINV_PRESENCE_CLASS�v
    AND ( TRUNC( xlv2v2.start_date_active ) IS NULL 
          OR
          TRUNC( xlv2v2.start_date_active ) <= TRUNC( xmrih.actual_ship_date )
        )                          
    AND ( TRUNC( xlv2v2.end_date_active ) IS NULL 
          OR
          TRUNC( xlv2v2.end_date_active ) >= TRUNC( xmrih.actual_ship_date )
        )                          
    -------------------------------------------------------------------------
    -- �i���ݏ���
    --���̓p�����[�^�F�ړ��ԍ������͍ς̏ꍇ
    AND   (( cur_mov_num IS NULL ) OR ( cur_mov_num = xmrih.mov_num ))
    --���̓p�����[�^�F�ړ��w�����������͍ς̏ꍇ
    AND   (( cur_instruction_post_code IS NULL ) 
             OR
           ( cur_instruction_post_code = xmrih.instruction_post_code )
          )
    --���̓p�����[�^�F�o�Ɍ������͍ς̏ꍇ
    AND   (( cur_shipped_locat_id IS NULL ) OR ( cur_shipped_locat_id = xmrih.shipped_locat_id ))
    --���̓p�����[�^�F���ɐ悪���͍ς̏ꍇ
    AND   (( cur_ship_to_locat_id IS NULL ) OR ( cur_ship_to_locat_id = xmrih.ship_to_locat_id ))
    AND   (TRUNC( xmrih.actual_ship_date ) >= TRUNC( cur_actual_ship_dt_from )
           AND 
           TRUNC( xmrih.actual_ship_date ) <= TRUNC( cur_actual_ship_dt_to ))
    --���̓p�����[�^�F�z���������͍ς̏ꍇ
    AND   (( cur_delivery_no IS NULL ) OR ( cur_delivery_no = xmrih.delivery_no ))
    AND   xmrih.status                IN (gv_status_out, gv_status_in_out)
                                                         -- 04:�u�o�ɕ񍐗L�vOR 06:�u���o�ɕ񍐗L�v
    AND   xmrih.product_flg           = cur_product_flg
    AND   xmrih.item_class            = cur_item_class
    AND   xmrih.mov_hdr_id            = xmril.mov_hdr_id
    AND   xmril.delete_flg            = gv_delete_flg               -- N:�uOFF�v
    AND   xmril.mov_line_id           = xmld.mov_line_id
    AND   xmld.document_type_code     = gv_docu_type_mov            -- 20:�u�ړ��v
    AND   xmld.record_type_code       = gv_rec_type_act             -- �u�o�Ɏ��сv
    AND   xmld.lot_id                 = ilm.lot_id
    AND   xmril.item_id               = ilm.item_id
    AND   xmril.item_id               = xic4v.item_id
    AND   xmril.item_id               = xim2v.item_id
    AND   ( TRUNC( xim2v.start_date_active ) IS NULL
            OR
            TRUNC( xim2v.start_date_active ) <= TRUNC( xmrih.actual_ship_date )
          )
    AND   ( TRUNC( xim2v.end_date_active ) IS NULL
            OR 
            TRUNC( xim2v.end_date_active ) >= TRUNC( xmrih.actual_ship_date )
          )
    ORDER BY 
       xmrih.mov_num
      ,xmril.item_code
      ,(CASE 
          WHEN xic4v.item_class_code = gv_seihin THEN
            ilm.attribute1
          ELSE NULL
        END )
      ,(CASE 
          WHEN xic4v.item_class_code = gv_seihin THEN
            ilm.attribute2
          ELSE NULL
        END )
      ,(CASE 
          WHEN xic4v.item_class_code <> gv_seihin THEN
            ilm.lot_no
          ELSE NULL
        END )
    ;
--
    --�w��
    CURSOR get_indicate_cur
    (
      cur_mov_num                 VARCHAR2
     ,cur_instruction_post_code   VARCHAR2
     ,cur_shipped_locat_id        NUMBER
     ,cur_ship_to_locat_id        NUMBER
     ,cur_delivery_no             VARCHAR2
     ,cur_product_flg             VARCHAR2
     ,cur_item_class              VARCHAR2
     ,cur_schedule_ship_dt_from   DATE
     ,cur_schedule_ship_dt_to     DATE
    )
    IS
    SELECT xmrih.mov_num                      AS  mov_num               -- 01:�ړ��ԍ�
          ,xmrih.shipped_locat_code           AS  shipped_locat_code    -- 02:�o�Ɍ��ۊǏꏊ
          ,xil2v1.description                 AS  description1          -- 03:�E�v
          ,xmrih.ship_to_locat_code           AS  ship_to_locat_code    -- 04:���ɐ�ۊǏꏊ
          ,xil2v2.description                 AS  description2          -- 05:�E�v
--2008.05.28 modify start
--          ,xmrih.actual_ship_date             AS  schedule_ship_date    -- 06:�o�ɗ\���
--          ,xmrih.actual_arrival_date          AS  schedule_arrival_date -- 07:���ɗ\���
          ,xmrih.schedule_ship_date           AS  schedule_ship_date    -- 06:�o�ɗ\���
          ,xmrih.schedule_arrival_date        AS  schedule_arrival_date -- 07:���ɗ\���
--2008.05.28 modify end
          ,xlv2v2.meaning                     AS  freight_charge_class  -- 08:�^���敪
          ,xmrih.freight_carrier_code         AS  freight_carrier_code  -- 09:�^���Ǝ�
          ,xc2v.party_name                    AS  party_name            -- 10:������
          ,xmrih.shipping_method_code         AS  shipping_method_code  -- 11:�z���敪
          ,xlv2v1.meaning                     AS  meaning               -- 12:���e
          ,xmrih.description                  AS  description3          -- 13:�E�v
          ,xmril.item_code                    AS  item_code             -- 14:�i��
          ,xim2v.item_short_name              AS  item_short_name       -- 15:����
          ,ilm.lot_no                         AS  lot_no                -- 16:���b�gNO
          ,ilm.attribute1                     AS  attribute1            -- 17:DFF1
          ,ilm.attribute2                     AS  attribute2            -- 18:DFF2
          ,xim2v.num_of_cases                 AS  num_of_cases          -- 19:�P�[�X����
          ,xim2v.frequent_qty                 AS  frequent_qty          -- 20:��\����
          ,ilm.attribute6                     AS  attribute6            -- 21:�݌ɓ���
          ,xmld.actual_quantity               AS  actual_quantity       -- 22:���ѐ���
          ,xim2v.item_um                      AS  uom_code              -- 23:�P��
          ,xmrih.sum_capacity                 AS  sum_capacity          -- 24:�ύڗe�ύ��v
          ,xmrih.sum_weight                   AS  sum_weight            -- 25:�ύڏd�ʍ��v
          ,xic4v.item_class_code              AS  segment1              -- 26:�Z�O�����g1
          ,xmrih.batch_no                     AS  batch_no              -- 27:��zNo
          ,xmrih.sum_pallet_weight            AS  sum_pallet_weight     -- 28:���v�p���b�g�d��
          ,xlv2v1.attribute6                  AS  koguchi               -- 29:�����敪
    FROM   xxinv_mov_req_instr_headers xmrih     -- �ړ��˗�/�w���w�b�_(�A�h�I��)
          ,xxinv_mov_req_instr_lines   xmril     -- �ړ��˗�/�w������(�A�h�I��)
          ,xxinv_mov_lot_details       xmld      -- �ړ����b�g�ڍ�(�A�h�I��)
          ,ic_lots_mst                 ilm       -- OPM���b�g�}�X�^
          ,xxcmn_item_categories4_v    xic4v     -- OPM�i�ڃJ�e�S���������VIEW4
          ,xxcmn_item_mst2_v           xim2v     -- OPM�i�ڃ}�X�^
          ,xxcmn_carriers2_v           xc2v      -- �^���Ǝҏ��VIEW2(�p�[�e�B�T�C�g�A�h�I��)
          ,xxcmn_item_locations2_v     xil2v1    -- OPM�ۊǏꏊ���VIEW
          ,xxcmn_item_locations2_v     xil2v2    -- OPM�ۊǏꏊ���VIEW
          ,xxcmn_lookup_values2_v      xlv2v1    -- �N�C�b�N�R�[�h���VIEW2
          ,xxcmn_lookup_values2_v      xlv2v2    -- �N�C�b�N�R�[�h���VIEW2
    WHERE 
    ------------------------------------------------------------------------
    -- 03:OPM�ۊǏꏊ�}�X�^.�E�v����
          xmrih.shipped_locat_id  = xil2v1.inventory_location_id
    AND   xil2v1.date_from        <= xmrih.schedule_ship_date
    AND ( xil2v1.date_to IS NULL 
          OR
          xil2v1.date_to >= xmrih.schedule_ship_date
        )
    -- 05:OPM�ۊǏꏊ�}�X�^.�E�v����
    AND   xmrih.ship_to_locat_id  = xil2v2.inventory_location_id
    AND   xil2v2.date_from        <= xmrih.schedule_ship_date
    AND ( xil2v2.date_to IS NULL 
          OR
          xil2v2.date_to >= xmrih.schedule_ship_date
        )
    -- 10:�p�[�e�B�T�C�g�A�h�I��.����������
--mod start 1.1
--    AND   xmrih.career_id         = xc2v.party_id
--    AND   TRUNC( xc2v.start_date_active ) <= TRUNC( xmrih.schedule_ship_date )
    AND   xmrih.career_id         = xc2v.party_id(+)
    AND   TRUNC( xc2v.start_date_active(+) ) <= TRUNC( xmrih.schedule_ship_date )
--mod end 1.1
    AND ( TRUNC( xc2v.end_date_active ) IS NULL
          OR
          TRUNC( xc2v.end_date_active )   >= TRUNC( xmrih.schedule_ship_date )
        )
    ------------------------------------------------------------------------
    -- 12:�N�C�b�N�R�[�h.���e����
--mod start 1.1
--    AND   xlv2v1.lookup_code = xmrih.shipping_method_code
--    AND   xlv2v1.lookup_type = gv_lookup_ship                 -- �N�C�b�N�R�[�h�uXXCMN_SHIP_METHOD�v
    AND   xlv2v1.lookup_code(+) = xmrih.shipping_method_code
    AND   xlv2v1.lookup_type(+) = gv_lookup_ship                 -- �N�C�b�N�R�[�h�uXXCMN_SHIP_METHOD�v
--mod end 1.1
    AND ( xlv2v1.start_date_active IS NULL 
          OR
          xlv2v1.start_date_active <= xmrih.schedule_ship_date
        )                          
    AND ( xlv2v1.end_date_active IS NULL 
          OR
          xlv2v1.end_date_active >= xmrih.schedule_ship_date
        )                          
    ------------------------------------------------------------------------
    -- 08:�N�C�b�N�R�[�h.�L���敪
--mod start 1.1
--    AND   xlv2v2.lookup_code = xmrih.freight_charge_class
--    AND   xlv2v2.lookup_type = gv_lookup_presence                   
    AND   xlv2v2.lookup_code(+) = xmrih.freight_charge_class
    AND   xlv2v2.lookup_type(+) = gv_lookup_presence                   
--mod end 1.1
                                                           -- �N�C�b�N�R�[�h�uXXINV_PRESENCE_CLASS�v
    AND ( xlv2v2.start_date_active IS NULL 
          OR
          xlv2v2.start_date_active <= xmrih.schedule_ship_date
        )                          
    AND ( xlv2v2.end_date_active IS NULL 
          OR
          xlv2v2.end_date_active >= xmrih.schedule_ship_date
        )                          
    -------------------------------------------------------------------------
    -- �i���ݏ���
    --���̓p�����[�^�F�ړ��ԍ������͍ς̏ꍇ
    AND   (( cur_mov_num IS NULL ) OR ( cur_mov_num = xmrih.mov_num ))
    --���̓p�����[�^�F�ړ��w�����������͍ς̏ꍇ
    AND   (( cur_instruction_post_code IS NULL )
             OR
           ( cur_instruction_post_code = xmrih.instruction_post_code ))
    --���̓p�����[�^�F�o�Ɍ������͍ς̏ꍇ
    AND   (( cur_shipped_locat_id IS NULL ) OR ( cur_shipped_locat_id = xmrih.shipped_locat_id ))
    --���̓p�����[�^�F���ɐ悪���͍ς̏ꍇ
    AND   (( cur_ship_to_locat_id IS NULL ) OR ( cur_ship_to_locat_id = xmrih.ship_to_locat_id ))
    AND   ( xmrih.schedule_ship_date     >= TRUNC( cur_schedule_ship_dt_from )
            AND 
            xmrih.schedule_ship_date <= TRUNC( cur_schedule_ship_dt_to ) )
    --���̓p�����[�^�F�z���������͍ς̏ꍇ
    AND   (( cur_delivery_no IS NULL ) OR ( cur_delivery_no = xmrih.delivery_no ))
    AND   xmrih.status                IN (gv_status_irai, gv_status_chosei, gv_status_out)
                                                -- 02:�u�˗��ρvOR 03:�u�������vOR 04:�u���ɕ񍐗L�v
    AND   xmrih.product_flg           = cur_product_flg
    AND   xmrih.item_class            = cur_item_class
    AND   xmrih.mov_hdr_id            = xmril.mov_hdr_id
    AND   xmril.delete_flg            = gv_delete_flg               -- N:�uOFF�v
    AND   xmril.mov_line_id           = xmld.mov_line_id
    AND   xmld.document_type_code     = gv_docu_type_mov            -- 20:�u�ړ��v
    AND   xmld.record_type_code       = gv_rec_type_si              -- �u�w���v
    AND   xmld.lot_id                 = ilm.lot_id
    AND   xmril.item_id               = ilm.item_id
    AND   xmril.item_id               = xic4v.item_id
    AND   xmril.item_id               = xim2v.item_id
    AND   ( TRUNC( xim2v.start_date_active ) IS NULL
            OR
            TRUNC( xim2v.start_date_active ) <= TRUNC( xmrih.schedule_ship_date )
          )
    AND   ( TRUNC( xim2v.end_date_active ) IS NULL
            OR 
            TRUNC( xim2v.end_date_active ) >= TRUNC( xmrih.schedule_ship_date )
          )
    ORDER BY 
       xmrih.mov_num
      ,xmril.item_code
      ,(CASE 
          WHEN xic4v.item_class_code = gv_seihin THEN
            ilm.attribute1
          ELSE NULL
        END )
      ,(CASE 
          WHEN xic4v.item_class_code = gv_seihin THEN
            ilm.attribute2
          ELSE NULL
        END )
      ,(CASE 
          WHEN xic4v.item_class_code <> gv_seihin THEN
            ilm.lot_no
          ELSE NULL
        END )
    ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ϐ��̏�����
    gr_head_data.move_number        := NULL ;  -- �ړ��ԍ�
    gr_head_data.base_id            := NULL ;  -- �o�Ɍ�(�R�[�h)
    gr_head_data.base_value         := NULL ;  -- �o�Ɍ�
    gr_head_data.in_id              := NULL ;  -- ���ɐ�(�R�[�h)
    gr_head_data.in_value           := NULL ;  -- ���ɐ�
    gr_head_data.out_date           := NULL ;  -- �o�ɓ�
    gr_head_data.arrive_date        := NULL ;  -- ����
    gr_head_data.fare_code          := NULL ;  -- �^���敪
    gr_head_data.deliver_code       := NULL ;  -- �^���敪
    gr_head_data.arr_code           := NULL ;  -- ��zNo
    gr_head_data.trader_code        := NULL ;  -- �^���Ǝ�(�R�[�h)
    gr_head_data.trader_name        := NULL ;  -- �^���Ǝ�
    xml_data_count                  := 0 ;     -- �擾�f�[�^����
    lv_move_number                  := NULL ;  -- �ړ��ԍ�
--
    -- ====================================================
    -- �S���ҏ��擾
    -- ====================================================
    -- �S������
    gv_dept_cd := SUBSTRB(xxcmn_common_pkg.get_user_dept_code(FND_GLOBAL.USER_ID, NULL), 1, 10) ;
    -- �S����
    gv_dept_nm := SUBSTRB(xxcmn_common_pkg.get_user_name(FND_GLOBAL.USER_ID), 1, 14) ;
--
    -- =====================================================
    -- �������擾�֐��Ăяo��
    -- =====================================================
    xxcmn_common_pkg.get_dept_info
      (
        gv_dept_cd
       ,NULL
       ,gv_postal_code
       ,gv_address_value
       ,gv_tel_value
       ,gv_fax_value
       ,gv_cat_value
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg
      );
--
    -- =====================================================
    -- �w�b�_�[�^�O�f�[�^�Z�b�g
    -- =====================================================
    -- �f�[�^�O���[�v���J�n�^�O�Z�b�g   <root>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'root' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- �f�[�^�O���[�v���J�n�^�O�Z�b�g   <data_info>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- �f�[�^�O���[�v���J�n�^�O�Z�b�g   <lg_denpyo_info>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_denpyo_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    IF ( gr_param.target_class = gv_actual_kbn ) THEN
      -- ====================================================
      -- �J�[�\���I�[�v��
      -- ====================================================
      <<get_actual_cur_loop>>
      FOR rec_get_actual_cur IN get_actual_cur
        (
           gr_param.move_no
          ,gr_param.move_instr_post_cd
          ,gr_param.ship
          ,gr_param.arrival
          ,gr_param.delivery_no
          ,gr_param.product_class
          ,gr_param.prod_class_code
          ,gr_param.ship_date_from
          ,gr_param.ship_date_to
        )
      LOOP
        -- ===================================================
        -- �o�͏��擾
        -- ===================================================
        gr_head_data.move_number   := rec_get_actual_cur.mov_num ;                     -- �ړ��ԍ�
        gr_head_data.base_id       := rec_get_actual_cur.shipped_locat_code ;
                                                                                 -- �o�Ɍ�(�R�[�h)
        gr_head_data.base_value    := rec_get_actual_cur.description1 ;                -- �o�Ɍ�
        gr_head_data.in_id         := rec_get_actual_cur.ship_to_locat_code ;
                                                                                 -- ���ɐ�(�R�[�h)
        gr_head_data.in_value      := rec_get_actual_cur.description2 ;                -- ���ɐ�
        gr_head_data.out_date      := rec_get_actual_cur.actual_ship_date ;            -- �o�ɓ�
        gr_head_data.arrive_date   := rec_get_actual_cur.actual_arrival_date ;         -- ����
        gr_head_data.fare_code     := rec_get_actual_cur.freight_charge_class ;        -- �^���敪
        gr_head_data.deliver_code  := rec_get_actual_cur.meaning ;                     -- �z���敪
        gr_head_data.arr_code      := rec_get_actual_cur.batch_no ;                    -- ��zNo
        gr_head_data.trader_code   := rec_get_actual_cur.actual_freight_carrier_code ; 
                                                                                 -- �^���Ǝ�(�R�[�h)
        gr_head_data.trader_name   := rec_get_actual_cur.party_name ;                  -- �^���Ǝ�
        gr_head_data.summary_value := rec_get_actual_cur.description3 ;                -- �E�v
--
        -- ===================================================
        -- XML�f�[�^�쐬�i���v���j
        -- ===================================================
        IF ( lv_move_number IS NOT NULL
             AND
             NVL( lv_move_number, '0' ) <> gr_head_data.move_number ) THEN
          create_xml_sum
            (
              ln_amount_sum                        -- 01.���v����
             ,ln_volume_sum                        -- 02.���v�̐�
             ,ln_weight_sum                        -- 03.���v�d��
             ,lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
             ,lv_errmsg) ;                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          -- ���v�p�ϐ��̏�����
          ln_weight_sum := 0 ;
          ln_amount_sum := 0 ;
          ln_volume_sum := 0 ;
        END IF;
--
        -- ===================================================
        -- XML�f�[�^�쐬�i�w�b�_���j
        -- ===================================================
        IF ( NVL( lv_move_number, '0' ) <> gr_head_data.move_number ) THEN
          create_xml_head(
           lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg) ;           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        END IF;
--
        -- ===================================================
        -- �݌ɓ������H����
        -- ===================================================
        -- �ϐ��̏�����
        ln_stock := 0;
        IF ( rec_get_actual_cur.segment1 = gv_seihin ) THEN
          ln_stock := rec_get_actual_cur.num_of_cases ;
        ELSIF ( rec_get_actual_cur.segment1 = gv_hanseihin 
                OR rec_get_actual_cur.segment1 = gv_genryou ) THEN
          IF ( rec_get_actual_cur.attribute6 IS NULL ) THEN
            ln_stock := rec_get_actual_cur.frequent_qty ;
          ELSE
            ln_stock := rec_get_actual_cur.attribute6 ;
          END IF ;
        ELSIF ( rec_get_actual_cur.segment1 = gv_shizai ) THEN
          ln_stock := rec_get_actual_cur.frequent_qty ;
        END IF;
--
        -- ===================================================
        -- XML�f�[�^�쐬�i���ו��j
        -- ===================================================
        create_xml_line(
           rec_get_actual_cur.item_code        -- 01:�i�ځi�R�[�h�j
          ,rec_get_actual_cur.item_short_name  -- 02:�i�ږ���
          ,rec_get_actual_cur.lot_no           -- 03:���b�gNo
          ,rec_get_actual_cur.attribute1       -- 04:������
          ,rec_get_actual_cur.attribute2       -- 05:�ŗL�L��
          ,ln_stock                            -- 06:�݌ɓ���
          ,rec_get_actual_cur.actual_quantity  -- 07:����
          ,rec_get_actual_cur.uom_code         -- 08:�P��
          ,lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg) ;                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- ===================================================
        -- ���v���̍��v�d�ʂ̎Z�o
        -- ===================================================
--2008.05.29 modify start
--        IF ( gr_param.prod_class_code = gv_item_kbn_drink 
--             AND gr_param.product_class = gv_product_class
--             AND rec_get_actual_cur.koguchi = gv_attribute6 ) THEN
--          -- �p�����[�^�̏��i�敪���h�����N ���� ���i���ʋ敪�����i ����
--          -- �z���敪�̏����敪���u�Ώہv�̏ꍇ
--          ln_weight_sum := NVL( ln_weight_sum, 0 ) + NVL( rec_get_actual_cur.sum_weight, 0 ) ;
--        ELSE
--          ln_weight_sum := NVL( ln_weight_sum, 0 ) + 
--                              ( NVL( rec_get_actual_cur.sum_weight, 0 ) +
--                                NVL( rec_get_actual_cur.sum_pallet_weight, 0 ) );
--        END IF;
        --
        IF ( NVL( lv_move_number, '0' ) <> gr_head_data.move_number ) THEN
          IF ( gr_param.prod_class_code = gv_item_kbn_drink 
               AND gr_param.product_class = gv_product_class
               AND rec_get_actual_cur.koguchi = gv_attribute6 ) THEN
          -- �p�����[�^�̏��i�敪���h�����N ���� ���i���ʋ敪�����i ����
          -- �z���敪�̏����敪���u�Ώہv�̏ꍇ
            ln_weight_sum      := NVL( rec_get_actual_cur.sum_weight, 0 ) ;
          ELSE
            ln_weight_sum      := NVL( rec_get_actual_cur.sum_weight, 0 ) + 
                                     NVL( rec_get_actual_cur.sum_pallet_weight, 0 ) ;
          END IF;
        END IF;
--2008.05.29 modify end
--
        -- ===================================================
        -- ���v���̍��v���ʂ̎Z�o
        -- ===================================================
        ln_amount_sum := NVL( rec_get_actual_cur.actual_quantity, 0 ) + NVL( ln_amount_sum, 0 ) ;
        -- ===================================================
        -- ���v���̍��v�̐ς̎Z�o
        -- ===================================================
--2008.05.29 modify start
--        ln_volume_sum := NVL( rec_get_actual_cur.sum_capacity, 0 ) + NVL( ln_volume_sum, 0 ) ;
        ln_volume_sum := NVL( ln_volume_sum, 0 ) ;
--2008.05.29 modify end
--
        -- �f�[�^�����J�E���g
        xml_data_count := xml_data_count + 1;
        -- �ړ��ԍ�
        lv_move_number := gr_head_data.move_number ;
      END LOOP get_actual_cur_loop;
--
      -- ===================================================
      -- XML�f�[�^�쐬�i���v���j
      -- ===================================================
      IF ( xml_data_count <> 0 ) THEN
        create_xml_sum
          (
            ln_amount_sum                        -- 01.���v����
           ,ln_volume_sum                        -- 02.���v�̐�
           ,ln_weight_sum                        -- 03.���v�d��
           ,lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
           ,lv_errmsg) ;                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      END IF;
--
    ELSIF ( gr_param.target_class = gv_indicate_kbn ) THEN
      <<get_indicate_cur_loop>>
      FOR rec_get_indicate IN get_indicate_cur
        (
           gr_param.move_no
          ,gr_param.move_instr_post_cd
          ,gr_param.ship
          ,gr_param.arrival
          ,gr_param.delivery_no
          ,gr_param.product_class
          ,gr_param.prod_class_code
          ,gr_param.ship_date_from
          ,gr_param.ship_date_to
        )
      LOOP
        -- ===================================================
        -- �o�͏��擾
        -- ===================================================
        gr_head_data.move_number        := rec_get_indicate.mov_num ;               -- �ړ��ԍ�
        gr_head_data.base_id            := rec_get_indicate.shipped_locat_code ;    
                                                                                 -- �o�Ɍ�(�R�[�h)
        gr_head_data.base_value         := rec_get_indicate.description1 ;          -- �o�Ɍ�
        gr_head_data.in_id              := rec_get_indicate.ship_to_locat_code ;    
                                                                                 -- ���ɐ�(�R�[�h)
        gr_head_data.in_value           := rec_get_indicate.description2 ;          -- ���ɐ�
        gr_head_data.out_date           := rec_get_indicate.schedule_ship_date ;    -- �o�ɓ�
        gr_head_data.arrive_date        := rec_get_indicate.schedule_arrival_date ; -- ����
        gr_head_data.fare_code          := rec_get_indicate.freight_charge_class ;  -- �^���敪
        gr_head_data.deliver_code       := rec_get_indicate.meaning ;               -- �z���敪
        gr_head_data.arr_code           := rec_get_indicate.batch_no ;              -- ��zNo
        gr_head_data.trader_code        := rec_get_indicate.freight_carrier_code ;  
                                                                                 -- �^���Ǝ�(�R�[�h)
        gr_head_data.trader_name        := rec_get_indicate.party_name ;            -- �^���Ǝ�
        gr_head_data.summary_value      := rec_get_indicate.description3 ;          -- �E�v
--
        -- ===================================================
        -- XML�f�[�^�쐬�i���v���j
        -- ===================================================
        IF ( lv_move_number IS NOT NULL
             AND
             NVL( lv_move_number, '0' ) <> gr_head_data.move_number ) THEN
          create_xml_sum(
           ln_amount_sum                        -- 01.���v����
          ,ln_volume_sum                        -- 02.���v�̐�
          ,ln_weight_sum                        -- 03.���v�d��
          ,lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg) ;                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          -- ���v�p�ϐ��̏�����
          ln_weight_sum := 0 ;
          ln_amount_sum := 0 ;
          ln_volume_sum := 0 ;
        END IF;
--
        -- ===================================================
        -- XML�f�[�^�쐬�i�w�b�_���j
        -- ===================================================
        IF ( NVL( lv_move_number, '0' ) <> gr_head_data.move_number ) THEN
          create_xml_head(
           lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg) ;           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        END IF;
--
        -- ===================================================
        -- �݌ɓ������H����
        -- ===================================================
        -- �ϐ��̏�����
        ln_stock := 0;
        IF ( rec_get_indicate.segment1 = gv_seihin ) THEN
          ln_stock := rec_get_indicate.num_of_cases ;
        ELSIF ( rec_get_indicate.segment1 = gv_hanseihin 
                OR rec_get_indicate.segment1 = gv_genryou ) THEN
          IF ( rec_get_indicate.attribute6 IS NULL ) THEN
            ln_stock := rec_get_indicate.frequent_qty ;
          ELSE
            ln_stock := rec_get_indicate.attribute6 ;
          END IF ;
        ELSIF ( rec_get_indicate.segment1 = gv_shizai ) THEN
          ln_stock := rec_get_indicate.frequent_qty ;
        END IF;
--
        -- ===================================================
        -- XML�f�[�^�쐬�i���ו��j
        -- ===================================================
        create_xml_line(
           rec_get_indicate.item_code        -- 01:�i�ځi�R�[�h�j
          ,rec_get_indicate.item_short_name  -- 02:�i�ږ���
          ,rec_get_indicate.lot_no           -- 03:���b�gNo
          ,rec_get_indicate.attribute1       -- 04:������
          ,rec_get_indicate.attribute2       -- 05:�ŗL�L��
          ,ln_stock                          -- 06:�݌ɓ���
          ,rec_get_indicate.actual_quantity  -- 07:����
          ,rec_get_indicate.uom_code         -- 08:�P��
          ,lv_errbuf                         -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                        -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg) ;                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        -- ===================================================
        -- ���v���̍��v�d�ʂ̎Z�o
        -- ===================================================
--2008.05.29 modify start
--        IF ( gr_param.prod_class_code = gv_item_kbn_drink 
--             AND gr_param.product_class = gv_product_class
--             AND rec_get_indicate.koguchi = gv_attribute6 ) THEN
--          -- �p�����[�^�̏��i�敪���h�����N ���� ���i���ʋ敪�����i ����
--          -- �z���敪�̏����敪���u�Ώہv�̏ꍇ
--          ln_weight_sum      := NVL( ln_weight_sum, 0 ) + NVL( rec_get_indicate.sum_weight, 0 ) ;
--        ELSE
--          ln_weight_sum      := NVL( ln_weight_sum, 0 ) + 
--                                   ( NVL( rec_get_indicate.sum_weight, 0 ) + 
--                                     NVL( rec_get_indicate.sum_pallet_weight, 0 ) ) ;
--        END IF;
        --
        IF ( NVL( lv_move_number, '0' ) <> gr_head_data.move_number ) THEN
          IF ( gr_param.prod_class_code = gv_item_kbn_drink 
               AND gr_param.product_class = gv_product_class
               AND rec_get_indicate.koguchi = gv_attribute6 ) THEN
          -- �p�����[�^�̏��i�敪���h�����N ���� ���i���ʋ敪�����i ����
          -- �z���敪�̏����敪���u�Ώہv�̏ꍇ
            ln_weight_sum      := NVL( rec_get_indicate.sum_weight, 0 ) ;
          ELSE
            ln_weight_sum      := NVL( rec_get_indicate.sum_weight, 0 ) + 
                                     NVL( rec_get_indicate.sum_pallet_weight, 0 ) ;
          END IF;
        END IF;
--2008.05.29 modify end
        -- ===================================================
        -- ���v���̍��v���ʂ̎Z�o
        -- ===================================================
        ln_amount_sum := NVL( rec_get_indicate.actual_quantity, 0 ) + NVL( ln_amount_sum, 0 ) ;
        -- ===================================================
        -- ���v���̍��v�̐ς̎Z�o
        -- ===================================================
--2008.05.29 modify start
--        ln_volume_sum := NVL( rec_get_indicate.sum_capacity, 0 ) + NVL( ln_volume_sum, 0 ) ;
        ln_volume_sum := NVL( ln_volume_sum, 0 ) ;
--2008.05.29 modify end
        -- �f�[�^�����J�E���g
        xml_data_count := xml_data_count + 1;
        -- �ړ��ԍ�
        lv_move_number := gr_head_data.move_number;
      END LOOP get_indicate_cur_loop ;
      -- ===================================================
      -- XML�f�[�^�쐬�i���v���j
      -- ===================================================
      IF ( xml_data_count <> 0 ) THEN
        create_xml_sum(
         ln_amount_sum                        -- 01.���v����
        ,ln_volume_sum                        -- 02.���v�̐�
        ,ln_weight_sum                        -- 03.���v�d��
        ,lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg) ;                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      END IF;
    END IF ;
--
    IF ( xml_data_count = 0 ) THEN
      -- =====================================================
      -- �擾�f�[�^�O����XML�f�[�^�쐬����
      -- =====================================================
      prc_create_zeroken_xml_data
        (
          lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
         ,lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
         ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
    -- �f�[�^�����Z�b�g
    on_xml_data_count := xml_data_count ;
--
    END IF;
--
    -- =====================================================
    -- �I���^�O�Z�b�g
    -- =====================================================
    -- �f�[�^�O���[�v���I���^�O�Z�b�g   </lg_denpyo_info>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_denpyo_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- �f�[�^�O���[�v���I���^�O�Z�b�g   </data_info>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- �f�[�^�O���[�v���I���^�O�Z�b�g   </root>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/root' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
      --*** �l�擾�G���[��O ***
    WHEN data_check_expt THEN
      ov_errmsg  := lv_errmsg ;                                           --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;                                     --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_xml ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     iv_product_class      IN     VARCHAR2       --   01.���i���ʋ敪
    ,iv_prod_class_code    IN     VARCHAR2       --   02.���i�敪
    ,iv_target_class       IN     VARCHAR2       --   03.�w��/���ы敪
    ,iv_move_no            IN     VARCHAR2       --   04.�ړ��ԍ�
    ,iv_move_instr_post_cd IN     VARCHAR2       --   05.�ړ��w������
    ,iv_ship               IN     VARCHAR2       --   06.�o�Ɍ�
    ,iv_arrival            IN     VARCHAR2       --   07.���ɐ�
    ,iv_ship_date_from     IN     VARCHAR2       --   08.�o�ɓ�FROM
    ,iv_ship_date_to       IN     VARCHAR2       --   09.�o�ɓ�TO
    ,iv_delivery_no        IN     VARCHAR2       --   10.�z��No.
    ,ov_errbuf            OUT     VARCHAR2       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode           OUT     VARCHAR2       --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg            OUT     VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- *** ���[�J���萔 ***
    lr_param_rec            rec_param_data ;               -- �p�����[�^��n���p
    xml_data_table          XML_DATA ;
    ln_retcode              NUMBER ;
    ln_xml_data_count       NUMBER ;
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- �p�����[�^�i�[����
    -- =====================================================
    gr_param.product_class      := iv_product_class ;          -- 01.���i���ʋ敪
    gr_param.prod_class_code    := iv_prod_class_code ;        -- 02.���i�敪
    gr_param.target_class       := iv_target_class ;           -- 03.�w��/���ы敪
    gr_param.move_no            := iv_move_no ;                -- 04.�ړ��ԍ�
    gr_param.move_instr_post_cd := iv_move_instr_post_cd ;     -- 05.�ړ��w������
    gr_param.ship               := TO_NUMBER( iv_ship ) ;      -- 06.�o�Ɍ�
    gr_param.arrival            := TO_NUMBER( iv_arrival ) ;   -- 07.���ɐ�
    gr_param.ship_date_from     := FND_DATE.STRING_TO_DATE(iv_ship_date_from, gc_date_fmt_ymd) ;
                                                               -- 08.�o�ɓ�FROM
    gr_param.ship_date_to       := FND_DATE.STRING_TO_DATE(iv_ship_date_to, gc_date_fmt_ymd) ;
                                                               -- 09.�o�ɓ�TO
    gr_param.delivery_no        := iv_delivery_no ;            -- 10.�z��No.
--
    -- ====================================================
    -- XML�f�[�^(Temp)�쐬
    -- ====================================================
    create_xml(
       ln_xml_data_count      -- �擾�f�[�^����
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg) ;           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�n���h�����O
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    IF (lv_retcode = gv_status_normal AND ln_xml_data_count = 0) THEN
      lv_retcode := gv_status_warn;
    END IF;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
    -- =====================================================
    -- XML�f�[�^�o�͏���
    -- =====================================================
    output_xml(
        ov_errbuf         =>   lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
       ,ov_retcode        =>   lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
       ,ov_errmsg         =>   lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (ov_retcode = gv_status_error) THEN   -- ���^�[���R�[�h���u�G���[�v
      RAISE global_process_expt ;
--
    ELSIF (    (ov_retcode = gv_status_normal)
           AND (ln_xml_data_count = 0)) THEN  -- ���^�[���R�[�h���u����v��������0��
      ov_retcode := gv_status_warn;
--
    END IF;
--
  EXCEPTION
      -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main (
    errbuf                OUT VARCHAR2,         --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode               OUT VARCHAR2,         --   ���^�[���E�R�[�h    --# �Œ� #
    iv_product_class      IN  VARCHAR2,         --   01.���i���ʋ敪
    iv_prod_class_code    IN  VARCHAR2,         --   02.���i�敪
    iv_target_class       IN  VARCHAR2,         --   03.�w��/���ы敪
    iv_move_no            IN  VARCHAR2,         --   04.�ړ��ԍ�
    iv_move_instr_post_cd IN  VARCHAR2,         --   05.�ړ��w������
    iv_ship               IN  VARCHAR2,         --   06.�o�Ɍ�
    iv_arrival            IN  VARCHAR2,         --   07.���ɐ�
    iv_ship_date_from     IN  VARCHAR2,         --   08.�o�ɓ�FROM
    iv_ship_date_to       IN  VARCHAR2,         --   09.�o�ɓ�TO
    iv_delivery_no        IN  VARCHAR2)         --   10.�z��No.
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain(
      iv_product_class,      --   01.���i���ʋ敪
      iv_prod_class_code,    --   02.���i�敪
      iv_target_class,       --   03.�w��/���ы敪
      iv_move_no,            --   04.�ړ��ԍ�
      iv_move_instr_post_cd, --   05.�ړ��w������
      iv_ship,               --   06.�o�Ɍ�
      iv_arrival,            --   07.���ɐ�
      iv_ship_date_from,     --   08.�o�ɓ�FROM
      iv_ship_date_to,       --   09.�o�ɓ�TO
      iv_delivery_no,        --   10.�z��No.
      lv_errbuf,             --   �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,            --   ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg) ;           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxinv510001c ;
/