CREATE OR REPLACE PACKAGE BODY xxwsh930004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH930004C(body)
 * Description      : ���o�ɏ�񍷈ك��X�g�i���Ɋ�j
 * MD.050/070       : ���Y�������ʁi�o�ׁE�ړ��C���^�t�F�[�X�jIssue1.0(T_MD050_BPO_930)
 *                    ���Y�������ʁi�o�ׁE�ړ��C���^�t�F�[�X�jIssue1.0(T_MD070_BPO_93D)
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  prc_create_out_data         PROCEDURE : �w�l�k�f�[�^�o�͏���
 *  prc_ins_temp_data           PROCEDURE : ���ԃe�[�u���o�^
 *  prc_set_temp_data           PROCEDURE : ���ԃe�[�u���o�^�f�[�^�ݒ�
 *  prc_create_move_data        PROCEDURE : �ړ��f�[�^���o����
 *  prc_create_xml_data_user    PROCEDURE : �^�O�o�� - ���[�U�[���
 *  prc_create_xml_data         PROCEDURE : �w�l�k�f�[�^�ҏW
 *  convert_into_xml            FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  submain                     PROCEDURE : ���C�������v���V�[�W��
 *  main                        PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/03    1.0   Oracle���V����   �V�K�쐬
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
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  check_move_data_expt         EXCEPTION;     -- �ړ��f�[�^���o�����ł̗�O
  check_create_xml_expt        EXCEPTION;     -- �w�l�k�f�[�^�ҏW�ł̗�O
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
  -- ===============================================================================================
  -- ���[�U�[�錾��
  -- ===============================================================================================
  -- ==================================================
  -- �O���[�o���萔
  -- ==================================================
  gc_pkg_name             CONSTANT VARCHAR2(20) := 'xxwsh930004c' ;     -- �p�b�P�[�W��
  gc_report_id            CONSTANT VARCHAR2(20) := 'XXWSH930004T' ;     -- ���[ID
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;            -- �A�v���P�[�V����
  gc_err_code_no_data     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122' ;  -- �f�[�^�O�����b�Z�[�W
--
  ------------------------------
  -- �Q�ƃ^�C�v
  ------------------------------
  -- ���o�ɏ�񍷈ك��X�g�o�͋敪
  gc_lookup_output_type       CONSTANT VARCHAR2(100) := 'XXWSH_930CD_LIST_OUTPUT_CLASS' ;
  -- �z���敪
  gc_lookup_ship_method_code  CONSTANT VARCHAR2(100) := 'XXCMN_SHIP_METHOD' ;
  -- ���b�g�X�e�[�^�X
  gc_lookup_lot_status        CONSTANT VARCHAR2(100) := 'XXCMN_LOT_STATUS' ;
--
  ------------------------------
  -- �Q�ƃR�[�h
  ------------------------------
  -- �i�ڋ敪
  gc_item_div_sei         CONSTANT VARCHAR2(1)  := '5' ;  -- ���i
  -- ���o�ɏ�񍷈ك��X�g�o�͋敪
  gc_output_type_nrep     CONSTANT VARCHAR2(1)  := '1' ;  -- ����
  gc_output_type_rsrv     CONSTANT VARCHAR2(1)  := '2' ;  -- �ۗ�
  gc_output_type_diff     CONSTANT VARCHAR2(1)  := '3' ;  -- �˗���
  gc_output_type_ndif     CONSTANT VARCHAR2(1)  := '4' ;  -- ���ٖ�
  gc_output_type_ndel     CONSTANT VARCHAR2(1)  := '5' ;  -- �o�ɖ�
  gc_output_type_nstc     CONSTANT VARCHAR2(1)  := '6' ;  -- ���ɖ�
  gc_output_type_iodf     CONSTANT VARCHAR2(1)  := '7' ;  -- �o����
  -- ���َ��R
  gc_reason_nrep          CONSTANT VARCHAR2(10) := '����' ;
  gc_reason_rsrv          CONSTANT VARCHAR2(10) := '�ۗ�' ;
  gc_reason_diff          CONSTANT VARCHAR2(10) := '�˗���' ;
  gc_reason_ndif          CONSTANT VARCHAR2(10) := '���ٖ�' ;
  gc_reason_ndel          CONSTANT VARCHAR2(10) := '�o�ɖ�' ;
  gc_reason_nstc          CONSTANT VARCHAR2(10) := '���ɖ�' ;
  gc_reason_iodf          CONSTANT VARCHAR2(10) := '�o����' ;
  -- �ړ��^�C�v
  gc_mov_type_y           CONSTANT VARCHAR2(1)  := '1' ;    -- �ϑ�����
  -- �ړ��X�e�[�^�X
  gc_mov_status_cmp       CONSTANT VARCHAR2(2)  := '02' ;   -- �˗���
  gc_mov_status_adj       CONSTANT VARCHAR2(2)  := '03' ;   -- ������
  gc_mov_status_del       CONSTANT VARCHAR2(2)  := '04' ;   -- �o�ɕ񍐗L
  gc_mov_status_stc       CONSTANT VARCHAR2(2)  := '05' ;   -- ���ɕ񍐗L
  gc_mov_status_dsr       CONSTANT VARCHAR2(2)  := '06' ;   -- ���o�ɕ񍐗L
  -- EOS�f�[�^�^�C�v
  gc_eos_type_rpt_move_o  CONSTANT VARCHAR2(3)  := '220' ;  -- �ړ��o�Ɋm���
  gc_eos_type_rpt_move_i  CONSTANT VARCHAR2(3)  := '230' ;  -- �ړ����Ɋm���
  -- YesNo�敪
  gc_yn_div_n             CONSTANT VARCHAR2(1)  := 'N' ;    -- NO
  -- �o�׎x���敪
  gc_sp_class_move        CONSTANT VARCHAR2(1)  := '3' ;    -- �ړ��i�v���O����������j
  -- �o�׎x���敪�i�ϊ��j
  gc_sp_class_name_move   CONSTANT VARCHAR2(4)  := '�ړ�' ; -- �ړ��i�v���O����������j
  -- �󒍃J�e�S��
  gc_order_cat_o          CONSTANT VARCHAR2(10) := 'ORDER' ;
  -- ���b�g�Ǘ��敪
  gc_lot_ctl_y            CONSTANT VARCHAR2(1) := '1' ;     -- ���b�g�Ǘ�����
  gc_lot_ctl_n            CONSTANT VARCHAR2(1) := '0' ;     -- ���b�g�Ǘ��Ȃ�
  -- �ړ����b�g�ڍ׃A�h�I���F�����^�C�v
  gc_doc_type_move        CONSTANT VARCHAR2(2) := '20' ;    -- �ړ�
  -- �ړ����b�g�ڍ׃A�h�I���F���R�[�h�^�C�v
  gc_rec_type_inst        CONSTANT VARCHAR2(2) := '10' ;    -- �w��
  gc_rec_type_stck        CONSTANT VARCHAR2(2) := '20' ;    -- �o�Ɏ���
  gc_rec_type_dlvr        CONSTANT VARCHAR2(2) := '30' ;    -- ���Ɏ���
  -- �o�׈˗��h�e�F�ۗ��X�e�[�^�X
  gc_reserved_status_y    CONSTANT VARCHAR2(1) := '1' ;     -- �ۗ�
--
  ------------------------------
  -- ���̑�
  ------------------------------
  gc_max_date_char        CONSTANT VARCHAR2(10) := '9999/12/31' ;
--
  -- ==================================================
  -- ���[�U�[��`�O���[�o���^
  -- ==================================================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD
    (
      prod_div              VARCHAR2(1)         -- 01 : ���i�敪
     ,item_div              VARCHAR2(1)         -- 02 : �i�ڋ敪
     ,date_from             DATE                -- 03 : ����From
     ,date_to               DATE                -- 04 : ����To
     ,dept_code             VARCHAR2(4)         -- 05 : ����
     ,output_type           VARCHAR2(1)         -- 06 : �o�͋敪
     ,block_01              VARCHAR2(2)         -- 07 : �u���b�N�P
     ,block_02              VARCHAR2(2)         -- 08 : �u���b�N�Q
     ,block_03              VARCHAR2(2)         -- 09 : �u���b�N�R
     ,ship_to_locat_code    VARCHAR2(4)         -- 10 : ���ɐ�
     ,online_type           VARCHAR2(1)         -- 11 : �I�����C���Ώۋ敪
     ,request_no            VARCHAR2(12)        -- 12 : �ړ�No
    ) ;
--    
  -- ���ԃe�[�u���o�^�p���R�[�h�ϐ�
  TYPE rec_temp_tab_data IS RECORD
    (
      arvl_code             xxwsh_930d_tmp.arvl_code%TYPE           -- ���ɑq�ɃR�[�h
     ,arvl_name             xxwsh_930d_tmp.arvl_name%TYPE           -- ���ɑq�ɖ���
     ,location_code         xxwsh_930d_tmp.location_code%TYPE       -- �o�ɑq�ɃR�[�h
     ,location_name         xxwsh_930d_tmp.location_name%TYPE       -- �o�ɑq�ɖ���
     ,ship_date             xxwsh_930d_tmp.ship_date%TYPE           -- �o�ɓ�
     ,arvl_date             xxwsh_930d_tmp.arvl_date%TYPE           -- ���ɓ�
     ,career_code           xxwsh_930d_tmp.career_code%TYPE         -- �^���Ǝ҃R�[�h
     ,career_name           xxwsh_930d_tmp.career_name%TYPE         -- �^���ƎҖ���
     ,ship_method_code      xxwsh_930d_tmp.ship_method_code%TYPE    -- �z���敪�R�[�h
     ,ship_method_name      xxwsh_930d_tmp.ship_method_name%TYPE    -- �z���敪����
     ,delivery_no           xxwsh_930d_tmp.delivery_no%TYPE         -- �z���m��
     ,request_no            xxwsh_930d_tmp.request_no%TYPE          -- �ړ��m��
     ,item_code             xxwsh_930d_tmp.item_code%TYPE           -- �i�ڃR�[�h
     ,item_name             xxwsh_930d_tmp.item_name%TYPE           -- �i�ږ���
     ,lot_no                xxwsh_930d_tmp.lot_no%TYPE              -- ���b�g�ԍ�
     ,product_date          xxwsh_930d_tmp.product_date%TYPE        -- ������
     ,use_by_date           xxwsh_930d_tmp.use_by_date%TYPE         -- �ܖ�����
     ,original_char         xxwsh_930d_tmp.original_char%TYPE       -- �ŗL�L��
     ,lot_status            xxwsh_930d_tmp.lot_status%TYPE          -- �i��
     ,quant_r               xxwsh_930d_tmp.quant_r%TYPE             -- �˗���
     ,quant_i               xxwsh_930d_tmp.quant_i%TYPE             -- ���ɐ�
     ,quant_o               xxwsh_930d_tmp.quant_o%TYPE             -- �o�ɐ�
     ,reason                xxwsh_930d_tmp.reason%TYPE              -- ���َ��R
    ) ;
--    
  -- ���o�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_get_data IS RECORD
    (
      arvl_code        VARCHAR2(100)  -- ���ɑq�ɃR�[�h
     ,arvl_name        VARCHAR2(100)  -- ���ɑq�ɖ���
     ,location_code    VARCHAR2(100)  -- �o�ɑq�ɃR�[�h
     ,location_name    VARCHAR2(100)  -- �o�ɑq�ɖ���
     ,ship_date        DATE           -- �o�ɓ�
     ,arvl_date        DATE           -- ���ɓ�
     ,career_id        VARCHAR2(100)  -- ���������F�^���Ǝ�
     ,ship_method_code VARCHAR2(100)  -- ���������F�z���敪
     ,delivery_no      VARCHAR2(100)  -- �z���m��
     ,request_no       VARCHAR2(100)  -- �ړ��m��
     ,order_line_id    VARCHAR2(100)  -- ���������F���ׂh�c
     ,item_id          VARCHAR2(100)  -- ���������F�i�ڂh�c
     ,item_code        VARCHAR2(100)  -- �i�ڃR�[�h
     ,item_name        VARCHAR2(100)  -- �i�ږ���
     ,lot_ctl          VARCHAR2(100)  -- ���������F���b�g�g�p
     ,quant_r          NUMBER         -- �˗����i���b�g�Ǘ��O�j
     ,quant_i          NUMBER         -- ���ɐ��i���b�g�Ǘ��O�j
     ,quant_o          NUMBER         -- �o�ɐ��i���b�g�Ǘ��O�j
     ,status           VARCHAR2(100)  -- �󒍃w�b�_�X�e�[�^�X
    ) ;
--    
-- ���ԃe�[�u���i�[�p
  TYPE arvl_code_type            IS TABLE OF
    xxinv_mov_req_instr_headers.ship_to_locat_code%TYPE    INDEX BY BINARY_INTEGER;--���ɑq�ɃR�[�h
--
  TYPE arvl_name_type            IS TABLE OF
    mtl_item_locations.description%TYPE                    INDEX BY BINARY_INTEGER;--���ɑq�ɖ���
--
  TYPE location_code_type        IS TABLE OF
    mtl_item_locations.segment1%TYPE                       INDEX BY BINARY_INTEGER;--�o�ɑq�ɃR�[�h
--
  TYPE location_name_type        IS  TABLE OF
    mtl_item_locations.description%TYPE                    INDEX BY BINARY_INTEGER;--�o�ɑq�ɖ���
--
  TYPE ship_date_type            IS  TABLE OF
    xxinv_mov_req_instr_headers.schedule_ship_date%TYPE    INDEX BY BINARY_INTEGER;--�o�ɓ�
--
  TYPE arvl_date_type            IS  TABLE OF
    xxinv_mov_req_instr_headers.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER;--���ɓ�
--
  TYPE career_code_type          IS TABLE OF
    xxcmn_carriers2_v.party_number%TYPE                    INDEX BY BINARY_INTEGER;--�^���Ǝ҃R�[�h
--
  TYPE ship_method_code_type     IS TABLE OF
    xxcmn_carriers2_v.party_short_name%TYPE                INDEX BY BINARY_INTEGER; --�^���ƎҖ���
--
  TYPE delivery_no_type          IS TABLE OF
    xxcmn_lookup_values_v.lookup_code%TYPE                 INDEX BY BINARY_INTEGER;--�z���敪�R�[�h
--
  TYPE request_no_type           IS TABLE OF
    xxcmn_lookup_values_v.meaning%TYPE                     INDEX BY BINARY_INTEGER;--�z���敪����
--
  TYPE order_line_id_type        IS TABLE OF
    xxinv_mov_req_instr_headers.delivery_no%TYPE           INDEX BY BINARY_INTEGER;-- �z���m��
--
  TYPE item_id_type              IS TABLE OF
    xxinv_mov_req_instr_headers.mov_num%TYPE               INDEX BY BINARY_INTEGER;--�ړ��m��
--
  TYPE item_code_type            IS TABLE OF
    xxcmn_item_mst2_v.item_no%TYPE                         INDEX BY BINARY_INTEGER;--�i�ڃR�[�h
--
  TYPE item_name_type            IS TABLE OF
    xxcmn_item_mst2_v.item_short_name%TYPE                 INDEX BY BINARY_INTEGER;--�i�ږ���
--
  TYPE lot_ctl_type              IS TABLE OF
    ic_lots_mst.lot_no%TYPE                                INDEX BY BINARY_INTEGER;--���b�g�ԍ�
--
  TYPE product_date_type         IS TABLE OF
    ic_lots_mst.attribute1%TYPE                            INDEX BY BINARY_INTEGER;--������
--
  TYPE use_by_date_type          IS TABLE OF
    ic_lots_mst.attribute3%TYPE                            INDEX BY BINARY_INTEGER;--�ܖ�����
--
  TYPE original_char_type        IS  TABLE OF
    ic_lots_mst.attribute2%TYPE                            INDEX BY BINARY_INTEGER;--�ŗL�L��
--
  TYPE meaning_type              IS TABLE OF
    xxcmn_lookup_values_v.meaning%TYPE                     INDEX BY BINARY_INTEGER;--�i��
--
  TYPE quant_r_type              IS TABLE OF
    xxinv_mov_req_instr_lines.instruct_qty%TYPE            INDEX BY BINARY_INTEGER;--�˗���
--
  TYPE quant_i_type              IS TABLE OF
    xxinv_mov_req_instr_lines.ship_to_quantity%TYPE        INDEX BY BINARY_INTEGER;--���ɐ�
--
  TYPE quant_o_type              IS TABLE OF
    xxinv_mov_req_instr_lines.shipped_quantity%TYPE        INDEX BY BINARY_INTEGER;--�o�ɐ�
--
  TYPE reason_type               IS TABLE OF
    xxwsh_930d_tmp.reason%TYPE                             INDEX BY BINARY_INTEGER;--���َ��R
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gr_param              rec_param_data ;      -- �p�����[�^
  gn_data_cnt           NUMBER DEFAULT 0 ;    -- �����f�[�^�J�E���^
--
  gb_get_flg            BOOLEAN DEFAULT FALSE ;-- �f�[�^�擾����t���O
  gt_xml_data_table     XML_DATA ;             -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx            NUMBER DEFAULT 0 ;     -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
--
  gn_created_by               NUMBER ;  -- �쐬��
  gn_last_updated_by          NUMBER ;  -- �ŏI�X�V��
  gn_last_update_login        NUMBER ;  -- �ŏI�X�V���O�C��
  gn_request_id               NUMBER ;  -- �v��ID
  gn_program_application_id   NUMBER ;  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  gn_program_id               NUMBER ;  -- �R���J�����g�E�v���O����ID
--
  -- ==============================
  -- ���ԃe�[�u���o�^�p
  -- ==============================
  gt_arvl_code_tbl         arvl_code_type;        -- ���ɑq�ɃR�[�h
  gt_arvl_name_tbl         arvl_name_type;        -- ���ɑq�ɖ���
  gt_location_code_tbl     location_code_type;    -- �o�ɑq�ɃR�[�h
  gt_location_name_tbl     location_name_type;    -- �o�ɑq�ɖ���
  gt_ship_date_tbl         ship_date_type;        -- �o�ɓ�
  gt_arvl_date_tbl         arvl_date_type;        -- ���ɓ�
  gt_career_code_tbl       career_code_type;      -- �^���Ǝ҃R�[�h
  gt_career_name_tbl       ship_method_code_type; -- �^���ƎҖ���
  gt_ship_method_code_tbl  delivery_no_type;      -- �z���敪�R�[�h
  gt_ship_method_name_tbl  request_no_type;       -- �z���敪����
  gt_delivery_no_tbl       order_line_id_type;    -- �z���m��
  gt_request_no_tbl        item_id_type;          -- �ړ��m��
  gt_item_code_tbl         item_code_type;        -- �i�ڃR�[�h
  gt_item_name_tbl         item_name_type;        -- �i�ږ���
  gt_lot_ctl_tbl           lot_ctl_type;          -- ���b�g�ԍ�
  gt_product_date_tbl      product_date_type;     -- ������
  gt_use_by_date_tbl       use_by_date_type;      -- �ܖ�����
  gt_original_char_tbl     original_char_type;    -- �ŗL�L��
  gt_meaning_tbl           meaning_type;          -- �i��
  gt_quant_r_tbl           quant_r_type;          -- �˗���
  gt_quant_i_tbl           quant_i_type;          -- ���ɐ�
  gt_quant_o_tbl           quant_o_type;          -- �o�ɐ�
  gt_reason_tbl            reason_type;           -- ���َ��R
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
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_user
   * Description      : ���[�U�[���^�O�o��
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_user
    (
      ov_errbuf             OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_xml_data_user' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �J�n�^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- �f�[�^�^�O
    -- ====================================================
    -- ���[�h�c
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gc_report_id ;
--
    -- ���s��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( SYSDATE, 'YYYY/MM/DD HH24:MI:SS' ) ;
--
    -- ���O�C�����[�U�[�F��������
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_dept( FND_GLOBAL.USER_ID ) ;
--
    -- ���O�C�����[�U�[�F���[�U�[��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_name( FND_GLOBAL.USER_ID ) ;
--
    -- ====================================================
    -- �I���^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_xml_data_user ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_out_data
   * Description      : �w�l�k�f�[�^�o�͏���
   ************************************************************************************************/
  PROCEDURE prc_create_out_data
    (
      ov_errbuf     OUT    VARCHAR2             -- �G���[�E���b�Z�[�W
     ,ov_retcode    OUT    VARCHAR2             -- ���^�[���E�R�[�h
     ,ov_errmsg     OUT    VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'prc_create_out_data' ; -- �v���O������
--
    -- ���ԃe�[�u���f�[�^���o�p
    cv_sql_dtl        CONSTANT VARCHAR2(32000)
      := ' SELECT DISTINCT'
      || '        x9t.item_code         AS item_code'
      || '       ,x9t.item_name         AS item_name'
      || '       ,x9t.lot_no            AS lot_no'
      || '       ,TO_CHAR( x9t.product_date, ''YYYY/MM/DD'' ) AS product_date'
      || '       ,TO_CHAR( x9t.use_by_date , ''YYYY/MM/DD'' ) AS use_by_date'
      || '       ,x9t.original_char     AS original_char'
      || '       ,x9t.lot_status        AS lot_status'
      || '       ,NVL( x9t.quant_r, ''0'' ) AS quant_r'
      || '       ,NVL( x9t.quant_i, ''0'' ) AS quant_i'
      || '       ,NVL( x9t.quant_o, ''0'' ) AS quant_o'
      || '       ,x9t.reason                AS reason'
      || ' FROM xxwsh_930d_tmp   x9t'
      || ' WHERE NVL( x9t.reason, ''*'' ) = NVL( :V1, NVL( x9t.reason, ''*'' ) )'
      || ' AND    x9t.delivery_no  = :V2'
      || ' AND    x9t.request_no   = :V3'
      ;
    cv_sql_order_1    CONSTANT VARCHAR2(32000)
      := ' ORDER BY TO_NUMBER( x9t.item_code )'
      || '         ,TO_CHAR(x9t.product_date, ''YYYY/MM/DD'')'
      || '         ,x9t.original_char'
      ;
    cv_sql_order_2    CONSTANT VARCHAR2(32000)
      := ' ORDER BY TO_NUMBER( x9t.item_code )'
      || '         ,TO_NUMBER( x9t.lot_no )'
      ;
    -- ==================================================
    -- �J  �[  �\  ��  ��  ��
    -- ==================================================
    -- �}�X�^���R�[�h�擾�J�[�\��
    CURSOR cu_mst( p_item_code xxwsh_930d_tmp.item_code%TYPE )
    IS
      SELECT mst.arvl_code           -- ���ɑq�ɃR�[�h
            ,mst.arvl_name           -- ���ɑq�ɖ���
            ,mst.location_code       -- �o�ɑq�ɃR�[�h
            ,mst.location_name       -- �o�ɑq�ɖ���
            ,mst.ship_date           -- �o�ɓ�
            ,mst.arvl_date           -- ���ɓ�
            ,mst.career_code         -- �^���Ǝ�
            ,mst.career_name         -- �^���ƎҖ���
            ,mst.ship_method_code    -- �z���敪�R�[�h
            ,mst.ship_method_name    -- �z���敪����
            ,mst.delivery_no         -- �z��No
            ,mst.request_no          -- �ړ�No
      FROM
      (
        SELECT DISTINCT
               x9t.arvl_code         AS arvl_code
              ,x9t.arvl_name         AS arvl_name
              ,x9t.location_code     AS location_code
              ,x9t.location_name     AS location_name
              ,TO_CHAR( x9t.ship_date , 'YYYY/MM/DD' ) AS ship_date
              ,TO_CHAR( x9t.arvl_date , 'YYYY/MM/DD' ) AS arvl_date
              ,x9t.career_code       AS career_code
              ,x9t.career_name       AS career_name
              ,x9t.ship_method_code  AS ship_method_code
              ,x9t.ship_method_name  AS ship_method_name
              ,x9t.delivery_no       AS delivery_no
              ,x9t.request_no        AS request_no
        FROM xxwsh_930d_tmp   x9t
        WHERE x9t.item_code = NVL( p_item_code, x9t.item_code )
      ) mst
      ORDER BY mst.location_code
              ,mst.ship_date
              ,mst.arvl_date
              ,mst.delivery_no
              ,mst.request_no
    ;    
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    lv_sql                  VARCHAR2(32000) ;
    -- �u���C�N���f�p
    lv_tmp_arvl_code    VARCHAR2(4) DEFAULT '*' ;
    -- �}�X�^���ڏo�͗p
    lv_ship_to_location_code     VARCHAR2(4) ;        -- ���ɑq�ɃR�[�h
    lv_ship_to_location_name     VARCHAR2(20);        -- ���ɑq�ɖ���
    lv_shipped_locat_code        VARCHAR2(4) ;        -- �o�ɑq�ɃR�[�h
    lv_shipped_locat_name        VARCHAR2(20);        -- �o�ɑq�ɖ���
    lv_ship_date                 VARCHAR2(10);        -- �o�ɓ�
    lv_arvl_date                 VARCHAR2(10);        -- ���ɓ�
    lv_freight_carrier_code      VARCHAR2(4) ;        -- �^���Ǝ҃R�[�h
    lv_freight_carrier_name      VARCHAR2(20);        -- �^���ƎҖ���
    lv_ship_method_code          VARCHAR2(2) ;        -- �z���敪�R�[�h
    lv_ship_method_name          VARCHAR2(14);        -- �z���敪����
    lv_delivery_no               VARCHAR2(12);        -- �z���m��
    lv_request_no                VARCHAR2(12);        -- �ړ��m��
    lv_param_reason              VARCHAR2(6) ;        -- ���َ��R�i�r�p�k���s�p�j
--
    -- ==================================================
    -- �q�����J�[�\���錾
    -- ==================================================
    TYPE ref_cursor IS REF CURSOR ;             -- REF_CURSOR�p
    TYPE ret_value  IS RECORD
      (
        item_code           VARCHAR2(7)         -- �i�ڃR�[�h
       ,item_name           VARCHAR2(20)        -- �i�ږ���
       ,lot_no              VARCHAR2(10)        -- ���b�g�ԍ�
       ,product_date        VARCHAR2(10)        -- ������
       ,use_by_date         VARCHAR2(10)        -- �ܖ�����
       ,original_char       VARCHAR2(6)         -- �ŗL�L��
       ,lot_status          VARCHAR2(10)        -- �i��
       ,quant_r             VARCHAR2(12)        -- �˗���
       ,quant_i             VARCHAR2(12)        -- ���ɐ�
       ,quant_o             VARCHAR2(12)        -- �o�ɐ�
       ,reason              VARCHAR2(6)         -- ���َ��R
      ) ;
    lc_ref    ref_cursor ;
    lr_ref    ret_value ;
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- ���ԃe�[�u���f�[�^���o�r�p�k������
    -- ====================================================
    ------------------------------
    -- �o�D�i�ڋ敪�����i�̏ꍇ
    ------------------------------
    IF ( gr_param.item_div = gc_item_div_sei ) THEN
      lv_sql := cv_sql_dtl || cv_sql_order_1 ;
    ------------------------------
    -- �o�D�i�ڋ敪�����i�ȊO�̏ꍇ
    ------------------------------
    ELSE
      lv_sql := cv_sql_dtl || cv_sql_order_2 ;
--
    END IF ;
--
    -- ====================================================
    -- �p�����[�^�ϊ�
    -- ====================================================
    BEGIN
      -- �o�͋敪
      IF ( gr_param.output_type IS NOT NULL ) THEN
        SELECT xlvv.meaning
        INTO   lv_param_reason
        FROM xxcmn_lookup_values_v xlvv
        WHERE xlvv.lookup_type = gc_lookup_output_type
        AND   xlvv.lookup_code = gr_param.output_type
        ;
        
      END IF ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_api_others_expt ;
      WHEN TOO_MANY_ROWS THEN
        RAISE global_api_others_expt ;
    END ;
--
    -- ====================================================
    -- ���X�g�O���[�v�J�n�^�O�i���ɑq�Ɂj
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_lctn_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
--
    <<mst_data_loop>>
   FOR re_data IN cu_mst( lv_request_no ) LOOP
      -- ----------------------------------------------------
      -- ���׃J�[�\���I�[�v��
      -- ----------------------------------------------------
      OPEN lc_ref FOR lv_sql
      USING lv_param_reason
           ,re_data.delivery_no
           ,re_data.request_no
      ;
      FETCH lc_ref INTO lr_ref ;
--
      IF ( lc_ref%FOUND ) THEN
        -- ====================================================
        -- ���ɑq�Ƀu���C�N
        -- ====================================================
        IF ( re_data.arvl_code <> lv_tmp_arvl_code ) THEN
          -- ----------------------------------------------------
          -- �O���[�v�I���^�O�o��
          -- ----------------------------------------------------
          -- ���񃌃R�[�h�̏ꍇ�͕\�����Ȃ�
          IF ( lv_tmp_arvl_code <> '*' ) THEN
            -- ���X�g�O���[�v�I���^�O�i���ɏ��j
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_spmt_info' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �O���[�v�I���^�O�i���ɑq�Ɂj
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_lctn' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          END IF ;
--
          -- ----------------------------------------------------
          -- �O���[�v�J�n�^�O�o��
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_lctn' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          -- ----------------------------------------------------
          -- �f�[�^�^�O�o��
          -- ----------------------------------------------------
          -- ���ɑq�ɃR�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_to_location_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := re_data.arvl_code ;
          -- ���ɑq�ɖ���
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_to_location_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := re_data.arvl_name ;
--
          -- ----------------------------------------------------
          -- ���X�g�O���[�v�J�n�^�O�i�o�ׁj
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_spmt_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          -- ----------------------------------------------------
          -- �u���C�N���f�p���ڂ̑ޔ�
          -- ----------------------------------------------------
          lv_tmp_arvl_code := re_data.arvl_code ;
--
        END IF ;
--
        -- ----------------------------------------------------
        -- �O���[�v�J�n�^�O�o��
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_spto' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �}�X�^���ڂ̑ޔ�
        -- ----------------------------------------------------
        lv_shipped_locat_code     := re_data.location_code;        -- �o�ɑq��
        lv_shipped_locat_name     := re_data.location_name;        -- �o�ɑq�ɖ���
        lv_ship_date              := re_data.ship_date ;           -- �o�ɓ�
        lv_arvl_date              := re_data.arvl_date ;           -- ���ɓ�
        lv_freight_carrier_code   := re_data.career_code ;         -- �^���Ǝ҃R�[�h
        lv_freight_carrier_name   := re_data.career_name ;         -- �^���ƎҖ���
        lv_ship_method_code       := re_data.ship_method_code ;    -- �z���敪�R�[�h
        lv_ship_method_name       := re_data.ship_method_name ;    -- �z���敪����
        lv_delivery_no            := re_data.delivery_no ;         -- �z���m��
        lv_request_no             := re_data.request_no ;          -- �ړ��m��
--
        -- ====================================================
        -- ���׏��o��
        -- ====================================================
        -- ----------------------------------------------------
        -- ���X�g�O���[�v�J�n�^�O�i���ׁj
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        <<dtl_data_loop>>
        LOOP
--
          gn_data_cnt := gn_data_cnt + 1 ;
--
          -- ----------------------------------------------------
          -- �O���[�v�J�n�^�O�i���ׁj
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          -- ----------------------------------------------------
          -- �f�[�^�^�O�o��
          -- ----------------------------------------------------
          -- �o�ɓ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_ship_date ;
          -- ���ɓ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'arvl_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_arvl_date ;
          -- �o�ɑq�ɃR�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_locat_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value :=  lv_shipped_locat_code;
          -- �o�ɑq�ɖ���
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_locat_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value :=  lv_shipped_locat_name;
          -- �^���Ǝ҃R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'freight_carrier_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_freight_carrier_code ;
          -- �^���ƎҖ���
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'freight_carrier_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_freight_carrier_name ;
          -- �z���敪�R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_method_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_ship_method_code ;
          -- �z���敪����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_method_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_ship_method_name ;
          -- �z���m��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_no' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_delivery_no ;
          -- �ړ��m��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mov_num' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_request_no ;
--
          -- �i�ڃR�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_code ;
          -- �i�ږ���
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_name ;
          -- ���b�g�m��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.lot_no ;
          -- ������
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'product_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.product_date ;
          -- �ܖ�����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'use_by_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.use_by_date ;
          -- �ŗL�L��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_sign' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.original_char ;
          -- �i��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'quality' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.lot_status ;
          -- �˗���
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'actual_quantity' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.quant_r ;
          -- ���ɐ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_to_quantity' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.quant_i ;
          -- �o�ɐ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_quantity' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.quant_o ;
          -- ���َ��R
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.reason ;
--
          -- ----------------------------------------------------
          -- �O���[�v�I���^�O�i���ׁj
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          -- ----------------------------------------------------
          -- �}�X�^���ڂ̏�����
          -- ----------------------------------------------------
          lv_shipped_locat_code    := NULL ;  -- �o�ɑq��
          lv_shipped_locat_name    := NULL ;  -- �o�ɑq�ɖ���
          lv_ship_date             := NULL ;  -- �o�ɓ�
          lv_arvl_date             := NULL ;  -- ���ɓ�
          lv_freight_carrier_code  := NULL ;  -- �^���Ǝ҃R�[�h
          lv_freight_carrier_name  := NULL ;  -- �^���ƎҖ���
          lv_ship_method_code      := NULL ;  -- �z���敪�R�[�h
          lv_ship_method_name      := NULL ;  -- �z���敪����
          lv_delivery_no           := NULL ;  -- �z���m��
          lv_request_no            := NULL ;  -- �ړ��m��
--
          FETCH lc_ref INTO lr_ref ;
          EXIT WHEN lc_ref%NOTFOUND ;
--
        END LOOP dtl_data_loop ;
        -- ====================================================
        -- �J�[�\���N���[�Y
        -- ====================================================
        CLOSE lc_ref ;
--
        -- ���X�g�O���[�v�I���^�O�i���ׁj
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �O���[�v�I���^�O�o��
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_spto' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      ELSE
        -- ====================================================
        -- �J�[�\���N���[�Y
        -- ====================================================
        CLOSE lc_ref ;
      END IF;
--
    END LOOP mst_data_loop ;
--
    -- ====================================================
    -- �O���[�v�I���^�O�o��
    -- ====================================================
    -- ���X�g�O���[�v�I���^�O�i�o�ɏ��j
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_spmt_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �O���[�v�I���^�O�i���ɑq�Ɂj
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_lctn' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- ���X�g�O���[�v�I���^�O�i���ɑq�Ɂj
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_lctn_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- �A�E�g�p�����[�^�Z�b�g
    -- ====================================================
    ov_errbuf  := lv_errbuf ;     --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode := lv_retcode ;    --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg  := lv_errmsg ;     --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_out_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_ins_temp_data
   * Description      : ���ԃe�[�u���o�^
   ************************************************************************************************/
  PROCEDURE prc_ins_temp_data
    (
      ov_errbuf     OUT    VARCHAR2             -- �G���[�E���b�Z�[�W
     ,ov_retcode    OUT    VARCHAR2             -- ���^�[���E�R�[�h
     ,ov_errmsg     OUT    VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'prc_ins_temp_data' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- ���ԃe�[�u��������
    -- ====================================================
    DELETE FROM xxwsh_930d_tmp;
    --
    -- ====================================================
    -- ���ԃe�[�u���o�^
    -- ====================================================
    FORALL i IN 1 .. gt_arvl_code_tbl.COUNT
      INSERT INTO xxwsh_930d_tmp
        ( arvl_code                     -- ���ɑq�ɃR�[�h
         ,arvl_name                     -- ���ɑq�ɖ���
         ,location_code                 -- �o�ɑq�ɃR�[�h
         ,location_name                 -- �o�ɑq�ɖ���
         ,ship_date                     -- �o�ɓ�
         ,arvl_date                     -- ���ɓ�
         ,career_code                   -- �^���Ǝ҃R�[�h
         ,career_name                   -- �^���ƎҖ���
         ,ship_method_code              -- �z���敪�R�[�h
         ,ship_method_name              -- �z���敪����
         ,delivery_no                   -- �z���m��
         ,request_no                    -- �ړ��m��
         ,item_code                     -- �i�ڃR�[�h
         ,item_name                     -- �i�ږ���
         ,lot_no                        -- ���b�g�ԍ�
         ,product_date                  -- ������
         ,use_by_date                   -- �ܖ�����
         ,original_char                 -- �ŗL�L��
         ,lot_status                    -- �i��
         ,quant_r                       -- �˗���
         ,quant_i                       -- ���ɐ�
         ,quant_o                       -- �o�ɐ�
         ,reason                        -- ���َ��R
         ,created_by                    -- �쐬��
         ,creation_date                 -- �쐬��
         ,last_updated_by               -- �ŏI�X�V��
         ,last_update_date              -- �ŏI�X�V��
         ,last_update_login             -- �ŏI�X�V���O�C��
         ,request_id                    -- �v��ID
         ,program_application_id        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id                    -- �R���J�����g�E�v���O����ID
         ,program_update_date           -- �v���O�����X�V��
        )
      VALUES
        (
          SUBSTRB( gt_arvl_code_tbl(i)        , 1, 4  )  -- ���ɑq�ɃR�[�h
         ,SUBSTRB( gt_arvl_name_tbl(i)        , 1, 20 )  -- ���ɑq�ɖ���
         ,SUBSTRB( gt_location_code_tbl(i)    , 1, 4  )  -- �o�ɑq�ɃR�[�h
         ,SUBSTRB( gt_location_name_tbl(i)    , 1, 20 )  -- �o�ɑq�ɖ���
         ,gt_ship_date_tbl(i)                            -- �o�ɓ�
         ,gt_arvl_date_tbl(i)                            -- ���ɓ�
         ,SUBSTRB( gt_career_code_tbl(i)      , 1, 4  )  -- �^���Ǝ҃R�[�h
         ,SUBSTRB( gt_career_name_tbl(i) , 1, 20 )       -- �^���ƎҖ���
         ,SUBSTRB( gt_ship_method_code_tbl(i) , 1, 2  )  -- �z���敪�R�[�h
         ,SUBSTRB( gt_ship_method_name_tbl(i) , 1, 14 )  -- �z���敪����
         ,SUBSTRB( gt_delivery_no_tbl(i)      , 1, 12 )  -- �z���m��
         ,SUBSTRB( gt_request_no_tbl(i)       , 1, 12 )  -- �ړ��m��
         ,SUBSTRB( gt_item_code_tbl(i)        , 1, 7  )  -- �i�ڃR�[�h
         ,SUBSTRB( gt_item_name_tbl(i)        , 1, 20 )  -- �i�ږ���
         ,SUBSTRB( gt_lot_ctl_tbl(i)          , 1, 10 )  -- ���b�g�ԍ�
         ,gt_product_date_tbl(i)                         -- ������
         ,gt_use_by_date_tbl(i)                          -- �ܖ�����
         ,SUBSTRB( gt_original_char_tbl(i)    , 1, 6  )  -- �ŗL�L��
         ,SUBSTRB( gt_meaning_tbl(i)          , 1, 10 )  -- �i��
         ,SUBSTRB( gt_quant_r_tbl(i)          , 1, 12 )  -- �˗���
         ,SUBSTRB( gt_quant_i_tbl(i)          , 1, 12 )  -- ���ɐ�
         ,SUBSTRB( gt_quant_o_tbl(i)          , 1, 12 )  -- �o�ɐ�
         ,SUBSTRB( gt_reason_tbl(i)           , 1, 6  )  -- ���َ��R
         ,gn_created_by               -- �쐬��
         ,SYSDATE                     -- �쐬��
         ,gn_last_updated_by          -- �ŏI�X�V��
         ,SYSDATE                     -- �ŏI�X�V��
         ,gn_last_update_login        -- �ŏI�X�V���O�C��
         ,gn_request_id               -- �v��ID
         ,gn_program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,gn_program_id               -- �R���J�����g�E�v���O����ID
         ,SYSDATE                     -- �v���O�����X�V��
        ) ;
--
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_ins_temp_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_set_temp_data
   * Description      : ���ԃe�[�u���o�^�f�[�^�ݒ�
   ************************************************************************************************/
  PROCEDURE prc_set_temp_data
    (
      ir_get_data   IN    rec_get_data        -- ���o�f�[�^
     ,or_temp_tab   OUT   rec_temp_tab_data   -- ���ԃe�[�u���o�^�f�[�^
     ,ov_errbuf     OUT   VARCHAR2            -- �G���[�E���b�Z�[�W
     ,ov_retcode    OUT   VARCHAR2            -- ���^�[���E�R�[�h
     ,ov_errmsg     OUT   VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'prc_set_temp_data' ; -- �v���O������
--
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    lv_reserved_status  xxwsh_shipping_lines_if.reserved_status%TYPE ;   -- �ۗ��X�e�[�^�X
--
    ln_temp_cnt         NUMBER DEFAULT 0 ;   -- �擾���R�[�h�J�E���g
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
--
    --------------------------------------------------
    -- ���ɑq�ɐݒ�
    --------------------------------------------------
    or_temp_tab.arvl_code := ir_get_data.arvl_code ;  -- ���ɑq�ɃR�[�h
    or_temp_tab.arvl_name := ir_get_data.arvl_name ;  -- ���ɑq�ɖ���
    --------------------------------------------------
    -- �o�ɑq�ɐݒ�
    --------------------------------------------------
    or_temp_tab.location_code := ir_get_data.location_code ;  -- �o�ɑq�ɃR�[�h
    or_temp_tab.location_name := ir_get_data.location_name ;  -- �o�ɑq�ɖ���
--
    --------------------------------------------------
    -- �o�ɓ��E���ɓ��ݒ�
    --------------------------------------------------
    or_temp_tab.ship_date := ir_get_data.ship_date ;  -- �o�ɓ�
    or_temp_tab.arvl_date := ir_get_data.arvl_date ;  -- ���ɓ�
--
    --------------------------------------------------
    -- �^���ƎҐݒ�
    --------------------------------------------------
    BEGIN
      -- �ۗ��f�[�^�̏ꍇ
      IF ( ir_get_data.status IS NULL ) THEN
        SELECT xc.party_number
              ,xc.party_short_name
        INTO   or_temp_tab.career_code  -- �^���Ǝ҃R�[�h
              ,or_temp_tab.career_name  -- �^���ƎҖ���
        FROM xxcmn_carriers2_v  xc      -- �^���Ǝҏ��VIEW2
        WHERE gr_param.date_from BETWEEN xc.start_date_active AND xc.end_date_active
        AND   xc.party_number     = ir_get_data.career_id
        ;
     -- �ۗ��f�[�^�ȊO�̏ꍇ
      ELSE
        SELECT xc.party_number
              ,xc.party_short_name
        INTO   or_temp_tab.career_code  -- �^���Ǝ҃R�[�h
              ,or_temp_tab.career_name  -- �^���ƎҖ���
        FROM xxcmn_carriers2_v  xc      -- �^���Ǝҏ��VIEW2
        WHERE gr_param.date_from BETWEEN xc.start_date_active AND xc.end_date_active
        AND   xc.party_id        = ir_get_data.career_id
        ;
     END IF ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        or_temp_tab.career_code := NULL ;
        or_temp_tab.career_name := NULL ;
      WHEN TOO_MANY_ROWS THEN
        or_temp_tab.career_code := NULL ;
        or_temp_tab.career_name := NULL ;
    END ;
--
    --------------------------------------------------
    -- �z���敪�ݒ�
    --------------------------------------------------
    BEGIN
      SELECT xlv.lookup_code
            ,xlv.meaning
      INTO   or_temp_tab.ship_method_code   -- �z���敪�R�[�h
            ,or_temp_tab.ship_method_name   -- �z���敪����
      FROM xxcmn_lookup_values_v   xlv   -- �N�C�b�N�R�[�h���VIEW
      WHERE xlv.lookup_type = gc_lookup_ship_method_code
      AND   xlv.lookup_code = ir_get_data.ship_method_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        or_temp_tab.ship_method_code := NULL ;
        or_temp_tab.ship_method_name := NULL ;
      WHEN TOO_MANY_ROWS THEN
        or_temp_tab.ship_method_code := NULL ;
        or_temp_tab.ship_method_name := NULL ;
    END ;
--
    --------------------------------------------------
    -- �z���m���E�ړ��m���ݒ�
    --------------------------------------------------
    or_temp_tab.delivery_no := ir_get_data.delivery_no ;  -- �z���m��
    or_temp_tab.request_no  := ir_get_data.request_no ;   -- �ړ��m��
--
    --------------------------------------------------
    -- �i�ڐݒ�
    --------------------------------------------------
    or_temp_tab.item_code := ir_get_data.item_code ;  -- �i�ڃR�[�h
    or_temp_tab.item_name := ir_get_data.item_name ;  -- �i�ږ���
--
    --------------------------------------------------
    -- ���b�g���ݒ�
    --------------------------------------------------
    -- ���b�g�Ǘ��i�ȊO�̏ꍇ
    IF ( ir_get_data.lot_ctl = gc_lot_ctl_n ) THEN
--
      or_temp_tab.lot_no        := NULL ;                 -- ���b�g�ԍ�
      or_temp_tab.product_date  := NULL ;                 -- ������
      or_temp_tab.use_by_date   := NULL ;                 -- �ܖ�����
      or_temp_tab.original_char := NULL ;                 -- �ŗL�L��
      or_temp_tab.lot_status    := NULL ;                 -- �i��
      or_temp_tab.quant_r       := ir_get_data.quant_r ;  -- �˗���
      or_temp_tab.quant_i       := ir_get_data.quant_i ;  -- ���ɐ�
      or_temp_tab.quant_o       := ir_get_data.quant_o ;  -- �o�ɐ�
--
    -- ���b�g�Ǘ��i�̏ꍇ
    ELSIF ( ir_get_data.lot_ctl = gc_lot_ctl_y ) THEN
--
      -- ���b�g���擾
      BEGIN
        SELECT ilm.lot_no                                    -- ���b�g�ԍ�
              ,FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )  -- ������
              ,ilm.attribute2                                -- �ŗL�L��
              ,FND_DATE.CANONICAL_TO_DATE( ilm.attribute3 )  -- �ܖ�����
              ,xlv.meaning                                   -- �i��
              ,SUM( CASE
                      WHEN (xmld.record_type_code = gc_rec_type_inst) THEN xmld.actual_quantity
                      ELSE 0
                    END )                                    -- �˗���
              ,SUM( CASE
                      WHEN (xmld.record_type_code = gc_rec_type_dlvr) THEN xmld.actual_quantity
                      ELSE 0
                    END )                                    -- ���ɐ�
              ,SUM( CASE
                      WHEN (xmld.record_type_code = gc_rec_type_stck) THEN xmld.actual_quantity
                      ELSE 0
                    END )                                    -- �o�ɐ�
        INTO   or_temp_tab.lot_no                            -- ���b�g�ԍ�
              ,or_temp_tab.product_date                      -- ������
              ,or_temp_tab.original_char                     -- �ŗL�L��
              ,or_temp_tab.use_by_date                       -- �ܖ�����
              ,or_temp_tab.lot_status                        -- �i��
              ,or_temp_tab.quant_r                           -- �˗���
              ,or_temp_tab.quant_i                           -- ���ɐ�
              ,or_temp_tab.quant_o                           -- �o�ɐ�
        FROM ic_lots_mst              ilm                    -- OPM���b�g�}�X�^
            ,xxinv_mov_lot_details    xmld                   -- �ړ����b�g�ڍ׃A�h�I��
            ,xxcmn_lookup_values_v    xlv                    -- �N�C�b�N�R�[�h���VIEW
        WHERE xlv.lookup_type         = gc_lookup_lot_status
        AND   ilm.attribute23         = xlv.lookup_code
        AND   xmld.actual_date        BETWEEN gr_param.date_from
                                      AND     NVL( gr_param.date_to, xmld.actual_date )
        AND   xmld.document_type_code = gc_doc_type_move -- �o�׎x���敪�i�ړ��j
        AND   xmld.mov_line_id        = ir_get_data.order_line_id
        AND   ilm.lot_id              = xmld.lot_id
        AND   ilm.item_id             = xmld.item_id
        AND   ilm.item_id             = ir_get_data.item_id
        GROUP BY ilm.lot_no
                ,ilm.attribute1
                ,ilm.attribute2
                ,ilm.attribute3
                ,xlv.meaning
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          or_temp_tab.lot_no        := NULL ;  -- ���b�g�ԍ�
          or_temp_tab.product_date  := NULL ;  -- ������
          or_temp_tab.use_by_date   := NULL ;  -- �ŗL�L��
          or_temp_tab.original_char := NULL ;  -- �ܖ�����
          or_temp_tab.lot_status    := NULL ;  -- �i��
          or_temp_tab.quant_r       := 0 ;     -- �˗���
          or_temp_tab.quant_i       := 0 ;     -- ���ɐ�
          or_temp_tab.quant_o       := 0 ;     -- �o�ɐ�
        WHEN TOO_MANY_ROWS THEN
          or_temp_tab.lot_no        := NULL ;  -- ���b�g�ԍ�
          or_temp_tab.product_date  := NULL ;  -- ������
          or_temp_tab.use_by_date   := NULL ;  -- �ŗL�L��
          or_temp_tab.original_char := NULL ;  -- �ܖ�����
          or_temp_tab.lot_status    := NULL ;  -- �i��
          or_temp_tab.quant_r       := 0 ;     -- �˗���
          or_temp_tab.quant_i       := 0 ;     -- ���ɐ�
          or_temp_tab.quant_o       := 0 ;     -- �o�ɐ�
      END ;
--
    END IF ;
--
    --------------------------------------------------
    -- ���َ��R�ݒ�
    --------------------------------------------------
    -- �ۗ��X�e�[�^�X
   BEGIN
      SELECT DISTINCT  xsli.reserved_status
      INTO   lv_reserved_status
      FROM xxwsh_shipping_headers_if  xshi      -- �o�׈˗��C���^�t�F�[�X�w�b�_�A�h�I��
          ,xxwsh_shipping_lines_if    xsli      -- �o�׈˗��C���^�t�F�[�X���׃A�h�I��
      WHERE xshi.header_id        = xsli.header_id
      AND   xshi.delivery_no      = ir_get_data.delivery_no   -- �z���m��
      AND   xshi.order_source_ref = ir_get_data.request_no    -- �ړ��m��
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
       lv_reserved_status := NULL ;
      WHEN TOO_MANY_ROWS THEN
       lv_reserved_status := NULL ;
    END ;
--
    ------------------------------
    -- �ۗ��X�e�[�^�X�F�u�ۗ��v
    ------------------------------
    IF ( lv_reserved_status = gc_reserved_status_y ) THEN
--
      or_temp_tab.quant_r       := ir_get_data.quant_r ;  -- �˗���
      or_temp_tab.quant_i       := ir_get_data.quant_i ;  -- ���ɐ�
      or_temp_tab.quant_o       := ir_get_data.quant_o ;  -- �o�ɐ�
--
      -- ���b�g���擾
      BEGIN
        SELECT xsli.lot_no
              ,xsli.designated_production_date
              ,xsli.use_by_date
              ,xsli.original_character
              ,NULL
        INTO   or_temp_tab.lot_no                 -- ���b�g�ԍ�
              ,or_temp_tab.product_date           -- ������
              ,or_temp_tab.use_by_date            -- �ܖ�����
              ,or_temp_tab.original_char          -- �ŗL�L��
              ,or_temp_tab.lot_status             -- �i��
        FROM xxwsh_shipping_headers_if  xshi      -- �o�׈˗��C���^�t�F�[�X�w�b�_�A�h�I��
            ,xxwsh_shipping_lines_if    xsli      -- �o�׈˗��C���^�t�F�[�X���׃A�h�I��
        WHERE xsli.line_id          = ir_get_data.order_line_id
        AND   xshi.header_id        = xsli.header_id
        AND   xshi.delivery_no      = ir_get_data.delivery_no   -- �z���m��
        AND   xshi.order_source_ref = ir_get_data.request_no    -- �ړ��m��
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          or_temp_tab.lot_no        := NULL ; -- ���b�g�ԍ�
          or_temp_tab.product_date  := NULL ; -- ������
          or_temp_tab.use_by_date   := NULL ; -- �ܖ�����
          or_temp_tab.original_char := NULL ; -- �ŗL�L��
          or_temp_tab.lot_status    := NULL ; -- �i��
        WHEN TOO_MANY_ROWS THEN
          or_temp_tab.lot_no        := NULL ; -- ���b�g�ԍ�
          or_temp_tab.product_date  := NULL ; -- ������
          or_temp_tab.use_by_date   := NULL ; -- �ܖ�����
          or_temp_tab.original_char := NULL ; -- �ŗL�L��
          or_temp_tab.lot_status    := NULL ; -- �i��
      END ;
--
      or_temp_tab.reason := gc_reason_rsrv ;  -- �ۗ�
--
    ELSE
      ------------------------------
      -- �˗��ρE�������̏ꍇ
      ------------------------------
      IF ( ir_get_data.status IN( gc_mov_status_cmp             -- �˗���
                                 ,gc_mov_status_adj ) ) THEN    -- ������
        ------------------------------
        -- �w����������т������ꍇ
        ------------------------------
        IF (   ( or_temp_tab.quant_r > 0 )
           AND ( or_temp_tab.quant_o = 0 ) ) THEN
--
          or_temp_tab.reason        := gc_reason_nrep ;     -- ����
--
        END IF ;
--
      ------------------------------
      -- �˗��ρE�������ȊO�̏ꍇ
      ------------------------------
      ELSE
        ------------------------------
        -- �w�b�_�[���x���̃`�F�b�N
        ------------------------------
        -- �w���Ǝ��т̈قȂ郌�R�[�h���擾����
        SELECT COUNT( xmrih.mov_hdr_id )
        INTO   ln_temp_cnt
        FROM   xxinv_mov_req_instr_headers    xmrih   -- �ړ��˗�/�w���w�b�_�A�h�I��
        WHERE (  xmrih.career_id             <> xmrih.actual_career_id                -- �^���Ǝ�
              OR xmrih.shipping_method_code  <> xmrih.actual_shipping_method_code     -- �z���敪
              OR xmrih.schedule_ship_date    <> xmrih.actual_ship_date                -- �o�ד�
              OR xmrih.schedule_arrival_date <> xmrih.actual_arrival_date         )   -- ���ד�
        AND   xmrih.mov_num                   = or_temp_tab.request_no  -- �ړ��m��
        ;
        ------------------------------
        -- �w���Ǝ��т��قȂ�ꍇ
        ------------------------------
        IF ( ln_temp_cnt > 0 ) THEN
--
          -- ���ɕ񍐗L�̏ꍇ
          IF ( ir_get_data.status = gc_mov_status_stc ) THEN
            or_temp_tab.reason := gc_reason_ndel ;  -- 
--
          -- �o�ɕ񍐗L�̏ꍇ
          ELSIF ( ir_get_data.status = gc_mov_status_del ) THEN
            or_temp_tab.reason := gc_reason_nstc ;  -- ���ɖ�
--
          -- ���o�ɕ񍐗L�̏ꍇ
          ELSIF ( ir_get_data.status = gc_mov_status_dsr ) THEN
            or_temp_tab.reason := gc_reason_iodf ;  -- �o����
--
          END IF ;
--
        ------------------------------
        -- �w���Ǝ��т��̏ꍇ
        ------------------------------
        ELSE
          ------------------------------
          -- ���ɕ񍐗L�̏ꍇ
          ------------------------------
          IF ( ir_get_data.status = gc_mov_status_stc ) THEN
            -- �˗����Ɠ��ɐ��������ꍇ
            IF ( or_temp_tab.quant_r = or_temp_tab.quant_i ) THEN
              or_temp_tab.reason        := NULL ;               -- ���قȂ�
--
            -- �˗����Ɠ��ɐ����قȂ�ꍇ
            ELSE
              or_temp_tab.reason := gc_reason_ndel ;  -- �o�ɖ�
--
            END IF ;
--
          ------------------------------
          -- �o�ɕ񍐗L�̏ꍇ
          ------------------------------
          ELSIF ( ir_get_data.status = gc_mov_status_del ) THEN
            -- �˗����Əo�ɐ��������ꍇ
            IF ( or_temp_tab.quant_r = or_temp_tab.quant_o ) THEN
              or_temp_tab.reason        := NULL ;               -- ���قȂ�
--
            -- �˗����Əo�ɐ����قȂ�ꍇ
            ELSE
              or_temp_tab.reason := gc_reason_nstc ;  -- ���ɖ�
--
            END IF ;
--
          ------------------------------
          -- ���o�ɕ񍐗L�̏ꍇ
          ------------------------------
          ELSIF ( ir_get_data.status = gc_mov_status_dsr ) THEN
            ------------------------------
            -- ���ɐ��Əo�ɐ����قȂ�ꍇ
            ------------------------------
            IF ( or_temp_tab.quant_i <> or_temp_tab.quant_o ) THEN
              or_temp_tab.reason        := gc_reason_iodf ;     -- �o����
--
            ------------------------------
            -- ���ɐ��Əo�ɐ�������̏ꍇ
            ------------------------------
            ELSE
              ------------------------------
              -- �˗����Ɠ��ɐ����قȂ� or
              -- �˗����Əo�ɐ����قȂ�ꍇ
              ------------------------------
              IF (  ( or_temp_tab.quant_r <> or_temp_tab.quant_i )
                 OR ( or_temp_tab.quant_r <> or_temp_tab.quant_o ) ) THEN
                or_temp_tab.reason := gc_reason_diff ;  -- �˗���
--
              ------------------------------
              -- ��L�ȊO�̏ꍇ
              ------------------------------
              ELSE
                or_temp_tab.reason        := NULL ;               -- ���قȂ�
--
              END IF ;
--
            END IF ;
--
          END IF ;
--
        END IF ;
--
      END IF ;
--
    END IF ;
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_set_temp_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_move_data
   * Description      : �ړ��f�[�^���o����
   ************************************************************************************************/
  PROCEDURE prc_create_move_data
    (
      ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'prc_create_move_data' ; -- �v���O������
--
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    lr_get_data       rec_get_data ;        -- ���o�f�[�^�i�[�p���R�[�h�ϐ�
    lr_temp_tab       rec_temp_tab_data ;   -- ���ԃe�[�u���o�^�p���R�[�h�ϐ�
    lv_data_count     NUMBER DEFAULT 0 ;    -- �J�E���g�p�ϐ�
--
    -- ==================================================
    -- �J  �[  �\  ��  ��  ��
    -- ==================================================
    -- �w���E���уf�[�^�擾�J�[�\��
    CURSOR cu_main
    IS
      SELECT xmrih.ship_to_locat_code     AS arvl_code            -- ���ɑq�ɃR�[�h
            ,xil.description              AS arvl_name            -- ���ɑq�ɖ���
            ,xil.segment1                 AS location_code        -- �o�ɑq�ɃR�[�h
            ,xil.description              AS location_name        -- �o�ɑq�ɖ���
            ,xmrih.schedule_ship_date     AS ship_date            -- �o�ɓ�
            ,xmrih.schedule_arrival_date  AS arvl_date            -- ���ɓ�
            ,xmrih.career_id              AS career_id            -- ���������F�^���Ǝ�
            ,xmrih.shipping_method_code   AS ship_method_code     -- ���������F�z���敪
            ,xmrih.delivery_no            AS delivery_no          -- �z���m��
            ,xmrih.mov_num                AS request_no           -- �ړ��m��
            ,xmril.mov_line_id            AS order_line_id        -- ���������F���ׂh�c
            ,ximv.item_id                 AS item_id              -- ���������F�i�ڂh�c
            ,ximv.item_no                 AS item_code            -- �i�ڃR�[�h
            ,ximv.item_short_name         AS item_name            -- �i�ږ���
            ,ximv.lot_ctl                 AS lot_ctl              -- ���������F���b�g�g�p
            ,NVL( xmril.instruct_qty    , 0 )   AS quant_r        -- �˗����i���b�g�Ǘ��O�j
            ,NVL( xmril.ship_to_quantity, 0 )   AS quant_i        -- ���ɐ��i���b�g�Ǘ��O�j
            ,NVL( xmril.shipped_quantity, 0 )   AS quant_o        -- �o�ɐ��i���b�g�Ǘ��O�j
            ,xmrih.status                 AS status               -- �w�b�_�X�e�[�^�X
      FROM xxinv_mov_req_instr_headers    xmrih   -- �ړ��˗�/�w���w�b�_�A�h�I��
          ,xxinv_mov_req_instr_lines      xmril   -- �ړ��˗�/�w�����׃A�h�I��
          ,xxcmn_item_locations2_v        xil     -- �n�o�l�ۊǏꏊ�}�X�^
          ,xxcmn_item_mst2_v              ximv    -- �n�o�l�i�ڏ��VIEW2
          ,xxcmn_item_categories4_v       xicv    -- �n�o�l�i�ڃJ�e�S���������VIEW4
      WHERE
      ----------------------------------------------------------------------------------------------
      -- �n�o�l�i��
      ----------------------------------------------------------------------------------------------
      -- �p�����[�^�����D���i�敪
            xicv.prod_class_code    = NVL( gr_param.prod_div, xicv.prod_class_code )
      -- �p�����[�^�����D�i�ڋ敪
      AND   xicv.item_class_code    = gr_param.item_div
      AND   ximv.item_id            = xicv.item_id
      AND   gr_param.date_from      BETWEEN ximv.start_date_active
                                    AND     NVL( ximv.end_date_active, gr_param.date_from )
      AND   xmril.item_id           = ximv.item_id
      ----------------------------------------------------------------------------------------------
      -- �ړ��˗��w�����׃A�h�I��
      ----------------------------------------------------------------------------------------------
      AND   NVL( xmril.delete_flg, gc_yn_div_n ) = gc_yn_div_n          -- ���폜
      AND   xmrih.mov_hdr_id        = xmril.mov_hdr_id
      ----------------------------------------------------------------------------------------------
      -- �n�o�l�ۊǏꏊ
      ----------------------------------------------------------------------------------------------
      -- �p�����[�^�����D���ɐ�
      AND   xil.segment1            = NVL( gr_param.ship_to_locat_code, xil.segment1 )
      -- �p�����[�^�����D�u���b�N�P�E�Q�E�R
      AND   (  gr_param.block_01      IS NULL
            OR xil.distribution_block = gr_param.block_01 )
      AND   (  gr_param.block_02      IS NULL
            OR xil.distribution_block = gr_param.block_02 )
      AND   (  gr_param.block_03      IS NULL
            OR xil.distribution_block = gr_param.block_03 )
      -- �p�����[�^�����D�I�����C���敪
      AND   xil.eos_control_type   = NVL( gr_param.online_type, xil.eos_control_type )
      AND   xmrih.shipped_locat_id = xil.inventory_location_id
      ----------------------------------------------------------------------------------------------
      -- �ړ��˗��w���w�b�_�A�h�I��
      ----------------------------------------------------------------------------------------------
      AND   xmrih.status              IN( gc_mov_status_cmp       -- �˗���
                                         ,gc_mov_status_adj       -- ������
                                         ,gc_mov_status_del       -- �o�ɕ񍐗L
                                         ,gc_mov_status_stc       -- ���ɕ񍐗L
                                         ,gc_mov_status_dsr )     -- ���o�ɕ񍐗L
      AND   xmrih.mov_type              = gc_mov_type_y           -- �ϑ�����
      -- �p�����[�^�����D�w������
      AND   xmrih.instruction_post_code = NVL( gr_param.dept_code, xmrih.instruction_post_code )
      -- �p�����[�^�����D�ړ��m��
      AND   xmrih.mov_num               = NVL( gr_param.request_no, xmrih.mov_num )
      -- �p�����[�^�����D�o�ɓ�FromTo
      AND   xmrih.schedule_ship_date    BETWEEN gr_param.date_from
                                        AND     NVL( gr_param.date_to, xmrih.schedule_ship_date )
      UNION
      SELECT xmrih.ship_to_locat_code           AS arvl_code            -- ���ɑq�ɃR�[�h
            ,xil.description                    AS arvl_name            -- ���ɑq�ɖ���
            ,xil.segment1                       AS location_code        -- �o�ɑq�ɃR�[�h
            ,xil.description                    AS location_name        -- �o�ɑq�ɖ���
            ,NVL( xmrih.actual_ship_date
                 ,xmrih.schedule_ship_date )    AS ship_date            -- �o�ɓ�
            ,NVL( xmrih.actual_arrival_date
                 ,xmrih.schedule_arrival_date ) AS arvl_date            -- ���ɓ�
            ,NVL( xmrih.actual_career_id
                 ,xmrih.career_id )             AS career_id            -- ���������F�^���Ǝ�
            ,NVL( xmrih.actual_shipping_method_code
                 ,xmrih.shipping_method_code )  AS ship_method_code     -- ���������F�z���敪
            ,xmrih.delivery_no                  AS delivery_no          -- �z���m��
            ,xmrih.mov_num                      AS request_no           -- �ړ��m��
            ,xmril.mov_line_id                  AS order_line_id        -- ���������F���ׂh�c
            ,ximv.item_id                       AS item_id              -- ���������F�i�ڂh�c
            ,ximv.item_no                       AS item_code            -- �i�ڃR�[�h
            ,ximv.item_short_name               AS item_name            -- �i�ږ���
            ,ximv.lot_ctl                       AS lot_ctl              -- ���������F���b�g�g�p
            ,NVL( xmril.instruct_qty    , 0 )   AS quant_r              -- �˗����i���b�g�Ǘ��O�j
            ,NVL( xmril.ship_to_quantity, 0 )   AS quant_i              -- ���ɐ��i���b�g�Ǘ��O�j
            ,NVL( xmril.shipped_quantity, 0 )   AS quant_o              -- �o�ɐ��i���b�g�Ǘ��O�j
            ,xmrih.status                       AS status               -- �w�b�_�X�e�[�^�X
      FROM xxinv_mov_req_instr_headers    xmrih   -- �ړ��˗�/�w���w�b�_�A�h�I��
          ,xxinv_mov_req_instr_lines      xmril   -- �ړ��˗�/�w�����׃A�h�I��
          ,xxcmn_item_locations2_v        xil-- �n�o�l�ۊǏꏊ�}�X�^
          ,xxcmn_item_mst2_v              ximv    -- �n�o�l�i�ڏ��VIEW2
          ,xxcmn_item_categories4_v       xicv    -- �n�o�l�i�ڃJ�e�S���������VIEW4
      WHERE
      ----------------------------------------------------------------------------------------------
      -- �n�o�l�i��
      ----------------------------------------------------------------------------------------------
      -- �p�����[�^�����D���i�敪
            xicv.prod_class_code    = NVL( gr_param.prod_div, xicv.prod_class_code )
      -- �p�����[�^�����D�i�ڋ敪
      AND   xicv.item_class_code    = NVL( gr_param.item_div, xicv.prod_class_code )
      AND   ximv.item_id            = xicv.item_id
      AND   gr_param.date_from      BETWEEN ximv.start_date_active
                                    AND     NVL( ximv.end_date_active, gr_param.date_from )
      AND   xmril.item_id           = ximv.item_id
      ----------------------------------------------------------------------------------------------
      -- �ړ��˗��w�����׃A�h�I��
      ----------------------------------------------------------------------------------------------
      AND   NVL( xmril.delete_flg, gc_yn_div_n ) = gc_yn_div_n          -- ���폜
      AND   xmrih.mov_hdr_id        = xmril.mov_hdr_id
      ----------------------------------------------------------------------------------------------
      -- �n�o�l�ۊǏꏊ
      ----------------------------------------------------------------------------------------------
      -- �p�����[�^�����D���ɐ�
      AND   xil.segment1            = NVL( gr_param.ship_to_locat_code, xil.segment1 )
      -- �p�����[�^�����D�u���b�N�P�E�Q�E�R
      AND   (  gr_param.block_01      IS NULL
            OR xil.distribution_block = gr_param.block_01 )
      AND   (  gr_param.block_02      IS NULL
            OR xil.distribution_block = gr_param.block_02 )
      AND   (  gr_param.block_03      IS NULL
            OR xil.distribution_block = gr_param.block_03 )
      -- �p�����[�^�����D�I�����C���敪
      AND   xil.eos_control_type   = NVL( gr_param.online_type, xil.eos_control_type )
      AND   xmrih.shipped_locat_id = xil.inventory_location_id
      ----------------------------------------------------------------------------------------------
      -- �ړ��˗��w���w�b�_�A�h�I��
      ----------------------------------------------------------------------------------------------
      AND   xmrih.status              IN( gc_mov_status_cmp       -- �˗���
                                         ,gc_mov_status_adj       -- ������
                                         ,gc_mov_status_del       -- �o�ɕ񍐗L
                                         ,gc_mov_status_stc       -- ���ɕ񍐗L
                                         ,gc_mov_status_dsr )     -- ���o�ɕ񍐗L
      AND   xmrih.mov_type              = gc_mov_type_y
      -- �p�����[�^�����D�w������
      AND   xmrih.instruction_post_code = NVL( gr_param.dept_code, xmrih.instruction_post_code )
      -- �p�����[�^�����D�ړ��m��
      AND   xmrih.mov_num               = NVL( gr_param.request_no, xmrih.mov_num )
      -- �p�����[�^�����D�o�ɓ�FromTo
      AND   xmrih.schedule_ship_date    BETWEEN gr_param.date_from
                                        AND     NVL( gr_param.date_to, xmrih.schedule_ship_date )
    ;
    -- �ۗ��f�[�^�擾
    CURSOR cu_reserv
    IS
      SELECT xshi.party_site_code             AS arvl_code        -- ���ɑq�ɃR�[�h
            ,xil.description                  AS arvl_name        -- ���ɑq�ɖ���
            ,xil.segment1                     AS location_code    -- �o�ɑq�ɃR�[�h
            ,xil.description                  AS location_name    -- �o�ɑq�ɖ���
            ,xshi.shipped_date                AS ship_date        -- �o�ɓ�
            ,xshi.arrival_date                AS arvl_date        -- ���ɓ�
            ,xshi.freight_carrier_code        AS career_id        -- ���������F�^���Ǝ�
            ,xshi.shipping_method_code        AS ship_method_code -- ���������F�z���敪
            ,xshi.delivery_no                 AS delivery_no      -- �z���m��
            ,xshi.order_source_ref            AS request_no       -- �ړ��m��
            ,xsli.line_id                     AS order_line_id    -- ���������F���ׂh�c
            ,ximv.item_id                     AS item_id          -- ���������F�i�ڂh�c
            ,ximv.item_no                     AS item_code        -- �i�ڃR�[�h
            ,ximv.item_short_name             AS item_name        -- �i�ږ���
            ,ximv.lot_ctl                     AS lot_ctl          -- ���������F���b�g�g�p
            ,xsli.orderd_quantity             AS quant_r          -- �˗���
            ,xsli.ship_to_quantity            AS quant_i          -- ���ɐ�
            ,xsli.shiped_quantity             AS quant_o          -- �o�ɐ�
            ,NULL                             AS status           -- �w�b�_�X�e�[�^�X
      FROM xxwsh_shipping_headers_if  xshi      -- �o�׈˗��C���^�t�F�[�X�w�b�_�A�h�I��
          ,xxwsh_shipping_lines_if    xsli      -- �o�׈˗��C���^�t�F�[�X���׃A�h�I��
          ,xxcmn_item_locations2_v    xil       -- �n�o�l�ۊǏꏊ�}�X�^
          ,xxcmn_item_mst2_v          ximv      -- �n�o�l�i�ڏ��VIEW2
          ,xxcmn_item_categories4_v   xicv      -- �n�o�l�i�ڃJ�e�S���������VIEW4
      WHERE
      ----------------------------------------------------------------------------------------------
      -- �n�o�l�i��
      ----------------------------------------------------------------------------------------------
      -- �p�����[�^�����D���i�敪
            xicv.prod_class_code    = NVL( gr_param.prod_div, xicv.prod_class_code )
      -- �p�����[�^�����D�i�ڋ敪
      AND   xicv.item_class_code    = NVL( gr_param.item_div, xicv.prod_class_code )
      AND   ximv.item_id                = xicv.item_id
      AND   gr_param.date_from      BETWEEN ximv.start_date_active
                                    AND     NVL( ximv.end_date_active, gr_param.date_from )
      AND   xsli.orderd_item_code       = ximv.item_no
      ----------------------------------------------------------------------------------------------
      -- �h�e����
      ----------------------------------------------------------------------------------------------
      AND   xsli.reserved_status  = gc_reserved_status_y        -- �ۗ��X�e�[�^�X = �ۗ�
      AND   xshi.header_id        = xsli.header_id
      ----------------------------------------------------------------------------------------------
      -- �n�o�l�ۊǏꏊ
      ----------------------------------------------------------------------------------------------
      -- �p�����[�^�����D���ɐ�
      AND   xil.segment1          = NVL( gr_param.ship_to_locat_code, xil.segment1 )
      -- �p�����[�^�����D�u���b�N�P�E�Q�E�R
      AND   (  gr_param.block_01      IS NULL
            OR xil.distribution_block = gr_param.block_01 )
      AND   (  gr_param.block_02      IS NULL
            OR xil.distribution_block = gr_param.block_02 )
      AND   (  gr_param.block_03      IS NULL
            OR xil.distribution_block = gr_param.block_03 )
      -- �p�����[�^�����D�I�����C���敪
      AND   xil.eos_control_type  = NVL( gr_param.online_type, xil.eos_control_type )
      AND   xshi.location_code    = xil.segment1
      ----------------------------------------------------------------------------------------------
      -- �h�e�w�b�_
      ----------------------------------------------------------------------------------------------
      AND   xshi.eos_data_type  IN( gc_eos_type_rpt_move_o      -- �ړ��o�Ɋm���
                                   ,gc_eos_type_rpt_move_i )    -- �ړ����Ɋm���
      -- �p�����[�^�����D�ړ��m��
      AND   xshi.order_source_ref = NVL( gr_param.request_no, xshi.order_source_ref )
      -- �p�����[�^�����D�o�ɓ�FromTo
      AND   xshi.shipped_date     BETWEEN gr_param.date_from
                                  AND     NVL( gr_param.date_to, xshi.shipped_date )
    ;
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
  BEGIN

--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �w�����уf�[�^���o�E�o�^����
    -- ====================================================
    -- �o�͋敪���u�ۗ��v�ȊO�̏ꍇ
    IF (  ( gr_param.output_type IS NULL )
       OR ( gr_param.output_type <> gc_output_type_rsrv ) ) THEN
     <<main_loop>>
      FOR re_main IN cu_main LOOP
       lv_data_count := lv_data_count + 1;
        --------------------------------------------------
        -- ���o�f�[�^�i�[
        --------------------------------------------------
        lr_get_data.arvl_code        := re_main.arvl_code;          -- ���ɑq�ɃR�[�h
        lr_get_data.arvl_name        := re_main.arvl_name;          -- ���ɑq�ɖ���
        lr_get_data.location_code    := re_main.location_code ;     -- �o�ɑq�ɃR�[�h
        lr_get_data.location_name    := re_main.location_name ;     -- �o�ɑq�ɖ���
        lr_get_data.ship_date        := re_main.ship_date ;         -- �o�ɓ�
        lr_get_data.arvl_date        := re_main.arvl_date ;         -- ���ɓ�
        lr_get_data.career_id        := re_main.career_id ;         -- ���������F�^���Ǝ�
        lr_get_data.ship_method_code := re_main.ship_method_code ;  -- ���������F�z���敪
        lr_get_data.delivery_no      := re_main.delivery_no ;       -- �z���m��
        lr_get_data.request_no       := re_main.request_no ;        -- �ړ��m��
        lr_get_data.order_line_id    := re_main.order_line_id ;     -- ���������F���ׂh�c
        lr_get_data.item_id          := re_main.item_id ;           -- ���������F�i�ڂh�c
        lr_get_data.item_code        := re_main.item_code ;         -- �i�ڃR�[�h
        lr_get_data.item_name        := re_main.item_name ;         -- �i�ږ���
        lr_get_data.lot_ctl          := re_main.lot_ctl ;           -- ���������F���b�g�g�p
        lr_get_data.quant_r          := re_main.quant_r ;           -- �˗����i���b�g�Ǘ��O�j
        lr_get_data.quant_i          := re_main.quant_i ;           -- ���ɐ��i���b�g�Ǘ��O�j
        lr_get_data.quant_o          := re_main.quant_o ;           -- �o�ɐ��i���b�g�Ǘ��O�j
        lr_get_data.status           := re_main.status ;            -- �󒍃w�b�_�X�e�[�^�X
--
        --------------------------------------------------
        -- ���ԃe�[�u���o�^�f�[�^�ݒ�
        --------------------------------------------------
        prc_set_temp_data
          (
            ir_get_data   => lr_get_data
           ,or_temp_tab   => lr_temp_tab
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE check_move_data_expt ;
        END IF ;
--
        --------------------------------------------------
        -- ���ԃe�[�u���f�[�^�i�[�p
        --------------------------------------------------
        gt_arvl_code_tbl(lv_data_count)          := lr_temp_tab.arvl_code;        -- ���ɑq�ɃR�[�h
        gt_arvl_name_tbl(lv_data_count)          := lr_temp_tab.arvl_name;        -- ���ɑq�ɖ���
        gt_location_code_tbl(lv_data_count)      := lr_temp_tab.location_code;    -- �o�ɑq�ɃR�[�h
        gt_location_name_tbl(lv_data_count)      := lr_temp_tab.location_name;    -- �o�ɑq�ɖ���
        gt_ship_date_tbl(lv_data_count)          := lr_temp_tab.ship_date;        -- �o�ɓ�
        gt_arvl_date_tbl(lv_data_count)          := lr_temp_tab.arvl_date;        -- ���ɓ�
        gt_career_code_tbl(lv_data_count)        := lr_temp_tab.career_code;      -- �^���Ǝ҃R�[�h
        gt_career_name_tbl(lv_data_count)        := lr_temp_tab.career_name;      -- �^���ƎҖ���
        gt_ship_method_code_tbl(lv_data_count)   := lr_temp_tab.ship_method_code; -- �z���敪�R�[�h
        gt_ship_method_name_tbl(lv_data_count)   := lr_temp_tab.ship_method_name; -- �z���敪����
        gt_delivery_no_tbl(lv_data_count)        := lr_temp_tab.delivery_no;      -- �z���m��
        gt_request_no_tbl(lv_data_count)         := lr_temp_tab.request_no;       -- �ړ��m��
        gt_item_code_tbl(lv_data_count)          := lr_temp_tab.item_code;        -- �i�ڃR�[�h
        gt_item_name_tbl(lv_data_count)          := lr_temp_tab.item_name;        -- �i�ږ���
        gt_lot_ctl_tbl(lv_data_count)            := lr_temp_tab.lot_no;           -- ���b�g�ԍ�
        gt_product_date_tbl(lv_data_count)       := lr_temp_tab.product_date;     -- ������
        gt_use_by_date_tbl(lv_data_count)        := lr_temp_tab.use_by_date;      -- �ܖ�����
        gt_original_char_tbl(lv_data_count)      := lr_temp_tab.original_char;    -- �ŗL�L��
        gt_meaning_tbl(lv_data_count)            := lr_temp_tab.lot_status;       -- �i��
        gt_quant_r_tbl(lv_data_count)            := lr_temp_tab.quant_r;          -- �˗���
        gt_quant_i_tbl(lv_data_count)            := lr_temp_tab.quant_i;          -- ���ɐ�
        gt_quant_o_tbl(lv_data_count)            := lr_temp_tab.quant_o;          -- �o�ɐ�
        gt_reason_tbl(lv_data_count)             := lr_temp_tab.reason;           -- ���َ��R
--
      END LOOP main_loop ;
      --------------------------------------------------
      -- ���ԃe�[�u���o�^
      --------------------------------------------------
      prc_ins_temp_data
        (
          ov_errbuf     => lv_errbuf
         ,ov_retcode    => lv_retcode
         ,ov_errmsg     => lv_errmsg
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE check_move_data_expt ;
      END IF ;
    END IF ;
--
    -- ====================================================
    -- �ۗ��f�[�^���o�E�o�^����
    -- ====================================================
    -- �o�͋敪���u�ۗ��v�̏ꍇ
    IF (  ( gr_param.output_type IS NULL )
       OR ( gr_param.output_type = gc_output_type_rsrv ) ) THEN
     <<reserv_loop>>
      FOR re_main IN cu_reserv LOOP
        -- �J�E���g
        lv_data_count := lv_data_count + 1;
        --------------------------------------------------
        -- ���o�f�[�^�i�[
        --------------------------------------------------
        lr_get_data.arvl_code        := re_main.arvl_code;          -- ���ɑq�ɃR�[�h
        lr_get_data.arvl_name        := re_main.arvl_name;          -- ���ɑq�ɖ���
        lr_get_data.location_code    := re_main.location_code ;     -- �o�ɑq�ɃR�[�h
        lr_get_data.location_name    := re_main.location_name ;     -- �o�ɑq�ɖ���
        lr_get_data.ship_date        := re_main.ship_date ;         -- �o�ɓ�
        lr_get_data.arvl_date        := re_main.arvl_date ;         -- ���ɓ�
        lr_get_data.career_id        := re_main.career_id ;         -- ���������F�^���Ǝ�
        lr_get_data.ship_method_code := re_main.ship_method_code ;  -- ���������F�z���敪
        lr_get_data.delivery_no      := re_main.delivery_no ;       -- �z���m��
        lr_get_data.request_no       := re_main.request_no ;        -- �ړ��m��
        lr_get_data.order_line_id    := re_main.order_line_id ;     -- ���������F���ׂh�c
        lr_get_data.item_id          := re_main.item_id ;           -- ���������F�i�ڂh�c
        lr_get_data.item_code        := re_main.item_code ;         -- �i�ڃR�[�h
        lr_get_data.item_name        := re_main.item_name ;         -- �i�ږ���
        lr_get_data.lot_ctl          := re_main.lot_ctl ;           -- ���������F���b�g�g�p
        lr_get_data.quant_r          := re_main.quant_r ;           -- �˗����i���b�g�Ǘ��O�j
        lr_get_data.quant_i          := re_main.quant_i ;           -- ���ɐ��i���b�g�Ǘ��O�j
        lr_get_data.quant_o          := re_main.quant_o ;           -- �o�ɐ��i���b�g�Ǘ��O�j
        lr_get_data.status           := re_main.status ;            -- �w�b�_�X�e�[�^�X
--
       --------------------------------------------------
        -- ���ԃe�[�u���o�^�f�[�^�ݒ�
        --------------------------------------------------
        prc_set_temp_data
          (
            ir_get_data   => lr_get_data
           ,or_temp_tab   => lr_temp_tab
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE check_move_data_expt ;
        END IF ;
--
        --------------------------------------------------
        -- ���ԃe�[�u���f�[�^�i�[�p
        --------------------------------------------------
        gt_arvl_code_tbl(lv_data_count)          := lr_temp_tab.arvl_code;        -- ���ɑq�ɃR�[�h
        gt_arvl_name_tbl(lv_data_count)          := lr_temp_tab.arvl_name;        -- ���ɑq�ɖ���
        gt_location_code_tbl(lv_data_count)      := lr_temp_tab.arvl_name;        -- �o�ɑq�ɃR�[�h
        gt_location_name_tbl(lv_data_count)      := lr_temp_tab.location_name;    -- �o�ɑq�ɖ���
        gt_ship_date_tbl(lv_data_count)          := lr_temp_tab.ship_date;        -- �o�ɓ�
        gt_arvl_date_tbl(lv_data_count)          := lr_temp_tab.arvl_date;        -- ���ɓ�
        gt_career_code_tbl(lv_data_count)        := lr_temp_tab.career_code;      -- �^���Ǝ҃R�[�h
        gt_career_name_tbl(lv_data_count)        := lr_temp_tab.career_name;      -- �^���ƎҖ���
        gt_ship_method_code_tbl(lv_data_count)   := lr_temp_tab.ship_method_code; -- �z���敪�R�[�h
        gt_ship_method_name_tbl(lv_data_count)   := lr_temp_tab.ship_method_name; -- �z���敪����
        gt_delivery_no_tbl(lv_data_count)        := lr_temp_tab.delivery_no;      -- �z���m��
        gt_request_no_tbl(lv_data_count)         := lr_temp_tab.request_no;       -- �ړ��m��
        gt_item_code_tbl(lv_data_count)          := lr_temp_tab.item_code;        -- �i�ڃR�[�h
        gt_item_name_tbl(lv_data_count)          := lr_temp_tab.item_name;        -- �i�ږ���
        gt_lot_ctl_tbl(lv_data_count)            := lr_temp_tab.lot_no;           -- ���b�g�ԍ�
        gt_product_date_tbl(lv_data_count)       := lr_temp_tab.product_date;     -- ������
        gt_use_by_date_tbl(lv_data_count)        := lr_temp_tab.use_by_date;      -- �ܖ�����
        gt_original_char_tbl(lv_data_count)      := lr_temp_tab.original_char;    -- �ŗL�L��
        gt_meaning_tbl(lv_data_count)            := lr_temp_tab.lot_status;       -- �i��
        gt_quant_r_tbl(lv_data_count)            := lr_temp_tab.quant_r;          -- �˗���
        gt_quant_i_tbl(lv_data_count)            := lr_temp_tab.quant_i;          -- ���ɐ�
        gt_quant_o_tbl(lv_data_count)            := lr_temp_tab.quant_o;          -- �o�ɐ�
        gt_reason_tbl(lv_data_count)             := lr_temp_tab.reason;           -- ���َ��R
      END LOOP main_loop ;
--
      --------------------------------------------------
      -- ���ԃe�[�u���o�^
      --------------------------------------------------
      prc_ins_temp_data
        (
          ov_errbuf     => lv_errbuf
         ,ov_retcode    => lv_retcode
         ,ov_errmsg     => lv_errmsg
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE check_move_data_expt ;
      END IF ;
    END IF ;
--
    -- ====================================================
    -- �A�E�g�p�����[�^�Z�b�g
    -- ====================================================
    ov_errbuf  := lv_errbuf ;     --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode := lv_retcode ;    --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg  := lv_errmsg ;     --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  EXCEPTION
    -- �ړ��f�[�^���o�����̗�O
    WHEN check_move_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_move_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�ҏW
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �ړ��f�[�^���o����
    -- ====================================================
    prc_create_move_data
      (
        ov_errbuf     => lv_errbuf
       ,ov_retcode    => lv_retcode
       ,ov_errmsg     => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE check_create_xml_expt ;
    END IF ;
--
    -- ====================================================
    -- �w�l�k�f�[�^�o�͏���
    -- ====================================================
    prc_create_out_data
      (
        ov_errbuf     => lv_errbuf
       ,ov_retcode    => lv_retcode
       ,ov_errmsg     => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE check_create_xml_expt ;
    END IF ;
--
    -- ====================================================
    -- �A�E�g�p�����[�^�Z�b�g
    -- ====================================================
    ov_errbuf  := lv_errbuf ;     --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode := lv_retcode ;    --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg  := lv_errmsg ;     --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  EXCEPTION
    -- �w�l�k�f�[�^�ҏW�̗�O
    WHEN check_create_xml_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_xml_data ;
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION convert_into_xml
    (
      iv_name              IN        VARCHAR2   --   �^�O�l�[��
     ,iv_value             IN        VARCHAR2   --   �^�O�f�[�^
     ,ic_type              IN        CHAR       --   �^�O�^�C�v
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'convert_into_xml' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_convert_data         VARCHAR2(2000) ;
--
  BEGIN
--
    IF ( ic_type = 'D' ) THEN
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
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_prod_div             IN     VARCHAR2         -- 01 : ���i�敪
     ,iv_item_div             IN     VARCHAR2         -- 02 : �i�ڋ敪
     ,iv_date_from            IN     VARCHAR2         -- 03 : ����From
     ,iv_date_to              IN     VARCHAR2         -- 04 : ����To
     ,iv_dept_code            IN     VARCHAR2         -- 05 : ����
     ,iv_output_type          IN     VARCHAR2         -- 06 : �o�͋敪
     ,iv_block_01             IN     VARCHAR2         -- 07 : �u���b�N�P
     ,iv_block_02             IN     VARCHAR2         -- 08 : �u���b�N�Q
     ,iv_block_03             IN     VARCHAR2         -- 09 : �u���b�N�R
     ,iv_ship_to_locat_code   IN     VARCHAR2         -- 10 : ���ɐ�
     ,iv_online_type          IN     VARCHAR2         -- 11 : �I�����C���Ώۋ敪
     ,iv_request_no           IN     VARCHAR2         -- 12 : �ړ�No
     ,ov_errbuf              OUT     VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode             OUT     VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg              OUT     VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;                      --   ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;                   --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- *** ���[�J���ϐ� ***
    lv_xml_string           VARCHAR2(32000) ;
    ln_retcode              NUMBER ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ��������
    -- =====================================================
    -- -----------------------------------------------------
    -- �p�����[�^�i�[
    -- -----------------------------------------------------
    gr_param.prod_div           := iv_prod_div ;                                          -- ���i�敪
    gr_param.item_div           := iv_item_div ;                                          -- �i�ڋ敪
    gr_param.date_from          := FND_DATE.CANONICAL_TO_DATE( iv_date_from ) ;           -- ����From
    gr_param.date_to            := FND_DATE.CANONICAL_TO_DATE( iv_date_to   ) ;           -- ����To
    gr_param.dept_code          := iv_dept_code ;                                         -- ����
    gr_param.output_type        := iv_output_type ;                                       -- �o�͋敪
    gr_param.block_01           := iv_block_01 ;                                          -- �u���b�N�P
    gr_param.block_02           := iv_block_02 ;                                          -- �u���b�N�Q
    gr_param.block_03           := iv_block_03 ;                                          -- �u���b�N�R
    gr_param.ship_to_locat_code := iv_ship_to_locat_code ;                                -- ���ɐ�
    gr_param.online_type        := iv_online_type ;                                       -- �I�����C���Ώۋ敪
    gr_param.request_no         := iv_request_no ;                                        -- �ړ�No
    -- -----------------------------------------------------
    -- ���O�C�����ޔ��i�v�g�n�J�����p�j
    -- -----------------------------------------------------
    gn_created_by             := FND_GLOBAL.USER_ID ;           -- �쐬��
    gn_last_updated_by        := FND_GLOBAL.USER_ID ;           -- �ŏI�X�V��
    gn_last_update_login      := FND_GLOBAL.LOGIN_ID ;          -- �ŏI�X�V���O�C��
    gn_request_id             := FND_GLOBAL.CONC_REQUEST_ID ;   -- �v��ID
    gn_program_application_id := FND_GLOBAL.PROG_APPL_ID ;      -- �b�o�E�A�v���P�[�V����ID
    gn_program_id             := FND_GLOBAL.CONC_PROGRAM_ID ;   -- �R���J�����g�E�v���O����ID
--
    -- =====================================================
    -- ���O�C�����[�U�[���o��
    -- =====================================================
    prc_create_xml_data_user
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- �w�l�k�t�@�C���f�[�^�ҏW
    -- =====================================================
    -- --------------------------------------------------
    -- ���X�g�O���[�v�J�n�^�O
    -- --------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- --------------------------------------------------
    -- �w�l�k�f�[�^�ҏW�������Ăяo���B
    -- --------------------------------------------------
    prc_create_xml_data
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- --------------------------------------------------
    -- ���X�g�O���[�v�I���^�O
    -- --------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ==================================================
    -- ���[�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF ( gn_data_cnt = 0 ) THEN
--
      -- --------------------------------------------------
      -- �O�����b�Z�[�W�̎擾
      -- --------------------------------------------------
      ov_retcode := gv_status_warn ;
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,gc_err_code_no_data ) ;
--
      -- --------------------------------------------------
      -- ���b�Z�[�W�̐ݒ�
      -- --------------------------------------------------
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <lg_lctn_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <g_lctn>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </g_lctn>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </lg_lctn_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </data_info>' ) ;
--
    -- --------------------------------------------------
    -- ���[�f�[�^���o�͂ł����ꍇ
    -- --------------------------------------------------
    ELSE
      -- --------------------------------------------------
      -- �w�l�k�o��
      -- --------------------------------------------------
      -- �w�l�k�f�[�^���o��
      <<xml_data_table>>
        -- �ҏW�����f�[�^���^�O�ɕϊ�
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- �ҏW�����f�[�^���^�O�ɕϊ�
        lv_xml_string := convert_into_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name  -- �^�O�l�[��
                           ,iv_value  => gt_xml_data_table(i).tag_value -- �^�O�f�[�^
                           ,ic_type   => gt_xml_data_table(i).tag_type  -- �^�O�^�C�v
                          ) ;
        -- �w�l�k�^�O�o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_xml_string) ;
      END LOOP xml_data_table ;
    END IF ;
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
    -- ==================================================
    -- ���ԃe�[�u�����[���o�b�N
    -- ==================================================
    ROLLBACK ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
--
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
      -- ==================================================
      -- ���ԃe�[�u�����[���o�b�N
      -- ==================================================
      ROLLBACK ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
      -- ==================================================
      -- ���ԃe�[�u�����[���o�b�N
      -- ==================================================
      ROLLBACK ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
      -- ==================================================
      -- ���ԃe�[�u�����[���o�b�N
      -- ==================================================
      ROLLBACK ;
--
--####################################  �Œ蕔 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main
    (
      errbuf                 OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode                OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_prod_div            IN     VARCHAR2         -- 01 : ���i�敪
     ,iv_item_div            IN     VARCHAR2         -- 02 : �i�ڋ敪
     ,iv_date_from           IN     VARCHAR2         -- 03 : ����From
     ,iv_date_to             IN     VARCHAR2         -- 04 : ����To
     ,iv_dept_code           IN     VARCHAR2         -- 05 : ����
     ,iv_output_type         IN     VARCHAR2         -- 06 : �o�͋敪
     ,iv_block_01            IN     VARCHAR2         -- 07 : �u���b�N�P
     ,iv_block_02            IN     VARCHAR2         -- 08 : �u���b�N�Q
     ,iv_block_03            IN     VARCHAR2         -- 09 : �u���b�N�R
     ,iv_ship_to_locat_code  IN     VARCHAR2         -- 10 : ���ɐ�
     ,iv_online_type         IN     VARCHAR2         -- 11 : �I�����C���Ώۋ敪
     ,iv_request_no          IN     VARCHAR2         -- 12 : �ړ�No
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ;  -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1) ;         --   ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000) ;      --   ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain
      (
        iv_prod_div           => iv_prod_div                         -- 01 : ���i�敪
       ,iv_item_div           => iv_item_div                         -- 02 : �i�ڋ敪
       ,iv_date_from          => iv_date_from                        -- 03 : ����From
       ,iv_date_to            => NVL(iv_date_to , gc_max_date_char)  -- 04 : ����To
       ,iv_dept_code          => iv_dept_code                        -- 05 : ����
       ,iv_output_type        => iv_output_type                      -- 06 : �o�͋敪
       ,iv_block_01           => iv_block_01                         -- 07 : �u���b�N�P
       ,iv_block_02           => iv_block_02                         -- 08 : �u���b�N�Q
       ,iv_block_03           => iv_block_03                         -- 09 : �u���b�N�R
       ,iv_ship_to_locat_code => iv_ship_to_locat_code               -- 10 : ���ɐ�
       ,iv_online_type        => iv_online_type                      -- 11 : �I�����C���Ώۋ敪
       ,iv_request_no         => iv_request_no                       -- 12 : �ړ�No
       ,ov_errbuf             => lv_errbuf                           -- �G���[�E���b�Z�[�W
       ,ov_retcode            => lv_retcode                          -- ���^�[���E�R�[�h
       ,ov_errmsg             => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
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
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwsh930004c ;
/
