CREATE OR REPLACE PACKAGE BODY xxinv570001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv570001c(body)
 * Description      : �ړ����o�Ɏ��ѓo�^
 * MD.050           : �ړ����o�Ɏ��ѓo�^(T_MD050_BPO_570)
 * MD.070           : �ړ����o�Ɏ��ѓo�^(T_MD070_BPO_57A)
 * Version          : 1.22
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init_proc               �������� (A-1)
 *  check_mov_num_proc      �ړ��ԍ��d���`�F�b�N
 *  get_move_data_proc      �ړ��˗�/�w���f�[�^�擾 (A-2)
 *  check_proc              �Ó����`�F�b�N (A-3)
 *  get_data_proc           �֘A�f�[�^�擾(A-4)
 *  regist_adji_proc        ���ђ����S�ԏ��o�^ (A-6)
 *  regist_xfer_proc        �ϑ�������ѓo�^ (A-5)
 *  regist_trni_proc        �ϑ��Ȃ����ѓo�^ (A-8)
 *  update_flg_proc         ���ьv��σt���O,���ђ����t���O�X�V(A-10,A-11)
 *  submain                 ���C�������v���V�[�W��
 *  main                    �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/19    1.0   Sumie Nakamura   �V�K�쐬
 *  2008/04/08    1.1   Sumie Nakamura   �����ύX�v��No49
 *  2008/06/02    1.2   Kazuo Kumamoto   �����e�X�g��Q�Ή�(�o�Ɏ��ѐ��ʁ����Ɏ��ѐ��ʂ̃X�e�[�^�X�ύX)
 *  2008/07/24    1.3   Takao Ohashi     T_TE080_BPO_540 �w�E5�Ή�
 *  2008/08/21    1.4   Yuko  Kawano     �����ύX�v���Ή� #202
 *  2008/09/26    1.5   Yuko  Kawano     �����e�X�g�w�E#156,�ۑ�T_S_457,T_S_629�Ή�
 *  2008/12/09    1.6   Naoki Fukuda     �{�ԏ�Q#470,#519(�ړ��ԍ��d���`�F�b�Ncheck_mov_num_proc�ǉ�)
 *  2008/12/11    1.7   Yuko  Kawano     �{�ԏ�Q#633(�ړ����ђ����s��Ή�)
 *  2008/12/11    1.8   Naoki Fukuda     �{�ԏ�Q#441
 *  2008/12/11    1.9   Takao Ohashi     �{�ԏ�Q#672
 *  2008/12/11    1.10  Yuko  Kawano     �{�ԏ�Q#633(�ړ����ђ����s��Ή�)
 *  2008/12/13    1.11  Yuko  Kawano     �{�ԏ�Q#633(�ړ����ђ����s��Ή�)
 *  2008/12/16    1.12  Yuko  Kawano     �{�ԏ�Q#633(�ړ����ђ����s��Ή�)
 *  2008/12/17    1.13  Yuko  Kawano     �{�ԏ�Q(�ړ����ђ����O���ʂ̍X�V�s��Ή�)
 *  2008/12/25    1.14  Hitomi Itou      �{�ԏ�Q#821(�o�Ɏ��ѓ��E���׎��ѓ��̖������`�F�b�N��ǉ�)
 *  2008/12/25    1.15  Yuko  Kawano     �{�ԏ�Q#844(�p�����[�^�\��������ѓ��ɕύX)
 *  2009/01/16    1.16  Yuko  Kawano     �{�ԏ�Q#988(���ђ���(�V�K���גǉ����̕s��Ή�))
 *  2009/01/28    1.17  Yuko  Kawano     �{�ԏ�Q#1093(���у��b�g�s��v�Ή�)
 *  2009/02/04    1.18  Yuko  Kawano     �{�ԏ�Q#1142(���ђ���(�W�������f�̕s��Ή�))
 *  2009/02/19    1.19  Akiyoshi Shiina  �{�ԏ�Q#1179(���b�g���ѐ���0�����݂���ړ����я��̏���)
 *  2009/02/19    1.20  Akiyoshi Shiina  �{�ԏ�Q#1194(���b�N�G���[���x���ɂ���)
 *  2009/02/24    1.21  Akiyoshi Shiina  �đΉ�_�{�ԏ�Q#1179(���b�g���ѐ���0�����݂���ړ����я��̏���)
 *  2009/06/09    1.22  Hitomi Itou      �{�ԏ�Q#1526(�ŐV�W���f�[�^���o��MAX(�ŏI�X�V��)�Ƃ���)
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;      -- �Ώی���
  gn_normal_cnt    NUMBER;      -- ���팏��
  gn_error_cnt     NUMBER;      -- �G���[����
  gn_warn_cnt      NUMBER;      -- �X�L�b�v����
--2008/09/26 Y.Kawano Add Start
  gn_out_cnt      NUMBER;      -- �ΏۊO����
--2008/09/26 Y.Kawano Add End
--
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  check_lock_expt           EXCEPTION;     -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name    CONSTANT VARCHAR2(100)                := 'xxinv570001c'; -- �p�b�P�[�W��
--
  gv_c_msg_kbn_inv   CONSTANT VARCHAR2(5)                  := 'XXINV';
  gv_c_msg_kbn_cmn   CONSTANT VARCHAR2(5)                  := 'XXCMN';
--
  -- ���b�Z�[�W�ԍ�
  gv_c_msg_57a_001   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10010'; -- �p�����[�^�G���[
  gv_c_msg_57a_002   CONSTANT VARCHAR2(15) := 'APP-XXINV-10032'; -- ���b�N�G���[
  gv_c_msg_57a_003   CONSTANT VARCHAR2(15) := 'APP-XXINV-10000'; -- API�G���[
  gv_c_msg_57a_004   CONSTANT VARCHAR2(15) := 'APP-XXINV-10056'; -- ���t�s��v���b�Z�[�W
  gv_c_msg_57a_005   CONSTANT VARCHAR2(15) := 'APP-XXINV-10003'; -- �J�����_�N���[�Y���b�Z�[�W
  gv_c_msg_57a_006   CONSTANT VARCHAR2(15) := 'APP-XXINV-10009'; -- �f�[�^�擾���s
  gv_c_msg_57a_007   CONSTANT VARCHAR2(15) := 'APP-XXINV-10008'; -- �f�[�^�擾�s��
--
--2008/09/26 Y.Kawano Add Start
  gv_c_msg_57a_008   CONSTANT VARCHAR2(15) := 'APP-XXINV-10174'; -- ������o�ɕۊǑq�ɃG���[
  gv_c_msg_57a_009   CONSTANT VARCHAR2(15) := 'APP-XXINV-10175'; -- �莝���ʂȂ��G���[
  gv_c_msg_57a_010   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002'; -- �v���t�@�C���擾�G���[
--2008/09/26 Y.Kawano Add End
  gv_c_msg_57a_011   CONSTANT VARCHAR2(15) := 'APP-XXINV-10181'; -- �ړ��ԍ��d���G���[ 2008/12/09 �{�ԏ�Q#470,#512 Add
--
-- 2008/12/25 H.Itou Add Start
  gv_c_msg_57a_012   CONSTANT VARCHAR2(15)   := 'APP-XXINV-10182'; -- �������G���[
-- 2008/12/25 H.Itou Add End
  -- �g�[�N��
  gv_c_tkn_parameter           CONSTANT VARCHAR2(30)  := 'PARAMETER';
  gv_c_tkn_value               CONSTANT VARCHAR2(30)  := 'VALUE';
  gv_c_tkn_api                 CONSTANT VARCHAR2(30)  := 'API_NAME';
  gv_c_tkn_mov_num             CONSTANT VARCHAR2(30)  := 'MOV_NUM';
  gv_c_tkn_mov_line_num        CONSTANT VARCHAR2(30)  := 'MOV_LINE_NUM';
  gv_c_tkn_item                CONSTANT VARCHAR2(30)  := 'ITEM';
  gv_c_tkn_lot_num             CONSTANT VARCHAR2(30)  := 'LOT_NUM';
  gv_c_tkn_shipped_day         CONSTANT VARCHAR2(30)  := 'SHIPPED_DAY';
  gv_c_tkn_ship_to_day         CONSTANT VARCHAR2(30)  := 'SHIP_TO_DAY';
  gv_c_tkn_errmsg              CONSTANT VARCHAR2(30)  := 'ERR_MSG';
  gv_c_tkn_msg                 CONSTANT VARCHAR2(30)  := 'MSG';
--2008/09/26 Y.Kawano Add Start
  gv_c_tkn_profile             CONSTANT VARCHAR2(30)  := 'NG_PROFILE';
--
  gv_c_tkn_shipped_loct        CONSTANT VARCHAR2(30)  := 'SHIPPED_LOCATION';
  gv_c_tkn_ship_to_loct        CONSTANT VARCHAR2(30)  := 'SHIP_TO_LOCATION';
--2008/09/26 Y.Kawano Add End
--
  gv_c_tkn_parameter_val       CONSTANT VARCHAR2(30)  := '�ړ��ԍ�';
  gv_c_tkn_table               CONSTANT VARCHAR2(30)  := 'TABLE';
  gv_c_tkn_table_val           CONSTANT VARCHAR2(60)  := '�ړ��˗�/�w���w�b�_(�A�h�I��)';
  gv_c_tkn_err_val             CONSTANT VARCHAR2(60)  := '�ړ��˗�/�w�����';
--mod start 1.3
--  gv_c_tkn_api_val_a           CONSTANT VARCHAR2(60)  := '�݌ɐ���API';
--  gv_c_tkn_api_val_x           CONSTANT VARCHAR2(60)  := '�݌ɓ]��API';
  gv_c_tkn_api_val_a           CONSTANT VARCHAR2(60)  := '�݌ɐ���';
  gv_c_tkn_api_val_x           CONSTANT VARCHAR2(60)  := '�݌ɓ]��';
--mod end 1.3
--
  gv_c_tkn_val_mov_num         CONSTANT VARCHAR2(60)  := '�ړ��ԍ�';
  gv_c_tkn_val_line_num        CONSTANT VARCHAR2(60)  := '���הԍ�';
  gv_c_tkn_val_item            CONSTANT VARCHAR2(60)  := '�i��';
  gv_c_tkn_val_lot_num         CONSTANT VARCHAR2(60)  := '���b�gNo';
  gv_c_tkn_val_o_date          CONSTANT VARCHAR2(60)  := '�o�Ɏ��ѓ�';
  gv_c_tkn_val_i_date          CONSTANT VARCHAR2(60)  := '���Ɏ��ѓ�';
--
--2008/09/26 Y.Kawano Add Start
  gv_c_tkn_prf_start_day       CONSTANT VARCHAR2(60)  := 'XXINV:�݌ɓ]���p���[�U�[';
--2008/09/26 Y.Kawano Add End
--
  gv_c_out_date                CONSTANT VARCHAR2(60)   := '�o�Ɏ��ѓ�';
  gv_c_in_date                 CONSTANT VARCHAR2(60)   := '���Ɏ��ѓ�';
  gv_c_calendar                CONSTANT VARCHAR2(60)   := '�݌ɃJ�����_�[';
  gv_c_no_data_msg             CONSTANT VARCHAR2(100)  := '��ЁE�g�D�E�q�ɏ��擾�G���[ �ړ��ԍ�:';
--
  -- �݌ɓ]��API����^�C�v
  gv_c_trans_type1             CONSTANT NUMBER          := '1';  -- Insert
  gv_c_trans_type2             CONSTANT NUMBER          := '2';  -- Release
  gv_c_trans_type3             CONSTANT NUMBER          := '3';  -- Receive
--
  -- ���R�R�[�h
  gv_c_msg                     CONSTANT VARCHAR2(100)   := '���R�R�[�h �ړ�����';
  gv_c_msg_cr                  CONSTANT VARCHAR2(100)   := '���R�R�[�h �ړ����ђ���';
  gv_c_reason_desc             CONSTANT VARCHAR2(100)   := '�ړ�����';       -- �ړ�����
  gv_c_reason_desc_correct     CONSTANT VARCHAR2(100)   := '�ړ����ђ���';   -- �ړ����ђ���
--
  -- EBS�W�������^�C�v
  gv_c_doc_type_xfer           CONSTANT VARCHAR2(10)    := 'XFER';         -- �݌Ƀg���������^�C�v
  gv_c_doc_type_trni           CONSTANT VARCHAR2(10)    := 'TRNI';         -- �݌Ƀg���������^�C�v
  gv_c_doc_type_adji           CONSTANT VARCHAR2(10)    := 'ADJI';         -- �݌Ƀg���������^�C�v
--
  -- ���b�g�Ǘ��敪
--  gv_c_lot_ctl_y               CONSTANT NUMBER    := 1;                 -- ���b�g�Ǘ��F�L
--  gv_c_lot_ctl_n               CONSTANT NUMBER    := 0;                 -- ���b�g�Ǘ��F��
--
  gv_status_code               VARCHAR2(10);                -- �ړ��X�e�[�^�X�R�[�h�l
  gv_yn_code                   VARCHAR2(10);                -- YES_NO�敪�R�[�h�l
--
  -- �N�C�b�N�R�[�h �ړ��^�C�v
  gv_c_move_type_y                     CONSTANT VARCHAR2(10)   := '1';             -- �ϑ�����
  gv_c_move_type_n                     CONSTANT VARCHAR2(10)   := '2';             -- �ϑ��Ȃ�
--
  -- �N�C�b�N�R�[�h �ړ��X�e�[�^�X
  gv_c_move_status                     CONSTANT VARCHAR2(10)   := '06';            -- ���o�ɕ񍐗L
--
  -- �N�C�b�N�R�[�h YES_NO�敪
  gv_c_ynkbn_y                         CONSTANT VARCHAR2(10)   := 'Y';             -- YES
  gv_c_ynkbn_n                         CONSTANT VARCHAR2(10)   := 'N';             -- NO
--
  -- �N�C�b�N�R�[�h �����^�C�v
  gv_c_document_type                   CONSTANT VARCHAR2(10)   := '20';            -- �ړ�
--
  -- �N�C�b�N�R�[�h ���R�[�h�^�C�v
  gv_c_document_type_out               CONSTANT VARCHAR2(10)   := '20';            -- �o��
  gv_c_document_type_in                CONSTANT VARCHAR2(10)   := '30';            -- ����
--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �ړ��˗��w���f�[�^���i�[���郌�R�[�h
  TYPE move_data_rec IS RECORD(
    mov_hdr_id              xxinv_mov_req_instr_headers.mov_hdr_id%TYPE            -- �ړ��w�b�_ID
   ,mov_num                 xxinv_mov_req_instr_headers.mov_num%TYPE               -- �ړ��ԍ�
   ,mov_type                xxinv_mov_req_instr_headers.mov_type%TYPE              -- �ړ��^�C�v
   ,comp_actual_flg         xxinv_mov_req_instr_headers.comp_actual_flg%TYPE       -- ���ьv��σt���O
   ,correct_actual_flg      xxinv_mov_req_instr_headers.correct_actual_flg%TYPE    -- ���ђ����t���O
   ,shipped_locat_id        xxinv_mov_req_instr_headers.shipped_locat_id%TYPE      -- �o�Ɍ�ID
   ,shipped_locat_code      xxinv_mov_req_instr_headers.shipped_locat_code%TYPE    -- �o�Ɍ��ۊǏꏊ
   ,ship_to_locat_id        xxinv_mov_req_instr_headers.ship_to_locat_id%TYPE      -- ���ɐ�ID
   ,ship_to_locat_code      xxinv_mov_req_instr_headers.ship_to_locat_code%TYPE    -- ���ɐ�ۊǏꏊ
   ,schedule_ship_date      xxinv_mov_req_instr_headers.schedule_ship_date%TYPE    -- �o�ɗ\���
   ,schedule_arrival_date   xxinv_mov_req_instr_headers.schedule_arrival_date%TYPE -- ���ɗ\���
   ,actual_ship_date        xxinv_mov_req_instr_headers.actual_ship_date%TYPE      -- �o�Ɏ��ѓ�
   ,actual_arrival_date     xxinv_mov_req_instr_headers.actual_arrival_date%TYPE   -- ���Ɏ��ѓ�
   ,mov_line_id             xxinv_mov_req_instr_lines.mov_line_id%TYPE           -- �ړ�����ID
   ,line_number             xxinv_mov_req_instr_lines.line_number%TYPE           -- ���הԍ�
   ,item_id                 xxinv_mov_req_instr_lines.item_id%TYPE               -- OPM�i��ID
   ,item_code               xxinv_mov_req_instr_lines.item_code%TYPE             -- �i��
   ,uom_code                xxinv_mov_req_instr_lines.uom_code%TYPE              -- �P��
   ,shipped_quantity        xxinv_mov_req_instr_lines.shipped_quantity%TYPE      -- �o�Ɏ��ѐ���
   ,ship_to_quantity        xxinv_mov_req_instr_lines.ship_to_quantity%TYPE      -- ���Ɏ��ѐ���
-- add start 1.3
   ,mov_lot_dtl_id          xxinv_mov_lot_details.mov_lot_dtl_id%TYPE            -- ���b�g�ڍ�ID(�o�ɗp)
   ,mov_lot_dtl_id2         xxinv_mov_lot_details.mov_lot_dtl_id%TYPE            -- ���b�g�ڍ�ID(���ɗp)
-- add end 1.3
   ,lot_id                  xxinv_mov_lot_details.lot_id%TYPE                    -- ���b�gID
   ,lot_no                  xxinv_mov_lot_details.lot_no%TYPE                    -- ���b�gNo
   ,lot_out_actual_date     xxinv_mov_lot_details.actual_date%TYPE               -- ���ѓ�  [�o��]
   ,lot_out_actual_quantity xxinv_mov_lot_details.actual_quantity%TYPE           -- ���ѐ���[�o��]
   ,lot_in_actual_date      xxinv_mov_lot_details.actual_date%TYPE               -- ���ѓ�  [����]
   ,lot_in_actual_quantity  xxinv_mov_lot_details.actual_quantity%TYPE           -- ���ѐ���[����]
--2008/12/11 Y.Kawano Add Start
   ,lot_out_bf_act_quantity xxinv_mov_lot_details.before_actual_quantity%TYPE    -- �����O���ѐ���[�o��]
   ,lot_in_bf_act_quantity  xxinv_mov_lot_details.before_actual_quantity%TYPE    -- �����O���ѐ���[����]
--2008/12/11 Y.Kawano Add End
   ,ng_flag                 NUMBER                                               -- NG�t���O
   ,skip_flag               NUMBER                                               -- skip�t���O
--2008/09/26 Y.Kawano Add Start
   ,exist_flag              NUMBER                                               -- ���݃`�F�b�N�t���O
--2008/09/26 Y.Kawano Add End
   ,err_msg                 varchar2(5000)                                       -- �G���[���e
  );
--
  -- �ړ��˗��w���f�[�^���i�[����PLSQL�\
  TYPE move_data_tbl IS TABLE OF move_data_rec INDEX BY BINARY_INTEGER;
  move_data_rec_tbl     move_data_tbl;  -- �ړ����i�[PLSQL�\
  move_data_rec_tmp     move_data_tbl;  -- tmp�p
  move_target_tbl       move_data_tbl;  -- ���я����ΏۗpPLSQL�\
--
  -- �ړ������i�[���郌�R�[�h
  TYPE mov_hdr_rec IS RECORD(
    mov_hdr_id            xxinv_mov_req_instr_headers.mov_hdr_id%TYPE,         -- �ړ��w�b�_ID
    mov_num               xxinv_mov_req_instr_headers.mov_num%TYPE             -- �ړ��ԍ�
--2008/09/26 Y.Kawano Add Start
   ,skip_flag             NUMBER                                               -- skip�t���O
   ,exist_flag            NUMBER                                               -- ���݃`�F�b�N�t���O
   ,out_flag              NUMBER                                               -- �����ΏۊO�t���O
--2008/09/26 Y.Kawano Add End
  );
--
  -- �X�V�Ώۂ��i�[����PLSQL�\
  TYPE mov_hdr_tbl IS TABLE OF mov_hdr_rec INDEX BY BINARY_INTEGER;
  mov_num_rec_tbl     mov_hdr_tbl; -- �X�V�Ώۈړ��L�[���i�[�p
  err_mov_rec_tbl     mov_hdr_tbl; -- �ړ��L�[���G���[�i�[�p
  mov_num_ok_tbl      mov_hdr_tbl; -- �X�V�Ώۈړ��L�[���i�[�p
  err_mov_tmp_rec_tbl mov_hdr_tbl; -- �ړ��L�[���G���[�i�[wk�p
--
  -- �G���[���e�i�[���R�[�h
  TYPE err_rec IS RECORD(
    out_msg            VARCHAR2(5000)          -- ���b�Z�[�W���e
  );
--
  -- �G���[���ePLSQL�\
  TYPE err_rec_tbl IS TABLE OF err_rec INDEX BY BINARY_INTEGER;
  out_err_tbl     err_rec_tbl;                 -- �o�̓G���[���b�Z�[�W
  out_err_tbl2    err_rec_tbl;                 -- �o�̓G���[���b�Z�[�W
--
  -- �݌ɐ���API���s�Ώۃ��R�[�h
  TYPE adji_api_rec IS RECORD(
     item_no         IC_ITEM_MST.ITEM_NO%TYPE         -- �i�ڃR�[�h
    ,from_whse_code  IC_WHSE_MST.WHSE_CODE%TYPE       -- �q�ɃR�[�h
    ,to_whse_code    IC_WHSE_MST.WHSE_CODE%TYPE       -- �q�ɃR�[�h
    ,lot_no          IC_LOTS_MST.LOT_NO%TYPE          -- ���b�gNo
    ,from_location   MTL_ITEM_LOCATIONS.SEGMENT1%TYPE -- �ۊǑq�ɃR�[�h
    ,to_location     MTL_ITEM_LOCATIONS.SEGMENT1%TYPE -- �ۊǑq�ɃR�[�h
    ,trans_qty_out   NUMBER                           -- ����
    ,trans_qty_in    NUMBER                           -- ����
    ,from_co_code    SY_ORGN_MST_B.CO_CODE%TYPE       -- ��ЃR�[�h
    ,to_co_code      SY_ORGN_MST_B.CO_CODE%TYPE       -- ��ЃR�[�h
    ,from_orgn_code  SY_ORGN_MST_B.ORGN_CODE%TYPE     -- �g�D�R�[�h
    ,to_orgn_code    SY_ORGN_MST_B.ORGN_CODE%TYPE     -- �g�D�R�[�h
    ,trans_date_out  DATE                             -- �����
    ,trans_date_in   DATE                             -- �����
    ,attribute1      VARCHAR2(240)                    -- �ړ�����ID(DFF1)
   );
--
  TYPE adji_data_tbl IS TABLE OF adji_api_rec INDEX BY BINARY_INTEGER;
  adji_data_rec_tbl      adji_data_tbl;  -- ADJI�p
--
  -- �ړ�API���s�Ώۃ��R�[�h
  TYPE move_api_rec IS RECORD(
    orgn_code               SY_ORGN_MST_B.ORGN_CODE%TYPE      -- �g�D�R�[�h
   ,item_no                 IC_ITEM_MST.ITEM_NO%TYPE          -- �i�ڃR�[�h
   ,lot_no                  IC_LOTS_MST.LOT_NO%TYPE           -- ���b�gNo
   ,source_warehouse        IC_WHSE_MST.WHSE_CODE%TYPE        -- �q�ɃR�[�h
   ,source_location         MTL_ITEM_LOCATIONS.SEGMENT1%TYPE  -- �ۊǑq�ɃR�[�h
   ,target_warehouse        IC_WHSE_MST.WHSE_CODE%TYPE        -- �q�ɃR�[�h
   ,target_location         MTL_ITEM_LOCATIONS.SEGMENT1%TYPE  -- �ۊǑq�ɃR�[�h
   ,scheduled_release_date  DATE                              -- �����[�X�\���
   ,scheduled_receive_date  DATE                              -- ����\���
   ,actual_release_date     DATE                              -- �����[�X���ѓ�
   ,actual_receive_date     DATE                              -- ������ѓ�
   ,release_quantity1       NUMBER                            -- ����
   ,attribute1              VARCHAR2(240)                     -- �ړ�����ID(DFF1)
   );
--
  TYPE move_api_tbl IS TABLE OF move_api_rec INDEX BY BINARY_INTEGER;
  move_api_rec_tbl     move_api_tbl;  -- XFER�p
--
  -- �ړ�API���s�Ώۃ��R�[�h
  TYPE trni_api_rec IS RECORD(
    item_no                 IC_ITEM_MST.ITEM_NO%TYPE          -- �i�ڃR�[�h
   ,from_whse_code          IC_WHSE_MST.WHSE_CODE%TYPE        -- �q�ɃR�[�h
   ,to_whse_code            IC_WHSE_MST.WHSE_CODE%TYPE        -- �q�ɃR�[�h
   ,lot_no                  IC_LOTS_MST.LOT_NO%TYPE           -- ���b�gNo
   ,from_location           MTL_ITEM_LOCATIONS.SEGMENT1%TYPE  -- �ۊǑq�ɃR�[�h
   ,to_location             MTL_ITEM_LOCATIONS.SEGMENT1%TYPE  -- �ۊǑq�ɃR�[�h
   ,trans_qty               NUMBER                            -- ����
   ,co_code                 SY_ORGN_MST_B.CO_CODE%TYPE        -- ��ЃR�[�h
   ,orgn_code               SY_ORGN_MST_B.ORGN_CODE%TYPE      -- �g�D�R�[�h
   ,trans_date              DATE                              -- �����
   ,attribute1              VARCHAR2(240)                     -- �ړ�����ID(DFF1)
   );
--
  TYPE trni_api_tbl IS TABLE OF trni_api_rec INDEX BY BINARY_INTEGER;
  trni_api_rec_tbl      trni_api_tbl;  -- TRNI�p
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_rec_idx        NUMBER DEFAULT 1;   -- �ړ��˗��w���f�[�^ PLSQL�\INDEX
  gn_idx            NUMBER DEFAULT 1;   -- INDEX
--
  gd_sysdate                DATE;             -- �V�X�e�����t
  gn_user_id                NUMBER;           -- ���[�UID
  gv_user_name              VARCHAR2(100);    -- ���[�U��
  gn_login_id               NUMBER;           -- �ŏI�X�V���O�C��
  gn_conc_request_id        NUMBER;           -- �v��ID
  gn_prog_appl_id           NUMBER;           -- �ݶ��āE��۸��т̱��ع����ID
  gn_conc_program_id        NUMBER;           -- �R���J�����g�E�v���O����ID
--
--
--2008/09/26 Y.Kawano Add Start
    gv_xfer_user_name       VARCHAR2(100);    -- ���[�U��
--2008/09/26 Y.Kawano Add End
--
  gn_created_by             NUMBER(15);                      -- �쐬��
  gd_creation_date          DATE;                            -- �쐬��
  gv_check_proc_retcode     VARCHAR2(1);                     -- �Ó����`�F�b�N�X�e�[�^�X
--
  gv_reason_code            SY_REAS_CDS_B.REASON_CODE%TYPE;  -- �ړ����ю��R�R�[�h�l
  gv_reason_code_cor        SY_REAS_CDS_B.REASON_CODE%TYPE;  -- �ړ����ђ������R�R�[�h�l
--
  -- �݌ɃJ�����_
  gd_close_period_date      DATE;            -- �݌ɃJ�����_�[�N���[�Y��
--
-- �ړ���񒊏o�Ώۃf�[�^�Ȃ�
   gn_no_data_flg           NUMBER := 0;
-- 2009/02/19 v1.20 ADD START
--
  gb_lock_expt_flg          BOOLEAN := FALSE; -- ���b�N�G���[�t���O
-- 2009/02/19 v1.20 ADD END
--
  /**********************************************************************************
  * Procedure Name   : init_proc
  * Description      : �������� (A-1)
  ***********************************************************************************/
  PROCEDURE init_proc(
    iv_mov_num      IN  VARCHAR2,     --   �ړ��ԍ�
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt                NUMBER;    -- ���݃`�F�b�N�p�J�E���g
    l_setup_return_sts    BOOLEAN;   -- GMI�nAPI�ďo�p�߂�l
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �V�X�e�����t�擾
    gd_sysdate := SYSDATE;
    -- WHO�J�������擾
    gn_user_id          := FND_GLOBAL.USER_ID;              -- ���[�UID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;             -- �ŏI�X�V���O�C��
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;      -- �v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;         -- �ݶ��āE��۸��т̱��ع����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;      -- �R���J�����g�E�v���O����ID
    gv_user_name        := FND_GLOBAL.USER_NAME;            -- ���[�U�[��
--
--2008/09/26 Y.Kawano Add Start
    gv_xfer_user_name   := FND_PROFILE.VALUE('XXINV_XFER_USER');
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_xfer_user_name IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_cmn,
                                            gv_c_msg_57a_010,         -- �v���t�@�C���擾�G���[
                                            gv_c_tkn_profile,         -- �g�[�N��PROFILE
                                            gv_c_tkn_prf_start_day    -- XXINV:�݌ɓ]���p���[�U�[
                                            );
       lv_errbuf := lv_errmsg;
       RAISE global_api_expt;
    END IF;
--2008/09/26 Y.Kawano Add End
--
    -- ������
    gn_normal_cnt    := 0;
    gn_warn_cnt      := 0;
    gn_target_cnt    := 0;
--2008/09/26 Y.Kawano Add Start
    gn_out_cnt       := 0;
--2008/09/26 Y.Kawano Add End
--
    ------------------------------------------
    -- ���̓p�����[�^�ړ��ԍ��̑��݃`�F�b�N
    ------------------------------------------
    BEGIN
      -- ���̓p�����[�^�ړ��ԍ���NULL�łȂ��ꍇ
      IF (iv_mov_num IS NOT NULL) THEN
--
        SELECT count(*)
        INTO   ln_cnt
        FROM   xxinv_mov_req_instr_headers  -- �ړ��˗�/�w���w�b�_(�A�h�I��)
        WHERE  mov_num = iv_mov_num         -- �ړ��ԍ�
        --AND    status  = gv_c_move_status   -- �X�e�[�^�X
        ;
--
        -- ���݂��Ȃ��ꍇ
        IF (ln_cnt) = 0 THEN                           --*** �p�����[�^�G���[ ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_cmn,
                                                gv_c_msg_57a_001,         -- �p�����[�^�G���[
                                                gv_c_tkn_parameter,       -- �g�[�N��PARAMETER
                                                gv_c_tkn_parameter_val,   -- �ړ��ԍ�
                                                gv_c_tkn_value,           -- �g�[�N��VALUE
                                                iv_mov_num                -- �p�����[�^���͒l
                                                );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN                             --*** �p�����[�^�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_cmn,
                                              gv_c_msg_57a_001,       -- �p�����[�^�G���[
                                              gv_c_tkn_parameter,     -- �g�[�N��PARAMETER
                                              gv_c_tkn_parameter_val, -- �ړ��ԍ�
                                              gv_c_tkn_value,         -- �g�[�N��VALUE
                                              iv_mov_num              -- �p�����[�^���͒l
                                              );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    ------------------------------------------
    -- ���R�R�[�h�擾 ����
    ------------------------------------------
    BEGIN
      SELECT srcb.reason_code                       -- ���їp�R�[�h
      INTO   gv_reason_code
      FROM   sy_reas_cds_b      srcb                -- ���R�R�[�h
            ,sy_reas_cds_tl     srct                -- ���R�R�[�h
      WHERE srcb.reason_code  = srct.reason_code
      AND   srct.language     = 'JA'
      AND   srct.source_lang  = 'JA'
      AND   srct.reason_desc1 = gv_c_reason_desc   -- ���їp�E�v
      AND   srcb.delete_mark  = 0                  -- �폜�}�[�N
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                             --*** �f�[�^�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                              gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                              gv_c_tkn_msg,     -- �g�[�N��MSG
                                              gv_c_msg          -- �g�[�N���l
                                              );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN TOO_MANY_ROWS THEN                             --*** �f�[�^�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                              gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                              gv_c_tkn_msg,     -- �g�[�N��MSG
                                              gv_c_msg          -- �g�[�N���l
                                              );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    ------------------------------------------
    -- ���R�R�[�h�擾 ���ђ���
    ------------------------------------------
    BEGIN
      SELECT srcb.reason_code                       -- ���їp�R�[�h
      INTO   gv_reason_code_cor
      FROM   sy_reas_cds_b      srcb                -- ���R�R�[�h
            ,sy_reas_cds_tl     srct                -- ���R�R�[�h
      WHERE srcb.reason_code  = srct.reason_code
      AND   srct.language     = 'JA'
      AND   srct.source_lang  = 'JA'
      AND   srct.reason_desc1 = gv_c_reason_desc_correct   -- ���їp�E�v
      AND   srcb.delete_mark  = 0                          -- �폜�}�[�N
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                             --*** �f�[�^�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                              gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                              gv_c_tkn_msg,     -- �g�[�N��MSG
                                              gv_c_msg_cr       -- �g�[�N���l
                                              );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN TOO_MANY_ROWS THEN                             --*** �f�[�^�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                              gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                              gv_c_tkn_msg,     -- �g�[�N��MSG
                                              gv_c_msg_cr       -- �g�[�N���l
                                              );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    ------------------------------------------
    -- ���ʊ֐��ɂ��݌ɃJ�����_�[�̒��߃N���[�Y���̎擾
    ------------------------------------------
    BEGIN
      -- �݌ɃJ�����_�[�N���[�Y���擾
      gd_close_period_date :=
          TRUNC(LAST_DAY(FND_DATE.STRING_TO_DATE(xxcmn_common_pkg.get_opminv_close_period(),
               'YYYY/MM')));
    EXCEPTION
      WHEN OTHERS THEN                             --*** �f�[�^�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                              gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                              gv_c_tkn_msg,     -- �g�[�N��MSG
                                              gv_c_calendar     -- �g�[�N���l
                                              );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--

    ------------------------------------------
    -- GMI�nAPI�ďo�̃Z�b�g�A�b�v
    ------------------------------------------
    l_setup_return_sts := GMIGUTL.Setup(gv_user_name);
    IF NOT (l_setup_return_sts) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'*** Failed to call GMIGUTL.Setup(). ***');
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
  END init_proc;
--
  -- 2008/12/09 �{�ԏ�Q#470,#519 Add Start ----------------------------------------------------
  /**********************************************************************************
   * Procedure Name   : check_mov_num_proc
   * Description      : �ړ��ԍ��d���`�F�b�N
   ***********************************************************************************/
  PROCEDURE check_mov_num_proc(
    iv_mov_num    IN  VARCHAR2,     --   �ړ��ԍ�
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_mov_num_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_mov_num        xxinv_mov_req_instr_headers.mov_num%TYPE;          -- �ړ��ԍ�
    ln_rec_cnt        NUMBER;                                            -- ���R�[�h����
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR xxinv_move_cur
    IS
      SELECT xmrih2.mov_num
      INTO   ln_rec_cnt
      FROM (
        SELECT xmrih.mov_num
              ,COUNT(xmrih.mov_num) AS mov_num_cnt
        FROM   xxinv_mov_req_instr_headers xmrih                -- �ړ��˗�/�w���w�b�_(�A�h�I��)
        GROUP BY xmrih.mov_num
      ) xmrih2
      WHERE xmrih2.mov_num_cnt > 1                              -- �d�����Ă���
      ORDER BY xmrih2.mov_num;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ln_rec_cnt   := 0;        -- ���R�[�h����������
--
    -- **************************************************
    -- �p�����[�^�ړ��ԍ����w�肳��Ă���ꍇ
    -- **************************************************
    IF (iv_mov_num IS NOT NULL) THEN
--
      SELECT COUNT(xmrih.mov_num)
      INTO   ln_rec_cnt
      FROM   xxinv_mov_req_instr_headers xmrih               -- �ړ��˗�/�w���w�b�_(�A�h�I��)
      WHERE  xmrih.mov_num = iv_mov_num;                     -- �ړ��ԍ�
--
      IF ln_rec_cnt > 1 THEN  -- �p�����[�^�w�肳�ꂽ�ړ��ԍ�������������ꍇ
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                              gv_c_msg_57a_011,     -- �ړ��ԍ��d���G���[
                                              gv_c_tkn_mov_num,     -- �g�[�N���ړ��ԍ�
                                              iv_mov_num            -- �d���ړ��ԍ�
                                              );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
        ov_retcode := gv_status_error;
      END IF;
--
    -- **************************************************
    -- �p�����[�^�ړ��ԍ����w�肳��Ă��Ȃ��ꍇ
    -- **************************************************
    ELSE
--
      OPEN xxinv_move_cur;
      <<xxinv_mov_cur_loop>>
      LOOP
        FETCH xxinv_move_cur
        INTO lv_mov_num       -- �ړ��ԍ�
          ;
        EXIT when xxinv_move_cur%NOTFOUND;
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                              gv_c_msg_57a_011,     -- �ړ��ԍ��d���G���[
                                              gv_c_tkn_mov_num,     -- �g�[�N���ړ��ԍ�
                                              lv_mov_num            -- �d���ړ��ԍ�
                                              );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
        ov_retcode := gv_status_error;
--
      END LOOP xxinv_mov_num_cur_loop;
--
      CLOSE xxinv_move_cur;  -- �J�[�\���N���[�Y
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (xxinv_move_cur%ISOPEN) THEN
        CLOSE xxinv_move_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (xxinv_move_cur%ISOPEN) THEN
        CLOSE xxinv_move_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (xxinv_move_cur%ISOPEN) THEN
        CLOSE xxinv_move_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (xxinv_move_cur%ISOPEN) THEN
        CLOSE xxinv_move_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_mov_num_proc;
  -- 2008/12/09 �{�ԏ�Q#470,#519 Add End ------------------------------------------------------
--
  /**********************************************************************************
   * Procedure Name   : get_move_data_proc
   * Description      : �ړ��˗�/�w���f�[�^�擾 (A-2)
   ***********************************************************************************/
  PROCEDURE get_move_data_proc(
    iv_mov_num    IN  VARCHAR2,     --   �ړ��ԍ�
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_move_data_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_mov_num        xxinv_mov_req_instr_headers.MOV_NUM%TYPE;          -- �ړ��ԍ�
    ln_location_id    xxcmn_item_locations_v.inventory_location_id%TYPE; -- �ۊǑq��ID
    ln_item_id        ic_tran_pnd.item_id%TYPE;                          -- �i��ID
    ln_lot_id         ic_tran_pnd.lot_id%TYPE;                           -- ���b�gID
    lv_location       ic_tran_pnd.location%TYPE;                         -- �ۊǑq�ɃR�[�h
    lv_mov_line_id    ic_xfer_mst.attribute1%TYPE;                       -- �ړ�����ID
    lv_mov_num_bk     xxinv_mov_req_instr_headers.MOV_NUM%TYPE;          -- �ړ��ԍ�
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- ==================================
    -- �ړ����̎擾�J�[�\��
    -- ==================================
--2009/01/28 Y.Kawano Mod Start #1093
--    -- ���o�����Ɉړ��ԍ�����
--    CURSOR xxinv_mov_num_cur(lv_mov_num IN xxinv_mov_req_instr_headers.mov_num%TYPE)
--    IS
--      SELECT xmrih.mov_hdr_id                                -- �ړ��w�b�_ID
--            ,xmrih.mov_num                                   -- �ړ��ԍ�
--            ,xmrih.mov_type                                  -- �ړ��^�C�v
--            ,xmrih.comp_actual_flg                           -- ���ьv��σt���O
--            ,xmrih.correct_actual_flg                        -- ���ђ����t���O
--            ,xmrih.shipped_locat_id                          -- �o�Ɍ�ID
--            ,xmrih.shipped_locat_code                        -- �o�Ɍ��ۊǏꏊ
--            ,xmrih.ship_to_locat_id                          -- ���ɐ�ID
--            ,xmrih.ship_to_locat_code                        -- ���ɐ�ۊǏꏊ
--            ,xmrih.schedule_ship_date                        -- �o�ɗ\���
--            ,xmrih.schedule_arrival_date                     -- ���ɗ\���
--            ,xmrih.actual_ship_date                          -- �o�Ɏ��ѓ�
--            ,xmrih.actual_arrival_date                       -- ���Ɏ��ѓ�
--            ,xmril.mov_line_id                               -- �ړ�����ID
--            ,xmril.line_number                               -- ���הԍ�
--            ,xmril.item_id                                   -- OPM�i��ID
--            ,xmril.item_code                                 -- �i��
--            ,xmril.uom_code                                  -- �P��
--            ,xmril.shipped_quantity                          -- �o�Ɏ��ѐ���
--            ,xmril.ship_to_quantity                          -- ���Ɏ��ѐ���
---- add start 1.3
--            ,xmld.mov_lot_dtl_id                             -- ���b�g�ڍ�ID(�o�ɗp)
--            ,xmld2.mov_lot_dtl_id   mov_lot_dtl_id2          -- ���b�g�ڍ�ID(���ɗp)
---- add end 1.3
--            ,xmld.lot_id                                     -- ���b�gID
--            ,xmld.lot_no                                     -- ���b�gNo
--            ,xmld.actual_date       lot_out_actual_date      -- ���ѓ�  [�o��]
--            ,xmld.actual_quantity   lot_out_actual_quantity  -- ���ѐ���[�o��]
--            ,xmld2.actual_date      lot_in_actual_date       -- ���ѓ�  [����]
--            ,xmld2.actual_quantity  lot_in_actual_quantity   -- ���ѐ���[����]
----2008/12/11 Y.Kawano Add Start
--            ,xmld.before_actual_quantity   lot_out_bf_actual_quantity  -- ���ѐ���[�o��]
--            ,xmld2.before_actual_quantity  lot_in_bf_actual_quantity   -- ���ѐ���[����]
----2008/12/11 Y.Kawano Add End
--      FROM   xxinv_mov_req_instr_headers xmrih                  -- �ړ��˗�/�w���w�b�_(�A�h�I��)
--            ,xxinv_mov_req_instr_lines   xmril                  -- �ړ��˗�/�w������(�A�h�I��)
--            ,xxinv_mov_lot_details       xmld                   -- �ړ����b�g�ڍ�(�A�h�I��)  �o�ɗp
--            ,xxinv_mov_lot_details       xmld2                  -- �ړ����b�g�ڍ�(�A�h�I��)  ���ɗp
--      WHERE  xmrih.mov_hdr_id          = xmril.mov_hdr_id            -- �w�b�_ID
--      AND    xmril.mov_line_id         = xmld.mov_line_id            -- ����ID �o��
--      AND    xmril.mov_line_id         = xmld2.mov_line_id           -- ����ID ����
--      AND    xmld.document_type_code   = gv_c_document_type      -- �����^�C�v[�ړ�]
--      AND    xmld2.document_type_code  = gv_c_document_type      -- �����^�C�v[�ړ�]
--      AND    xmld.record_type_code     = gv_c_document_type_out      -- ���R�[�h�^�C�v[�o��]
--      AND    xmld2.record_type_code    = gv_c_document_type_in       -- ���R�[�h�^�C�v[����]
--      AND    xmld.lot_id               = xmld2.lot_id                -- ���b�gID
--      AND    xmrih.status              = gv_c_move_status            -- �X�e�[�^�X[ ���o�ɕ񍐗L ]
--      AND  (
--            (xmrih.comp_actual_flg    = gv_c_ynkbn_n)               -- ���ьv��σt���O[ OFF ]�܂���
--             OR
--            ((xmrih.comp_actual_flg    = gv_c_ynkbn_y)  AND (xmrih.correct_actual_flg = gv_c_ynkbn_y))
--           )                                        -- ���ђ����t���O[ ON ]�����ьv��σt���O[ ON ]
--      AND    xmril.delete_flg          = gv_c_ynkbn_n                -- ����t���O[N]
--      AND    xmrih.mov_num             = lv_mov_num                  -- �ړ��ԍ�
----      ORDER BY xmrih.mov_hdr_id, xmril.line_number,
--      FOR UPDATE OF xmrih.mov_hdr_id NOWAIT;
--
--    -- ���o�����Ɉړ��ԍ��Ȃ�
--    CURSOR xxinv_move_cur
--    IS
--      SELECT xmrih.mov_hdr_id                                -- �ړ��w�b�_ID
--            ,xmrih.mov_num                                   -- �ړ��ԍ�
--            ,xmrih.mov_type                                  -- �ړ��^�C�v
--            ,xmrih.comp_actual_flg                           -- ���ьv��σt���O
--            ,xmrih.correct_actual_flg                        -- ���ђ����t���O
--            ,xmrih.shipped_locat_id                          -- �o�Ɍ�ID
--            ,xmrih.shipped_locat_code                        -- �o�Ɍ��ۊǏꏊ
--            ,xmrih.ship_to_locat_id                          -- ���ɐ�ID
--            ,xmrih.ship_to_locat_code                        -- ���ɐ�ۊǏꏊ
--            ,xmrih.schedule_ship_date                        -- �o�ɗ\���
--            ,xmrih.schedule_arrival_date                     -- ���ɗ\���
--            ,xmrih.actual_ship_date                          -- �o�Ɏ��ѓ�
--            ,xmrih.actual_arrival_date                       -- ���Ɏ��ѓ�
--            ,xmril.mov_line_id                               -- �ړ�����ID
--            ,xmril.line_number                               -- ���הԍ�
--            ,xmril.item_id                                   -- OPM�i��ID
--            ,xmril.item_code                                 -- �i��
--            ,xmril.uom_code                                  -- �P��
--            ,xmril.shipped_quantity                          -- �o�Ɏ��ѐ���
--            ,xmril.ship_to_quantity                          -- ���Ɏ��ѐ���
---- add start 1.3
--            ,xmld.mov_lot_dtl_id                             -- ���b�g�ڍ�ID(�o�ɗp)
--            ,xmld2.mov_lot_dtl_id   mov_lot_dtl_id2          -- ���b�g�ڍ�ID(���ɗp)
---- add end 1.3
--            ,xmld.lot_id                                     -- ���b�gID
--            ,xmld.lot_no                                     -- ���b�g��
--            ,xmld.actual_date       lot_out_actual_date      -- ���ѓ�  [�o��]
--            ,xmld.actual_quantity   lot_out_actual_quantity  -- ���ѐ���[�o��]
--            ,xmld2.actual_date      lot_in_actual_date       -- ���ѓ�  [����]
--            ,xmld2.actual_quantity  lot_in_actual_quantity   -- ���ѐ���[����]
----2008/12/11 Y.Kawano Add Start
--            ,xmld.before_actual_quantity   lot_out_bf_actual_quantity  -- ���ѐ���[�o��]
--            ,xmld2.before_actual_quantity  lot_in_bf_actual_quantity   -- ���ѐ���[����]
----2008/12/11 Y.Kawano Add End
--      FROM   xxinv_mov_req_instr_headers xmrih                  -- �ړ��˗�/�w���w�b�_(�A�h�I��)
--            ,xxinv_mov_req_instr_lines   xmril                  -- �ړ��˗�/�w������(�A�h�I��)
--            ,xxinv_mov_lot_details       xmld                   -- �ړ����b�g�ڍ�(�A�h�I��)  �o�ɗp
--            ,xxinv_mov_lot_details       xmld2                  -- �ړ����b�g�ڍ�(�A�h�I��)  ���ɗp
--      WHERE  xmrih.mov_hdr_id          = xmril.mov_hdr_id            -- �w�b�_ID
--      AND    xmril.mov_line_id         = xmld.mov_line_id            -- ����ID �o��
--      AND    xmril.mov_line_id         = xmld2.mov_line_id           -- ����ID ����
--      AND    xmld.document_type_code   = gv_c_document_type      -- �����^�C�v[�ړ�]
--      AND    xmld2.document_type_code  = gv_c_document_type      -- �����^�C�v[�ړ�]
--      AND    xmld.record_type_code     = gv_c_document_type_out      -- ���R�[�h�^�C�v[�o��]
--      AND    xmld2.record_type_code    = gv_c_document_type_in       -- ���R�[�h�^�C�v[����]
--      AND    xmld.lot_id               = xmld2.lot_id                -- ���b�gID
--      AND    xmrih.status              = gv_c_move_status            -- �X�e�[�^�X[ ���o�ɕ񍐗L ]
--      AND   (
--             (xmrih.comp_actual_flg    = gv_c_ynkbn_n)               -- ���ьv��σt���O[ OFF ]
--              OR
--             ((xmrih.comp_actual_flg    = gv_c_ynkbn_y) AND (xmrih.correct_actual_flg = gv_c_ynkbn_y))
--             )                                          -- ���ђ����t���O[ ON ] ���ьv��σt���O[ ON ]
--      AND    xmril.delete_flg          = gv_c_ynkbn_n               -- ����t���O[N]
--      ORDER BY xmrih.mov_num                                        -- �ړ��ԍ�
--      FOR UPDATE OF xmrih.mov_hdr_id NOWAIT;
--
    -- ���o�����Ɉړ��ԍ�����
    CURSOR xxinv_mov_num_cur(lv_mov_num IN xxinv_mov_req_instr_headers.mov_num%TYPE)
    IS
      SELECT main.mov_hdr_id                                -- �ړ��w�b�_ID
            ,main.mov_num                                   -- �ړ��ԍ�
            ,main.mov_type                                  -- �ړ��^�C�v
            ,main.comp_actual_flg                           -- ���ьv��σt���O
            ,main.correct_actual_flg                        -- ���ђ����t���O
            ,main.shipped_locat_id                          -- �o�Ɍ�ID
            ,main.shipped_locat_code                        -- �o�Ɍ��ۊǏꏊ
            ,main.ship_to_locat_id                          -- ���ɐ�ID
            ,main.ship_to_locat_code                        -- ���ɐ�ۊǏꏊ
            ,main.schedule_ship_date                        -- �o�ɗ\���
            ,main.schedule_arrival_date                     -- ���ɗ\���
            ,main.actual_ship_date                          -- �o�Ɏ��ѓ�
            ,main.actual_arrival_date                       -- ���Ɏ��ѓ�
            ,main.mov_line_id                               -- �ړ�����ID
            ,main.line_number                               -- ���הԍ�
            ,main.item_id                                   -- OPM�i��ID
            ,main.item_code                                 -- �i��
            ,main.uom_code                                  -- �P��
            ,main.shipped_quantity                          -- �o�Ɏ��ѐ���
            ,main.ship_to_quantity                          -- ���Ɏ��ѐ���
            ,main.mov_lot_dtl_id                            -- ���b�g�ڍ�ID(�o�ɗp)
            ,main.mov_lot_dtl_id2                           -- ���b�g�ڍ�ID(���ɗp)
            ,main.lot_id                                     -- ���b�gID
            ,main.lot_no                                     -- ���b�gNo
            ,main.lot_out_actual_date                        -- ���ѓ�  [�o��]
            ,main.lot_out_actual_quantity                    -- ���ѐ���[�o��]
            ,main.lot_in_actual_date                         -- ���ѓ�  [����]
            ,main.lot_in_actual_quantity                     -- ���ѐ���[����]
            ,main.lot_out_bf_actual_quantity                 -- ���ѐ���[�o��]
            ,main.lot_in_bf_actual_quantity                  -- ���ѐ���[����]
      FROM (
          SELECT xmrih.mov_hdr_id                                -- �ړ��w�b�_ID
                ,xmrih.mov_num                                   -- �ړ��ԍ�
                ,xmrih.mov_type                                  -- �ړ��^�C�v
                ,xmrih.comp_actual_flg                           -- ���ьv��σt���O
                ,xmrih.correct_actual_flg                        -- ���ђ����t���O
                ,xmrih.shipped_locat_id                          -- �o�Ɍ�ID
                ,xmrih.shipped_locat_code                        -- �o�Ɍ��ۊǏꏊ
                ,xmrih.ship_to_locat_id                          -- ���ɐ�ID
                ,xmrih.ship_to_locat_code                        -- ���ɐ�ۊǏꏊ
                ,xmrih.schedule_ship_date                        -- �o�ɗ\���
                ,xmrih.schedule_arrival_date                     -- ���ɗ\���
                ,xmrih.actual_ship_date                          -- �o�Ɏ��ѓ�
                ,xmrih.actual_arrival_date                       -- ���Ɏ��ѓ�
                ,xmril.mov_line_id                               -- �ړ�����ID
                ,xmril.line_number                               -- ���הԍ�
                ,xmril.item_id                                   -- OPM�i��ID
                ,xmril.item_code                                 -- �i��
                ,xmril.uom_code                                  -- �P��
                ,xmril.shipped_quantity                          -- �o�Ɏ��ѐ���
                ,xmril.ship_to_quantity                          -- ���Ɏ��ѐ���
                ,xmld.mov_lot_dtl_id                             -- ���b�g�ڍ�ID(�o�ɗp)
                ,xmld2.mov_lot_dtl_id   mov_lot_dtl_id2          -- ���b�g�ڍ�ID(���ɗp)
                ,xmld.lot_id                                     -- ���b�gID
                ,xmld.lot_no                                     -- ���b�gNo
                ,xmld.actual_date       lot_out_actual_date      -- ���ѓ�  [�o��]
                ,xmld.actual_quantity   lot_out_actual_quantity  -- ���ѐ���[�o��]
                ,xmld2.actual_date      lot_in_actual_date       -- ���ѓ�  [����]
                ,xmld2.actual_quantity  lot_in_actual_quantity   -- ���ѐ���[����]
                ,xmld.before_actual_quantity   lot_out_bf_actual_quantity  -- ���ѐ���[�o��]
                ,xmld2.before_actual_quantity  lot_in_bf_actual_quantity   -- ���ѐ���[����]
          FROM   xxinv_mov_req_instr_headers xmrih                  -- �ړ��˗�/�w���w�b�_(�A�h�I��)
                ,xxinv_mov_req_instr_lines   xmril                  -- �ړ��˗�/�w������(�A�h�I��)
                ,xxinv_mov_lot_details       xmld                   -- �ړ����b�g�ڍ�(�A�h�I��)  �o�ɗp
                ,xxinv_mov_lot_details       xmld2                  -- �ړ����b�g�ڍ�(�A�h�I��)  ���ɗp
          WHERE  xmrih.mov_hdr_id             = xmril.mov_hdr_id            -- �w�b�_ID
          AND    xmril.mov_line_id            = xmld.mov_line_id            -- ����ID �o��
          AND    xmld.mov_line_id             = xmld2.mov_line_id(+)
          AND    xmld.document_type_code      = gv_c_document_type      -- �����^�C�v[�ړ�]
          AND    xmld2.document_type_code(+)  = gv_c_document_type      -- �����^�C�v[�ړ�]
          AND    xmld.record_type_code        = gv_c_document_type_out      -- ���R�[�h�^�C�v[�o��]
          AND    xmld2.record_type_code(+)    = gv_c_document_type_in       -- ���R�[�h�^�C�v[����]
          AND    xmld.lot_id                  = xmld2.lot_id(+)             -- ���b�gID
          AND    xmrih.status                 = gv_c_move_status            -- �X�e�[�^�X[ ���o�ɕ񍐗L ]
          AND  (
                (xmrih.comp_actual_flg        = gv_c_ynkbn_n)               -- ���ьv��σt���O[ OFF ]�܂���
                 OR
                ((xmrih.comp_actual_flg       = gv_c_ynkbn_y) AND (xmrih.correct_actual_flg = gv_c_ynkbn_y))
               )                                        -- ���ђ����t���O[ ON ]�����ьv��σt���O[ ON ]
          AND    xmril.delete_flg             = gv_c_ynkbn_n                -- ����t���O[N]
          AND    xmrih.mov_num                = lv_mov_num                  -- �ړ��ԍ�
          UNION
          SELECT xmrih.mov_hdr_id                                -- �ړ��w�b�_ID
                ,xmrih.mov_num                                   -- �ړ��ԍ�
                ,xmrih.mov_type                                  -- �ړ��^�C�v
                ,xmrih.comp_actual_flg                           -- ���ьv��σt���O
                ,xmrih.correct_actual_flg                        -- ���ђ����t���O
                ,xmrih.shipped_locat_id                          -- �o�Ɍ�ID
                ,xmrih.shipped_locat_code                        -- �o�Ɍ��ۊǏꏊ
                ,xmrih.ship_to_locat_id                          -- ���ɐ�ID
                ,xmrih.ship_to_locat_code                        -- ���ɐ�ۊǏꏊ
                ,xmrih.schedule_ship_date                        -- �o�ɗ\���
                ,xmrih.schedule_arrival_date                     -- ���ɗ\���
                ,xmrih.actual_ship_date                          -- �o�Ɏ��ѓ�
                ,xmrih.actual_arrival_date                       -- ���Ɏ��ѓ�
                ,xmril.mov_line_id                               -- �ړ�����ID
                ,xmril.line_number                               -- ���הԍ�
                ,xmril.item_id                                   -- OPM�i��ID
                ,xmril.item_code                                 -- �i��
                ,xmril.uom_code                                  -- �P��
                ,xmril.shipped_quantity                          -- �o�Ɏ��ѐ���
                ,xmril.ship_to_quantity                          -- ���Ɏ��ѐ���
                ,xmld.mov_lot_dtl_id                             -- ���b�g�ڍ�ID(�o�ɗp)
                ,xmld2.mov_lot_dtl_id   mov_lot_dtl_id2          -- ���b�g�ڍ�ID(���ɗp)
                ,xmld2.lot_id                                    -- ���b�gID
                ,xmld2.lot_no                                    -- ���b�gNo
                ,xmld.actual_date       lot_out_actual_date      -- ���ѓ�  [�o��]
                ,xmld.actual_quantity   lot_out_actual_quantity  -- ���ѐ���[�o��]
                ,xmld2.actual_date      lot_in_actual_date       -- ���ѓ�  [����]
                ,xmld2.actual_quantity  lot_in_actual_quantity   -- ���ѐ���[����]
                ,xmld.before_actual_quantity   lot_out_bf_actual_quantity  -- ���ѐ���[�o��]
                ,xmld2.before_actual_quantity  lot_in_bf_actual_quantity   -- ���ѐ���[����]
          FROM   xxinv_mov_req_instr_headers xmrih                  -- �ړ��˗�/�w���w�b�_(�A�h�I��)
                ,xxinv_mov_req_instr_lines   xmril                  -- �ړ��˗�/�w������(�A�h�I��)
                ,xxinv_mov_lot_details       xmld                   -- �ړ����b�g�ڍ�(�A�h�I��)  �o�ɗp
                ,xxinv_mov_lot_details       xmld2                  -- �ړ����b�g�ڍ�(�A�h�I��)  ���ɗp
          WHERE  xmrih.mov_hdr_id             = xmril.mov_hdr_id            -- �w�b�_ID
          AND    xmril.mov_line_id            = xmld2.mov_line_id           -- ����ID ����
          AND    xmld.mov_line_id(+)          = xmld2.mov_line_id
          AND    xmld.document_type_code(+)   = gv_c_document_type      -- �����^�C�v[�ړ�]
          AND    xmld2.document_type_code     = gv_c_document_type      -- �����^�C�v[�ړ�]
          AND    xmld.record_type_code(+)     = gv_c_document_type_out      -- ���R�[�h�^�C�v[�o��]
          AND    xmld2.record_type_code       = gv_c_document_type_in       -- ���R�[�h�^�C�v[����]
          AND    xmld.lot_id(+)               = xmld2.lot_id                -- ���b�gID
          AND    xmrih.status                 = gv_c_move_status            -- �X�e�[�^�X[ ���o�ɕ񍐗L ]
          AND  (
                (xmrih.comp_actual_flg        = gv_c_ynkbn_n)               -- ���ьv��σt���O[ OFF ]�܂���
                 OR
                ((xmrih.comp_actual_flg    = gv_c_ynkbn_y)  AND (xmrih.correct_actual_flg = gv_c_ynkbn_y))
               )                                        -- ���ђ����t���O[ ON ]�����ьv��σt���O[ ON ]
          AND    xmril.delete_flg             = gv_c_ynkbn_n                -- ����t���O[N]
          AND    xmrih.mov_num                = lv_mov_num                  -- �ړ��ԍ�
          ) main
         ,xxinv_mov_req_instr_headers xih
      WHERE      main.mov_hdr_id = xih.mov_hdr_id
      FOR UPDATE OF xih.mov_hdr_id NOWAIT;
--
    -- ���o�����Ɉړ��ԍ��Ȃ�
    CURSOR xxinv_move_cur
    IS
      SELECT main.mov_hdr_id                                -- �ړ��w�b�_ID
            ,main.mov_num                                   -- �ړ��ԍ�
            ,main.mov_type                                  -- �ړ��^�C�v
            ,main.comp_actual_flg                           -- ���ьv��σt���O
            ,main.correct_actual_flg                        -- ���ђ����t���O
            ,main.shipped_locat_id                          -- �o�Ɍ�ID
            ,main.shipped_locat_code                        -- �o�Ɍ��ۊǏꏊ
            ,main.ship_to_locat_id                          -- ���ɐ�ID
            ,main.ship_to_locat_code                        -- ���ɐ�ۊǏꏊ
            ,main.schedule_ship_date                        -- �o�ɗ\���
            ,main.schedule_arrival_date                     -- ���ɗ\���
            ,main.actual_ship_date                          -- �o�Ɏ��ѓ�
            ,main.actual_arrival_date                       -- ���Ɏ��ѓ�
            ,main.mov_line_id                               -- �ړ�����ID
            ,main.line_number                               -- ���הԍ�
            ,main.item_id                                   -- OPM�i��ID
            ,main.item_code                                 -- �i��
            ,main.uom_code                                  -- �P��
            ,main.shipped_quantity                          -- �o�Ɏ��ѐ���
            ,main.ship_to_quantity                          -- ���Ɏ��ѐ���
            ,main.mov_lot_dtl_id                            -- ���b�g�ڍ�ID(�o�ɗp)
            ,main.mov_lot_dtl_id2                           -- ���b�g�ڍ�ID(���ɗp)
            ,main.lot_id                                    -- ���b�gID
            ,main.lot_no                                    -- ���b�g��
            ,main.lot_out_actual_date                       -- ���ѓ�  [�o��]
            ,main.lot_out_actual_quantity                   -- ���ѐ���[�o��]
            ,main.lot_in_actual_date                        -- ���ѓ�  [����]
            ,main.lot_in_actual_quantity                    -- ���ѐ���[����]
            ,main.lot_out_bf_actual_quantity                -- ���ѐ���[�o��]
            ,main.lot_in_bf_actual_quantity                 -- ���ѐ���[����]
      FROM (
          SELECT xmrih.mov_hdr_id                                -- �ړ��w�b�_ID
                ,xmrih.mov_num                                   -- �ړ��ԍ�
                ,xmrih.mov_type                                  -- �ړ��^�C�v
                ,xmrih.comp_actual_flg                           -- ���ьv��σt���O
                ,xmrih.correct_actual_flg                        -- ���ђ����t���O
                ,xmrih.shipped_locat_id                          -- �o�Ɍ�ID
                ,xmrih.shipped_locat_code                        -- �o�Ɍ��ۊǏꏊ
                ,xmrih.ship_to_locat_id                          -- ���ɐ�ID
                ,xmrih.ship_to_locat_code                        -- ���ɐ�ۊǏꏊ
                ,xmrih.schedule_ship_date                        -- �o�ɗ\���
                ,xmrih.schedule_arrival_date                     -- ���ɗ\���
                ,xmrih.actual_ship_date                          -- �o�Ɏ��ѓ�
                ,xmrih.actual_arrival_date                       -- ���Ɏ��ѓ�
                ,xmril.mov_line_id                               -- �ړ�����ID
                ,xmril.line_number                               -- ���הԍ�
                ,xmril.item_id                                   -- OPM�i��ID
                ,xmril.item_code                                 -- �i��
                ,xmril.uom_code                                  -- �P��
                ,xmril.shipped_quantity                          -- �o�Ɏ��ѐ���
                ,xmril.ship_to_quantity                          -- ���Ɏ��ѐ���
                ,xmld.mov_lot_dtl_id                             -- ���b�g�ڍ�ID(�o�ɗp)
                ,xmld2.mov_lot_dtl_id   mov_lot_dtl_id2          -- ���b�g�ڍ�ID(���ɗp)
                ,xmld.lot_id                                     -- ���b�gID
                ,xmld.lot_no                                     -- ���b�g��
                ,xmld.actual_date       lot_out_actual_date      -- ���ѓ�  [�o��]
                ,xmld.actual_quantity   lot_out_actual_quantity  -- ���ѐ���[�o��]
                ,xmld2.actual_date      lot_in_actual_date       -- ���ѓ�  [����]
                ,xmld2.actual_quantity  lot_in_actual_quantity   -- ���ѐ���[����]
                ,xmld.before_actual_quantity   lot_out_bf_actual_quantity  -- ���ѐ���[�o��]
                ,xmld2.before_actual_quantity  lot_in_bf_actual_quantity   -- ���ѐ���[����]
          FROM   xxinv_mov_req_instr_headers xmrih                  -- �ړ��˗�/�w���w�b�_(�A�h�I��)
                ,xxinv_mov_req_instr_lines   xmril                  -- �ړ��˗�/�w������(�A�h�I��)
                ,xxinv_mov_lot_details       xmld                   -- �ړ����b�g�ڍ�(�A�h�I��)  �o�ɗp
                ,xxinv_mov_lot_details       xmld2                  -- �ړ����b�g�ڍ�(�A�h�I��)  ���ɗp
          WHERE  xmrih.mov_hdr_id             = xmril.mov_hdr_id            -- �w�b�_ID
          AND    xmril.mov_line_id            = xmld.mov_line_id            -- ����ID �o��
          AND    xmld.mov_line_id             = xmld2.mov_line_id(+)
          AND    xmld.document_type_code      = gv_c_document_type      -- �����^�C�v[�ړ�]
          AND    xmld2.document_type_code(+)  = gv_c_document_type      -- �����^�C�v[�ړ�]
          AND    xmld.record_type_code        = gv_c_document_type_out      -- ���R�[�h�^�C�v[�o��]
          AND    xmld2.record_type_code(+)    = gv_c_document_type_in       -- ���R�[�h�^�C�v[����]
          AND    xmld.lot_id                  = xmld2.lot_id(+)             -- ���b�gID
          AND    xmrih.status                 = gv_c_move_status            -- �X�e�[�^�X[ ���o�ɕ񍐗L ]
          AND   (
                 (xmrih.comp_actual_flg     = gv_c_ynkbn_n)               -- ���ьv��σt���O[ OFF ]
                  OR
                 ((xmrih.comp_actual_flg    = gv_c_ynkbn_y) AND (xmrih.correct_actual_flg = gv_c_ynkbn_y))
                 )                                          -- ���ђ����t���O[ ON ] ���ьv��σt���O[ ON ]
          AND    xmril.delete_flg             = gv_c_ynkbn_n               -- ����t���O[N]
          UNION
          SELECT xmrih.mov_hdr_id                                -- �ړ��w�b�_ID
                ,xmrih.mov_num                                   -- �ړ��ԍ�
                ,xmrih.mov_type                                  -- �ړ��^�C�v
                ,xmrih.comp_actual_flg                           -- ���ьv��σt���O
                ,xmrih.correct_actual_flg                        -- ���ђ����t���O
                ,xmrih.shipped_locat_id                          -- �o�Ɍ�ID
                ,xmrih.shipped_locat_code                        -- �o�Ɍ��ۊǏꏊ
                ,xmrih.ship_to_locat_id                          -- ���ɐ�ID
                ,xmrih.ship_to_locat_code                        -- ���ɐ�ۊǏꏊ
                ,xmrih.schedule_ship_date                        -- �o�ɗ\���
                ,xmrih.schedule_arrival_date                     -- ���ɗ\���
                ,xmrih.actual_ship_date                          -- �o�Ɏ��ѓ�
                ,xmrih.actual_arrival_date                       -- ���Ɏ��ѓ�
                ,xmril.mov_line_id                               -- �ړ�����ID
                ,xmril.line_number                               -- ���הԍ�
                ,xmril.item_id                                   -- OPM�i��ID
                ,xmril.item_code                                 -- �i��
                ,xmril.uom_code                                  -- �P��
                ,xmril.shipped_quantity                          -- �o�Ɏ��ѐ���
                ,xmril.ship_to_quantity                          -- ���Ɏ��ѐ���
                ,xmld.mov_lot_dtl_id                             -- ���b�g�ڍ�ID(�o�ɗp)
                ,xmld2.mov_lot_dtl_id   mov_lot_dtl_id2          -- ���b�g�ڍ�ID(���ɗp)
                ,xmld2.lot_id                                    -- ���b�gID
                ,xmld2.lot_no                                    -- ���b�g��
                ,xmld.actual_date       lot_out_actual_date      -- ���ѓ�  [�o��]
                ,xmld.actual_quantity   lot_out_actual_quantity  -- ���ѐ���[�o��]
                ,xmld2.actual_date      lot_in_actual_date       -- ���ѓ�  [����]
                ,xmld2.actual_quantity  lot_in_actual_quantity   -- ���ѐ���[����]
                ,xmld.before_actual_quantity   lot_out_bf_actual_quantity  -- ���ѐ���[�o��]
                ,xmld2.before_actual_quantity  lot_in_bf_actual_quantity   -- ���ѐ���[����]
          FROM   xxinv_mov_req_instr_headers xmrih                  -- �ړ��˗�/�w���w�b�_(�A�h�I��)
                ,xxinv_mov_req_instr_lines   xmril                  -- �ړ��˗�/�w������(�A�h�I��)
                ,xxinv_mov_lot_details       xmld                   -- �ړ����b�g�ڍ�(�A�h�I��)  �o�ɗp
                ,xxinv_mov_lot_details       xmld2                  -- �ړ����b�g�ڍ�(�A�h�I��)  ���ɗp
          WHERE  xmrih.mov_hdr_id             = xmril.mov_hdr_id            -- �w�b�_ID
          AND    xmril.mov_line_id            = xmld2.mov_line_id       -- ����ID ����
          AND    xmld.mov_line_id(+)          = xmld2.mov_line_id
          AND    xmld.document_type_code(+)   = gv_c_document_type      -- �����^�C�v[�ړ�]
          AND    xmld2.document_type_code     = gv_c_document_type      -- �����^�C�v[�ړ�]
          AND    xmld.record_type_code(+)     = gv_c_document_type_out      -- ���R�[�h�^�C�v[�o��]
          AND    xmld2.record_type_code       = gv_c_document_type_in       -- ���R�[�h�^�C�v[����]
          AND    xmld.lot_id(+)               = xmld2.lot_id                -- ���b�gID
          AND    xmrih.status                 = gv_c_move_status            -- �X�e�[�^�X[ ���o�ɕ񍐗L ]
          AND   (
                 (xmrih.comp_actual_flg     = gv_c_ynkbn_n)               -- ���ьv��σt���O[ OFF ]
                  OR
                 ((xmrih.comp_actual_flg    = gv_c_ynkbn_y) AND (xmrih.correct_actual_flg = gv_c_ynkbn_y))
                 )                                          -- ���ђ����t���O[ ON ] ���ьv��σt���O[ ON ]
          AND    xmril.delete_flg             = gv_c_ynkbn_n               -- ����t���O[N]
          ) main
         ,xxinv_mov_req_instr_headers xih
      WHERE      main.mov_hdr_id = xih.mov_hdr_id
      ORDER BY   main.mov_num                                        -- �ړ��ԍ�
      FOR UPDATE OF xih.mov_hdr_id NOWAIT;
--2009/01/29 Y.Kawano Mod  End #1093
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- **************************************************
    -- *** �ړ��˗�/�w���f�[�^�擾
    -- **************************************************
--
    -- **************************************************
    -- �p�����[�^�ړ��ԍ����w�肳��Ă���ꍇ
    -- **************************************************
    IF (iv_mov_num IS NOT NULL) THEN
--
      -------------------------------
      -- ���o�����ړ��ԍ�����̃J�[�\�����I�[�v��
      -------------------------------
      OPEN xxinv_mov_num_cur(iv_mov_num);
--
      <<xxinv_mov_num_cur_loop>>
      LOOP
        FETCH xxinv_mov_num_cur
        INTO move_data_rec_tbl(gn_rec_idx).mov_hdr_id                 -- �ړ��w�b�_ID
            ,move_data_rec_tbl(gn_rec_idx).mov_num                    -- �ړ��ԍ�
            ,move_data_rec_tbl(gn_rec_idx).mov_type                   -- �ړ��^�C�v
            ,move_data_rec_tbl(gn_rec_idx).comp_actual_flg            -- ���ьv��σt���O
            ,move_data_rec_tbl(gn_rec_idx).correct_actual_flg         -- ���ђ����t���O
            ,move_data_rec_tbl(gn_rec_idx).shipped_locat_id           -- �o�Ɍ�ID
            ,move_data_rec_tbl(gn_rec_idx).shipped_locat_code         -- �o�Ɍ��ۊǏꏊ
            ,move_data_rec_tbl(gn_rec_idx).ship_to_locat_id           -- ���ɐ�ID
            ,move_data_rec_tbl(gn_rec_idx).ship_to_locat_code         -- ���ɐ�ۊǏꏊ
            ,move_data_rec_tbl(gn_rec_idx).schedule_ship_date         -- �o�ɗ\���
            ,move_data_rec_tbl(gn_rec_idx).schedule_arrival_date      -- ���ɗ\���
            ,move_data_rec_tbl(gn_rec_idx).actual_ship_date           -- �o�Ɏ��ѓ�
            ,move_data_rec_tbl(gn_rec_idx).actual_arrival_date        -- ���Ɏ��ѓ�
            ,move_data_rec_tbl(gn_rec_idx).mov_line_id                -- �ړ�����ID
            ,move_data_rec_tbl(gn_rec_idx).line_number                -- ���הԍ�
            ,move_data_rec_tbl(gn_rec_idx).item_id                    -- OPM�i��ID
            ,move_data_rec_tbl(gn_rec_idx).item_code                  -- �i��
            ,move_data_rec_tbl(gn_rec_idx).uom_code                   -- �P��
            ,move_data_rec_tbl(gn_rec_idx).shipped_quantity           -- �o�Ɏ��ѐ���
            ,move_data_rec_tbl(gn_rec_idx).ship_to_quantity           -- ���Ɏ��ѐ���
-- add start 1.3
            ,move_data_rec_tbl(gn_rec_idx).mov_lot_dtl_id             -- ���b�g�ڍ�ID(�o�ɗp)
            ,move_data_rec_tbl(gn_rec_idx).mov_lot_dtl_id2            -- ���b�g�ڍ�ID(���ɗp)
-- add end 1.3
            ,move_data_rec_tbl(gn_rec_idx).lot_id                     -- ���b�gID
            ,move_data_rec_tbl(gn_rec_idx).lot_no                     -- ���b�gNo
            ,move_data_rec_tbl(gn_rec_idx).lot_out_actual_date        -- ���ѓ�  [�o��]
            ,move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity    -- ���ѐ���[�o��]
            ,move_data_rec_tbl(gn_rec_idx).lot_in_actual_date         -- ���ѓ�  [����]
            ,move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity     -- ���ѐ���[����]
-- 2008/12/11 Y.Kawano Add Start
            ,move_data_rec_tbl(gn_rec_idx).lot_out_bf_act_quantity    -- �����O���ѐ���[�o��]
            ,move_data_rec_tbl(gn_rec_idx).lot_in_bf_act_quantity     -- �����O���ѐ���[����]
-- 2008/12/11 Y.Kawano Add End
          ;
        EXIT when xxinv_mov_num_cur%NOTFOUND;
--
        -- �Ώۃf�[�^
        IF (move_data_rec_tbl(gn_rec_idx).mov_num <> lv_mov_num_bk) 
        OR (lv_mov_num_bk IS NULL) 
        THEN
--
          -- �Ώی����C���N�������g
          gn_target_cnt := gn_target_cnt + 1;
          lv_mov_num_bk := move_data_rec_tbl(gn_rec_idx).mov_num;
--
        END IF;
--
        -- PL/SQL�\INDEX �C���N�������g
        gn_rec_idx := gn_rec_idx + 1;
--
      END LOOP xxinv_mov_num_cur_loop;
--
      IF gn_target_cnt = 0 THEN
        -- 0���̏ꍇ�A����I���ɂ���
        gn_no_data_flg := 1;
      END IF;
      -- �J�[�\���N���[�Y
      CLOSE xxinv_mov_num_cur;
--
    -- **************************************************
    -- �p�����[�^�ړ��ԍ����w�肳��Ă��Ȃ��ꍇ
    -- **************************************************
    ELSE
      -------------------------------
      -- ���o�����ړ��ԍ��Ȃ��̃J�[�\�����I�[�v��
      -------------------------------
      OPEN xxinv_move_cur;
      <<xxinv_mov_cur_loop>>
      LOOP
        FETCH xxinv_move_cur
        INTO move_data_rec_tbl(gn_rec_idx).mov_hdr_id                 -- �ړ��w�b�_ID
            ,move_data_rec_tbl(gn_rec_idx).mov_num                    -- �ړ��ԍ�
            ,move_data_rec_tbl(gn_rec_idx).mov_type                   -- �ړ��^�C�v
            ,move_data_rec_tbl(gn_rec_idx).comp_actual_flg            -- ���ьv��σt���O
            ,move_data_rec_tbl(gn_rec_idx).correct_actual_flg         -- ���ђ����t���O
            ,move_data_rec_tbl(gn_rec_idx).shipped_locat_id           -- �o�Ɍ�ID
            ,move_data_rec_tbl(gn_rec_idx).shipped_locat_code         -- �o�Ɍ��ۊǏꏊ
            ,move_data_rec_tbl(gn_rec_idx).ship_to_locat_id           -- ���ɐ�ID
            ,move_data_rec_tbl(gn_rec_idx).ship_to_locat_code         -- ���ɐ�ۊǏꏊ
            ,move_data_rec_tbl(gn_rec_idx).schedule_ship_date         -- �o�ɗ\���
            ,move_data_rec_tbl(gn_rec_idx).schedule_arrival_date      -- ���ɗ\���
            ,move_data_rec_tbl(gn_rec_idx).actual_ship_date           -- �o�Ɏ��ѓ�
            ,move_data_rec_tbl(gn_rec_idx).actual_arrival_date        -- ���Ɏ��ѓ�
            ,move_data_rec_tbl(gn_rec_idx).mov_line_id                -- �ړ�����ID
            ,move_data_rec_tbl(gn_rec_idx).line_number                -- ���הԍ�
            ,move_data_rec_tbl(gn_rec_idx).item_id                    -- OPM�i��ID
            ,move_data_rec_tbl(gn_rec_idx).item_code                  -- �i��
            ,move_data_rec_tbl(gn_rec_idx).uom_code                   -- �P��
            ,move_data_rec_tbl(gn_rec_idx).shipped_quantity           -- �o�Ɏ��ѐ���
            ,move_data_rec_tbl(gn_rec_idx).ship_to_quantity           -- ���Ɏ��ѐ���
-- add start 1.3
            ,move_data_rec_tbl(gn_rec_idx).mov_lot_dtl_id             -- ���b�g�ڍ�ID(�o�ɗp)
            ,move_data_rec_tbl(gn_rec_idx).mov_lot_dtl_id2            -- ���b�g�ڍ�ID(���ɗp)
-- add end 1.3
            ,move_data_rec_tbl(gn_rec_idx).lot_id                     -- ���b�gID
            ,move_data_rec_tbl(gn_rec_idx).lot_no                     -- ���b�gNo
            ,move_data_rec_tbl(gn_rec_idx).lot_out_actual_date        -- ���ѓ�  [�o��]
            ,move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity    -- ���ѐ���[�o��]
            ,move_data_rec_tbl(gn_rec_idx).lot_in_actual_date         -- ���ѓ�  [����]
            ,move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity     -- ���ѐ���[����]
-- 2008/12/11 Y.Kawano Add Start
            ,move_data_rec_tbl(gn_rec_idx).lot_out_bf_act_quantity    -- �����O���ѐ���[�o��]
            ,move_data_rec_tbl(gn_rec_idx).lot_in_bf_act_quantity     -- �����O���ѐ���[����]
-- 2008/12/11 Y.Kawano Add End
          ;
        EXIT when xxinv_move_cur%NOTFOUND;
--
        -- �Ώۃf�[�^
        IF (move_data_rec_tbl(gn_rec_idx).mov_num <> lv_mov_num_bk)
        OR (lv_mov_num_bk IS NULL) 
        THEN
--
          -- �Ώی����C���N�������g
          gn_target_cnt := gn_target_cnt + 1;
          lv_mov_num_bk := move_data_rec_tbl(gn_rec_idx).mov_num;
--
        END IF;
--
        -- PL/SQL�\INDEX �C���N�������g
        gn_rec_idx := gn_rec_idx + 1;
--
      END LOOP xxinv_mov_cur_loop;
-- 
      IF gn_target_cnt = 0 THEN
        -- 0���̏ꍇ�A����I���ɂ���
        gn_no_data_flg := 1;
      END IF;
--
      -- �J�[�\���N���[�Y
      CLOSE xxinv_move_cur;
--
    END IF;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    WHEN check_lock_expt THEN                           --*** ���b�N�擾�G���[ ***
      IF (xxinv_move_cur%ISOPEN) THEN
        CLOSE xxinv_move_cur;
      END IF;
      -- �G���[���b�Z�[�W�擾
-- 2009/02/19 v1.20 UPDATE START
--      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
      lv_errmsg := '�x���F'
                   || xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
-- 2009/02/19 v1.20 UPDATE END
                                            gv_c_msg_57a_002,   -- ���b�N�G���[
                                            gv_c_tkn_table,     -- �g�[�N��TABLE
                                            gv_c_tkn_table_val  -- �g�[�N���l
                                            );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
-- 2009/02/19 v1.20 ADD START
      gb_lock_expt_flg := TRUE; -- ���b�N�G���[�t���O
--
-- 2009/02/19 v1.20 ADD END
    WHEN NO_DATA_FOUND THEN                             --*** �f�[�^�Ȃ� ***
      IF (xxinv_move_cur%ISOPEN) THEN
        CLOSE xxinv_move_cur;
      END IF;
      IF (xxinv_mov_num_cur%ISOPEN) THEN
        CLOSE xxinv_mov_num_cur;
      END IF;
--
      -- 0���̏ꍇ�A����I���ɂ���
      gn_no_data_flg := 1;
--
--#################################  �Œ��O������ START   ####################################
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (xxinv_move_cur%ISOPEN) THEN
        CLOSE xxinv_move_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (xxinv_move_cur%ISOPEN) THEN
        CLOSE xxinv_move_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (xxinv_move_cur%ISOPEN) THEN
        CLOSE xxinv_move_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (xxinv_move_cur%ISOPEN) THEN
        CLOSE xxinv_move_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_move_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : check_proc
   * Description      : �Ó����`�F�b�N (A-3)
   ***********************************************************************************/
  PROCEDURE check_proc(
    ov_errbuf     OUT VARCHAR2,                 --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,                 --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)                 --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_proc'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_msg_log           VARCHAR2(2000) := NULL;  -- ���b�Z�[�W������i�[�p
    lv_wk_errmsg         VARCHAR2(2000) := NULL;  -- ���b�Z�[�W������i�[�p
    lv_out_actual_date   VARCHAR2(20);            -- �o�ɓ����O�o�͗p
    lv_in_actual_date    VARCHAR2(20);            -- ���ɓ����O�o�͗p
    lv_err_mov_num       xxinv_mov_req_instr_headers.mov_num%TYPE;    -- �ړ��ԍ�wk�p
    lv_mov_num_bk        xxinv_mov_req_instr_headers.mov_num%TYPE;    -- �ړ��ԍ�wk�p
    lv_mov_hdr_id_bk     xxinv_mov_req_instr_headers.mov_hdr_id%TYPE; -- �ړ��ԍ�wk�p
    lv_pre_mov_num       xxinv_mov_req_instr_headers.mov_num%TYPE;    -- �ړ��ԍ�wk�p
    ln_tmp_idx           NUMBER;
    ln_idx               NUMBER;
--
--2008/08/21 Y.Kawano Add Start
    lv_err_flg           VARCHAR(1);              -- �G���[�`�F�b�N�p�t���O
--2008/08/21 Y.Kawano Add End
--2008/09/26 Y.Kawano Add Start
    ln_exist             NUMBER;                  -- ���݃`�F�b�N�p�t���O
    lt_bef_mov_num       xxinv_mov_req_instr_headers.mov_num%TYPE;    -- �ړ��ԍ�wk�p
--2008/09/26 Y.Kawano Add End
    lv_whse_code_from    xxcmn_item_locations_v.whse_code%TYPE;       -- 2008/12/11 �{�ԏ�Q#441 Add
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --------------------------------------------------------------
    FND_FILE.PUT_LINE(FND_FILE.LOG,'------ check_proc START ------');
    --------------------------------------------------------------
    -- **************************************************
    -- *** �擾�������R�[�h�̊e�`�F�b�N
    -- **************************************************
    <<check_loop>>
    FOR gn_rec_idx IN 1 .. move_data_rec_tbl.COUNT LOOP
--
      -----------------------
      -- for debug
      FND_FILE.PUT_LINE(FND_FILE.LOG,'LOOP START');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')mov_num='|| move_data_rec_tbl(gn_rec_idx).mov_num);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')line_number='|| move_data_rec_tbl(gn_rec_idx).line_number);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')item_code='|| move_data_rec_tbl(gn_rec_idx).item_code);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_no='|| move_data_rec_tbl(gn_rec_idx).lot_no);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_out_actual_quantity='|| move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_in_actual_quantity='|| move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity);
      -----------------------
--
      -- �t���O������
      move_data_rec_tbl(gn_rec_idx).ng_flag   := 0;
--add start 1.2
      move_data_rec_tbl(gn_rec_idx).skip_flag := 0;
--add end 1.2
--2008/09/26 Y.Kawano Add Start
      ln_exist                                 := 0;
      move_data_rec_tbl(gn_rec_idx).exist_flag := 0;
--2008/09/26 Y.Kawano Add End
--
      -- **************************************************
      -- *** �o�Ɏ��ѐ��ʂƓ��Ɏ��ѐ��ʂ̔�r
      -- **************************************************
      -- �o�Ɏ��ѐ��ʂƓ��Ɏ��ѐ��ʂ��قȂ�ꍇ
--2009/01/28 Y.Kawano Mod Start #1093
--      IF ( move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity
--           <> move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity ) THEN
      IF (
           ( move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity
             <> move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity )
-- 2009/02/19 v1.19 UPDATE START
--        OR (  ( move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity IS NOT NULL )
        OR (  ( move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity > 0 )
-- 2009/02/19 v1.19 UPDATE END
          AND ( move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity  IS NULL ) )
        OR (  ( move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity IS NULL )
-- 2009/02/19 v1.19 UPDATE START
--          AND ( move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity  IS NOT NULL ) )
          AND ( move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity  > 0 ) )
-- 2009/02/19 v1.19 UPDATE END
         )
      THEN
--2009/01/28 Y.Kawano Mod End   #1093
--
        move_data_rec_tbl(gn_rec_idx).ng_flag   := 1;  -- NG�t���O
--add start 1.2
        move_data_rec_tbl(gn_rec_idx).skip_flag := 1;  -- �X�L�b�v�t���O
--add end 1.2
--
      END IF;
--
--2008/09/26 Y.Kawano Add Start
      -- �O�����ŃG���[�łȂ��ꍇ
      IF ( move_data_rec_tbl(gn_rec_idx).ng_flag = 0 ) THEN
        -- **************************************************
        -- *** �o�Ɍ��ۊǑq�ɂƓ��ɐ�ۊǑq�ɂ̔�r
        -- **************************************************
        -- �o�Ɍ��ۊǑq�ɂƓ��ɐ�ۊǑq�ɂ������ۊǑq�ɂ̏ꍇ
        IF ( move_data_rec_tbl(gn_rec_idx).shipped_locat_id
                = move_data_rec_tbl(gn_rec_idx).ship_to_locat_id ) THEN
--
          -- �G���[���b�Z�[�W
          lv_wk_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                   gv_c_msg_57a_008,      -- ������o�ɕۊǑq�ɃG���[
                                                   gv_c_tkn_mov_num,      -- �g�[�N���ړ��ԍ�
                                                   move_data_rec_tbl(gn_rec_idx).mov_num,
                                                   gv_c_tkn_shipped_loct, -- �g�[�N���o�Ɍ��ۊǑq��
                                                   move_data_rec_tbl(gn_rec_idx).shipped_locat_code,
                                                   gv_c_tkn_ship_to_loct, -- �g�[�N�����ɐ�ۊǑq��
                                                   move_data_rec_tbl(gn_rec_idx).ship_to_locat_code
                                                   );
          -- �㑱�����ΏۊO
          move_data_rec_tbl(gn_rec_idx).ng_flag := 1;  -- NG�t���O
          -- �G���[���e�i�[
          move_data_rec_tbl(gn_rec_idx).err_msg := lv_wk_errmsg;
--
        END IF;
      END IF;
--
      -- �O�����ŃG���[�łȂ��ꍇ
      IF ( move_data_rec_tbl(gn_rec_idx).ng_flag = 0 ) THEN
        -- **************************************************
        -- *** �o�Ɍ��ۊǑq�ɂ̎莝���ʑ��݃`�F�b�N
        -- **************************************************
        -- �ړ��^�C�v���ϑ�����̏ꍇ
        IF ( move_data_rec_tbl(gn_rec_idx).mov_type = gv_c_move_type_y ) THEN
--
          SELECT COUNT(1)
          INTO   ln_exist
          FROM   ic_loct_inv ili
          WHERE  ili.location = move_data_rec_tbl(gn_rec_idx).shipped_locat_code
          AND    ili.item_id  = move_data_rec_tbl(gn_rec_idx).item_id
          AND    ili.lot_id   = move_data_rec_tbl(gn_rec_idx).lot_id
          ;
          -- �莝���ʂ����݂��Ȃ��ꍇ
          IF ( ln_exist = 0 ) THEN
--
            -- 2008/12/11 �{�ԏ�Q#441 Del Start -------------------------------------------
            ---- �x�����b�Z�[�W
            --lv_wk_errmsg
            --  := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,     -- 'XXINV'
            --                              gv_c_msg_57a_009,     -- �莝���ʂȂ��G���[
            --                              gv_c_tkn_shipped_loct,-- �g�[�N���o�Ɍ��ۊǑq��
            --                              move_data_rec_tbl(gn_rec_idx).shipped_locat_code,
            --                              gv_c_tkn_item,        -- �g�[�N���i��
            --                              move_data_rec_tbl(gn_rec_idx).item_code,
            --                              gv_c_tkn_lot_num,     -- �g�[�N�����b�gNo
            --                              move_data_rec_tbl(gn_rec_idx).lot_no,
            --                              gv_c_tkn_mov_num,     -- �g�[�N���ړ��ԍ�
            --                              move_data_rec_tbl(gn_rec_idx).mov_num
            --                             );
            --
            ---- �㑱�����ΏۊO
            --move_data_rec_tbl(gn_rec_idx).ng_flag    := 1;         -- NG�t���O
            ---- �G���[���e�i�[
            --move_data_rec_tbl(gn_rec_idx).err_msg    := lv_wk_errmsg;
            ---- ���݃G���[�`�F�b�N�t���O
            --move_data_rec_tbl(gn_rec_idx).exist_flag := 1;  -- ���݃`�F�b�N�t���O
            -- 2008/12/11 �{�ԏ�Q#441 Del End ---------------------------------------------
--
            -- 2008/12/11 �{�ԏ�Q#441 Add Start -------------------------------------------
            BEGIN
              SELECT xilv.whse_code   -- �q�ɃR�[�h
              INTO   lv_whse_code_from
              FROM   xxcmn_item_locations_v  xilv
                    ,ic_whse_mst             iwm
                    ,sy_orgn_mst_b           somb
              WHERE  xilv.whse_code = iwm.whse_code
              AND    iwm.orgn_code  = somb.orgn_code
              AND    xilv.segment1  = move_data_rec_tbl(gn_rec_idx).shipped_locat_code;  -- �o�Ɍ��ۊǏꏊ�R�[�h
            EXCEPTION
              WHEN OTHERS THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,
                  'GMIPAPI.INVENTORY_POSTING �q�ɃR�[�h�擾�G���[�F'||move_data_rec_tbl(gn_rec_idx).shipped_locat_code);
                RAISE global_api_expt;
            END;
--
            INSERT INTO ic_loct_inv
              (item_id
              ,whse_code
              ,lot_id
              ,location
              ,loct_onhand
              ,loct_onhand2
              ,lot_status
              ,qchold_res_code
              ,delete_mark
              ,text_code
              ,last_updated_by
              ,created_by
              ,last_update_date
              ,creation_date
              ,last_update_login
              ,program_application_id
              ,program_id
              ,program_update_date
              ,request_id
              )
            VALUES
             ( move_data_rec_tbl(gn_rec_idx).item_id             -- item_id
              ,lv_whse_code_from                                 -- whse_code
              ,move_data_rec_tbl(gn_rec_idx).lot_id              -- lot_id
              ,move_data_rec_tbl(gn_rec_idx).shipped_locat_code  -- location
              ,0                                                 -- loct_onhand
              ,NULL                                              -- loct_onhand2
              ,NULL                                              -- lot_status
              ,NULL                                              -- qchold_res_code
              ,0                                                 -- delete_mark
              ,NULL                                              -- text_code
              ,gn_user_id                                        -- last_updated_by
              ,gn_user_id                                        -- created_by
              ,gd_sysdate                                        -- last_update_date
              ,gd_sysdate                                        -- creation_date
              ,NULL                                              -- last_update_login
              ,NULL                                              -- program_application_id
              ,NULL                                              -- program_id
              ,NULL                                              -- program_update_date
              ,NULL                                              -- request_id
             );
            -- 2008/12/11 �{�ԏ�Q#441 Add End ----------------------------------------------
--
          END IF;
        END IF;
      END IF;
--2008/09/26 Y.Kawano Add End
--
      -- �O�����ŃG���[�łȂ��ꍇ
      IF ( move_data_rec_tbl(gn_rec_idx).ng_flag = 0 ) THEN
        -- **************************************************
        -- *** �o�Ɏ��ѓ��Ɠ��Ɏ��ѓ��̔�r
        -- **************************************************
        -- �ړ��^�C�v���ϑ��Ȃ��̏ꍇ
        IF ( move_data_rec_tbl(gn_rec_idx).mov_type = gv_c_move_type_n ) THEN
--
          -- �o�Ɏ��ѓ��Ɠ��Ɏ��ѓ����قȂ�ꍇ
          IF ( TRUNC(move_data_rec_tbl(gn_rec_idx).actual_ship_date)
               <> TRUNC(move_data_rec_tbl(gn_rec_idx).actual_arrival_date) ) THEN
--
            -- �����ϊ� �o�Ɏ��ѓ�
            lv_out_actual_date := TO_CHAR(move_data_rec_tbl(gn_rec_idx).actual_ship_date,
                                          'YYYY/MM/DD');
            -- �����ϊ� ���Ɏ��ѓ�
            lv_in_actual_date := TO_CHAR(move_data_rec_tbl(gn_rec_idx).actual_arrival_date,
                                         'YYYY/MM/DD');
--
            -- �x�����b�Z�[�W
            lv_wk_errmsg
              := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,     -- 'XXINV'
                                          gv_c_msg_57a_004,     -- ���t�s��v���b�Z�[�W
                                          gv_c_tkn_mov_num,                    -- �g�[�N���ړ��ԍ�
                                          move_data_rec_tbl(gn_rec_idx).mov_num,
                                          gv_c_tkn_mov_line_num,               -- �g�[�N�����הԍ�
                                          move_data_rec_tbl(gn_rec_idx).line_number,
                                          gv_c_tkn_item,                       -- �g�[�N���i��
                                          move_data_rec_tbl(gn_rec_idx).item_code,
                                          gv_c_tkn_lot_num,                    -- �g�[�N�����b�gNo
                                          move_data_rec_tbl(gn_rec_idx).lot_no,
                                          gv_c_tkn_shipped_day,                -- �g�[�N���o�Ɏ��ѓ�
                                          lv_out_actual_date,
                                          gv_c_tkn_ship_to_day,                -- �g�[�N�����Ɏ��ѓ�
                                          lv_in_actual_date
                                         );
--
            -- �㑱�����ΏۊO
            move_data_rec_tbl(gn_rec_idx).ng_flag := 1;         -- NG�t���O
            -- �G���[���e�i�[
            move_data_rec_tbl(gn_rec_idx).err_msg := lv_wk_errmsg;
--
          END IF;
        END IF;
      END IF;
--
--      -- �O�����ŃG���[�łȂ��ꍇ
      IF ( move_data_rec_tbl(gn_rec_idx).ng_flag = 0 ) THEN
        -- **************************************************
        -- *** ���ѓ��̍݌ɃJ�����_�`�F�b�N �o�Ɏ��ѓ�
        -- **************************************************
        -- �o�Ɏ��ѓ����݌ɃJ�����_�[�̃I�[�v������Ă��Ȃ��ꍇ
        IF ( TRUNC(move_data_rec_tbl(gn_rec_idx).actual_ship_date)
               <= gd_close_period_date ) THEN
--
          -- �����ϊ� �o�Ɏ��ѓ�
          lv_out_actual_date := TO_CHAR(move_data_rec_tbl(gn_rec_idx).actual_ship_date,
                                        'YYYY/MM/DD');
--
          -- ���b�Z�[�W�o�͂��镶����
          lv_msg_log :=
            gv_c_tkn_val_mov_num  ||':'|| move_data_rec_tbl(gn_rec_idx).mov_num     ||','||
            gv_c_out_date         ||':'|| lv_out_actual_date
            ;
--
          -- �G���[���b�Z�[�W
          lv_wk_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                   gv_c_msg_57a_005,  -- �J�����_�N���[�Y���b�Z�[�W
                                                   gv_c_tkn_errmsg,   -- �g�[�N��MSG
                                                   lv_msg_log         -- �g�[�N���l
                                                   );
          -- �㑱�����ΏۊO
          move_data_rec_tbl(gn_rec_idx).ng_flag := 1;  -- NG�t���O
          -- �G���[���e�i�[
          move_data_rec_tbl(gn_rec_idx).err_msg := lv_wk_errmsg;
--
        END IF;
      END IF;
--
      -- �O�����ŃG���[�łȂ��ꍇ
      IF ( move_data_rec_tbl(gn_rec_idx).ng_flag = 0 ) THEN
        -- **************************************************
        -- *** ���ѓ��̍݌ɃJ�����_�`�F�b�N ���Ɏ��ѓ�
        -- **************************************************
        -- ���Ɏ��ѓ����݌ɃJ�����_�[�I�[�v������Ă��Ȃ��ꍇ
        IF ( TRUNC(move_data_rec_tbl(gn_rec_idx).actual_arrival_date)
              <= gd_close_period_date ) THEN
--
          -- �����ϊ� ���Ɏ��ѓ�
          lv_in_actual_date := TO_CHAR(move_data_rec_tbl(gn_rec_idx).actual_arrival_date,
                                       'YYYY/MM/DD');
--
          -- ���b�Z�[�W�o�͂��镶����
          lv_msg_log :=
            gv_c_tkn_val_mov_num  ||':'|| move_data_rec_tbl(gn_rec_idx).mov_num     ||','||
            gv_c_in_date          ||':'|| lv_in_actual_date
            ;
--
          -- �G���[���b�Z�[�W
          lv_wk_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                   gv_c_msg_57a_005, -- �J�����_�N���[�Y���b�Z�[�W
                                                   gv_c_tkn_errmsg,  -- �g�[�N��MSG
                                                   lv_msg_log        -- �g�[�N���l
                                                   );
--
          -- �㑱�����ΏۊO
          move_data_rec_tbl(gn_rec_idx).ng_flag := 1;  -- NG�t���O
          -- �G���[���e�i�[
          move_data_rec_tbl(gn_rec_idx).err_msg := lv_wk_errmsg;
--
        END IF;
      END IF;
--
-- 2008/12/25 H.Itou Add Start
      -- �O�����ŃG���[�łȂ��ꍇ
      IF ( move_data_rec_tbl(gn_rec_idx).ng_flag = 0 ) THEN
        -- **************************************************
        -- *** ���ѓ��̖������`�F�b�N �o�Ɏ��ѓ�
        -- **************************************************
        -- �o�Ɏ��ѓ����������̏ꍇ
        IF ( TRUNC(move_data_rec_tbl(gn_rec_idx).actual_ship_date) > TRUNC(SYSDATE) ) THEN
--
          -- �����ϊ� �o�Ɏ��ѓ�
          lv_out_actual_date := TO_CHAR(move_data_rec_tbl(gn_rec_idx).actual_ship_date,
                                        'YYYY/MM/DD');
--
          -- ���b�Z�[�W�o�͂��镶����
          lv_msg_log :=
            gv_c_tkn_val_mov_num  ||':'|| move_data_rec_tbl(gn_rec_idx).mov_num     ||','||
            gv_c_out_date         ||':'|| lv_out_actual_date
            ;
--
          -- �G���[���b�Z�[�W
          lv_wk_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                   gv_c_msg_57a_012,   -- �������G���[���b�Z�[�W
                                                   gv_c_tkn_value,     -- �g�[�N��
                                                   gv_c_out_date,      -- �g�[�N���l
                                                   gv_c_tkn_errmsg,    -- �g�[�N��
                                                   lv_msg_log          -- �g�[�N���l
                                                   );
          -- �㑱�����ΏۊO
          move_data_rec_tbl(gn_rec_idx).ng_flag := 1;  -- NG�t���O
          -- �G���[���e�i�[
          move_data_rec_tbl(gn_rec_idx).err_msg := lv_wk_errmsg;
--
        END IF;
      END IF;
--
      -- �O�����ŃG���[�łȂ��ꍇ
      IF ( move_data_rec_tbl(gn_rec_idx).ng_flag = 0 ) THEN
        -- **************************************************
        -- *** ���ѓ��̖������`�F�b�N ���Ɏ��ѓ�
        -- **************************************************
        -- �o�Ɏ��ѓ����������̏ꍇ
        IF ( TRUNC(move_data_rec_tbl(gn_rec_idx).actual_arrival_date) > TRUNC(SYSDATE) ) THEN
--
          -- �����ϊ� ���Ɏ��ѓ�
          lv_in_actual_date := TO_CHAR(move_data_rec_tbl(gn_rec_idx).actual_arrival_date,
                                       'YYYY/MM/DD');
--
          -- ���b�Z�[�W�o�͂��镶����
          lv_msg_log :=
            gv_c_tkn_val_mov_num  ||':'|| move_data_rec_tbl(gn_rec_idx).mov_num     ||','||
            gv_c_in_date          ||':'|| lv_in_actual_date
            ;
--
          -- �G���[���b�Z�[�W
          lv_wk_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                   gv_c_msg_57a_012,   -- �������G���[���b�Z�[�W
                                                   gv_c_tkn_value,     -- �g�[�N��
                                                   gv_c_in_date,       -- �g�[�N���l
                                                   gv_c_tkn_errmsg,    -- �g�[�N��
                                                   lv_msg_log          -- �g�[�N���l
                                                   );
          -- �㑱�����ΏۊO
          move_data_rec_tbl(gn_rec_idx).ng_flag := 1;  -- NG�t���O
          -- �G���[���e�i�[
          move_data_rec_tbl(gn_rec_idx).err_msg := lv_wk_errmsg;
--
        END IF;
      END IF;
-- 2008/12/25 H.Itou Add End
--
    END LOOP check_loop;
--
    --==============================================================
    -- �`�F�b�N��f�[�^����
    --==============================================================
--
    -- ������
    lv_pre_mov_num   := NULL;
    lv_mov_hdr_id_bk := NULL;
    lv_mov_num_bk    := NULL;
    lv_err_mov_num   := NULL;
    ln_tmp_idx       := 1;
    ln_idx           := 1;
--
    <<data_loop>>
    FOR gn_rec_idx IN 1 .. move_data_rec_tbl.COUNT LOOP
--
      -----------------------
      -- for debug
      FND_FILE.PUT_LINE(FND_FILE.LOG,'----- ����LOOP START -----');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lv_mov_num_bk='||lv_mov_num_bk);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lv_err_mov_num='||lv_err_mov_num);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')mov_num='|| move_data_rec_tbl(gn_rec_idx).mov_num);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')line_number='|| move_data_rec_tbl(gn_rec_idx).line_number);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')item_code='|| move_data_rec_tbl(gn_rec_idx).item_code);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_no='|| move_data_rec_tbl(gn_rec_idx).lot_no);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_out_actual_quantity='|| move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_in_actual_quantity='|| move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity);
      -----------------------
--
      -- ������
      out_err_tbl(gn_rec_idx).out_msg := '0';
--
      IF ((move_data_rec_tbl(gn_rec_idx).mov_num <> lv_err_mov_num) 
      OR (lv_err_mov_num IS NULL))
      THEN
        -----------------------------------------------
        -- �`�F�b�N�ŃG���[�ɂȂ�Ȃ������f�[�^�̏ꍇ
        -----------------------------------------------
        IF (move_data_rec_tbl(gn_rec_idx).ng_flag = 0) THEN
--
          -----------------------
          -- for debug
          FND_FILE.PUT_LINE(FND_FILE.LOG,'--- NORMAL DATA ---');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')mov_num='|| move_data_rec_tbl(gn_rec_idx).mov_num);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')line_number='|| move_data_rec_tbl(gn_rec_idx).line_number);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')item_code='|| move_data_rec_tbl(gn_rec_idx).item_code);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_no='|| move_data_rec_tbl(gn_rec_idx).lot_no);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_out_actual_quantity='|| move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_in_actual_quantity='|| move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity);
          -----------------------
--
          -- tmp�Ɋi�[
          move_data_rec_tmp(gn_rec_idx) := move_data_rec_tbl(gn_rec_idx);
          -- �u���C�N�����p �ړ��ԍ��i�[
          lv_mov_num_bk    := move_data_rec_tbl(gn_rec_idx).mov_num;
          lv_mov_hdr_id_bk := move_data_rec_tbl(gn_rec_idx).mov_hdr_id;
--
        -----------------------------------------------
        -- �`�F�b�N�ŃG���[�ɂȂ����f�[�^�̏ꍇ
        -----------------------------------------------
        ELSE
--
          -----------------------
          -- for debug
          FND_FILE.PUT_LINE(FND_FILE.LOG,'--- ERROR DATA ---');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')mov_num='|| move_data_rec_tbl(gn_rec_idx).mov_num);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')line_number='|| move_data_rec_tbl(gn_rec_idx).line_number);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')item_code='|| move_data_rec_tbl(gn_rec_idx).item_code);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_no='|| move_data_rec_tbl(gn_rec_idx).lot_no);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_out_actual_quantity='|| move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_in_actual_quantity='|| move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity);
          -----------------------
--
          -- �X�L�b�v����(�ړ��ԍ��P��)
--mod start 1.2
--          gn_warn_cnt := gn_warn_cnt + 1;
--2008/09/26 Y.Kawano Mod Start
--          --�o�Ɏ��ѐ��ʁ����Ɏ��ѐ��ʂ̏ꍇ�͉��Z���Ȃ�
--          IF (move_data_rec_tbl(gn_rec_idx).skip_flag = 0) THEN
          --�o�Ɏ��ѐ��ʁ����Ɏ��ѐ��ʂ̏ꍇ�͉��Z���Ȃ�
          --�o�Ɍ��̎莝���ʂ����݂��Ȃ��ꍇ�͉��Z���Ȃ�
          IF (  (move_data_rec_tbl(gn_rec_idx).skip_flag = 0) 
            AND (move_data_rec_tbl(gn_rec_idx).exist_flag = 0) ) 
          THEN
            gn_warn_cnt := gn_warn_cnt + 1;
          END IF;
--2008/09/26 Y.Kawano Mod End
--mod end 1.2
--
          IF (move_data_rec_tbl(gn_rec_idx).err_msg IS NOT NULL) THEN
            -- ���O�o�͗pPLSQL�\�Ɋi�[
            out_err_tbl(gn_rec_idx).out_msg := move_data_rec_tbl(gn_rec_idx).err_msg;
          END IF;
--
          -- tmp�N���A
          --move_data_rec_tmp.DELETE;
          move_data_rec_tmp(gn_rec_idx).mov_hdr_id := -1;
--
          -- �u���C�N�p�ړ��ԍ�
          lv_mov_num_bk    := NULL;
          lv_mov_hdr_id_bk := NULL;
          -- �G���[�ړ��ԍ��i�[
          lv_err_mov_num  := move_data_rec_tbl(gn_rec_idx).mov_num;
--
          ---------
          -- for debug
          FND_FILE.PUT_LINE(FND_FILE.LOG,'�G���[�ړ��ԍ��i�[ lv_err_mov_num='||lv_err_mov_num);
          ---------
--
          err_mov_tmp_rec_tbl(ln_tmp_idx).mov_num := move_data_rec_tbl(gn_rec_idx).mov_num;
--2008/09/26 Y.Kawano Add Start
          -- �o�Ɍ��̎莝���ʂ����݂��Ȃ��ꍇ�͑ΏۊO�Ƃ���
          IF ( move_data_rec_tbl(gn_rec_idx).skip_flag = 1 ) THEN
            --�X�L�b�v�t���O�i�[
            err_mov_tmp_rec_tbl(ln_tmp_idx).skip_flag := 1;
            --�ΏۊO�t���O�i�[
            err_mov_tmp_rec_tbl(ln_tmp_idx).out_flag := 1;
          END IF;
          --
          -- �o�Ɏ��ѐ��ʁ����Ɏ��ѐ��ʂ̏ꍇ�͑ΏۊO�Ƃ���
          IF ( move_data_rec_tbl(gn_rec_idx).exist_flag = 1 ) 
          THEN
            --���݃`�F�b�N�t���O�i�[
            err_mov_tmp_rec_tbl(ln_tmp_idx).exist_flag := 1;
            --�ΏۊO�t���O�i�[
            err_mov_tmp_rec_tbl(ln_tmp_idx).out_flag := 1;
          END IF;
--2008/09/26 Y.Kawano Add End
--
          ln_tmp_idx := ln_tmp_idx + 1;
--
        END IF;
      END IF;
--
    END LOOP data_loop;
--
--2008/08/21 Y.Kawano Mod Start
--    <<rec_loop>>
--    FOR gn_rec_idx IN 1 .. move_data_rec_tbl.COUNT LOOP
--
--      -- �G���[�ړ��ԍ�������ꍇ
--      IF err_mov_tmp_rec_tbl.exists(1) then
--
--        <<target_loop>>
--        FOR ln_tmp_idx IN 1 .. err_mov_tmp_rec_tbl.COUNT LOOP
--
--          -- �G���[�ړ��ԍ��łȂ��ꍇ
--          IF  move_data_rec_tbl(gn_rec_idx).mov_num <> err_mov_tmp_rec_tbl(ln_tmp_idx).mov_num THEN
--
--            -- �����Ώ�PLSQL�\�Ɋi�[
--            move_target_tbl(ln_idx) := move_data_rec_tbl(gn_rec_idx);
--            ln_idx := ln_idx + 1;
--
--          END IF;
--
--        END LOOP target_loop;
--
--      -- �G���[�ړ��ԍ����Ȃ��ꍇ
--      ELSE
--
--        -- �����Ώ�PLSQL�\�Ɋi�[
--        move_target_tbl := move_data_rec_tbl;
--
--      END IF;
--
--    END LOOP rec_loop;
--
    -- �G���[�ړ��ԍ�������ꍇ
    IF err_mov_tmp_rec_tbl.exists(1) then
--
      <<rec_loop>>
      FOR gn_rec_idx IN 1 .. move_data_rec_tbl.COUNT LOOP
--
     -- �G���[�`�F�b�N�t���O�̏�����
        lv_err_flg := gv_c_ynkbn_n;
--
        <<target_loop>>
        FOR ln_tmp_idx IN 1 .. err_mov_tmp_rec_tbl.COUNT LOOP
--
          -- �G���[�ړ��ԍ��̏ꍇ
          IF move_data_rec_tbl(gn_rec_idx).mov_num = err_mov_tmp_rec_tbl(ln_tmp_idx).mov_num THEN
--
            lv_err_flg := gv_c_ynkbn_y;
--
--2008/09/26 Y.Kawano Add Start
            --����ړ��ԍ��z����1���ł��ΏۊO���܂܂��ꍇ�A�S�f�[�^��ΏۊO�Ƃ���B
            IF (err_mov_tmp_rec_tbl(ln_tmp_idx).out_flag = 1) THEN
              move_data_rec_tbl(gn_rec_idx).ng_flag := 1;
            END IF;
--2008/09/26 Y.Kawano Add End
--
          END IF;
--
          EXIT target_loop WHEN (lv_err_flg = gv_c_ynkbn_y);
--
        END LOOP target_loop;
--
        IF ( lv_err_flg = gv_c_ynkbn_n ) THEN
            -- �����Ώ�PLSQL�\�Ɋi�[
            move_target_tbl(ln_idx) := move_data_rec_tbl(gn_rec_idx);
            ln_idx := ln_idx + 1;
        END IF;
--
      END LOOP rec_loop;
--
    -- �G���[�ړ��ԍ����Ȃ��ꍇ
    ELSE
--
      -- �����Ώ�PLSQL�\�ɑS�f�[�^���i�[
      move_target_tbl := move_data_rec_tbl;
--
    END IF;
--2008/08/21 Y.Kawano Mod End
--
--2008/09/26 Y.Kawano Add Start
    -- �X�L�b�v�����擾
      <<skip_loop>>
    FOR ln_tmp_idx IN 1 .. err_mov_tmp_rec_tbl.COUNT LOOP
      --������
      lt_bef_mov_num := NULL;
      --
      IF ( ( err_mov_tmp_rec_tbl(ln_tmp_idx).mov_num <> lt_bef_mov_num )
        OR ( lt_bef_mov_num is null ) )
      THEN
        -- �o�Ɍ��̎莝���ʂ����݂��Ȃ��ꍇ��1�`�[1�X�L�b�v�����Ƃ���
        IF ( err_mov_tmp_rec_tbl(ln_tmp_idx).exist_flag = 1 ) 
        THEN
          gn_warn_cnt := gn_warn_cnt + 1;
        END IF;
        -- �o�Ɏ��ѐ��ʁ����Ɏ��ѐ��ʂ̏ꍇ�͑ΏۊO�����Ƃ���
        IF ( err_mov_tmp_rec_tbl(ln_tmp_idx).skip_flag = 1 )
        THEN
          gn_out_cnt := gn_out_cnt + 1;
        END IF;
      --
      END IF;
      --
      --�ړ��ԍ��ޔ�
      lt_bef_mov_num := err_mov_tmp_rec_tbl(ln_tmp_idx).mov_num;
--
    END LOOP skip_loop;
    --
    --�ΏۊO���������݂���ꍇ�A�Ώی������猸������
    IF ( gn_out_cnt <> 0 )
    THEN
      gn_target_cnt := gn_target_cnt - gn_out_cnt;
    END IF;
--2008/09/26 Y.Kawano Add End
--
    -- �X�L�b�v������0���łȂ��ꍇ
    IF gn_warn_cnt <> 0 THEN
      -- �X�e�[�^�X�x���Z�b�g
      ov_retcode := gv_status_warn;             -- �x��
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END check_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_data_proc
   * Description      : �֘A�f�[�^�擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_data_proc(
    ov_errbuf         OUT VARCHAR2,              --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,              --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)              --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_out_orgn_code           IC_TRAN_PND.ORGN_CODE%TYPE;  -- �g�D�R�[�h�o�ɗp
    lv_out_co_code             IC_TRAN_PND.CO_CODE%TYPE;    -- ��ЃR�[�h�o�ɗp
    lv_from_whse_code          IC_TRAN_PND.WHSE_CODE%TYPE;  -- �o�ɑq�ɃR�[�h
--
    lv_in_orgn_code            IC_TRAN_PND.ORGN_CODE%TYPE;  -- �g�D�R�[�h���ɗp
    lv_in_co_code              IC_TRAN_PND.CO_CODE%TYPE;    -- ��ЃR�[�h���ɗp
    lv_to_whse_code            IC_TRAN_PND.WHSE_CODE%TYPE;  -- ���ɑq�ɃR�[�h
--
    ld_out_trans_date          DATE;         -- �����(�o��) ����
    ld_in_trans_date           DATE;         -- �����(����) ����
    ln_out_pnd_trans_qty       NUMBER;       -- �o�ɐ�(�ۗ��g����)
    ln_out_cmp_trans_qty       NUMBER;       -- �o�ɐ�(�����g����)
    ln_in_pnd_trans_qty        NUMBER;       -- ���ɐ�(�ۗ��g����)
    ln_in_cmp_trans_qty        NUMBER;       -- ���ɐ�(�����g����)
    ln_out_cmp_a_trans_qty     NUMBER;       -- �����o�ɐ�(�����g����)
    ln_in_cmp_a_trans_qty      NUMBER;       -- �������ɐ�(�����g����)
--
    ld_a_out_trans_date        DATE;         -- �����(�o��)  ���ђ���
    ld_a_in_trans_date         DATE;         -- �����(����)  ���ђ���

--
    lv_from_orgn_code          SY_ORGN_MST_B.ORGN_CODE%TYPE; -- �g�D�R�[�h(�o�ɗp)
    lv_from_co_code            SY_ORGN_MST_B.CO_CODE%TYPE;   -- ��ЃR�[�h(�o�ɗp)
    lv_to_orgn_code            SY_ORGN_MST_B.ORGN_CODE%TYPE; -- �g�D�R�[�h(���ɗp)
    lv_to_co_code              SY_ORGN_MST_B.CO_CODE%TYPE;   -- ��ЃR�[�h(���ɗp)
    ln_err_flg                 NUMBER := 0;                  -- �f�[�^�擾�t���O
--
    lv_err_msg_value           VARCHAR2(2000);               -- �G���[���b�Z�[�W���e
--
    lv_mov_num_bk              xxinv_mov_req_instr_headers.mov_num%TYPE;    -- �ړ��ԍ�wk�p
    ln_idx_adji                NUMBER := 1;
    ln_idx_trni                NUMBER := 1;
    ln_idx_move                NUMBER := 1;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- ==================================
    -- �g�D,���,�q�ɂ̎擾�J�[�\��
    -- ==================================
    CURSOR xxcmn_locations_cur(
                            ln_from_location_id IN xxcmn_item_locations_v.inventory_location_id%TYPE
                           ,ln_to_location_id   IN xxcmn_item_locations_v.inventory_location_id%TYPE)
    IS
      SELECT somb.orgn_code   from_orgn_code            -- �v�����g�R�[�h(�o�Ɍ�)
            ,somb.co_code     from_co_code              -- ��ЃR�[�h    (�o�Ɍ�)
            ,xilv.whse_code   from_whse_code            -- �q�ɃR�[�h    (�o�Ɍ�)
            ,somb2.orgn_code  to_orgn_code              -- �v�����g�R�[�h(���ɐ�)
            ,somb2.co_code    to_co_code                -- ��ЃR�[�h    (���ɐ�)
            ,xilv2.whse_code  to_whse_code              -- �q�ɃR�[�h    (���ɐ�)
      FROM   xxcmn_item_locations_v xilv              -- OPM�ۊǏꏊ���VIEW(�o�Ɍ��p)
            ,sy_orgn_mst_b          somb              -- OPM�v�����g�}�X�^(�o�Ɍ��p)
            ,xxcmn_item_locations_v xilv2             -- OPM�ۊǏꏊ���VIEW(���ɐ�p)
            ,sy_orgn_mst_b          somb2             -- OPM�v�����g�}�X�^(���ɐ�p)
      WHERE  xilv.orgn_code              = somb.orgn_code         -- �v�����g�R�[�h
      AND    xilv.inventory_location_id  = ln_from_location_id    -- �ۊǑq��ID
      AND    xilv2.orgn_code             = somb2.orgn_code       -- �v�����g�R�[�h
      AND    xilv2.inventory_location_id = ln_to_location_id     -- �ۊǑq��ID
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    <<rec_loop>>
    FOR gn_rec_idx IN 1 .. move_target_tbl.COUNT LOOP
--
      -- �ϐ�������
      lv_out_orgn_code       := NULL;    -- �g�D�R�[�h�o�ɗp
      lv_out_co_code         := NULL;    -- ��ЃR�[�h�o�ɗp
      lv_from_whse_code      := NULL;    -- �o�ɑq�ɃR�[�h
      lv_in_orgn_code        := NULL;    -- �g�D�R�[�h���ɗp
      lv_in_co_code          := NULL;    -- ��ЃR�[�h���ɗp
      lv_to_whse_code        := NULL;    -- ���ɑq�ɃR�[�h
      ld_out_trans_date      := NULL;    -- �����(�o��)
      ld_in_trans_date       := NULL;    -- �����(����)
      ln_out_pnd_trans_qty   := 0;       -- �o�ɐ�(�ۗ��g����)
      ln_out_cmp_trans_qty   := 0;       -- �o�ɐ�(�����g����)
      ln_in_pnd_trans_qty    := 0;       -- ���ɐ�(�ۗ��g����)
      ln_in_cmp_trans_qty    := 0;       -- ���ɐ�(�����g����)
      ln_out_cmp_a_trans_qty := 0;       -- �����o�ɐ�(�����g����)
      ln_in_cmp_a_trans_qty  := 0;       -- �������ɐ�(�����g����)
      lv_err_msg_value       := NULL;    -- �G���[���b�Z�[�W
      lv_mov_num_bk          := NULL;    -- �u���C�N�p�ړ��ԍ�
      out_err_tbl2(gn_rec_idx).out_msg := '0';
      err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := -1;
--
      /*****************************************************/
      -- ���ьv��σt���O=ON,����,���ђ����t���O=ON�̏ꍇ
      /*****************************************************/
      IF (move_target_tbl(gn_rec_idx).comp_actual_flg = gv_c_ynkbn_y)
      AND (move_target_tbl(gn_rec_idx).correct_actual_flg = gv_c_ynkbn_y) THEN
--
--2008/12/11 Y.Kawano Add Start
        /*****************************************/
        -- �����O�㐔�ʂ�0�̏ꍇ
        /*****************************************/
        -- API�o�^������skip����
-- 2009/02/24 v1.21 UPDATE START
/*
        IF ((move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0)
          AND (move_target_tbl(gn_rec_idx).lot_in_actual_quantity = 0)
          AND (move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity = 0)
          AND (move_target_tbl(gn_rec_idx).lot_in_bf_act_quantity = 0))
*/
        IF (
             (
               (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0)
                 AND (move_target_tbl(gn_rec_idx).lot_in_actual_quantity = 0)
                   AND (move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity = 0)
                     AND (move_target_tbl(gn_rec_idx).lot_in_bf_act_quantity = 0)
             )
             OR
             (
               (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0)
                 AND (move_target_tbl(gn_rec_idx).lot_in_actual_quantity IS NULL)
             )
             OR
             (
               (move_target_tbl(gn_rec_idx).lot_out_actual_quantity IS NULL)
                 AND (move_target_tbl(gn_rec_idx).lot_in_actual_quantity = 0)
             )
           )
-- 2009/02/24 v1.21 UPDATE END
        THEN
          NULL;
        ELSE
--2008/12/11 Y.Kawano Add End
--
          /*****************************************/
          -- �ϑ�����̏ꍇ
          /*****************************************/
          IF ( move_target_tbl(gn_rec_idx).mov_type = gv_c_move_type_y ) THEN  --(typeif)
--
          --for debug
          FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------  �ϑ�����   -----------------');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'mov_line_id = '|| move_target_tbl(gn_rec_idx).mov_line_id);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'item_id='||to_char(move_target_tbl(gn_rec_idx).item_id));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'lot_id='||to_char(move_target_tbl(gn_rec_idx).lot_id));
--
            ----------------------------------
            -- �o�Ɍ����
            ----------------------------------
            BEGIN
              -- �ۗ��g������� ���ьv�コ��Ă���ŐV���擾
              SELECT itp.orgn_code               -- �g�D�R�[�h
                    ,itp.co_code                 -- ��ЃR�[�h
                    ,itp.whse_code               -- �q��
                    ,itp.trans_date              -- �����
                    ,itp.trans_qty               -- ����
              INTO   lv_out_orgn_code
                    ,lv_out_co_code
                    ,lv_from_whse_code
                    ,ld_out_trans_date
                    ,ln_out_pnd_trans_qty
              FROM   ic_tran_pnd   itp                      -- OPM�ۗ��݌Ƀg�����U�N�V����
                    ,ic_xfer_mst   ixm                      -- OPM�݌ɓ]���}�X�^
              WHERE  itp.location      = move_target_tbl(gn_rec_idx).shipped_locat_code
                                                                                 -- �o�Ɍ��ۊǑq��
                AND  itp.item_id       = move_target_tbl(gn_rec_idx).item_id     -- �i��ID
                AND  itp.lot_id        = move_target_tbl(gn_rec_idx).lot_id      -- ���b�gID
                AND  itp.doc_type      = gv_c_doc_type_xfer                      -- �����^�C�v
                AND  itp.doc_id        = ixm.transfer_id                         -- ����ID
                AND  itp.completed_ind = 1                                       -- �����t���O
          ------ 2008/04/11 modify start  ------
            --AND  ixm.attribute1    = move_target_tbl(gn_rec_idx).mov_line_id -- �ړ�����ID
            --AND  ROWNUM            = 1                                       -- �ŐV�̃f�[�^
          --ORDER BY itp.creation_date DESC                                    -- �쐬�� �~��
-- 2009/06/09 H.Itou Mod Start �{�ԏ�Q#1527 MAX(ID)�͍ŐV�łȂ��ꍇ������̂ŁAMAX(�ŏI�X�V��)�ɕύX�B
--              AND  ixm.transfer_id IN
--                                  (SELECT MAX(transfer_id)
              AND  ixm.attribute1      = move_target_tbl(gn_rec_idx).mov_line_id
              AND  ixm.last_update_date IN
                                  (SELECT MAX(last_update_date)
-- 2009/06/09 H.Itou Mod End
                                   FROM   ic_xfer_mst
                                   WHERE  item_id        = move_target_tbl(gn_rec_idx).item_id
                                   AND    lot_id         = move_target_tbl(gn_rec_idx).lot_id
                                   AND    from_location  = move_target_tbl(gn_rec_idx).shipped_locat_code
                                   AND    attribute1     = move_target_tbl(gn_rec_idx).mov_line_id
                                   )
            ------ 2008/04/11 modify end    ------
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- �f�[�^�擾�ł��Ȃ��ꍇ�A���ʂ�0�Ƃ���
                ln_out_pnd_trans_qty := 0;
                lv_out_orgn_code     := NULL;
                lv_out_co_code       := NULL;
                lv_from_whse_code    := NULL;
                ld_out_trans_date    := NULL;
            END;
--
            BEGIN
              -- �����g������� ���ьv�コ��Ă���ŐV�̒��������擾
              SELECT itc.trans_qty               -- ����
                    ,itc.trans_date              -- ����� -- 2008/04/14 add
              INTO   ln_out_cmp_trans_qty
                    ,ld_a_out_trans_date                    -- 2008/04/14 add
              FROM   ic_tran_cmp   itc                      -- OPM�����݌Ƀg�����U�N�V����
                    ,ic_adjs_jnl   iaj                      -- OPM�݌ɒ����W���[�i��
                    ,ic_jrnl_mst   ijm                      -- OPM�W���[�i���}�X�^
              WHERE  itc.location      = move_target_tbl(gn_rec_idx).shipped_locat_code
                                                                                  -- �o�Ɍ��ۊǑq��
                AND  itc.item_id       = move_target_tbl(gn_rec_idx).item_id      -- �i��ID
                AND  itc.lot_id        = move_target_tbl(gn_rec_idx).lot_id       -- ���b�gID
                AND  itc.doc_type      = iaj.trans_type                           -- �����^�C�v
                AND  itc.doc_type      = gv_c_doc_type_adji                       -- �����^�C�v
--2008/12/13 Y.Kawano Upd Start
--              --AND  itc.doc_line      = iaj.doc_line                             -- ������הԍ�
                AND  itc.doc_line      = iaj.doc_line                             -- ������הԍ�
                AND  itc.doc_id        = iaj.doc_id                               -- ���ID
--2008/12/13 Y.Kawano Upd End
                AND  ijm.journal_id    = iaj.journal_id                           -- �W���[�i��ID
--2008/12/13 Y.Kawano Del Start
--                AND  ijm.journal_id    = itc.doc_id                               -- �W���[�i��ID
--2008/12/13 Y.Kawano Del End
            ------ 2008/04/11 modify start  ------
              --AND  ijm.attribute1    = move_target_tbl(gn_rec_idx).mov_line_id  -- �ړ�����ID
                AND  itc.location   = iaj.location
                AND  itc.item_id    = iaj.item_id
                AND  itc.lot_id     = iaj.lot_id
-- 2009/06/09 H.Itou Mod Start �{�ԏ�Q#1527 MAX(ID)�͍ŐV�łȂ��ꍇ������̂ŁAMAX(�ŏI�X�V��)�ɕύX�B
--                AND  iaj.journal_id IN
--                                    (SELECT MAX(adj.journal_id)           -- �ŐV�̃f�[�^
                AND  ijm.attribute1 = move_target_tbl(gn_rec_idx).mov_line_id
                AND  iaj.last_update_date IN
                                    (SELECT MAX(adj.last_update_date)           -- �ŐV�̃f�[�^
-- 2009/06/09 H.Itou Mod End
                                     FROM   ic_adjs_jnl   adj
                                           ,ic_jrnl_mst   jrn
                                     WHERE adj.journal_id  = jrn.journal_id
                                     AND   adj.item_id     = move_target_tbl(gn_rec_idx).item_id
                                     AND   adj.lot_id      = move_target_tbl(gn_rec_idx).lot_id
                                     AND   adj.location    = move_target_tbl(gn_rec_idx).shipped_locat_code
                                     AND   jrn.attribute1  = move_target_tbl(gn_rec_idx).mov_line_id
                                     AND   adj.trans_type  = gv_c_doc_type_adji
                                     AND   adj.reason_code = gv_reason_code_cor
                                    )
              --AND  ROWNUM            = 1                                        -- �ŐV�̃f�[�^
              --ORDER BY itc.creation_date DESC                                     -- �쐬�� �~��
            ------ 2008/04/11 modify end    ------
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- �f�[�^�擾�ł��Ȃ��ꍇ�A���ʂ�0�Ƃ���
                ln_out_cmp_trans_qty := 0;
--2009/01/16 Y.Kawano Add Start
                ld_a_out_trans_date    := NULL;
--2009/01/16 Y.Kawano Add End
            END;
--
            ----------------------------------
            -- ���ɐ���
            ----------------------------------
            -- �ۗ��g������� ���ьv�コ��Ă���ŐV���擾
            BEGIN
              SELECT itp.orgn_code               -- �g�D�R�[�h
                    ,itp.co_code                 -- ��ЃR�[�h
                    ,itp.whse_code               -- �q��
                    ,itp.trans_date              -- �����
                    ,itp.trans_qty               -- ����
              INTO   lv_in_orgn_code
                    ,lv_in_co_code
                    ,lv_to_whse_code
                    ,ld_in_trans_date
                    ,ln_in_pnd_trans_qty
              FROM   ic_tran_pnd   itp                      -- OPM�ۗ��݌Ƀg�����U�N�V����
                    ,ic_xfer_mst   ixm                      -- OPM�݌ɓ]���}�X�^
              WHERE  itp.location      = move_target_tbl(gn_rec_idx).ship_to_locat_code
                                                                                -- ���ɐ�ۊǑq��
                AND  itp.item_id       = move_target_tbl(gn_rec_idx).item_id    -- �i��ID
                AND  itp.lot_id        = move_target_tbl(gn_rec_idx).lot_id     -- ���b�gID
                AND  itp.doc_type      = gv_c_doc_type_xfer                     -- �����^�C�v
                AND  itp.doc_id        = ixm.transfer_id                        -- ����ID
                AND  itp.completed_ind = 1                                      -- �����t���O
              ------ 2008/04/11 modify start  ------
             -- AND  ixm.attribute1    = move_target_tbl(gn_rec_idx).mov_line_id -- �ړ�����ID
-- 2009/06/09 H.Itou Mod Start �{�ԏ�Q#1527 MAX(ID)�͍ŐV�łȂ��ꍇ������̂ŁAMAX(�ŏI�X�V��)�ɕύX�B
--                AND  ixm.transfer_id IN
--                                    (SELECT MAX(transfer_id)                     -- �ŐV�̃f�[�^
                AND  ixm.attribute1    = move_target_tbl(gn_rec_idx).mov_line_id
                AND  ixm.last_update_date IN
                                    (SELECT MAX(last_update_date)                     -- �ŐV�̃f�[�^
-- 2009/06/09 H.Itou Mod End
                                     FROM   ic_xfer_mst
                                     WHERE  item_id     = move_target_tbl(gn_rec_idx).item_id
                                     AND    lot_id      = move_target_tbl(gn_rec_idx).lot_id
                                     AND    to_location = move_target_tbl(gn_rec_idx).ship_to_locat_code
                                     AND    attribute1  = move_target_tbl(gn_rec_idx).mov_line_id
                                     )
               --   AND  ROWNUM            = 1                                      -- �ŐV�̃f�[�^
             -- ORDER BY itp.creation_date DESC                                   -- �쐬�� �~��
            ------ 2008/04/11 modify end    ------
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- �f�[�^�擾�ł��Ȃ��ꍇ�A���ʂ�0�Ƃ���
                ln_in_pnd_trans_qty := 0;
                lv_in_orgn_code     := NULL;
                lv_in_co_code       := NULL;
                lv_to_whse_code     := NULL;
                ld_in_trans_date    := NULL;
            END;
--
            -- �����g������� ���ьv�コ��Ă���ŐV�̒��������擾
            BEGIN
              SELECT itc.trans_qty               -- ����
                    ,itc.trans_date              -- ����� -- 2008/04/14 add
              INTO   ln_in_cmp_trans_qty
                    ,ld_a_in_trans_date                     -- 2008/04/14 add
              FROM   ic_tran_cmp   itc                      -- OPM�����݌Ƀg�����U�N�V����
                    ,ic_adjs_jnl   iaj                      -- OPM�݌ɒ����W���[�i��
                    ,ic_jrnl_mst   ijm                      -- OPM�W���[�i���}�X�^
              WHERE  itc.location      = move_target_tbl(gn_rec_idx).ship_to_locat_code
                                                                                -- ���ɐ�ۊǑq��
                AND  itc.item_id       = move_target_tbl(gn_rec_idx).item_id
                                                                                -- �i��ID
                AND  itc.lot_id        = move_target_tbl(gn_rec_idx).lot_id
                                                                                -- ���b�gID
                AND  itc.doc_type      = iaj.trans_type                         -- �����^�C�v
                AND  itc.doc_type      = gv_c_doc_type_adji                     -- �����^�C�v
--2008/12/13 Y.Kawano Upd Start
--              --AND  itc.doc_line      = iaj.doc_line                           -- ������הԍ�
                AND  itc.doc_line      = iaj.doc_line                           -- ������הԍ�
                AND  itc.doc_id        = iaj.doc_id                             -- ���ID
--2008/12/13 Y.Kawano Upd End
                AND  ijm.journal_id    = iaj.journal_id                         -- �W���[�i��ID
--2008/12/13 Y.Kawano Del Start
--                AND  ijm.journal_id    = itc.doc_id                             -- �W���[�i��ID
--2008/12/13 Y.Kawano Del End
            ------ 2008/04/11 modify start  ------
            --  AND  ijm.attribute1    = move_target_tbl(gn_rec_idx).mov_line_id  -- �ړ�����ID
                AND  itc.location   = iaj.location
                AND  itc.item_id    = iaj.item_id
                AND  itc.lot_id     = iaj.lot_id
-- 2009/06/09 H.Itou Mod Start �{�ԏ�Q#1527 MAX(ID)�͍ŐV�łȂ��ꍇ������̂ŁAMAX(�ŏI�X�V��)�ɕύX�B
--                AND  iaj.journal_id IN
--                                    (SELECT MAX(adj.journal_id)           -- �ŐV�̃f�[�^
                AND  ijm.attribute1 = move_target_tbl(gn_rec_idx).mov_line_id
                AND  iaj.last_update_date IN
                                    (SELECT MAX(adj.last_update_date)           -- �ŐV�̃f�[�^
-- 2009/06/09 H.Itou Mod End
                                     FROM   ic_adjs_jnl   adj
                                           ,ic_jrnl_mst   jrn
                                     WHERE adj.journal_id  = jrn.journal_id
                                     AND   adj.item_id     = move_target_tbl(gn_rec_idx).item_id
                                     AND   adj.lot_id      = move_target_tbl(gn_rec_idx).lot_id
                                     AND   adj.location    = move_target_tbl(gn_rec_idx).ship_to_locat_code
                                     AND   jrn.attribute1  = move_target_tbl(gn_rec_idx).mov_line_id
                                     AND   adj.trans_type  = gv_c_doc_type_adji
                                     AND   adj.reason_code = gv_reason_code_cor
                                    )
            --    AND  ROWNUM            = 1                                      -- �ŐV�̃f�[�^
            --  ORDER BY itc.creation_date DESC                                   -- �쐬�� �~��
            ------ 2008/04/11 modify end    ------
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- �f�[�^�擾�ł��Ȃ��ꍇ�A���ʂ�0�Ƃ���
                ln_in_cmp_trans_qty := 0;
--2009/01/16 Y.Kawano Add Start
                ld_a_in_trans_date  := NULL;
--2009/01/16 Y.Kawano Add End
            END;
          ---------------------------------------------------------
          -- 2008/04/08 Modify Start
          -----------------------
          -- for debug
--          FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_out_pnd_trans_qty = '|| to_char(ln_out_pnd_trans_qty));
--          FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_in_pnd_trans_qty = '|| to_char(ln_in_pnd_trans_qty));
--          FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_out_cmp_trans_qty = '|| to_char(ln_out_cmp_trans_qty));
--          FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_in_cmp_trans_qty = '|| to_char(ln_in_cmp_trans_qty));
--
--          FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_out_trans_date = '|| to_char(ld_out_trans_date,'yyyy/mm/dd'));
--          FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_in_trans_date = '|| to_char(ld_in_trans_date,'yyyy/mm/dd'));
--          FND_FILE.PUT_LINE(FND_FILE.LOG,'actual_ship_date = '|| to_char(move_target_tbl(gn_rec_idx).actual_ship_date,'yyyy/mm/dd'));
--          FND_FILE.PUT_LINE(FND_FILE.LOG,'actual_arrival_date = '|| to_char(move_target_tbl(gn_rec_idx).actual_arrival_date,'yyyy/mm/dd'));
          -- for debug
          FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_out_pnd_trans_qty = '|| to_char(ln_out_pnd_trans_qty));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_in_pnd_trans_qty  = '|| to_char(ln_in_pnd_trans_qty));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_out_cmp_trans_qty = '|| to_char(ln_out_cmp_trans_qty));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_in_cmp_trans_qty  = '|| to_char(ln_in_cmp_trans_qty));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'out_actual_quantity  = '|| to_char(move_target_tbl(gn_rec_idx).lot_out_actual_quantity));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'in_actual_quantity   = '|| to_char(move_target_tbl(gn_rec_idx).lot_in_actual_quantity));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'out_bef_actual_qty   = '|| to_char(move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'in_bef_actual_qty    = '|| to_char(move_target_tbl(gn_rec_idx).lot_in_bf_act_quantity));
--
          FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_out_trans_date    = '|| to_char(ld_out_trans_date,'yyyy/mm/dd'));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_in_trans_date     = '|| to_char(ld_in_trans_date,'yyyy/mm/dd'));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_a_out_trans_date  = '|| to_char(ld_a_out_trans_date,'yyyy/mm/dd'));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_a_in_trans_date   = '|| to_char(ld_a_in_trans_date,'yyyy/mm/dd'));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'actual_ship_date     = '|| to_char(move_target_tbl(gn_rec_idx).actual_ship_date,'yyyy/mm/dd'));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'actual_arrival_date  = '|| to_char(move_target_tbl(gn_rec_idx).actual_arrival_date,'yyyy/mm/dd'));
          -----------------------
--
            ---------------------------------------------------------
            -- �ۗ��g�����o�ɂƓ��ɁA�܂��͊����g�����̏o�ɂƓ��ɂ��قȂ�
            ---------------------------------------------------------
            IF (ABS(ln_out_pnd_trans_qty) <> ABS(ln_in_pnd_trans_qty))  -- �ۗ��g�����̓��o�ɐ����Ⴄ
            OR (ABS(ln_out_cmp_trans_qty) <> ABS(ln_in_cmp_trans_qty))  -- �����g�����̓��o�ɐ����Ⴄ
            THEN  --(s)
--
              -- �ۗ��g�����܂��͊����g�����̃f�[�^�s����
              RAISE global_api_expt;
--
            ---------------------------------------------------------
            -- �ۗ��g�����o�ɂƓ��ɁA�����g�����̏o�ɂƓ��ɂ�����
            ---------------------------------------------------------
            ELSIF (ABS(ln_out_pnd_trans_qty) = ABS(ln_in_pnd_trans_qty)) -- �ۗ��g�����̓��o�ɐ�������
              AND (ABS(ln_out_cmp_trans_qty) = ABS(ln_in_cmp_trans_qty)) -- �����g�����̓��o�ɐ�������
            THEN  --(s)
--
              -- for debug -------------------------------------------
              FND_FILE.PUT_LINE(FND_FILE.LOG,'�y1�z�ۗ��g�����o�ɂƓ��ɁA�����g�����̏o�ɂƓ��ɂ�����');
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_out_pnd_trans_qty = '|| to_char(ABS(ln_out_pnd_trans_qty)));
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_in_pnd_trans_qty = '|| to_char(ABS(ln_in_pnd_trans_qty)));
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_out_cmp_trans_qty = '|| to_char(ABS(ln_out_cmp_trans_qty)));
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_in_cmp_trans_qty = '|| to_char(ABS(ln_in_cmp_trans_qty)));
--
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_in_cmp_trans_qty = '|| to_char(ABS(ln_in_cmp_trans_qty)));
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_in_cmp_trans_qty = '|| to_char(ABS(ln_in_cmp_trans_qty)));
              -- for debug -------------------------------------------
--
              --===========================================================
              -- ����(�ۗ��g����)�̓��t�ƈړ��w�b�_�A�h�I���̎��ѓ����قȂ�ꍇ
              -- ���S�ԍ��
              --===========================================================
              IF (TRUNC(ld_out_trans_date) <> TRUNC(move_target_tbl(gn_rec_idx).actual_ship_date))   -- �o�Ɏ��ѓ�
              OR (TRUNC(ld_in_trans_date) <> TRUNC(move_target_tbl(gn_rec_idx).actual_arrival_date)) -- ���Ɏ��ѓ�
              THEN  --(r)
--
              -- for debug
              FND_FILE.PUT_LINE(FND_FILE.LOG,'�y2�z����(�ۗ��g����)�̓��t�ƈړ��w�b�_�A�h�I���̎��ѓ����قȂ�');
--
              -- 2008/04/14 modify start
              --  -----------------------------------------------------------------
              --  -- ����(�ۗ��g����)�̐��ʂƎ��ђ���(�����g����)�̐��ʂ��قȂ�ꍇ
              --  -- �ԍ��
              --  IF  (ABS(ln_out_pnd_trans_qty) <> ABS(ln_out_cmp_trans_qty))    -- �o�ɐ�pnd��cmp
              --  AND (ABS(ln_in_pnd_trans_qty)  <> ABS(ln_in_cmp_trans_qty))     -- ���ɐ�pnd��cmp
              --  THEN
--
              -- for debug
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'�y2-1�zld_out_trans_date='|| to_char(ld_out_trans_date,'yyyy/mm/dd'));
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'�y2-1�zld_a_out_trans_date='|| to_char(ld_a_out_trans_date,'yyyy/mm/dd'));
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'�y2-1�zld_in_trans_date='|| to_char(ld_in_trans_date,'yyyy/mm/dd'));
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'�y2-1�zld_a_in_trans_date='|| to_char(ld_a_in_trans_date,'yyyy/mm/dd'));
--
                --=============================================================
                -- ����(�ۗ��g����)�Ǝ��ђ���(�����g����)�̎�������قȂ�ꍇ
                --=============================================================
                IF  (TRUNC(ld_out_trans_date) <> TRUNC(ld_a_out_trans_date)) -- �o�ɓ� ���тƎ��ђ���
                OR (TRUNC(ld_in_trans_date)  <> TRUNC(ld_a_in_trans_date))   -- ���ɓ� ���тƎ��ђ���
                OR ld_a_out_trans_date IS NULL
                OR ld_a_in_trans_date IS NULL
                THEN  --(q)
                -- 2008/04/14 modify end
--
              -- for debug
              FND_FILE.PUT_LINE(FND_FILE.LOG,'�y3�z����(�ۗ��g����)�̐��ʂƎ��ђ���(�����g����)�̎��ѓ����قȂ�');
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'�y4�z���ђ������i�[  start');
--
                  -- ���э����ʂ�0�łȂ��ꍇ
                  IF (ln_out_pnd_trans_qty <> 0) THEN
                    -----------------------------------------------------------------
                    -- �ԏ��
                    -- ���ђ������i�[  �݌ɐ���API���s�Ώۃ��R�[�h�Ƀf�[�^���i�[
                    adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
                    adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
                    adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
                    adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                    adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
                    adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                    adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_pnd_trans_qty);
                    adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_pnd_trans_qty);
                    adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
                    adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
                    adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
                    adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
                    adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
                    adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
                    adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                    -- �C���N�������g
                    ln_idx_adji := ln_idx_adji + 1;
                  END IF;
--
                -- for debug
--                FND_FILE.PUT_LINE(FND_FILE.LOG,'�y5�z���ђ������i�[  end');
                  -----------------------------------------------------------------
                  -- �����
                  -- �ړ����b�g�ڍׂ̐��ʂ�0�̏ꍇ(���ѓo�^���Ȃ�)
                  IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN  --(o)
                    -- �������Ȃ�
                    NULL;
--
                  -- for debug
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'�y6�z�ړ����b�g�ڍׂ̐��ʂ�0');
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'�������Ȃ�');
--
                  -----------------------------------------------------------------
                  -- �ړ����b�g�ڍׂ̐��ʂ�0�ȊO�̏ꍇ(���ѓo�^����)
                  ELSE  --(o)
--
                  -- for debug
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'�y7�z�ړ����b�g�ڍׂ̐��ʂ�0����Ȃ�');
--
                    -- ����(�ۗ��g����)�̐��ʂ�0�̏ꍇ�͑O��0���ьv�コ��Ă��邩��ۗ��g�����Ƀf�[�^�Ȃ�
                    -- �q�ɑg�D��Џ�񂪂Ȃ����ߎ擾����
                    IF (ln_out_pnd_trans_qty = 0) THEN  --(p)
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y8�z����(�ۗ��g����)�̐��ʂ�0������g�D���擾');
--
                      BEGIN
                        -- �ϐ�������
                        lv_from_orgn_code := NULL;
                        lv_from_co_code   := NULL;
                        lv_from_whse_code := NULL;
                        lv_to_orgn_code   := NULL;
                        lv_to_co_code     := NULL;
                        lv_to_whse_code   := NULL;
                        ln_err_flg        := 0;
--
                        -- �g�D,���,�q�ɂ̎擾�J�[�\���I�[�v��
                        OPEN xxcmn_locations_cur(
                                  move_target_tbl(gn_rec_idx).shipped_locat_id    -- �o�Ɍ�
                                 ,move_target_tbl(gn_rec_idx).ship_to_locat_id ); -- ���ɐ�
--
                        <<xxcmn_locations_cur_loop>>
                        LOOP
                          FETCH xxcmn_locations_cur
                          INTO  lv_from_orgn_code       -- �g�D�R�[�h(�o�ɗp)
                               ,lv_from_co_code         -- ��ЃR�[�h(�o�ɗp)
                               ,lv_from_whse_code       -- �q�ɃR�[�h(�o�ɗp)
                               ,lv_to_orgn_code         -- �g�D�R�[�h(���ɗp)
                               ,lv_to_co_code           -- ��ЃR�[�h(���ɗp)
                               ,lv_to_whse_code         -- �q�ɃR�[�h(���ɗp)
                               ;
                          EXIT WHEN xxcmn_locations_cur%NOTFOUND;

                        END LOOP xxcmn_locations_cur_loop;
--
                        -- �J�[�\���N���[�Y
                        CLOSE xxcmn_locations_cur;
--
                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN                             -- �f�[�^�擾�G���[ 
                          -- �G���[�t���O
                          ln_err_flg  := 1;
                          IF (xxcmn_locations_cur%ISOPEN) THEN
                            -- �J�[�\���N���[�Y
                            CLOSE xxcmn_locations_cur;
                          END IF;
                          -- �G���[���b�Z�[�W���e
                          lv_err_msg_value
                                := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                                gv_c_tkn_msg,     -- �g�[�N��MSG
                                                                lv_err_msg_value  -- �g�[�N���l
                                                                );
                          -- �G���[���e�i�[
                          out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                          -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
                          err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                          err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                        WHEN TOO_MANY_ROWS THEN                             -- �f�[�^�擾�G���[ 
                          -- �G���[�t���O
                          ln_err_flg  := 1;
--
                          IF (xxcmn_locations_cur%ISOPEN) THEN
                            -- �J�[�\���N���[�Y
                            CLOSE xxcmn_locations_cur;
                          END IF;
                          -- �G���[���b�Z�[�W���e
                          lv_err_msg_value
                                := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                                gv_c_tkn_msg,     -- �g�[�N��MSG
                                                                lv_err_msg_value  -- �g�[�N���l
                                                                );
                          -- �G���[���e�i�[
                          out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                          -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
                          err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                          err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                      END;
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y9�z�g�D���擾  END');
--
                      -----------------------------------------------------------------
                      -- �g�D�A��ЁA�q�ɏ�񂪎擾�ł����ꍇ
                      IF (ln_err_flg = 0) THEN
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y10�z���ѓo�^�p�Ɋi�[ start');
--
                        -- ���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
                        move_api_rec_tbl(ln_idx_move).orgn_code              := lv_from_orgn_code;
                        move_api_rec_tbl(ln_idx_move).item_no                := move_target_tbl(gn_rec_idx).item_code;
                        move_api_rec_tbl(ln_idx_move).lot_no                 := move_target_tbl(gn_rec_idx).lot_no;
                        move_api_rec_tbl(ln_idx_move).source_warehouse       := lv_from_whse_code;
                        move_api_rec_tbl(ln_idx_move).source_location        := move_target_tbl(gn_rec_idx).shipped_locat_code; -- �o�Ɍ�
                        move_api_rec_tbl(ln_idx_move).target_warehouse       := lv_to_whse_code;
                        move_api_rec_tbl(ln_idx_move).target_location        := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- ���ɐ�
-- 2008/12/25 Y.Kawano Upd Start #844
--                        move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                        move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).schedule_arrival_date;
                        move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).actual_ship_date;
                        move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
                        move_api_rec_tbl(ln_idx_move).actual_release_date    := move_target_tbl(gn_rec_idx).actual_ship_date;    -- �o�Ɏ��ѓ�
                        move_api_rec_tbl(ln_idx_move).actual_receive_date    := move_target_tbl(gn_rec_idx).actual_arrival_date; -- ���Ɏ��ѓ�
                        move_api_rec_tbl(ln_idx_move).release_quantity1      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                        move_api_rec_tbl(ln_idx_move).attribute1             := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                        -- �C���N�������g
                        ln_idx_move := ln_idx_move + 1;
--
                      END IF;
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y11�z���ѓo�^�p�Ɋi�[ end');
--
                    -----------------------------------------------------
                    -- ����(�ۗ��g����)�̐��ʂ�0�łȂ��ꍇ
                    -- �O����ьv�コ��Ă��邩��q�ɑg�D��Џ�񂪂���
                    -----------------------------------------------------
                    ELSE  --(p)
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y12�z�g�D��񂠂邩��  �f�[�^�����i�[ START');
--
                      -- ���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
                      move_api_rec_tbl(ln_idx_move).orgn_code              := lv_out_orgn_code;
                      move_api_rec_tbl(ln_idx_move).item_no                := move_target_tbl(gn_rec_idx).item_code;
                      move_api_rec_tbl(ln_idx_move).lot_no                 := move_target_tbl(gn_rec_idx).lot_no;
                      move_api_rec_tbl(ln_idx_move).source_warehouse       := lv_from_whse_code;
                      move_api_rec_tbl(ln_idx_move).source_location        := move_target_tbl(gn_rec_idx).shipped_locat_code; -- �o�Ɍ�
                      move_api_rec_tbl(ln_idx_move).target_warehouse       := lv_to_whse_code;
                      move_api_rec_tbl(ln_idx_move).target_location        := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- ���ɐ�
-- 2008/12/25 Y.Kawano Upd Start #844
--                      move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                      move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).schedule_arrival_date;
                      move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).actual_ship_date;
                      move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
                      move_api_rec_tbl(ln_idx_move).actual_release_date    := move_target_tbl(gn_rec_idx).actual_ship_date;    -- �o�Ɏ��ѓ�
                      move_api_rec_tbl(ln_idx_move).actual_receive_date    := move_target_tbl(gn_rec_idx).actual_arrival_date; -- ���Ɏ��ѓ�
                      move_api_rec_tbl(ln_idx_move).release_quantity1      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                      move_api_rec_tbl(ln_idx_move).attribute1             := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                      -- �C���N�������g
                      ln_idx_move := ln_idx_move + 1;
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y13�z�g�D��񂠂邩��  �f�[�^�����i�[ End');
--
                    END IF;  --(p)
--
                  END IF;  --(o)
--
              -- 2008/04/14 modify start
              --  ---------------------------------------------------------------
              --  -- ����(�ۗ��g����)�Ǝ��ђ���(�����g����)�̂������ꍇ
              --  ---------------------------------------------------------------
              --  ELSIF (ABS(ln_out_pnd_trans_qty) = ABS(ln_out_cmp_trans_qty))   -- �o�ɐ�
              --  AND   (ABS(ln_in_pnd_trans_qty)  = ABS(ln_in_cmp_trans_qty))    -- ���ɐ�
              --  THEN
--
                --=============================================================
                -- ����(�ۗ��g����)�Ǝ��ђ���(�����g����)�̎�����������ꍇ
                --=============================================================
                ELSIF (TRUNC(ld_out_trans_date) = TRUNC(ld_a_out_trans_date))  -- �o�ɓ� ���тƎ��ђ���
                AND (TRUNC(ld_in_trans_date)  = TRUNC(ld_a_in_trans_date))  -- ���ɓ� ���тƎ��ђ���
                THEN  --(q)
--
                -- for debug
                FND_FILE.PUT_LINE(FND_FILE.LOG,'�y14a ����(�ۗ��g����)�Ǝ��ђ���(�����g����)�̎�����������z');
--
                ---------------------------------------------------------------
                -- ����(�ۗ��g����)�Ǝ��ђ���(�����g����)�̐��ʂ������ꍇ
                ---------------------------------------------------------------
                  IF (ABS(ln_out_pnd_trans_qty) = ABS(ln_out_cmp_trans_qty))   -- �o�ɐ�
                  AND (ABS(ln_in_pnd_trans_qty) = ABS(ln_in_cmp_trans_qty))    -- ���ɐ�
                  THEN  --(m)
--
                  -- for debug
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'�y14b ����(�ۗ��g����)�Ǝ��ђ���(�����g����)�̐��ʂ������z');
--
                    -- 2008/04/15 modify start
                    -- �������Ȃ�
                    -- NULL;
--
                    -- ���b�g�ڍׂ̎��ѐ��ʂ�0�̏ꍇ
                    IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN
                      -- �������Ȃ�
                      NULL;
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y14c ���b�g�ڍׂ̎��ѐ��ʂ�0  �������Ȃ��z');
--
                    -- ���b�g�ڍׂ̎��ѐ��ʂ�0�ȊO�̏ꍇ
                    ELSE
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y14c ���b�g�ڍׂ̎��ѐ��ʂ�0����Ȃ�  ���쐬�z');
--
                      -- ���쐬
                      move_api_rec_tbl(ln_idx_move).orgn_code              := lv_out_orgn_code;
                      move_api_rec_tbl(ln_idx_move).item_no                := move_target_tbl(gn_rec_idx).item_code;
                      move_api_rec_tbl(ln_idx_move).lot_no                 := move_target_tbl(gn_rec_idx).lot_no;
                      move_api_rec_tbl(ln_idx_move).source_warehouse       := lv_from_whse_code;
                      move_api_rec_tbl(ln_idx_move).source_location        := move_target_tbl(gn_rec_idx).shipped_locat_code; -- �o�Ɍ�
                      move_api_rec_tbl(ln_idx_move).target_warehouse       := lv_to_whse_code;
                      move_api_rec_tbl(ln_idx_move).target_location        := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- ���ɐ�
-- 2008/12/25 Y.Kawano Upd Start #844
--                      move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                      move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).schedule_arrival_date;
                      move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).actual_ship_date;
                      move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
                      move_api_rec_tbl(ln_idx_move).actual_release_date    := move_target_tbl(gn_rec_idx).actual_ship_date;    -- �o�Ɏ��ѓ�
                      move_api_rec_tbl(ln_idx_move).actual_receive_date    := move_target_tbl(gn_rec_idx).actual_arrival_date; -- ���Ɏ��ѓ�
                      move_api_rec_tbl(ln_idx_move).release_quantity1      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                      move_api_rec_tbl(ln_idx_move).attribute1             := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                      -- �C���N�������g
                      ln_idx_move := ln_idx_move + 1;
--
                    END IF;
                    -- 2008/04/15 modify end
--
                  ---------------------------------------------------------------
                  -- ����(�ۗ��g����)�Ǝ��ђ���(�����g����)�̐��ʂ��قȂ�ꍇ
                  ---------------------------------------------------------------
                  ELSE  --(m)
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'�y14�z����(�ۗ��g����)�Ǝ��ђ���(�����g����)�̐��ʂ��قȂ�');
--
                    -- 2008/04/14 modify start
                    -- �ԍ쐬
                    -- �����ʂ�0�ȊO(���т���)�̏ꍇ�A�ԍ��
                    IF (ln_out_pnd_trans_qty <> 0) THEN
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y14-1�z�ԍ쐬  �i�[ start');
--
                      -- ���ђ������i�[  �݌ɐ���API���s�Ώۃ��R�[�h�Ƀf�[�^���i�[
                      adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
                      adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
                      adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
                      adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                      adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
                      adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                      adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_pnd_trans_qty);
                      adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_pnd_trans_qty);
                      adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
                      adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
                      adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
                      adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
                      adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
                      adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
                      adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                      -- �C���N�������g
                      ln_idx_adji := ln_idx_adji + 1;
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y14-1�z�ԍ쐬  �i�[ end');
--
                    END IF;
                    -- 2008/04/14 modify end
--
                    -- ���쐬
                    -----------------------------------------------------------------
                    -- �ړ����b�g�ڍׂ̐��ʂ�0�̏ꍇ(���ѓo�^���Ȃ�)
                    IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN  --(l)
--
                      -- �������Ȃ�
                      NULL;
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y15�z�ړ����b�g�ڍׂ̐��ʂ�0');
--
                   -----------------------------------------------------------------
                    -- �ړ����b�g�ڍׂ̐��ʂ�0�ȊO�̏ꍇ(���ѓo�^����)
                    ELSE  --(l)
                      --for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y16�z�ړ����b�g�ڍׂ̐��ʂ�0�ȊO');
--
                      -- ����(�ۗ��g����)�̐��ʂ�0�̏ꍇ�͑O��0���ьv�コ��Ă��邩��ۗ��g�����Ƀf�[�^�Ȃ�
                      -- �q�ɑg�D��Џ�񂪂Ȃ����ߎ擾����
                      IF (ln_out_pnd_trans_qty = 0) THEN  --(k)
--
                        --for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y17�z����(�ۗ��g����)�̐��ʂ�0������g�D���擾');
--
                        BEGIN
                          -- �ϐ�������
                          lv_from_orgn_code := NULL;
                          lv_from_co_code   := NULL;
                          lv_from_whse_code := NULL;
                          lv_to_orgn_code   := NULL;
                          lv_to_co_code     := NULL;
                          lv_to_whse_code   := NULL;
                          ln_err_flg        := 0;
--
                          -- �g�D,���,�q�ɂ̎擾�J�[�\���I�[�v��
                          OPEN xxcmn_locations_cur(
                                    move_target_tbl(gn_rec_idx).shipped_locat_id    -- �o�Ɍ�
                                   ,move_target_tbl(gn_rec_idx).ship_to_locat_id ); -- ���ɐ�
--
                          <<xxcmn_locations_cur_loop>>
                          LOOP
                            FETCH xxcmn_locations_cur
                            INTO  lv_from_orgn_code       -- �g�D�R�[�h(�o�ɗp)
                                 ,lv_from_co_code         -- ��ЃR�[�h(�o�ɗp)
                                 ,lv_from_whse_code       -- �q�ɃR�[�h(�o�ɗp)
                                 ,lv_to_orgn_code         -- �g�D�R�[�h(���ɗp)
                                 ,lv_to_co_code           -- ��ЃR�[�h(���ɗp)
                                 ,lv_to_whse_code         -- �q�ɃR�[�h(���ɗp)
                                 ;
                            EXIT WHEN xxcmn_locations_cur%NOTFOUND;
--
                          END LOOP xxcmn_locations_cur_loop;
--
                          -- �J�[�\���N���[�Y
                          CLOSE xxcmn_locations_cur;
--
                        EXCEPTION
                          WHEN NO_DATA_FOUND THEN                             -- �f�[�^�擾�G���[ 
                            -- �G���[�t���O
                            ln_err_flg  := 1;
                            IF (xxcmn_locations_cur%ISOPEN) THEN
                              -- �J�[�\���N���[�Y
                              CLOSE xxcmn_locations_cur;
                            END IF;
                            -- �G���[���b�Z�[�W���e
                            lv_err_msg_value
                                  := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                            lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                  gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                                  gv_c_tkn_msg,     -- �g�[�N��MSG
                                                                  lv_err_msg_value  -- �g�[�N���l
                                                                  );
                            -- �G���[���e�i�[
                            out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                            -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
                            err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                            err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                          WHEN TOO_MANY_ROWS THEN                             -- �f�[�^�擾�G���[ 
                            -- �G���[�t���O
                            ln_err_flg  := 1;
--
                            IF (xxcmn_locations_cur%ISOPEN) THEN
                              -- �J�[�\���N���[�Y
                              CLOSE xxcmn_locations_cur;
                            END IF;
                            -- �G���[���b�Z�[�W���e
                            lv_err_msg_value
                                  := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                            lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                  gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                                  gv_c_tkn_msg,     -- �g�[�N��MSG
                                                                  lv_err_msg_value  -- �g�[�N���l
                                                                  );
                            -- �G���[���e�i�[
                            out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                            -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
                            err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                            err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                        END;
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y18�z�g�D���擾 END');
--
                        -----------------------------------------------------------------
                        -- �g�D�A��ЁA�q�ɏ�񂪎擾�ł����ꍇ
                        IF (ln_err_flg = 0) THEN
                          --for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'�y19�z���ѓo�^�p�i�[ start');
--
                          -- ���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
                          move_api_rec_tbl(ln_idx_move).orgn_code              := lv_from_orgn_code;
                          move_api_rec_tbl(ln_idx_move).item_no                := move_target_tbl(gn_rec_idx).item_code;
                          move_api_rec_tbl(ln_idx_move).lot_no                 := move_target_tbl(gn_rec_idx).lot_no;
                          move_api_rec_tbl(ln_idx_move).source_warehouse       := lv_from_whse_code;
                          move_api_rec_tbl(ln_idx_move).source_location        := move_target_tbl(gn_rec_idx).shipped_locat_code; -- �o�Ɍ�
                          move_api_rec_tbl(ln_idx_move).target_warehouse       := lv_to_whse_code;
                          move_api_rec_tbl(ln_idx_move).target_location        := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- ���ɐ�
-- 2008/12/25 Y.Kawano Upd Start #844
--                          move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                          move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).schedule_arrival_date;
                          move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).actual_ship_date;
                          move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
                          move_api_rec_tbl(ln_idx_move).actual_release_date    := move_target_tbl(gn_rec_idx).actual_ship_date;    -- �o�Ɏ��ѓ�
                          move_api_rec_tbl(ln_idx_move).actual_receive_date    := move_target_tbl(gn_rec_idx).actual_arrival_date; -- ���Ɏ��ѓ�
                          move_api_rec_tbl(ln_idx_move).release_quantity1      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                          move_api_rec_tbl(ln_idx_move).attribute1             := to_char(move_target_tbl(gn_rec_idx).mov_line_id);

--
                          -- �C���N�������g
                          ln_idx_move := ln_idx_move + 1;
--
                          --for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'�y20�z���ѓo�^�p�i�[ end');
--
                        END IF;
--
                      -----------------------------------------------------
                      -- ����(�ۗ��g����)�̐��ʂ�0�łȂ��ꍇ
                      -- �O����ьv�コ��Ă��邩��q�ɑg�D��Џ�񂪂���
                      -----------------------------------------------------
                      ELSE  --(k)
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y21�z���ѓo�^�p�i�[ start');
--
                        -- ���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
                        move_api_rec_tbl(ln_idx_move).orgn_code              := lv_out_orgn_code;
                        move_api_rec_tbl(ln_idx_move).item_no                := move_target_tbl(gn_rec_idx).item_code;
                        move_api_rec_tbl(ln_idx_move).lot_no                 := move_target_tbl(gn_rec_idx).lot_no;
                        move_api_rec_tbl(ln_idx_move).source_warehouse       := lv_from_whse_code;
                        move_api_rec_tbl(ln_idx_move).source_location        := move_target_tbl(gn_rec_idx).shipped_locat_code; -- �o�Ɍ�
                        move_api_rec_tbl(ln_idx_move).target_warehouse       := lv_to_whse_code;
                        move_api_rec_tbl(ln_idx_move).target_location        := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- ���ɐ�
-- 2008/12/25 Y.Kawano Upd Start #844
--                        move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                        move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).schedule_arrival_date;
                        move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).actual_ship_date;
                        move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
                        move_api_rec_tbl(ln_idx_move).actual_release_date    := move_target_tbl(gn_rec_idx).actual_ship_date;    -- �o�Ɏ��ѓ�
                        move_api_rec_tbl(ln_idx_move).actual_receive_date    := move_target_tbl(gn_rec_idx).actual_arrival_date; -- ���Ɏ��ѓ�
                        move_api_rec_tbl(ln_idx_move).release_quantity1      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                        move_api_rec_tbl(ln_idx_move).attribute1             := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                        -- �C���N�������g
                        ln_idx_move := ln_idx_move + 1;
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y22�z���ѓo�^�p�i�[ end');
--
                      END IF;  --(k)
--
                    END IF;  --(l)
--
                  END IF;  --(m)
--
                END IF;--(q)
--
              --===========================================================
              -- ����(�ۗ��g����)�̓��t�ƈړ��w�b�_�A�h�I���̎��ѓ��������ꍇ 
              -- �����ʂ��ύX����Ă���f�[�^�̂ݏ����Ώۂɂ���
              --===========================================================
              ELSE  --(r)
-- add start 1.9
                IF((move_target_tbl(gn_rec_idx).lot_out_actual_quantity = move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity) 
                  AND (move_target_tbl(gn_rec_idx).lot_in_actual_quantity = move_target_tbl(gn_rec_idx).lot_in_bf_act_quantity))
                THEN  --(j)
                  NULL;
                ELSE  --(j)
-- add end 1.9
                  --for debug
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'�y23�z�ۗ��g�����̓��t�ƃA�h�I���̎��ѓ�������');
--
-- 2008/12/16 Y.Kawano Del Start
-- ��LIF��(j)�ŁA�ύX�Ȃ����͑ΏۊO�ƂȂ��Ă���ׁA�s�v��IF�����폜
--                  ------------------------------------------------------------------
--                  -- ���b�g�ڍ׃A�h�I���̐��ʂƎ���(�ۗ��g����)�̐��ʂ������ꍇ
--                  -- �����b�g�ڍ׃A�h�I���̐��ʂ��ύX����Ă��Ȃ�
--                  ------------------------------------------------------------------
--                  IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = ABS(ln_out_pnd_trans_qty)) THEN  --(i)
--
--                    -- �������Ȃ�
--                    NULL;
--                    --for debug
--                    FND_FILE.PUT_LINE(FND_FILE.LOG,'�y24�z���b�g�ڍ׃A�h�I�����ʂƎ���(�ۗ��g����)�̐��ʂ�����');
--                    FND_FILE.PUT_LINE(FND_FILE.LOG,'�y24-1�z�������Ȃ�');
--
--                  ------------------------------------------------------------------
--                  -- ���b�g�ڍ׃A�h�I���̐��ʂƎ���(�ۗ��g����)�̐��ʂ��قȂ�ꍇ
--                  -- �����b�g�ڍ׃A�h�I���̐��ʂ��ύX����Ă���
--                  ------------------------------------------------------------------
--                  ELSE  --(i)
-- 2008/12/16 Y.Kawano Del End
--
                    --for debug
--                    FND_FILE.PUT_LINE(FND_FILE.LOG,'�y25�z���b�g�ڍ׃A�h�I���̐��ʂƎ���(�ۗ��g����)�̐��ʂ��قȂ�');
--
                    --================================================================
                    -- ����(�ۗ��g����)�̐��ʂƎ��ђ���(�����g����)�̐��ʂ��قȂ�ꍇ
                    --================================================================
                    -- 2008/4/14 modify start
                    --  IF (ABS(ln_out_pnd_trans_qty) <> ABS(ln_out_cmp_trans_qty))    -- �o�ɐ�
                    --  AND (ABS(ln_in_pnd_trans_qty)  <> ABS(ln_in_cmp_trans_qty))    -- ���ɐ�
                    --  THEN
--
                    IF (TRUNC(ld_out_trans_date) <> TRUNC(ld_a_out_trans_date))  -- �o�ɓ� ���тƎ��ђ���
                    OR (TRUNC(ld_in_trans_date)  <> TRUNC(ld_a_in_trans_date))  -- ���ɓ� ���тƎ��ђ���
                    OR ld_a_out_trans_date IS NULL
                    OR ld_a_in_trans_date IS NULL
                    THEN  --(h)
--
                      --for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y26�z����(�ۗ��g����)�Ǝ��ђ���(�����g����)�̎��ѓ����قȂ�');
--
                      ------------------------------------------------------------------
                      -- ����(�ۗ��g����)�̐��ʂ�0�łȂ��ꍇ
                      -- �ԍ��
                      ------------------------------------------------------------------
                      IF ( ABS(ln_out_pnd_trans_qty) <> 0 ) THEN
--
                        --for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y27�z����(�ۗ��g����)�̐��ʂ�0�łȂ� �ԍ��');
--
                        -- ���ђ����쐬���i�[
                        -- ���ђ������i�[  �݌ɐ���API���s�Ώۃ��R�[�h�Ƀf�[�^���i�[
                        adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
                        adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
                        adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
                        adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                        adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
                        adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                        adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_pnd_trans_qty);
                        adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_pnd_trans_qty);
                        adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
                        adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
                        adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
                        adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
                        adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
                        adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
                        adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                        -- �C���N�������g
                        ln_idx_adji := ln_idx_adji + 1;
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y28�z�ԍ�� END');
--
                      END IF;
--
                    ------------------------------------------------------------------
                      -- �����
                      -- �ړ����b�g�ڍׂ̐��ʂ�0�̏ꍇ(���ѓo�^���Ȃ�)
                      IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN  --(g)
                        -- �������Ȃ�
                        NULL;
--
                      --for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y29�z�ړ����b�g�ڍׂ̐��ʂ�0����');
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y29-1�z�������Ȃ�');
--
                      -- �ړ����b�g�ڍׂ̐��ʂ�0�ȊO�̏ꍇ(���ѓo�^����)
                      ELSE  --(g)
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y30�z�ړ����b�g�ڍׂ̐��ʂ�0�ȊO����');
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y31�z���ѓo�^�p�i�[  START');
--
                        BEGIN
                          -- �ϐ�������
                          lv_from_orgn_code := NULL;
                          lv_from_co_code   := NULL;
                          lv_from_whse_code := NULL;
                          lv_to_orgn_code   := NULL;
                          lv_to_co_code     := NULL;
                          lv_to_whse_code   := NULL;
                          ln_err_flg        := 0;
--
                          -- �g�D,���,�q�ɂ̎擾�J�[�\���I�[�v��
                          OPEN xxcmn_locations_cur(
                                    move_target_tbl(gn_rec_idx).shipped_locat_id    -- �o�Ɍ�
                                   ,move_target_tbl(gn_rec_idx).ship_to_locat_id ); -- ���ɐ�
--
                          <<xxcmn_locations_cur_loop>>
                          LOOP
                            FETCH xxcmn_locations_cur
                            INTO  lv_from_orgn_code       -- �g�D�R�[�h(�o�ɗp)
                                 ,lv_from_co_code         -- ��ЃR�[�h(�o�ɗp)
                                 ,lv_from_whse_code       -- �q�ɃR�[�h(�o�ɗp)
                                 ,lv_to_orgn_code         -- �g�D�R�[�h(���ɗp)
                                 ,lv_to_co_code           -- ��ЃR�[�h(���ɗp)
                                 ,lv_to_whse_code         -- �q�ɃR�[�h(���ɗp)
                                 ;
                            EXIT WHEN xxcmn_locations_cur%NOTFOUND;
--
                          END LOOP xxcmn_locations_cur_loop;
--
                          -- �J�[�\���N���[�Y
                          CLOSE xxcmn_locations_cur;
--
                        EXCEPTION
                          WHEN NO_DATA_FOUND THEN                             -- �f�[�^�擾�G���[ 
                            -- �G���[�t���O
                            ln_err_flg  := 1;
                            IF (xxcmn_locations_cur%ISOPEN) THEN
                              -- �J�[�\���N���[�Y
                              CLOSE xxcmn_locations_cur;
                            END IF;
                            -- �G���[���b�Z�[�W���e
                            lv_err_msg_value
                                    := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                            lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                  gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                                  gv_c_tkn_msg,     -- �g�[�N��MSG
                                                                  lv_err_msg_value  -- �g�[�N���l
                                                                  );
                            -- �G���[���e�i�[
                            out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                            -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
                            err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                            err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                          WHEN TOO_MANY_ROWS THEN                             -- �f�[�^�擾�G���[ 
                            -- �G���[�t���O
                            ln_err_flg  := 1;
--
                            IF (xxcmn_locations_cur%ISOPEN) THEN
                              -- �J�[�\���N���[�Y
                              CLOSE xxcmn_locations_cur;
                            END IF;
                            -- �G���[���b�Z�[�W���e
                            lv_err_msg_value
                                    := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                            lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                  gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                                  gv_c_tkn_msg,     -- �g�[�N��MSG
                                                                  lv_err_msg_value  -- �g�[�N���l
                                                                  );
                            -- �G���[���e�i�[
                            out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                            -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
                            err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                            err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                        END;
--
                        -- �g�D�A��ЁA�q�ɏ�񂪎擾�ł����ꍇ
                        IF (ln_err_flg = 0) THEN
                          -- ���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
                          move_api_rec_tbl(ln_idx_move).orgn_code              := lv_from_orgn_code;
                          move_api_rec_tbl(ln_idx_move).item_no                := move_target_tbl(gn_rec_idx).item_code;
                          move_api_rec_tbl(ln_idx_move).lot_no                 := move_target_tbl(gn_rec_idx).lot_no;
                          move_api_rec_tbl(ln_idx_move).source_warehouse       := lv_from_whse_code;
                          move_api_rec_tbl(ln_idx_move).source_location        := move_target_tbl(gn_rec_idx).shipped_locat_code; -- �o�Ɍ�
                          move_api_rec_tbl(ln_idx_move).target_warehouse       := lv_to_whse_code;
                          move_api_rec_tbl(ln_idx_move).target_location        := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- ���ɐ�
-- 2008/12/25 Y.Kawano Upd Start #844
--                          move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                          move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).schedule_arrival_date;
                          move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).actual_ship_date;
                          move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
                          move_api_rec_tbl(ln_idx_move).actual_release_date    := move_target_tbl(gn_rec_idx).actual_ship_date;    -- �o�Ɏ��ѓ�
                          move_api_rec_tbl(ln_idx_move).actual_receive_date    := move_target_tbl(gn_rec_idx).actual_arrival_date; -- ���Ɏ��ѓ�
                          move_api_rec_tbl(ln_idx_move).release_quantity1      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                          move_api_rec_tbl(ln_idx_move).attribute1             := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                          -- �C���N�������g
                          ln_idx_move := ln_idx_move + 1;
--
                        END IF;
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y32�z���ѓo�^�p�i�[  END');
--
                      END IF;  --(g)
--
                  --================================================================
                  -- ����(�ۗ��g����)�̐��ʂƎ��ђ���(�����g����)�̐��ʂ������ꍇ
                  -- �ԍ��Ȃ� ���������
                  --================================================================
                  -- 2008/4/14 modify start
                  --  ELSIF (ABS(ln_out_pnd_trans_qty) = ABS(ln_out_cmp_trans_qty))   -- �o�ɐ�
                  --    AND (ABS(ln_in_pnd_trans_qty)  = ABS(ln_in_cmp_trans_qty))    -- ���ɐ�
                  --  THEN
--
                    ELSIF (TRUNC(ld_out_trans_date) = TRUNC(ld_a_out_trans_date))  -- �o�ɓ� ���тƎ��ђ���
                    AND (TRUNC(ld_in_trans_date)  = TRUNC(ld_a_in_trans_date))  -- ���ɓ� ���тƎ��ђ���
                    THEN  --(h)
--
                    --for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'�y33�z����(�ۗ��g����)�Ǝ��ђ���(�����g����)�̎��ѓ�������');
--
-- 2008/12/13 Y.Kawano Del Start
---- 2008/12/11 Y.Kawano Add Start
--                    ------------------------------------------------------------------
--                    -- ����(�ۗ��g����)�̐��ʂ�0�łȂ��ꍇ
--                    -- �ԍ��
--                    ------------------------------------------------------------------
--                    IF ( ABS(ln_out_pnd_trans_qty) <> 0 ) THEN
--
--                      --for debug
--                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y33-1�z����(�ۗ��g����)�̐��ʂ�0�łȂ� �ԍ��');
--
--                      -- ���ђ����쐬���i�[
--                      -- ���ђ������i�[  �݌ɐ���API���s�Ώۃ��R�[�h�Ƀf�[�^���i�[
--                      adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
--                      adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
--                      adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
--                      adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
--                      adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
--                      adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
--                      adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_pnd_trans_qty);
--                      adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_pnd_trans_qty);
--                      adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
--                      adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
--                      adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
--                      adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
--                      adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
--                      adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
--                      adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
--                      -- �C���N�������g
--                      ln_idx_adji := ln_idx_adji + 1;
--
--                      -- for debug
--                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y28�z�ԍ�� END');
--
--                    END IF;
-- 2008/12/11 Y.Kawano Add End
-- 2008/12/13 Y.Kawano Del End
--
                      IF (ABS(ln_out_pnd_trans_qty) = ABS(ln_out_cmp_trans_qty))   -- �o�ɐ�
                      AND (ABS(ln_in_pnd_trans_qty) = ABS(ln_in_cmp_trans_qty))    -- ���ɐ�
                      THEN  --(f)
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y34�z����(�ۗ��g����)�Ǝ��ђ���(�����g����)�̐��ʂ�����');
--
-- 2008/12/13 Y.Kawano Upd Strat
--                      --�������Ȃ�
--                      NULL;
--
-- 2009/02/04 Y.Kawano Add Start #1142
                        ------------------------------------------------------------------
                        -- �A�h�I���̎��ѐ��ʂƒ����O���ʂ��قȂ�ꍇ
                        -- �ԍ��
                        ------------------------------------------------------------------
                        IF  ( (move_target_tbl(gn_rec_idx).lot_out_actual_quantity
                                                        <> move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity) 
                          AND (move_target_tbl(gn_rec_idx).lot_in_actual_quantity
                                                        <> move_target_tbl(gn_rec_idx).lot_in_bf_act_quantity)
                          AND (move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity <> 0)
                          AND (move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity <> 0)
                            )
                        THEN
--
                         --for debug
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'�y34�z�A�h�I���̎��ѐ��ʂƒ����O���ʂ��قȂ� �ԍ��');
--
                          -- ���ђ����쐬���i�[
                          -- ���ђ������i�[  �݌ɐ���API���s�Ώۃ��R�[�h�Ƀf�[�^���i�[
                          adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
                          adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
                          adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
                          adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                          adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
                          adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                          adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_pnd_trans_qty);
                          adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_pnd_trans_qty);
                          adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
                          adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
                          adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
                          adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
                          adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
                          adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
                          adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                          -- �C���N�������g
                          ln_idx_adji := ln_idx_adji + 1;
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y34�z�ԍ�� END');
--
                        END IF;
-- 2009/02/04 Y.Kawano Add End   #1142
--
                        -- �ړ����b�g�ڍׂ̐��ʂ�0�ȊO�̏ꍇ(���ѓo�^����)
                        IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity <> 0) THEN  --(e)
--
--                        -- �ړ����b�g�ڍׂ̐��ʂ�0�ȊO�̏ꍇ(���ѓo�^����)
--                        ELSE
                        -- 2008/4/14 modify end
                          --for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'�y35�z�ړ����b�g�ڍׂ̐��ʂ�0�ȊO��');
--
                          -------------------------------------------------------------
                          -- ����(�ۗ��g����)�̐��ʂ�0�̏ꍇ�͑O��0���ьv�コ��Ă��邩��ۗ��g�����Ƀf�[�^�Ȃ�
                          -- �q�ɑg�D��Џ�񂪂Ȃ����ߎ擾����
                          -------------------------------------------------------------
                          IF (ln_out_pnd_trans_qty = 0) THEN  --(d)
                            --for debug
--                            FND_FILE.PUT_LINE(FND_FILE.LOG,'�y36�zln_out_pnd_trans_qty = 0');
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'�y37�z�g�D���擾  START');
--
                            BEGIN
                              -- �ϐ�������
                              lv_from_orgn_code := NULL;
                              lv_from_co_code   := NULL;
                              lv_from_whse_code := NULL;
                              lv_to_orgn_code   := NULL;
                              lv_to_co_code     := NULL;
                              lv_to_whse_code   := NULL;
                              ln_err_flg        := 0;
--
                              -- �g�D,���,�q�ɂ̎擾�J�[�\���I�[�v��
                              OPEN xxcmn_locations_cur(
                                        move_target_tbl(gn_rec_idx).shipped_locat_id    -- �o�Ɍ�
                                       ,move_target_tbl(gn_rec_idx).ship_to_locat_id ); -- ���ɐ�
--
                              <<xxcmn_locations_cur_loop>>
                              LOOP
                                FETCH xxcmn_locations_cur
                                INTO  lv_from_orgn_code       -- �g�D�R�[�h(�o�ɗp)
                                     ,lv_from_co_code         -- ��ЃR�[�h(�o�ɗp)
                                     ,lv_from_whse_code       -- �q�ɃR�[�h(�o�ɗp)
                                     ,lv_to_orgn_code         -- �g�D�R�[�h(���ɗp)
                                     ,lv_to_co_code           -- ��ЃR�[�h(���ɗp)
                                     ,lv_to_whse_code         -- �q�ɃR�[�h(���ɗp)
                                     ;
                                EXIT WHEN xxcmn_locations_cur%NOTFOUND;
--
                              END LOOP xxcmn_locations_cur_loop;
--
                              -- �J�[�\���N���[�Y
                              CLOSE xxcmn_locations_cur;
--
                            EXCEPTION
                              WHEN NO_DATA_FOUND THEN                             -- �f�[�^�擾�G���[ 
                                -- �G���[�t���O
                                ln_err_flg  := 1;
                                IF (xxcmn_locations_cur%ISOPEN) THEN
                                  -- �J�[�\���N���[�Y
                                  CLOSE xxcmn_locations_cur;
                                END IF;
                                -- �G���[���b�Z�[�W���e
                                lv_err_msg_value
                                      := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                                lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                      gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                                      gv_c_tkn_msg,     -- �g�[�N��MSG
                                                                      lv_err_msg_value  -- �g�[�N���l
                                                                      );
                                -- �G���[���e�i�[
                                out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                                -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
                                err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                                err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                              WHEN TOO_MANY_ROWS THEN                             -- �f�[�^�擾�G���[ 
                                -- �G���[�t���O
                                ln_err_flg  := 1;
--
                                IF (xxcmn_locations_cur%ISOPEN) THEN
                                  -- �J�[�\���N���[�Y
                                  CLOSE xxcmn_locations_cur;
                                END IF;
                                -- �G���[���b�Z�[�W���e
                                lv_err_msg_value
                                      := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                                lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                      gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                                      gv_c_tkn_msg,     -- �g�[�N��MSG
                                                                      lv_err_msg_value  -- �g�[�N���l
                                                                      );
                                -- �G���[���e�i�[
                                out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                                -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
                                err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                                err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                            END;
                            --for debug
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'�y38�z�g�D���擾  END');
--
                            -----------------------------------------------------------------
                            -- �g�D�A��ЁA�q�ɏ�񂪎擾�ł����ꍇ
                            IF (ln_err_flg = 0) THEN
                              -- for debug
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'�y39�z���ъi�[  START');
--
                              -- ���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
                              move_api_rec_tbl(ln_idx_move).orgn_code              := lv_from_orgn_code;
                              move_api_rec_tbl(ln_idx_move).item_no                := move_target_tbl(gn_rec_idx).item_code;
                              move_api_rec_tbl(ln_idx_move).lot_no                 := move_target_tbl(gn_rec_idx).lot_no;
                              move_api_rec_tbl(ln_idx_move).source_warehouse       := lv_from_whse_code;
                              move_api_rec_tbl(ln_idx_move).source_location        := move_target_tbl(gn_rec_idx).shipped_locat_code; -- �o�Ɍ�
                              move_api_rec_tbl(ln_idx_move).target_warehouse       := lv_to_whse_code;
                              move_api_rec_tbl(ln_idx_move).target_location        := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- ���ɐ�
-- 2008/12/25 Y.Kawano Upd Start #844
--                              move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                              move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).schedule_arrival_date;
                             move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).actual_ship_date;
                             move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
                              move_api_rec_tbl(ln_idx_move).actual_release_date    := move_target_tbl(gn_rec_idx).actual_ship_date;    -- �o�Ɏ��ѓ�
                              move_api_rec_tbl(ln_idx_move).actual_receive_date    := move_target_tbl(gn_rec_idx).actual_arrival_date; -- ���Ɏ��ѓ�
                              move_api_rec_tbl(ln_idx_move).release_quantity1      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                              move_api_rec_tbl(ln_idx_move).attribute1             := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                              -- �C���N�������g
                              ln_idx_move := ln_idx_move + 1;
--
                              --for debug
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'�y40�z���ъi�[  END');
--
                            END IF;
--
                          -----------------------------------------------------
                          -- ����(�ۗ��g����)�̐��ʂ�0�łȂ��ꍇ
                          -- �O����ьv�コ��Ă��邩��q�ɑg�D��Џ�񂪂���
                          -----------------------------------------------------
                          ELSE  --(d)
--
                            -- for debug
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'�y41�z���т����i�[  START');
--
                            -- ���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
                            move_api_rec_tbl(ln_idx_move).orgn_code              := lv_out_orgn_code;
                            move_api_rec_tbl(ln_idx_move).item_no                := move_target_tbl(gn_rec_idx).item_code;
                            move_api_rec_tbl(ln_idx_move).lot_no                 := move_target_tbl(gn_rec_idx).lot_no;
                            move_api_rec_tbl(ln_idx_move).source_warehouse       := lv_from_whse_code;
                            move_api_rec_tbl(ln_idx_move).source_location        := move_target_tbl(gn_rec_idx).shipped_locat_code; -- �o�Ɍ�
                            move_api_rec_tbl(ln_idx_move).target_warehouse       := lv_to_whse_code;
                            move_api_rec_tbl(ln_idx_move).target_location        := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- ���ɐ�
-- 2008/12/25 Y.Kawano Upd Start #844
--                            move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                            move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).schedule_arrival_date;
                            move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).actual_ship_date;
                            move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
                            move_api_rec_tbl(ln_idx_move).actual_release_date    := move_target_tbl(gn_rec_idx).actual_ship_date;    -- �o�Ɏ��ѓ�
                            move_api_rec_tbl(ln_idx_move).actual_receive_date    := move_target_tbl(gn_rec_idx).actual_arrival_date; -- ���Ɏ��ѓ�
                            move_api_rec_tbl(ln_idx_move).release_quantity1      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                            move_api_rec_tbl(ln_idx_move).attribute1             := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                            -- �C���N�������g
                            ln_idx_move := ln_idx_move + 1;
--
                            --for debug
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'�y42�z���т����i�[  end');
--
                          END IF;  -- (d)
--
                        END IF;  --(e)
--
-- 2008/12/13 Y.Kawano Upd End
                      -- �����ʂƐԐ��ʂ��Ⴄ�ꍇ
                      ELSE  --(f)
                        --for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y33-2�z����(�ۗ��g����)�Ǝ��ђ���(�����g����)�̐��ʈႤ');
                      -- 2008/04/14 modify end
--
                        -- 2008/4/14 modify start
                        -- �����
                        -- �ړ����b�g�ڍׂ̐��ʂ�0�̏ꍇ(���ѓo�^���Ȃ�)
                        --IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN
                        --  -- �������Ȃ�
                        --  NULL;
                        --  --for debug
                        --  --FND_FILE.PUT_LINE(FND_FILE.LOG,'�y34�z�ړ����b�g�ڍׂ̐��ʂ�0�����牽�����Ȃ�');
--
--2008/12/13 Y.Kawano Upd Start
--                        -- �ړ����b�g�ڍׂ̐��ʂ�0�̏ꍇ
--                        IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN
--2008/12/13 Y.Kawano Upd Start
--
                        -- 2008/4/14 modify start
                        --���э����� 0�ȊO�̏ꍇ �ԍ��
                        IF (ln_out_pnd_trans_qty <> 0) THEN  -- (c)
                          --for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'�y34�z�ԍ��');
--
                          -- ���ђ����쐬���i�[
                          -- ���ђ������i�[  �݌ɐ���API���s�Ώۃ��R�[�h�Ƀf�[�^���i�[
                          adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
                          adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
                          adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
                          adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                          adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
                          adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                          adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_pnd_trans_qty);
                          adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_pnd_trans_qty);
                          adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
                          adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
                          adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
                          adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
                          adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
                          adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
                          adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                          -- �C���N�������g
                          ln_idx_adji := ln_idx_adji + 1;
--
                        END IF;  -- (c)
--
--2008/12/13 Y.Kawano Upd Start
--                      END IF;
--2008/12/13 Y.Kawano Upd End
--
                        -- �ړ����b�g�ڍׂ̐��ʂ�0�ȊO�̏ꍇ(���ѓo�^����)
                        IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity <> 0) THEN  --(b)
--
--                        -- �ړ����b�g�ڍׂ̐��ʂ�0�ȊO�̏ꍇ(���ѓo�^����)
--                        ELSE
                        -- 2008/4/14 modify end
                          --for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'�y35�z�ړ����b�g�ڍׂ̐��ʂ�0�ȊO��');
--
                          -------------------------------------------------------------
                          -- ����(�ۗ��g����)�̐��ʂ�0�̏ꍇ�͑O��0���ьv�コ��Ă��邩��ۗ��g�����Ƀf�[�^�Ȃ�
                          -- �q�ɑg�D��Џ�񂪂Ȃ����ߎ擾����
                          -------------------------------------------------------------
                          IF (ln_out_pnd_trans_qty = 0) THEN --(a)
                            --for debug
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'�y36�zln_out_pnd_trans_qty = 0');
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'�y37�z�g�D���擾  START');
--
                            BEGIN
                              -- �ϐ�������
                              lv_from_orgn_code := NULL;
                              lv_from_co_code   := NULL;
                              lv_from_whse_code := NULL;
                              lv_to_orgn_code   := NULL;
                              lv_to_co_code     := NULL;
                              lv_to_whse_code   := NULL;
                              ln_err_flg        := 0;
--
                              -- �g�D,���,�q�ɂ̎擾�J�[�\���I�[�v��
                              OPEN xxcmn_locations_cur(
                                        move_target_tbl(gn_rec_idx).shipped_locat_id    -- �o�Ɍ�
                                       ,move_target_tbl(gn_rec_idx).ship_to_locat_id ); -- ���ɐ�
--
                              <<xxcmn_locations_cur_loop>>
                              LOOP
                                FETCH xxcmn_locations_cur
                                INTO  lv_from_orgn_code       -- �g�D�R�[�h(�o�ɗp)
                                     ,lv_from_co_code         -- ��ЃR�[�h(�o�ɗp)
                                     ,lv_from_whse_code       -- �q�ɃR�[�h(�o�ɗp)
                                     ,lv_to_orgn_code         -- �g�D�R�[�h(���ɗp)
                                     ,lv_to_co_code           -- ��ЃR�[�h(���ɗp)
                                     ,lv_to_whse_code         -- �q�ɃR�[�h(���ɗp)
                                     ;
                                EXIT WHEN xxcmn_locations_cur%NOTFOUND;
--
                              END LOOP xxcmn_locations_cur_loop;
--
                              -- �J�[�\���N���[�Y
                              CLOSE xxcmn_locations_cur;
--
                            EXCEPTION
                              WHEN NO_DATA_FOUND THEN                             -- �f�[�^�擾�G���[ 
                                -- �G���[�t���O
                                ln_err_flg  := 1;
                                IF (xxcmn_locations_cur%ISOPEN) THEN
                                  -- �J�[�\���N���[�Y
                                  CLOSE xxcmn_locations_cur;
                                END IF;
                                -- �G���[���b�Z�[�W���e
                                lv_err_msg_value
                                      := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                                lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                      gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                                      gv_c_tkn_msg,     -- �g�[�N��MSG
                                                                      lv_err_msg_value  -- �g�[�N���l
                                                                      );
                                -- �G���[���e�i�[
                                out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                                -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
                                err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                                err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                              WHEN TOO_MANY_ROWS THEN                             -- �f�[�^�擾�G���[ 
                                -- �G���[�t���O
                                ln_err_flg  := 1;
--
                                IF (xxcmn_locations_cur%ISOPEN) THEN
                                  -- �J�[�\���N���[�Y
                                  CLOSE xxcmn_locations_cur;
                                END IF;
                                -- �G���[���b�Z�[�W���e
                                lv_err_msg_value
                                      := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                                lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                      gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                                      gv_c_tkn_msg,     -- �g�[�N��MSG
                                                                      lv_err_msg_value  -- �g�[�N���l
                                                                      );
                                -- �G���[���e�i�[
                                out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                                -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
                                err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                                err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                            END;
                            --for debug
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'�y38�z�g�D���擾  END');
--
                            -----------------------------------------------------------------
                            -- �g�D�A��ЁA�q�ɏ�񂪎擾�ł����ꍇ
                            IF (ln_err_flg = 0) THEN
                              -- for debug
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'�y39�z���ъi�[  START');
--
                              -- ���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
                              move_api_rec_tbl(ln_idx_move).orgn_code              := lv_from_orgn_code;
                              move_api_rec_tbl(ln_idx_move).item_no                := move_target_tbl(gn_rec_idx).item_code;
                              move_api_rec_tbl(ln_idx_move).lot_no                 := move_target_tbl(gn_rec_idx).lot_no;
                              move_api_rec_tbl(ln_idx_move).source_warehouse       := lv_from_whse_code;
                              move_api_rec_tbl(ln_idx_move).source_location        := move_target_tbl(gn_rec_idx).shipped_locat_code; -- �o�Ɍ�
                              move_api_rec_tbl(ln_idx_move).target_warehouse       := lv_to_whse_code;
                              move_api_rec_tbl(ln_idx_move).target_location        := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- ���ɐ�
-- 2008/12/25 Y.Kawano Upd Start #844
--                              move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                              move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).schedule_arrival_date;
                              move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).actual_ship_date;
                              move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
                              move_api_rec_tbl(ln_idx_move).actual_release_date    := move_target_tbl(gn_rec_idx).actual_ship_date;    -- �o�Ɏ��ѓ�
                              move_api_rec_tbl(ln_idx_move).actual_receive_date    := move_target_tbl(gn_rec_idx).actual_arrival_date; -- ���Ɏ��ѓ�
                              move_api_rec_tbl(ln_idx_move).release_quantity1      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                              move_api_rec_tbl(ln_idx_move).attribute1             := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                              -- �C���N�������g
                              ln_idx_move := ln_idx_move + 1;
--
                              --for debug
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'�y40�z���ъi�[  END');
--
                            END IF;
--
                          -----------------------------------------------------
                          -- ����(�ۗ��g����)�̐��ʂ�0�łȂ��ꍇ
                          -- �O����ьv�コ��Ă��邩��q�ɑg�D��Џ�񂪂���
                          -----------------------------------------------------
                          ELSE
--
                            -- for debug
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'�y41�z���т����i�[  START');
--
                            -- ���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
                            move_api_rec_tbl(ln_idx_move).orgn_code              := lv_out_orgn_code;
                            move_api_rec_tbl(ln_idx_move).item_no                := move_target_tbl(gn_rec_idx).item_code;
                            move_api_rec_tbl(ln_idx_move).lot_no                 := move_target_tbl(gn_rec_idx).lot_no;
                            move_api_rec_tbl(ln_idx_move).source_warehouse       := lv_from_whse_code;
                            move_api_rec_tbl(ln_idx_move).source_location        := move_target_tbl(gn_rec_idx).shipped_locat_code; -- �o�Ɍ�
                            move_api_rec_tbl(ln_idx_move).target_warehouse       := lv_to_whse_code;
                            move_api_rec_tbl(ln_idx_move).target_location        := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- ���ɐ�
-- 2008/12/25 Y.Kawano Upd Start #844
--                            move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                            move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).schedule_arrival_date;
                            move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).actual_ship_date;
                            move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
                            move_api_rec_tbl(ln_idx_move).actual_release_date    := move_target_tbl(gn_rec_idx).actual_ship_date;    -- �o�Ɏ��ѓ�
                            move_api_rec_tbl(ln_idx_move).actual_receive_date    := move_target_tbl(gn_rec_idx).actual_arrival_date; -- ���Ɏ��ѓ�
                            move_api_rec_tbl(ln_idx_move).release_quantity1      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                            move_api_rec_tbl(ln_idx_move).attribute1             := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                            -- �C���N�������g
                            ln_idx_move := ln_idx_move + 1;
--
                            --for debug
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'�y42�z���т����i�[  end');
--
                          END IF;  --(a)
--
                        END IF;  --(b)
--
                      END IF;  --(f)
--
                    END IF;  --(h)
--
-- 2008/12/16 Y.Kawano Del Start
--                  END IF;  --(i)
-- 2008/12/16 Y.Kawano Del End
-- add start 1.9
                END IF;  --(j)
-- add end 1.9
--
              END IF;  --(r)
--
            END IF;  --(s)
--
          -- 2008/04/08 Modify End
          ---------------------------------------------------------
          /*****************************************/
          -- �ϑ��Ȃ��̏ꍇ
          /*****************************************/
          ELSIF ( move_target_tbl(gn_rec_idx).mov_type = gv_c_move_type_n ) THEN  --(typeif)
            --for debug
            FND_FILE.PUT_LINE(FND_FILE.LOG,'--------------- �ϑ��Ȃ� ------------------');
--
            ----------------------------------
            -- �o�Ɍ����
            ----------------------------------
            -- �����g������� ���ьv�コ��Ă���ŐV���擾
            BEGIN
              SELECT itc.orgn_code               -- �v�����g�R�[�h
                    ,itc.co_code                 -- ��ЃR�[�h
                    ,itc.whse_code               -- �q��
                    ,itc.trans_date              -- �����
                    ,itc.trans_qty               -- ����
              INTO   lv_out_orgn_code
                    ,lv_out_co_code
                    ,lv_from_whse_code
                    ,ld_out_trans_date
                    ,ln_out_cmp_trans_qty
              FROM   ic_tran_cmp   itc                      -- OPM�����݌Ƀg�����U�N�V����
                    ,ic_adjs_jnl   iaj                      -- OPM�݌ɒ����W���[�i��
                    ,ic_jrnl_mst   ijm                      -- OPM�W���[�i���}�X�^
              WHERE  itc.location   = move_target_tbl(gn_rec_idx).shipped_locat_code
                                                                              -- �o�ɕۊǑq�ɃR�[�h
                AND  itc.item_id    = move_target_tbl(gn_rec_idx).item_id     -- �i��ID
                AND  itc.lot_id     = move_target_tbl(gn_rec_idx).lot_id      -- ���b�gID
                AND  itc.doc_type   = iaj.trans_type                          -- �����^�C�v
                AND  itc.doc_type   = gv_c_doc_type_trni                      -- �����^�C�v
-- 2008/12/13 Y.Kawano Upd Start
--                --AND  itc.doc_line   = iaj.doc_line                           -- ������הԍ�
                AND  itc.doc_line   = iaj.doc_line                             -- ������הԍ�
                AND  itc.doc_id     = iaj.doc_id                               -- �������ID
-- 2008/12/13 Y.Kawano Upd End
                AND  ijm.journal_id = iaj.journal_id                          -- �W���[�i��ID
-- 2008/12/13 Y.Kawano Del Start
--                AND  ijm.journal_id = itc.doc_id                              -- �W���[�i��ID
-- 2008/12/13 Y.Kawano Del End
            ------ 2008/04/11 modify start  ------
              --AND  ijm.attribute1 = move_target_tbl(gn_rec_idx).mov_line_id -- �ړ�����ID
                AND  itc.location   = iaj.location
                AND  itc.item_id    = iaj.item_id
                AND  itc.lot_id     = iaj.lot_id
-- 2009/06/09 H.Itou Mod Start �{�ԏ�Q#1527 MAX(ID)�͍ŐV�łȂ��ꍇ������̂ŁAMAX(�ŏI�X�V��)�ɕύX�B
--                AND  iaj.journal_id IN
--                                    (SELECT MAX(adj.journal_id)           -- �ŐV�̃f�[�^
                AND  ijm.attribute1 = move_target_tbl(gn_rec_idx).mov_line_id
                AND  iaj.last_update_date IN
                                    (SELECT MAX(adj.last_update_date)           -- �ŐV�̃f�[�^
-- 2009/06/09 H.Itou Mod End
                                     FROM   ic_adjs_jnl   adj
                                           ,ic_jrnl_mst   jrn
                                     WHERE adj.journal_id  = jrn.journal_id
                                     AND   adj.item_id     = move_target_tbl(gn_rec_idx).item_id
                                     AND   adj.lot_id      = move_target_tbl(gn_rec_idx).lot_id
                                     AND   adj.location    = move_target_tbl(gn_rec_idx).shipped_locat_code
                                     AND   jrn.attribute1  = move_target_tbl(gn_rec_idx).mov_line_id
                                     AND   adj.trans_type  = gv_c_doc_type_trni
                                     AND   adj.reason_code = gv_reason_code
                                    )
              --  AND  ROWNUM         = 1                                       -- �ŐV�̃f�[�^
            --ORDER BY itc.creation_date DESC                                 -- �쐬�� �~��
            ------ 2008/04/11 modify end    ------
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- �f�[�^�擾�ł��Ȃ��ꍇ�A���ʂ�0�Ƃ���
                ln_out_cmp_trans_qty := 0;
                lv_out_orgn_code     := NULL;
                lv_out_co_code       := NULL;
                lv_from_whse_code    := NULL;
                ld_out_trans_date    := NULL;
            END;
--
            -- �����g������� ���ьv�コ��Ă���ŐV�̒��������擾
            BEGIN
              SELECT itc.trans_qty               -- ����
                    ,itc.trans_date              -- ����� -- 2008/04/14 add
              INTO   ln_out_cmp_a_trans_qty
                    ,ld_a_out_trans_date                    -- 2008/04/14 add
              FROM   ic_tran_cmp   itc                      -- OPM�����݌Ƀg�����U�N�V����
                    ,ic_adjs_jnl   iaj                      -- OPM�݌ɒ����W���[�i��
                    ,ic_jrnl_mst   ijm                      -- OPM�W���[�i���}�X�^
              WHERE  itc.location   = move_target_tbl(gn_rec_idx).shipped_locat_code
                                                                              -- �o�ɕۊǑq�ɃR�[�h
                AND  itc.item_id    = move_target_tbl(gn_rec_idx).item_id     -- �i��ID
                AND  itc.lot_id     = move_target_tbl(gn_rec_idx).lot_id      -- ���b�gID
                AND  itc.doc_type   = iaj.trans_type                          -- �����^�C�v
                AND  itc.doc_type   = gv_c_doc_type_adji                      -- �����^�C�v
-- 2008/12/13 Y.Kawano Upd Start
--                --AND  itc.doc_line   = iaj.doc_line                           -- ������הԍ�
                AND  itc.doc_line   = iaj.doc_line                             -- ������הԍ�
                AND  itc.doc_id     = iaj.doc_id                               -- �������ID
-- 2008/12/13 Y.Kawano Upd End
                AND  ijm.journal_id = iaj.journal_id                          -- �W���[�i��ID
-- 2008/12/13 Y.Kawano Del Start
--                AND  ijm.journal_id = itc.doc_id                              -- �W���[�i��ID
-- 2008/12/13 Y.Kawano Del End
            ------ 2008/04/11 modify start  ------
              -- AND  ijm.attribute1 = move_target_tbl(gn_rec_idx).mov_line_id  -- �ړ�����ID
              -- AND  ROWNUM         = 1                                        -- �ŐV�̃f�[�^
              -- ORDER BY itc.creation_date DESC                                -- �쐬�� �~��
-- 2009/06/09 H.Itou Mod Start �{�ԏ�Q#1527 MAX(ID)�͍ŐV�łȂ��ꍇ������̂ŁAMAX(�ŏI�X�V��)�ɕύX�B
--                AND  iaj.journal_id IN
--                                      (SELECT MAX(adj.journal_id)           -- �ŐV�̃f�[�^
                AND  ijm.attribute1 = move_target_tbl(gn_rec_idx).mov_line_id
                AND  iaj.last_update_date IN
                                      (SELECT MAX(adj.last_update_date)           -- �ŐV�̃f�[�^
-- 2009/06/09 H.Itou Mod End
                                       FROM   ic_adjs_jnl   adj
                                             ,ic_jrnl_mst   jrn
                                       WHERE adj.journal_id  = jrn.journal_id
                                       AND   adj.item_id     = move_target_tbl(gn_rec_idx).item_id
                                       AND   adj.lot_id      = move_target_tbl(gn_rec_idx).lot_id
                                       AND   adj.location    = move_target_tbl(gn_rec_idx).shipped_locat_code
                                       AND   jrn.attribute1  = move_target_tbl(gn_rec_idx).mov_line_id
                                       AND   adj.trans_type  = gv_c_doc_type_adji
                                       AND   adj.reason_code = gv_reason_code_cor
                                      )
            ------ 2008/04/11 modify end    ------
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- �f�[�^�擾�ł��Ȃ��ꍇ�A���ʂ�0�Ƃ���
                ln_out_cmp_a_trans_qty := 0;
                ld_a_out_trans_date    := NULL;
            END;
--
            ----------------------------------
            -- ���ɐ���
            ----------------------------------
            -- �����g������� ���ьv�コ��Ă���ŐV���擾
            BEGIN
              SELECT itc.orgn_code               -- �v�����g�R�[�h
                    ,itc.co_code                 -- ��ЃR�[�h
                    ,itc.whse_code               -- �q��
                    ,itc.trans_date              -- �����
                    ,itc.trans_qty               -- ����
              INTO   lv_in_orgn_code
                    ,lv_in_co_code
                    ,lv_to_whse_code
                    ,ld_in_trans_date
                    ,ln_in_cmp_trans_qty
              FROM   ic_tran_cmp   itc                      -- OPM�����݌Ƀg�����U�N�V����
                    ,ic_adjs_jnl   iaj                      -- OPM�݌ɒ����W���[�i��
                    ,ic_jrnl_mst   ijm                      -- OPM�W���[�i���}�X�^
              WHERE  itc.location   = move_target_tbl(gn_rec_idx).ship_to_locat_code -- ���ɕۊǑq�ɃR�[�h
                AND  itc.item_id    = move_target_tbl(gn_rec_idx).item_id    -- �i��ID
                AND  itc.lot_id     = move_target_tbl(gn_rec_idx).lot_id     -- ���b�gID
                AND  itc.doc_type   = iaj.trans_type                         -- �����^�C�v
                AND  itc.doc_type   = gv_c_doc_type_trni                     -- �����^�C�v
-- 2008/12/13 Y.Kawano Upd Start
--                --AND  itc.doc_line   = iaj.doc_line                           -- ������הԍ�
                AND  itc.doc_line   = iaj.doc_line                           -- ������הԍ�
                AND  itc.doc_id     = iaj.doc_id                             -- �������ID
-- 2008/12/13 Y.Kawano Upd End
                AND  ijm.journal_id = iaj.journal_id                         -- �W���[�i��ID
-- 2008/12/13 Y.Kawano Del Start
--                AND  ijm.journal_id = itc.doc_id                              -- �W���[�i��ID
-- 2008/12/13 Y.Kawano Del End
          ------ 2008/04/11 modify start  ------
              -- AND  ijm.attribute1 = move_target_tbl(gn_rec_idx).mov_line_id -- �ړ�����ID
                AND  itc.location   = iaj.location
                AND  itc.item_id    = iaj.item_id
                AND  itc.lot_id     = iaj.lot_id
-- 2009/06/09 H.Itou Mod Start �{�ԏ�Q#1527 MAX(ID)�͍ŐV�łȂ��ꍇ������̂ŁAMAX(�ŏI�X�V��)�ɕύX�B
--                AND  iaj.journal_id IN
--                                      (SELECT MAX(adj.journal_id)           -- �ŐV�̃f�[�^
                AND  ijm.attribute1 = move_target_tbl(gn_rec_idx).mov_line_id
                AND  iaj.last_update_date IN
                                      (SELECT MAX(adj.last_update_date)           -- �ŐV�̃f�[�^
-- 2009/06/09 H.Itou Mod End
                                       FROM   ic_adjs_jnl   adj
                                             ,ic_jrnl_mst   jrn
                                       WHERE adj.journal_id  = jrn.journal_id
                                       AND   adj.item_id     = move_target_tbl(gn_rec_idx).item_id
                                       AND   adj.lot_id      = move_target_tbl(gn_rec_idx).lot_id
                                       AND   adj.location    = move_target_tbl(gn_rec_idx).ship_to_locat_code
                                       AND   jrn.attribute1  = move_target_tbl(gn_rec_idx).mov_line_id
                                       AND   adj.trans_type  = gv_c_doc_type_trni
                                       AND   adj.reason_code = gv_reason_code
                                      )
--                AND  ROWNUM         = 1                                       -- �ŐV�̃f�[�^
--              ORDER BY itc.creation_date DESC                                 -- �쐬�� �~��
            ------ 2008/04/11 modify end    ------
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- �f�[�^�擾�ł��Ȃ��ꍇ�A���ʂ�0�Ƃ���
                ln_in_cmp_trans_qty := 0;
                lv_in_orgn_code     := NULL;
                lv_in_co_code       := NULL;
                lv_to_whse_code     := NULL;
                ld_in_trans_date    := NULL;
            END;
--
            -- �����g������� ���ьv�コ��Ă���ŐV�̒��������擾
            BEGIN
              SELECT itc.trans_qty               -- ����
                    ,itc.trans_date              -- ����� -- 2008/04/14 add
              INTO   ln_in_cmp_a_trans_qty
                    ,ld_a_in_trans_date                     -- 2008/04/14 add
              FROM   ic_tran_cmp   itc                      -- OPM�����݌Ƀg�����U�N�V����
                    ,ic_adjs_jnl   iaj                      -- OPM�݌ɒ����W���[�i��
                    ,ic_jrnl_mst   ijm                      -- OPM�W���[�i���}�X�^
              WHERE  itc.location   = move_target_tbl(gn_rec_idx).ship_to_locat_code
                                                                             -- ���ɕۊǑq�ɃR�[�h
                AND  itc.item_id    = move_target_tbl(gn_rec_idx).item_id     -- �i��ID
                AND  itc.lot_id     = move_target_tbl(gn_rec_idx).lot_id      -- ���b�gID
                AND  itc.doc_type   = iaj.trans_type                         -- �����^�C�v
                AND  itc.doc_type   = gv_c_doc_type_adji                     -- �����^�C�v
-- 2008/12/13 Y.Kawano Upd Start
--                --AND  itc.doc_line   = iaj.doc_line                           -- ������הԍ�
                AND  itc.doc_line   = iaj.doc_line                           -- ������הԍ�
                AND  itc.doc_id     = iaj.doc_id                             -- �������ID
-- 2008/12/13 Y.Kawano Upd End
                AND  ijm.journal_id = iaj.journal_id                         -- �W���[�i��ID
-- 2008/12/13 Y.Kawano Del Start
--                AND  ijm.journal_id = itc.doc_id                              -- �W���[�i��ID
-- 2008/12/13 Y.Kawano Del End
          ------ 2008/04/11 modify start  ------
              -- AND  ijm.attribute1 = move_target_tbl(gn_rec_idx).mov_line_id -- �ړ�����ID
                AND  itc.location   = iaj.location
                AND  itc.item_id    = iaj.item_id
                AND  itc.lot_id     = iaj.lot_id
-- 2009/06/09 H.Itou Mod Start �{�ԏ�Q#1527 MAX(ID)�͍ŐV�łȂ��ꍇ������̂ŁAMAX(�ŏI�X�V��)�ɕύX�B
--                AND  iaj.journal_id IN
--                                      (SELECT MAX(adj.journal_id)           -- �ŐV�̃f�[�^
                AND  ijm.attribute1 = move_target_tbl(gn_rec_idx).mov_line_id
                AND  iaj.last_update_date IN
                                      (SELECT MAX(adj.last_update_date)           -- �ŐV�̃f�[�^
-- 2009/06/09 H.Itou Mod End
                                       FROM   ic_adjs_jnl   adj
                                             ,ic_jrnl_mst   jrn
                                       WHERE adj.journal_id  = jrn.journal_id
                                       AND   adj.item_id     = move_target_tbl(gn_rec_idx).item_id
                                       AND   adj.lot_id      = move_target_tbl(gn_rec_idx).lot_id
                                       AND   adj.location    = move_target_tbl(gn_rec_idx).ship_to_locat_code
                                       AND   jrn.attribute1  = move_target_tbl(gn_rec_idx).mov_line_id
                                       AND   adj.trans_type  = gv_c_doc_type_adji
                                       AND   adj.reason_code = gv_reason_code_cor
                                      )
--              AND  ROWNUM         = 1                                       -- �ŐV�̃f�[�^
--            ORDER BY itc.creation_date DESC                                 -- �쐬�� �~��
          ------ 2008/04/11 modify end    ------
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- �f�[�^�擾�ł��Ȃ��ꍇ�A���ʂ�0�Ƃ���
                ln_in_cmp_a_trans_qty := 0;
                ld_a_in_trans_date    := NULL;
            END;
          ---------------------------------------------------------
            -- 2008/04/08 Modify Start
            -- for debug
            FND_FILE.PUT_LINE(FND_FILE.LOG,'�y1�z');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'mov_line_id='||move_target_tbl(gn_rec_idx).mov_line_id);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'item_id='||to_char(move_target_tbl(gn_rec_idx).item_id));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'lot_id='||to_char(move_target_tbl(gn_rec_idx).lot_id));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_out_cmp_trans_qty='||to_char(ln_out_cmp_trans_qty));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_in_cmp_trans_qty='||to_char(ln_in_cmp_trans_qty));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_out_cmp_a_trans_qty= '||to_char(ln_out_cmp_a_trans_qty));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_in_cmp_a_trans_qty = '||to_char(ln_in_cmp_a_trans_qty));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'out_actual_quantity   = '|| to_char(move_target_tbl(gn_rec_idx).lot_out_actual_quantity));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'in_actual_quantity    = '|| to_char(move_target_tbl(gn_rec_idx).lot_in_actual_quantity));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'out_bef_actual_qty    = '|| to_char(move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'in_bef_actual_qty     = '|| to_char(move_target_tbl(gn_rec_idx).lot_in_bf_act_quantity));
            --
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_out_trans_date='||to_char(ld_out_trans_date,'yyyy/mm/dd'));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_in_trans_date=' ||to_char(ld_in_trans_date,'yyyy/mm/dd'));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_a_out_trans_date = '||to_char(ld_a_out_trans_date,'yyyy/mm/dd'));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_a_in_trans_date  = '||to_char(ld_a_in_trans_date,'yyyy/mm/dd'));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'actual_ship_date    = '|| to_char(move_target_tbl(gn_rec_idx).actual_ship_date,'yyyy/mm/dd'));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'actual_arrival_date = '|| to_char(move_target_tbl(gn_rec_idx).actual_arrival_date,'yyyy/mm/dd'));
--
            ---------------------------------------------------------
            -- ����(��)�̏o�ɂƓ��ɁA�܂��͒���(��)�̏o�ɂƓ��ɂ��قȂ�
            ---------------------------------------------------------
            IF (ABS(ln_out_cmp_trans_qty) <> ABS(ln_in_cmp_trans_qty))      -- �ۗ��g�����̓��o�ɐ����Ⴄ
            OR (ABS(ln_out_cmp_a_trans_qty) <> ABS(ln_in_cmp_a_trans_qty))  -- �����g�����̓��o�ɐ����Ⴄ
            THEN  -- (A)
--
              -- �����g����(TRNI)�܂��͊����g����(ADJI)�̃f�[�^�s����
              RAISE global_api_expt;
--
            ---------------------------------------------------------
            -- ����(��)�̏o�ɂƓ��ɁA����(��)�̏o�ɂƓ��ɂ�����
            ---------------------------------------------------------
            ELSIF (ABS(ln_out_cmp_trans_qty) = ABS(ln_in_cmp_trans_qty))     -- �ۗ��g�����̓��o�ɐ�������
              AND (ABS(ln_out_cmp_a_trans_qty) = ABS(ln_in_cmp_a_trans_qty)) -- �����g�����̓��o�ɐ�������
            THEN  -- (A)
            --for debug
            FND_FILE.PUT_LINE(FND_FILE.LOG,'�y2�z����(��)�̏o�ɂƓ��ɁA�܂��͒���(��)�̏o�ɂƓ��ɂ�����');
--
              --===========================================================
              -- ����(�����g����)�̓��t�ƈړ��w�b�_�A�h�I���̎��ѓ����قȂ�ꍇ
              -- ���S�ԍ��
              --===========================================================
              IF (TRUNC(ld_out_trans_date) <> move_target_tbl(gn_rec_idx).actual_ship_date)   -- �o�Ɏ��ѓ�
              OR (TRUNC(ld_in_trans_date) <> move_target_tbl(gn_rec_idx).actual_arrival_date) -- ���Ɏ��ѓ�
              THEN  -- (B)
--
              -- for debug
              FND_FILE.PUT_LINE(FND_FILE.LOG,'�y3�z����(�����g����)�̓��t�ƈړ��w�b�_�A�h�I���̎��ѓ����قȂ�');
--
              -- 2008/04/14 modify start
              --  -----------------------------------------------------------------
              --  -- ���т̐��ʂƎ��ђ����̐��ʂ��قȂ�ꍇ
              --  -- �ԍ��
              --  IF (ABS(ln_out_cmp_trans_qty) <> ABS(ln_out_cmp_a_trans_qty))    -- �o�ɐ�cmp��cmp_a
              --  AND (ABS(ln_in_cmp_trans_qty)  <> ABS(ln_in_cmp_a_trans_qty))    -- ���ɐ�cmp��cmp_a
              --  THEN
--
                --=============================================================
                -- ���тƎ��ђ����̎�������قȂ�ꍇ
                --=============================================================
                IF  (TRUNC(ld_out_trans_date) <> TRUNC(ld_a_out_trans_date)) -- �o�ɓ� ���тƎ��ђ���
                OR (TRUNC(ld_in_trans_date)  <> TRUNC(ld_a_in_trans_date))   -- ���ɓ� ���тƎ��ђ���
                OR ld_a_out_trans_date IS NULL
                OR ld_a_in_trans_date IS NULL
                THEN  -- (C)
              -- 2008/04/14 modify end
                -- for debug
                FND_FILE.PUT_LINE(FND_FILE.LOG,'�y4�z���тƎ��ђ����̎��ѓ����قȂ�');
--
                  -- �����ʂ�0�łȂ��ꍇ
                  IF (ln_out_cmp_trans_qty <> 0) THEN  -- (D)
                    --for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'�y6�z�����ʂ�0�łȂ�');
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'�y7�z���ђ������i�[ START');
--
                  -----------------------------------------------------------------
                  -- �ԏ��
                  -- ���ђ������i�[  �݌ɐ���API���s�Ώۃ��R�[�h�Ƀf�[�^���i�[
                    adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
                    adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
                    adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
                    adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                    adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
                    adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                    adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_cmp_trans_qty);
                    adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_cmp_trans_qty);
                    adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
                    adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
                    adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
                    adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
                    adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
                    adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
                    adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                    -- �C���N�������g
                    ln_idx_adji := ln_idx_adji + 1;
--
                    --for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'�y8�z���ђ������i�[ End');
                  END IF;  -- (D)
--
                  -----------------------------------------------------------------
                  -- �����
                  -- �ړ����̐��ʂ�0�̏ꍇ(���ѓo�^���Ȃ�)
                  IF ( move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0 ) THEN  -- (E)
                    -- �������Ȃ�
                    NULL;
                  --for debug
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'�y9�z���b�g�ڍא���=0');
--
                  -----------------------------------------------------------------
                  -- �ړ����̐��ʂ�0�łȂ��ꍇ(���ѓo�^����)
                  ELSE  -- (E)
--
                  --for debug
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'�y10�z���b�g�ڍא���<>0');
                  -----------------------------------------------------------------
                  -- ����(�ۗ��g����)�̐��ʂ�0�̏ꍇ�͑O��0���ьv�コ��Ă��邩��ۗ��g�����Ƀf�[�^�Ȃ�
                  -- �q�ɑg�D��Џ�񂪂Ȃ����ߎ擾����
                  -----------------------------------------------------------------
                    IF (ln_out_cmp_trans_qty = 0) THEN  -- (F)
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y11�zcmp_qty<>0');
--
                      BEGIN
                        -- �ϐ�������
                        lv_from_orgn_code := NULL;
                        lv_from_co_code   := NULL;
                        lv_from_whse_code := NULL;
                        lv_to_orgn_code   := NULL;
                        lv_to_co_code     := NULL;
                        lv_to_whse_code   := NULL;
                        ln_err_flg        := 0;
--
                        -- �g�D,���,�q�ɂ̎擾�J�[�\���I�[�v��
                        OPEN xxcmn_locations_cur(
                                move_target_tbl(gn_rec_idx).shipped_locat_id    -- �o�Ɍ�
                               ,move_target_tbl(gn_rec_idx).ship_to_locat_id ); -- ���ɐ�
--
                        <<xxcmn_locations_cur_loop>>
                        LOOP
                          FETCH xxcmn_locations_cur
                          INTO  lv_from_orgn_code       -- �g�D�R�[�h(�o�ɗp)
                               ,lv_from_co_code         -- ��ЃR�[�h(�o�ɗp)
                               ,lv_from_whse_code       -- �q�ɃR�[�h(�o�ɗp)
                               ,lv_to_orgn_code         -- �g�D�R�[�h(���ɗp)
                               ,lv_to_co_code           -- ��ЃR�[�h(���ɗp)
                               ,lv_to_whse_code         -- �q�ɃR�[�h(���ɗp)
                               ;
                          EXIT WHEN xxcmn_locations_cur%NOTFOUND;
--
                        END LOOP xxcmn_locations_cur_loop;
--
                        -- �J�[�\���N���[�Y
                        CLOSE xxcmn_locations_cur;
--
                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN                             -- �f�[�^�擾�G���[ 
                          -- �G���[�t���O
                          ln_err_flg  := 1;
                          IF (xxcmn_locations_cur%ISOPEN) THEN
                            -- �J�[�\���N���[�Y
                            CLOSE xxcmn_locations_cur;
                          END IF;
                          -- �G���[���b�Z�[�W���e
                          lv_err_msg_value
                                := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                                gv_c_tkn_msg,     -- �g�[�N��MSG
                                                                lv_err_msg_value  -- �g�[�N���l
                                                                );
                          -- �G���[���e�i�[
                          out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                          -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
                          err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                          err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                        WHEN TOO_MANY_ROWS THEN                             -- �f�[�^�擾�G���[ 
                          -- �G���[�t���O
                          ln_err_flg  := 1;
--
                          IF (xxcmn_locations_cur%ISOPEN) THEN
                            -- �J�[�\���N���[�Y
                            CLOSE xxcmn_locations_cur;
                          END IF;
                          -- �G���[���b�Z�[�W���e
                          lv_err_msg_value
                              := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                                gv_c_tkn_msg,     -- �g�[�N��MSG
                                                                lv_err_msg_value  -- �g�[�N���l
                                                                );
                          -- �G���[���e�i�[
                          out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                          -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
                          err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                          err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                      END;
--
                      -----------------------------------------------------------------
                      -- �g�D�A��ЁA�q�ɏ�񂪎擾�ł����ꍇ
                      IF (ln_err_flg = 0) THEN  --(G)
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y12�ztrni���ъi�[ START');
--
                        -- trni���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
                        trni_api_rec_tbl(ln_idx_trni).item_no        := move_target_tbl(gn_rec_idx).item_code;
                        trni_api_rec_tbl(ln_idx_trni).from_whse_code := lv_from_whse_code;
                        trni_api_rec_tbl(ln_idx_trni).to_whse_code   := lv_to_whse_code;
                        trni_api_rec_tbl(ln_idx_trni).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                        trni_api_rec_tbl(ln_idx_trni).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code; -- �o�Ɍ�
                        trni_api_rec_tbl(ln_idx_trni).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                        trni_api_rec_tbl(ln_idx_trni).trans_qty      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                        trni_api_rec_tbl(ln_idx_trni).co_code        := lv_from_co_code;
                        trni_api_rec_tbl(ln_idx_trni).orgn_code      := lv_from_orgn_code;
                        trni_api_rec_tbl(ln_idx_trni).trans_date     := move_target_tbl(gn_rec_idx).actual_ship_date; -- �o�Ɏ��ѓ�
                        trni_api_rec_tbl(ln_idx_trni).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                        -- �C���N�������g
                        ln_idx_trni := ln_idx_trni + 1;
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y13�ztrni���ъi�[ End');
--
                      END IF;   -- (G)
--
                    -----------------------------------------------------
                    -- ����(�ۗ��g����)�̐��ʂ�0�łȂ��ꍇ
                    -- �O����ьv�コ��Ă��邩��q�ɑg�D��Џ�񂪂���
                    -----------------------------------------------------
                    ELSE  --(F)
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'�y14�ztrni���ъi�[ Start');
--
                      -- trni���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
                      trni_api_rec_tbl(ln_idx_trni).item_no        := move_target_tbl(gn_rec_idx).item_code;
                      trni_api_rec_tbl(ln_idx_trni).from_whse_code := lv_from_whse_code;
                      trni_api_rec_tbl(ln_idx_trni).to_whse_code   := lv_to_whse_code;
                      trni_api_rec_tbl(ln_idx_trni).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                      trni_api_rec_tbl(ln_idx_trni).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code; -- �o�Ɍ�
                      trni_api_rec_tbl(ln_idx_trni).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- ���ɐ�
                      trni_api_rec_tbl(ln_idx_trni).trans_qty      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                      trni_api_rec_tbl(ln_idx_trni).co_code        := lv_out_co_code;
                      trni_api_rec_tbl(ln_idx_trni).orgn_code      := lv_out_orgn_code;
                      trni_api_rec_tbl(ln_idx_trni).trans_date     := move_target_tbl(gn_rec_idx).actual_ship_date; -- �o�Ɏ��ѓ�
                      trni_api_rec_tbl(ln_idx_trni).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                      -- �C���N�������g
                      ln_idx_trni := ln_idx_trni + 1;
--
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'�y15�ztrni���ъi�[ End');
--
                    END IF;  -- (F)
--
                  END IF; --�ړ����̐��ʔ��� -- (E)
--
                -- for debug
                FND_FILE.PUT_LINE(FND_FILE.LOG,'�y16�z');
--
              -- 2008/04/14 modify start
              --  ---------------------------------------------------------------
              --  -- ����(cmp)�̐��ʂƎ��ђ���(cmp_a)�̐��ʂ������ꍇ
              --  -- �ԍ��Ȃ� ���������
              --  ---------------------------------------------------------------
              --  ELSIF (ABS(ln_out_cmp_trans_qty) = ABS(ln_out_cmp_a_trans_qty))   -- �o�ɐ�
              --  AND   (ABS(ln_in_cmp_trans_qty)  = ABS(ln_in_cmp_a_trans_qty))    -- ���ɐ�
              --  THEN
--
                --=============================================================
                -- ����(cmp)�Ǝ��ђ���(cmp_a)�̎�����������ꍇ
                --=============================================================
                ELSIF (TRUNC(ld_out_trans_date) = TRUNC(ld_a_out_trans_date)) -- �o�ɓ� ���тƎ��ђ���
                AND (TRUNC(ld_in_trans_date)  = TRUNC(ld_a_in_trans_date))    -- ���ɓ� ���тƎ��ђ���
                THEN  -- (D)
--
                -- for debug
                FND_FILE.PUT_LINE(FND_FILE.LOG,'�y17�z���тƎ��ђ����̎��ѓ�������');
--
                  -- ����(cmp)�Ǝ��ђ���(cmp_a)�̐��ʂ������ꍇ
                  IF (ABS(ln_out_cmp_trans_qty) = ABS(ln_out_cmp_a_trans_qty))   -- �o�ɐ�
                  AND (ABS(ln_in_cmp_trans_qty)  = ABS(ln_in_cmp_a_trans_qty))   -- ���ɐ�
                  THEN  -- (H)
                  -- for debug
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'�y18�z���тƎ��ђ����̐��ʂ�����');
--
                  -- 2008/04/15 modify start
                  -- �������Ȃ�
                  --NULL;
                  -- ���b�g�ڍׂ̎��ѐ��ʂ�0�̏ꍇ
                    IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN  -- (I)
                      -- �������Ȃ�
                      NULL;
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'�y18a ���b�g�ڍׂ̎��ѐ��ʂ�0  �������Ȃ��z');
--
                    ELSE  -- (I)
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'�y18b ���b�g�ڍׂ̎��ѐ��ʂ�0����Ȃ�  ���쐬�z');
--
                    -- ���쐬
                    -- ���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'�y18c�ztrni���ъi�[ Start');
--
                      -- trni���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
                      trni_api_rec_tbl(ln_idx_trni).item_no        := move_target_tbl(gn_rec_idx).item_code;
                      trni_api_rec_tbl(ln_idx_trni).from_whse_code := lv_from_whse_code;
                      trni_api_rec_tbl(ln_idx_trni).to_whse_code   := lv_to_whse_code;
                      trni_api_rec_tbl(ln_idx_trni).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                      trni_api_rec_tbl(ln_idx_trni).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code; -- �o�Ɍ�
                      trni_api_rec_tbl(ln_idx_trni).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- ���ɐ�
                      trni_api_rec_tbl(ln_idx_trni).trans_qty      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                      trni_api_rec_tbl(ln_idx_trni).co_code        := lv_out_co_code;
                      trni_api_rec_tbl(ln_idx_trni).orgn_code      := lv_out_orgn_code;
                      trni_api_rec_tbl(ln_idx_trni).trans_date     := move_target_tbl(gn_rec_idx).actual_ship_date; -- �o�Ɏ��ѓ�
                      trni_api_rec_tbl(ln_idx_trni).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                      -- �C���N�������g
                      ln_idx_trni := ln_idx_trni + 1;
--
                    --FND_FILE.PUT_LINE(FND_FILE.LOG,'�y18c�ztrni���ъi�[ End');
--
                    END IF;  -- (I)
--
                  -- �����ʂƐԐ��ʂ��Ⴄ�ꍇ
                  ELSE  -- (H)
                  -- for debug
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'�y18-1�z�����ʂƐԐ��ʂ��Ⴄ');
                    -- �ԍ쐬
                    -- �����ʂ�0�ȊO(���т���)�̏ꍇ�A�ԍ��
                    IF (ln_out_cmp_trans_qty <> 0) THEN  -- (J)
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'�y18-2�z��  �i�[Start');
--
                      -- �ԏ��
                      -- ���ђ������i�[  �݌ɐ���API���s�Ώۃ��R�[�h�Ƀf�[�^���i�[
                      adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
                      adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
                      adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
                      adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                      adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
                      adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                      adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_cmp_trans_qty);
                      adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_cmp_trans_qty);
                      adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
                      adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
                      adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
                      adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
                      adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
                      adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
                      adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                      -- �C���N�������g
                      ln_idx_adji := ln_idx_adji + 1;
--
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'�y18-2�z��  �i�[End');
--
                    END IF;  -- (J)
--
                  --FND_FILE.PUT_LINE(FND_FILE.LOG,'�y19�z');
--
                    -----------------------------------------------------------------
                    -- �ړ����b�g�ڍׂ̐��ʂ�0�̏ꍇ(���ѓo�^���Ȃ�)
                    IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN  -- (K)
--
                      -- �������Ȃ�
                      NULL;
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'�y20�z���b�g�ڍׂ�0');
--
                    -----------------------------------------------------------------
                    -- �ړ����b�g�ڍׂ̐��ʂ�0�ȊO�̏ꍇ(���ѓo�^����)
                    ELSE  -- (K)
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'�y21�z���b�g�ڍׂ�0�ȊO');
--
                      -- ����(cmp)�̐��ʂ�0�̏ꍇ�͑O��0���ьv�コ��Ă��邩��f�[�^�Ȃ�
                      -- �q�ɑg�D��Џ�񂪂Ȃ����ߎ擾����
                      IF (ln_out_cmp_trans_qty = 0) THEN  -- (L)
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y22�zln_out_cmp_trans_qty��0');
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y23�z�g�D���擾START');
--
                        BEGIN
                          -- �ϐ�������
                          lv_from_orgn_code := NULL;
                          lv_from_co_code   := NULL;
                          lv_from_whse_code := NULL;
                          lv_to_orgn_code   := NULL;
                          lv_to_co_code     := NULL;
                          lv_to_whse_code   := NULL;
                          ln_err_flg        := 0;
--
                          -- �g�D,���,�q�ɂ̎擾�J�[�\���I�[�v��
                          OPEN xxcmn_locations_cur(
                                    move_target_tbl(gn_rec_idx).shipped_locat_id    -- �o�Ɍ�
                                   ,move_target_tbl(gn_rec_idx).ship_to_locat_id ); -- ���ɐ�
--
                          <<xxcmn_locations_cur_loop>>
                          LOOP
                            FETCH xxcmn_locations_cur
                            INTO  lv_from_orgn_code       -- �g�D�R�[�h(�o�ɗp)
                                 ,lv_from_co_code         -- ��ЃR�[�h(�o�ɗp)
                                 ,lv_from_whse_code       -- �q�ɃR�[�h(�o�ɗp)
                                 ,lv_to_orgn_code         -- �g�D�R�[�h(���ɗp)
                                 ,lv_to_co_code           -- ��ЃR�[�h(���ɗp)
                                 ,lv_to_whse_code         -- �q�ɃR�[�h(���ɗp)
                                 ;
                            EXIT WHEN xxcmn_locations_cur%NOTFOUND;
--
                          END LOOP xxcmn_locations_cur_loop;
--
                          -- �J�[�\���N���[�Y
                          CLOSE xxcmn_locations_cur;
--
                        EXCEPTION
                          WHEN NO_DATA_FOUND THEN                             -- �f�[�^�擾�G���[ 
                            -- �G���[�t���O
                            ln_err_flg  := 1;
                            IF (xxcmn_locations_cur%ISOPEN) THEN
                              -- �J�[�\���N���[�Y
                              CLOSE xxcmn_locations_cur;
                            END IF;
                            -- �G���[���b�Z�[�W���e
                            lv_err_msg_value
                                := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                            lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                  gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                                  gv_c_tkn_msg,     -- �g�[�N��MSG
                                                                  lv_err_msg_value  -- �g�[�N���l
                                                                  );
                            -- �G���[���e�i�[
                            out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                            -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
                            err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                            err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                          WHEN TOO_MANY_ROWS THEN                             -- �f�[�^�擾�G���[ 
                            -- �G���[�t���O
                            ln_err_flg  := 1;
--
                            IF (xxcmn_locations_cur%ISOPEN) THEN
                              -- �J�[�\���N���[�Y
                              CLOSE xxcmn_locations_cur;
                            END IF;
                            -- �G���[���b�Z�[�W���e
                            lv_err_msg_value
                                  := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                            lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                  gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                                  gv_c_tkn_msg,     -- �g�[�N��MSG
                                                                  lv_err_msg_value  -- �g�[�N���l
                                                                  );
                            -- �G���[���e�i�[
                            out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                            -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
                            err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                            err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                        END;
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y24�z�g�D���擾 End');
                        -----------------------------------------------------------------
                        -- �g�D�A��ЁA�q�ɏ�񂪎擾�ł����ꍇ
                        IF (ln_err_flg = 0) THEN  -- (M)
                          -- for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'�y25�ztrni���ъi�[  START');
--
                          -- trni���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
                          trni_api_rec_tbl(ln_idx_trni).item_no        := move_target_tbl(gn_rec_idx).item_code;
                          trni_api_rec_tbl(ln_idx_trni).from_whse_code := lv_from_whse_code;
                          trni_api_rec_tbl(ln_idx_trni).to_whse_code   := lv_to_whse_code;
                          trni_api_rec_tbl(ln_idx_trni).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                          trni_api_rec_tbl(ln_idx_trni).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code; -- �o�Ɍ�
                          trni_api_rec_tbl(ln_idx_trni).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                          trni_api_rec_tbl(ln_idx_trni).trans_qty      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                          trni_api_rec_tbl(ln_idx_trni).co_code        := lv_from_co_code;
                          trni_api_rec_tbl(ln_idx_trni).orgn_code      := lv_from_orgn_code;
                          trni_api_rec_tbl(ln_idx_trni).trans_date     := move_target_tbl(gn_rec_idx).actual_ship_date; -- �o�Ɏ��ѓ�
                          trni_api_rec_tbl(ln_idx_trni).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                          -- �C���N�������g
                          ln_idx_trni := ln_idx_trni + 1;
--
                          -- for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'�y26�ztrni���ъi�[  End');
--
                        END IF;  -- (M)
                      
--
                      -----------------------------------------------------
                      -- ����(cmp)�̐��ʂ�0�łȂ��ꍇ
                      -- �O����ьv�コ��Ă��邩��q�ɑg�D��Џ�񂪂���
                      -----------------------------------------------------
                      ELSE  -- (L)
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y27�ztrni���ъi�[���邾��  START');
--
                        -- trni���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
                        trni_api_rec_tbl(ln_idx_trni).item_no        := move_target_tbl(gn_rec_idx).item_code;
                        trni_api_rec_tbl(ln_idx_trni).from_whse_code := lv_from_whse_code;
                        trni_api_rec_tbl(ln_idx_trni).to_whse_code   := lv_to_whse_code;
                        trni_api_rec_tbl(ln_idx_trni).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                        trni_api_rec_tbl(ln_idx_trni).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code; -- �o�Ɍ��ۊǑq��
                        trni_api_rec_tbl(ln_idx_trni).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                        trni_api_rec_tbl(ln_idx_trni).trans_qty      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                        trni_api_rec_tbl(ln_idx_trni).co_code    := lv_out_co_code;
                        trni_api_rec_tbl(ln_idx_trni).orgn_code  := lv_out_orgn_code;
                        trni_api_rec_tbl(ln_idx_trni).trans_date := move_target_tbl(gn_rec_idx).actual_ship_date; -- �o�Ɏ��ѓ�
                        trni_api_rec_tbl(ln_idx_trni).attribute1 := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                        -- �C���N�������g
                        ln_idx_trni := ln_idx_trni + 1;
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y27�ztrni���ъi�[���邾��  End');
--
                      END IF;  -- (L)
--
                    END IF;  -- (K)
--
                  END IF;  -- (H)
--
                END IF;  -- (D)
--
              --===========================================================
              -- ����(cmp)�̓��t�ƈړ��w�b�_�A�h�I���̎��ѓ��������ꍇ 
              -- �����ʂ��ύX����Ă���f�[�^�̂ݏ����Ώۂɂ���
              --===========================================================
              ELSE  -- (B)
-- add start 1.9
                IF ((move_target_tbl(gn_rec_idx).lot_out_actual_quantity = move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity)
                  AND (move_target_tbl(gn_rec_idx).lot_in_actual_quantity = move_target_tbl(gn_rec_idx).lot_in_bf_act_quantity))
                THEN  -- (N)
                  NULL;
                ELSE  -- (N)
-- add end 1.9
                --for debug
                FND_FILE.PUT_LINE(FND_FILE.LOG,'�y28�z����(cmp)�̓��t�ƈړ��w�b�_�A�h�I���̎��ѓ�������');
--
-- 2008/12/16 Y.Kawano Del Start
-- ��LIF���ŁA�ύX�Ȃ����͑ΏۊO�ƂȂ��Ă���ׁA�s�v��IF�����폜
--                ------------------------------------------------------------------
--                -- ���b�g�ڍ׃A�h�I���̐��ʂƎ���(�ۗ��g����)�̐��ʂ������ꍇ
--                -- �����b�g�ڍ׃A�h�I���̐��ʂ��ύX����Ă��Ȃ�
--                ------------------------------------------------------------------
--                IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = ABS(ln_out_cmp_trans_qty)) THEN
--                  -- �������Ȃ�
--                  NULL;
--
--                  -- for debug
--                  FND_FILE.PUT_LINE(FND_FILE.LOG,'�y29�z���b�g�ڍ׃A�h�I���̐��ʂƎ���(�ۗ��g����)�̐��ʂ�����');
--                  FND_FILE.PUT_LINE(FND_FILE.LOG,'�y29�z�������Ȃ�');
--
--                ------------------------------------------------------------------
--                -- ���b�g�ڍ׃A�h�I���̐��ʂƎ���(cmp)�̐��ʂ��قȂ�ꍇ
--                -- �����b�g�ڍ׃A�h�I���̐��ʂ��ύX����Ă���
--                ------------------------------------------------------------------
--                ELSE
-- 2008/12/16 Y.Kawano Del End
                  -- for debug
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'�y30�z���b�g�ڍ׃A�h�I���̐��ʂƎ���(�ۗ��g����)�̐��ʂ��Ⴄ');
--
                  --================================================================
                  -- ����(cmp)�̐��ʂƎ��ђ���(cmp_a)�̐��ʂ��قȂ�ꍇ
                  --================================================================
                  -- 2008/4/14 modify start
                  --  IF (ABS(ln_out_cmp_trans_qty) <> ABS(ln_out_cmp_a_trans_qty))    -- �o�ɐ�
                  --  AND (ABS(ln_in_cmp_trans_qty)  <> ABS(ln_in_cmp_a_trans_qty))    -- ���ɐ�
                  --  THEN
--
                  IF (TRUNC(ld_out_trans_date) <> TRUNC(ld_a_out_trans_date))  -- �o�ɓ� ���тƎ��ђ���
                  OR (TRUNC(ld_in_trans_date)  <> TRUNC(ld_a_in_trans_date))  -- ���ɓ� ���тƎ��ђ���
                  OR ld_a_out_trans_date IS NULL
                  OR ld_a_in_trans_date IS NULL
                  THEN  -- (O)
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'�y31�z����(cmp)�Ǝ��ђ���(cmp_a)�̎��ѓ����قȂ�');
--
                    ------------------------------------------------------------------
                    -- ����(cmp)�̐��ʂ�0�łȂ��ꍇ
                    -- �ԍ��
                    ------------------------------------------------------------------
                    IF ( ABS(ln_out_cmp_trans_qty) <> 0 ) THEN  -- (P)
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y32�z����(cmp)�̐��ʂ�0�łȂ�');
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y33�z���ђ����i�[ Start');
--
                      -- ���ђ����쐬���i�[
                      -- �݌ɐ���API���s�Ώۃ��R�[�h�Ƀf�[�^���i�[ �o�Ƀf�[�^
                      adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
                      adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
                      adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
                      adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                      adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
                      adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                      adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_cmp_trans_qty);
                      adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_cmp_trans_qty);
                      adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
                      adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
                      adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
                      adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
                      adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
                      adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
                      adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                      -- �C���N�������g
                      ln_idx_adji := ln_idx_adji + 1;
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y33�z���ђ����i�[ End');
--
                    END IF;  -- (P)
--
                    ------------------------------------------------------------------
                    -- �����
                    -- �ړ����b�g�ڍׂ̐��ʂ�0�̏ꍇ(���ѓo�^���Ȃ�)
                    IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN  -- (Q)
                      -- �������Ȃ�
                      NULL;
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y34�z���b�g�ڍׂ̐��ʂ�0');
--
                    ------------------------------------------------------------------
                    -- �ړ����b�g�ڍׂ̐��ʂ�0�ȊO�̏ꍇ(���ѓo�^����)
                    ELSE  -- (Q)
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y35�z���b�g�ڍׂ̐��ʂ�0����Ȃ�');
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y36�ztrni����  �i�[START');
--
                      BEGIN
                        -- �ϐ�������
                        lv_from_orgn_code := NULL;
                        lv_from_co_code   := NULL;
                        lv_from_whse_code := NULL;
                        lv_to_orgn_code   := NULL;
                        lv_to_co_code     := NULL;
                        lv_to_whse_code   := NULL;
                        ln_err_flg        := 0;
--
                        -- �g�D,���,�q�ɂ̎擾�J�[�\���I�[�v��
                        OPEN xxcmn_locations_cur(
                                  move_target_tbl(gn_rec_idx).shipped_locat_id    -- �o�Ɍ�
                                 ,move_target_tbl(gn_rec_idx).ship_to_locat_id ); -- ���ɐ�
--
                        <<xxcmn_locations_cur_loop>>
                        LOOP
                          FETCH xxcmn_locations_cur
                          INTO  lv_from_orgn_code       -- �g�D�R�[�h(�o�ɗp)
                               ,lv_from_co_code         -- ��ЃR�[�h(�o�ɗp)
                               ,lv_from_whse_code       -- �q�ɃR�[�h(�o�ɗp)
                               ,lv_to_orgn_code         -- �g�D�R�[�h(���ɗp)
                               ,lv_to_co_code           -- ��ЃR�[�h(���ɗp)
                               ,lv_to_whse_code         -- �q�ɃR�[�h(���ɗp)
                               ;
                          EXIT WHEN xxcmn_locations_cur%NOTFOUND;
--
                        END LOOP xxcmn_locations_cur_loop;
--
                        -- �J�[�\���N���[�Y
                        CLOSE xxcmn_locations_cur;
--
                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN                             -- �f�[�^�擾�G���[ 
                          -- �G���[�t���O
                          ln_err_flg  := 1;
                          IF (xxcmn_locations_cur%ISOPEN) THEN
                            -- �J�[�\���N���[�Y
                            CLOSE xxcmn_locations_cur;
                          END IF;
                          -- �G���[���b�Z�[�W���e
                          lv_err_msg_value
                                := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                                gv_c_tkn_msg,     -- �g�[�N��MSG
                                                                lv_err_msg_value  -- �g�[�N���l
                                                                );
                          -- �G���[���e�i�[
                          out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                          -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
                          err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                          err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                        WHEN TOO_MANY_ROWS THEN                             -- �f�[�^�擾�G���[ 
                          -- �G���[�t���O
                          ln_err_flg  := 1;
--
                          IF (xxcmn_locations_cur%ISOPEN) THEN
                            -- �J�[�\���N���[�Y
                            CLOSE xxcmn_locations_cur;
                          END IF;
                          -- �G���[���b�Z�[�W���e
                          lv_err_msg_value
                                := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                                gv_c_tkn_msg,     -- �g�[�N��MSG
                                                                lv_err_msg_value  -- �g�[�N���l
                                                                );
                          -- �G���[���e�i�[
                          out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                          -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
                          err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                          err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                      END;
--
                      -----------------------------------------------------------------
                      -- �g�D�A��ЁA�q�ɏ�񂪎擾�ł����ꍇ
                      IF (ln_err_flg = 0) THEN  -- (R)
--
                        -- trni���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
                        trni_api_rec_tbl(ln_idx_trni).item_no        := move_target_tbl(gn_rec_idx).item_code;
                        trni_api_rec_tbl(ln_idx_trni).from_whse_code := lv_from_whse_code;
                        trni_api_rec_tbl(ln_idx_trni).to_whse_code   := lv_to_whse_code;
                        trni_api_rec_tbl(ln_idx_trni).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                        trni_api_rec_tbl(ln_idx_trni).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code; -- �o�Ɍ��ۊǑq��
                        trni_api_rec_tbl(ln_idx_trni).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                        trni_api_rec_tbl(ln_idx_trni).trans_qty      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                        trni_api_rec_tbl(ln_idx_trni).co_code    := lv_from_co_code;
                        trni_api_rec_tbl(ln_idx_trni).orgn_code  := lv_from_orgn_code;
                        trni_api_rec_tbl(ln_idx_trni).trans_date := move_target_tbl(gn_rec_idx).actual_ship_date; -- �o�Ɏ��ѓ�
                        trni_api_rec_tbl(ln_idx_trni).attribute1 := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                        -- �C���N�������g
                        ln_idx_trni := ln_idx_trni + 1;
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y36�ztrni����  �i�[End');
                      END IF;  -- (R)
--
                    END IF;  -- (Q)
--
                  -- 2008/4/14 modify start
                  --================================================================
                  -- ����(cmp)�̐��ʂƎ��ђ���(cmp_a)�̐��ʂ������ꍇ
                  -- �ԍ��Ȃ� ���������
                  --================================================================
                  --  ELSIF (ABS(ln_out_cmp_trans_qty) = ABS(ln_out_cmp_a_trans_qty))   -- �o�ɐ�
                  --    AND (ABS(ln_in_cmp_trans_qty)  = ABS(ln_in_cmp_a_trans_qty))    -- ���ɐ�
                  --  THEN
--
                  ELSIF (TRUNC(ld_out_trans_date) = TRUNC(ld_a_out_trans_date))  -- �o�ɓ� ���тƎ��ђ���
                  AND (TRUNC(ld_in_trans_date)  = TRUNC(ld_a_in_trans_date))  -- ���ɓ� ���тƎ��ђ���
                  THEN  -- (O)
                    --for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'�y37�z���тƎ��ђ����̎��ѓ�����');
--
--2008/12/13 Y.Kawano Del Start
--2008/12/11 Y.Kawano Add Start
--                    ------------------------------------------------------------------
--                    -- ����(cmp)�̐��ʂ�0�łȂ��ꍇ
--                    -- �ԍ��
--                    ------------------------------------------------------------------
--                    IF ( ABS(ln_out_cmp_trans_qty) <> 0 ) THEN
--
--                      -- for debug
--                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y32�z����(cmp)�̐��ʂ�0�łȂ�');
--                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y33�z���ђ����i�[ Start');
--
--                      -- ���ђ����쐬���i�[
--                      -- �݌ɐ���API���s�Ώۃ��R�[�h�Ƀf�[�^���i�[ �o�Ƀf�[�^
--                      adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
--                      adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
--                      adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
--                      adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
--                      adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
--                      adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
--                      adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_cmp_trans_qty);
--                      adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_cmp_trans_qty);
--                      adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
--                      adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
--                      adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
--                      adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
--                      adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
--                      adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
--                      adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
--                      -- �C���N�������g
--                      ln_idx_adji := ln_idx_adji + 1;
--
--                      -- for debug
--                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y33�z���ђ����i�[ End');
--
--                    END IF;
--2008/12/11 Y.Kawano Add End
--2008/12/13 Y.Kawano Del End
--
                    IF (ABS(ln_out_cmp_trans_qty) = ABS(ln_out_cmp_a_trans_qty))   -- �o�ɐ�
                    AND (ABS(ln_in_cmp_trans_qty) = ABS(ln_in_cmp_a_trans_qty))    -- ���ɐ�
                    THEN  -- (S)
--
-- 2009/02/04 Y.Kawano Add Start #1142
                      ------------------------------------------------------------------
                      -- �A�h�I���̎��ѐ��ʂƒ����O���ʂ��قȂ�ꍇ
                      -- �ԍ��
                      ------------------------------------------------------------------
                      IF  ( (move_target_tbl(gn_rec_idx).lot_out_actual_quantity
                                                      <> move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity) 
                        AND (move_target_tbl(gn_rec_idx).lot_in_actual_quantity
                                                      <> move_target_tbl(gn_rec_idx).lot_in_bf_act_quantity)
                        AND (move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity <> 0)
                        AND (move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity <> 0)
                          )
                      THEN
--
                       --for debug
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'�y38�z�A�h�I���̎��ѐ��ʂƒ����O���ʂ��قȂ� �ԍ��');
--
                        -- ���ђ����쐬���i�[
                        -- �݌ɐ���API���s�Ώۃ��R�[�h�Ƀf�[�^���i�[ �o�Ƀf�[�^
                        adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
                        adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
                        adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
                        adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                        adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
                        adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                        adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_cmp_trans_qty);
                        adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_cmp_trans_qty);
                        adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
                        adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
                        adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
                        adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
                        adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
                        adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
                        adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                        -- �C���N�������g
                        ln_idx_adji := ln_idx_adji + 1;
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y38�z�ԍ�� END');
--
                      END IF;
-- 2009/02/04 Y.Kawano Add End   #1142
--
--2008/12/13 Y.Kawano Upd Start
--                      NULL;
                      ------------------------------------------------------------------
                      -- �����
                      -- �ړ����b�g�ڍׂ̐��ʂ�0�̏ꍇ(���ѓo�^���Ȃ�)
                      IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN  -- (T)
                        -- �������Ȃ�
                        NULL;
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y40�z���b�g�ڍׂ̐��ʂ�0');
--
                      ------------------------------------------------------------------
                      -- �ړ����b�g�ڍׂ̐��ʂ�0�ȊO�̏ꍇ(���ѓo�^����)
                      ELSE  -- (T)
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y41�z���b�g�ڍׂ̐��ʂ�0����Ȃ�');
--
                        ------------------------------------------------------------------
                        -- ����(cmp)�̐��ʂ�0�̏ꍇ�͑O��0���ьv�コ��Ă��邩��f�[�^�Ȃ�
                        -- �q�ɑg�D��Џ�񂪂Ȃ����ߎ擾����
                        ------------------------------------------------------------------
                        IF (ln_out_cmp_trans_qty = 0) THEN  -- (U)
--
                          -- for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'�y42�zln_out_cmp_trans_qty = 0');
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'�y43�z�g�D���擾 Start');
--
                          BEGIN
                            -- �ϐ�������
                            lv_from_orgn_code := NULL;
                            lv_from_co_code   := NULL;
                            lv_from_whse_code := NULL;
                            lv_to_orgn_code   := NULL;
                            lv_to_co_code     := NULL;
                            lv_to_whse_code   := NULL;
                            ln_err_flg        := 0;
--
                            -- �g�D,���,�q�ɂ̎擾�J�[�\���I�[�v��
                            OPEN xxcmn_locations_cur(
                                      move_target_tbl(gn_rec_idx).shipped_locat_id    -- �o�Ɍ�
                                     ,move_target_tbl(gn_rec_idx).ship_to_locat_id ); -- ���ɐ�
--
                            <<xxcmn_locations_cur_loop>>
                            LOOP
                              FETCH xxcmn_locations_cur
                              INTO  lv_from_orgn_code       -- �g�D�R�[�h(�o�ɗp)
                                   ,lv_from_co_code         -- ��ЃR�[�h(�o�ɗp)
                                   ,lv_from_whse_code       -- �q�ɃR�[�h(�o�ɗp)
                                   ,lv_to_orgn_code         -- �g�D�R�[�h(���ɗp)
                                   ,lv_to_co_code           -- ��ЃR�[�h(���ɗp)
                                   ,lv_to_whse_code         -- �q�ɃR�[�h(���ɗp)
                                   ;
                              EXIT WHEN xxcmn_locations_cur%NOTFOUND;
--
                            END LOOP xxcmn_locations_cur_loop;
--
                            -- �J�[�\���N���[�Y
                            CLOSE xxcmn_locations_cur;
--
                          EXCEPTION
                            WHEN NO_DATA_FOUND THEN                             -- �f�[�^�擾�G���[ 
                              -- �G���[�t���O
                              ln_err_flg  := 1;
                              IF (xxcmn_locations_cur%ISOPEN) THEN
                                -- �J�[�\���N���[�Y
                                CLOSE xxcmn_locations_cur;
                              END IF;
                              -- �G���[���b�Z�[�W���e
                              lv_err_msg_value
                                    := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                              lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                    gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                                    gv_c_tkn_msg,     -- �g�[�N��MSG
                                                                    lv_err_msg_value  -- �g�[�N���l
                                                                    );
                              -- �G���[���e�i�[
                              out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                              -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
                              err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                              err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                            WHEN TOO_MANY_ROWS THEN                             -- �f�[�^�擾�G���[ 
                              -- �G���[�t���O
                              ln_err_flg  := 1;
--
                              IF (xxcmn_locations_cur%ISOPEN) THEN
                                -- �J�[�\���N���[�Y
                                CLOSE xxcmn_locations_cur;
                              END IF;
                              -- �G���[���b�Z�[�W���e
                              lv_err_msg_value
                                    := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                              lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                    gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                                    gv_c_tkn_msg,     -- �g�[�N��MSG
                                                                    lv_err_msg_value  -- �g�[�N���l
                                                                    );
                              -- �G���[���e�i�[
                              out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                              -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
                              err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                              err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                          END;
--
                          -- for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'�y44�z�g�D���擾 End');
--
                          -----------------------------------------------------------------
                          -- �g�D�A��ЁA�q�ɏ�񂪎擾�ł����ꍇ
                          IF (ln_err_flg = 0) THEN  -- (V)
--
                            -- for debug
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'�y45�ztrni���ъi�[ START');
--
                            -- trni���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
                            trni_api_rec_tbl(ln_idx_trni).item_no        := move_target_tbl(gn_rec_idx).item_code;
                            trni_api_rec_tbl(ln_idx_trni).from_whse_code := lv_from_whse_code;
                            trni_api_rec_tbl(ln_idx_trni).to_whse_code   := lv_to_whse_code;
                            trni_api_rec_tbl(ln_idx_trni).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                            trni_api_rec_tbl(ln_idx_trni).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code; -- �o�Ɍ�
                            trni_api_rec_tbl(ln_idx_trni).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                            trni_api_rec_tbl(ln_idx_trni).trans_qty      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                            trni_api_rec_tbl(ln_idx_trni).co_code        := lv_from_co_code;
                            trni_api_rec_tbl(ln_idx_trni).orgn_code      := lv_from_orgn_code;
                            trni_api_rec_tbl(ln_idx_trni).trans_date     := move_target_tbl(gn_rec_idx).actual_ship_date; -- �o�Ɏ��ѓ�
                            trni_api_rec_tbl(ln_idx_trni).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                            -- �C���N�������g
                            ln_idx_trni := ln_idx_trni + 1;
--
                            --for debug
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'�y46�ztrni���ъi�[ End');
--
                          END IF;  -- (V)
--
                        -----------------------------------------------------
                        -- ����(cmp)�̐��ʂ�0�łȂ��ꍇ
                        -- �O����ьv�コ��Ă��邩��q�ɑg�D��Џ�񂪂���
                        -----------------------------------------------------
                        ELSE  -- (U)
                          --for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'�y45�ztrni���ъi�[���邾�� Start');
--
                          -- trni���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
                          trni_api_rec_tbl(ln_idx_trni).item_no        := move_target_tbl(gn_rec_idx).item_code;
                          trni_api_rec_tbl(ln_idx_trni).from_whse_code := lv_from_whse_code;
                          trni_api_rec_tbl(ln_idx_trni).to_whse_code   := lv_to_whse_code;
                          trni_api_rec_tbl(ln_idx_trni).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                          trni_api_rec_tbl(ln_idx_trni).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code; -- �o�Ɍ��ۊǑq��
                          trni_api_rec_tbl(ln_idx_trni).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                          trni_api_rec_tbl(ln_idx_trni).trans_qty      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                          trni_api_rec_tbl(ln_idx_trni).co_code        := lv_out_co_code;
                          trni_api_rec_tbl(ln_idx_trni).orgn_code      := lv_out_orgn_code;
                          trni_api_rec_tbl(ln_idx_trni).trans_date     := move_target_tbl(gn_rec_idx).actual_ship_date; -- �o�Ɏ��ѓ�
                          trni_api_rec_tbl(ln_idx_trni).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                          -- �C���N�������g
                          ln_idx_trni := ln_idx_trni + 1;
--
                          -- for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'�y46�ztrni���ъi�[���邾�� End');
--
                        END IF;  -- (U)
--
                      END IF;  -- (T)
--
--                      END IF;
--2008/12/13 Y.Kawano Upd End
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y38�z���тƎ��ђ����̐��ʂ�����');
                  -- �����ʂƐԐ��ʂ��Ⴄ�ꍇ
                    ELSE  -- (S)
                    -- 2008/04/14 modify end
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'�y39�z���тƎ��ђ����̐��ʂ��Ⴄ');
--
--2008/12/13 Y.Kawano Add Start
                      ------------------------------------------------------------------
                      -- ����(cmp)�̐��ʂ�0�łȂ��ꍇ
                      -- �ԍ��
                      ------------------------------------------------------------------
                      IF ( ABS(ln_out_cmp_trans_qty) <> 0 ) THEN  -- (W)
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y32�z����(cmp)�̐��ʂ�0�łȂ�');
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y33�z���ђ����i�[ Start');
--
                        -- ���ђ����쐬���i�[
                        -- �݌ɐ���API���s�Ώۃ��R�[�h�Ƀf�[�^���i�[ �o�Ƀf�[�^
                        adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
                        adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
                        adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
                        adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                        adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
                        adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                        adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_cmp_trans_qty);
                        adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_cmp_trans_qty);
                        adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
                        adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
                        adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
                        adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
                        adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
                        adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
                        adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                        -- �C���N�������g
                        ln_idx_adji := ln_idx_adji + 1;
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y33�z���ђ����i�[ End');
--
                      END IF;  -- (W)
--2008/12/13 Y.Kawano Add End
--
                      ------------------------------------------------------------------
                      -- �����
                      -- �ړ����b�g�ڍׂ̐��ʂ�0�̏ꍇ(���ѓo�^���Ȃ�)
                      IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN  -- (X)
                        -- �������Ȃ�
                        NULL;
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y40�z���b�g�ڍׂ̐��ʂ�0');
--
                      ------------------------------------------------------------------
                      -- �ړ����b�g�ڍׂ̐��ʂ�0�ȊO�̏ꍇ(���ѓo�^����)
                      ELSE  -- (X)
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y41�z���b�g�ڍׂ̐��ʂ�0����Ȃ�');
--
                        ------------------------------------------------------------------
                        -- ����(cmp)�̐��ʂ�0�̏ꍇ�͑O��0���ьv�コ��Ă��邩��f�[�^�Ȃ�
                        -- �q�ɑg�D��Џ�񂪂Ȃ����ߎ擾����
                        ------------------------------------------------------------------
                        IF (ln_out_cmp_trans_qty = 0) THEN  -- (Y)
--
                          -- for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'�y42�zln_out_cmp_trans_qty = 0');
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'�y43�z�g�D���擾 Start');
--
                          BEGIN
                            -- �ϐ�������
                            lv_from_orgn_code := NULL;
                            lv_from_co_code   := NULL;
                            lv_from_whse_code := NULL;
                            lv_to_orgn_code   := NULL;
                            lv_to_co_code     := NULL;
                            lv_to_whse_code   := NULL;
                            ln_err_flg        := 0;
--
                            -- �g�D,���,�q�ɂ̎擾�J�[�\���I�[�v��
                            OPEN xxcmn_locations_cur(
                                      move_target_tbl(gn_rec_idx).shipped_locat_id    -- �o�Ɍ�
                                     ,move_target_tbl(gn_rec_idx).ship_to_locat_id ); -- ���ɐ�
--
                            <<xxcmn_locations_cur_loop>>
                            LOOP
                              FETCH xxcmn_locations_cur
                              INTO  lv_from_orgn_code       -- �g�D�R�[�h(�o�ɗp)
                                   ,lv_from_co_code         -- ��ЃR�[�h(�o�ɗp)
                                   ,lv_from_whse_code       -- �q�ɃR�[�h(�o�ɗp)
                                   ,lv_to_orgn_code         -- �g�D�R�[�h(���ɗp)
                                   ,lv_to_co_code           -- ��ЃR�[�h(���ɗp)
                                   ,lv_to_whse_code         -- �q�ɃR�[�h(���ɗp)
                                   ;
                              EXIT WHEN xxcmn_locations_cur%NOTFOUND;
--
                            END LOOP xxcmn_locations_cur_loop;
--
                            -- �J�[�\���N���[�Y
                            CLOSE xxcmn_locations_cur;
--
                          EXCEPTION
                            WHEN NO_DATA_FOUND THEN                             -- �f�[�^�擾�G���[ 
                              -- �G���[�t���O
                              ln_err_flg  := 1;
                              IF (xxcmn_locations_cur%ISOPEN) THEN
                                -- �J�[�\���N���[�Y
                                CLOSE xxcmn_locations_cur;
                              END IF;
                              -- �G���[���b�Z�[�W���e
                              lv_err_msg_value
                                    := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                              lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                    gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                                    gv_c_tkn_msg,     -- �g�[�N��MSG
                                                                    lv_err_msg_value  -- �g�[�N���l
                                                                    );
                              -- �G���[���e�i�[
                              out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                              -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
                              err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                              err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                            WHEN TOO_MANY_ROWS THEN                             -- �f�[�^�擾�G���[ 
                              -- �G���[�t���O
                              ln_err_flg  := 1;
--
                              IF (xxcmn_locations_cur%ISOPEN) THEN
                                -- �J�[�\���N���[�Y
                                CLOSE xxcmn_locations_cur;
                              END IF;
                              -- �G���[���b�Z�[�W���e
                              lv_err_msg_value
                                    := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                              lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                    gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                                    gv_c_tkn_msg,     -- �g�[�N��MSG
                                                                    lv_err_msg_value  -- �g�[�N���l
                                                                    );
                              -- �G���[���e�i�[
                              out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                              -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
                              err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                              err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                          END;
--
                            -- for debug
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'�y44�z�g�D���擾 End');
--
                          -----------------------------------------------------------------
                          -- �g�D�A��ЁA�q�ɏ�񂪎擾�ł����ꍇ
                          IF (ln_err_flg = 0) THEN  -- (Z)
--
                              -- for debug
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'�y45�ztrni���ъi�[ START');
--
                            -- trni���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
                            trni_api_rec_tbl(ln_idx_trni).item_no        := move_target_tbl(gn_rec_idx).item_code;
                            trni_api_rec_tbl(ln_idx_trni).from_whse_code := lv_from_whse_code;
                            trni_api_rec_tbl(ln_idx_trni).to_whse_code   := lv_to_whse_code;
                            trni_api_rec_tbl(ln_idx_trni).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                            trni_api_rec_tbl(ln_idx_trni).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code; -- �o�Ɍ�
                            trni_api_rec_tbl(ln_idx_trni).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                            trni_api_rec_tbl(ln_idx_trni).trans_qty      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                            trni_api_rec_tbl(ln_idx_trni).co_code        := lv_from_co_code;
                            trni_api_rec_tbl(ln_idx_trni).orgn_code      := lv_from_orgn_code;
                            trni_api_rec_tbl(ln_idx_trni).trans_date     := move_target_tbl(gn_rec_idx).actual_ship_date; -- �o�Ɏ��ѓ�
                            trni_api_rec_tbl(ln_idx_trni).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                            -- �C���N�������g
                            ln_idx_trni := ln_idx_trni + 1;
--
                              --for debug
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'�y46�ztrni���ъi�[ End');
--
                          END IF;  -- (Z)
--
                        -----------------------------------------------------
                        -- ����(cmp)�̐��ʂ�0�łȂ��ꍇ
                        -- �O����ьv�コ��Ă��邩��q�ɑg�D��Џ�񂪂���
                        -----------------------------------------------------
                        ELSE  -- (Y)
                          --for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'�y45�ztrni���ъi�[���邾�� Start');
--
                          -- trni���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
                          trni_api_rec_tbl(ln_idx_trni).item_no        := move_target_tbl(gn_rec_idx).item_code;
                          trni_api_rec_tbl(ln_idx_trni).from_whse_code := lv_from_whse_code;
                          trni_api_rec_tbl(ln_idx_trni).to_whse_code   := lv_to_whse_code;
                          trni_api_rec_tbl(ln_idx_trni).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                          trni_api_rec_tbl(ln_idx_trni).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code; -- �o�Ɍ��ۊǑq��
                          trni_api_rec_tbl(ln_idx_trni).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                          trni_api_rec_tbl(ln_idx_trni).trans_qty      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                          trni_api_rec_tbl(ln_idx_trni).co_code        := lv_out_co_code;
                          trni_api_rec_tbl(ln_idx_trni).orgn_code      := lv_out_orgn_code;
                          trni_api_rec_tbl(ln_idx_trni).trans_date     := move_target_tbl(gn_rec_idx).actual_ship_date; -- �o�Ɏ��ѓ�
                          trni_api_rec_tbl(ln_idx_trni).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                          -- �C���N�������g
                          ln_idx_trni := ln_idx_trni + 1;
--
                          -- for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'�y46�ztrni���ъi�[���邾�� End');
--
                        END IF;  -- (Y)
--
                      END IF;  -- (X)
--
                    END IF;  -- (S)
--
                  END IF;  -- (O)
--
                END IF;  -- (N)
--
--
-- 2008/12/16 Y.Kawano Del Start
--                END IF;
-- 2008/12/16 Y.Kawano Del End
--
--
-- add start 1.9
              END IF;  -- (B)
-- add end 1.9
--
            END IF;  -- (A)
            -- 2008/04/08 Modify End
            ---------------------------------------------------------
          END IF;  --(typeif)  -- �ϑ�����Ȃ��̕���
          --
--2008/12/11 Y.Kawano Add Start
        END IF;      -- ���ђ����O�㐔��0��������
--2008/12/11 Y.Kawano Add End
--
      /*****************************************************/
      -- ���ьv��σt���O = OFF �̏ꍇ
      /*****************************************************/
      ELSIF ( move_target_tbl(gn_rec_idx).comp_actual_flg = gv_c_ynkbn_n ) THEN
--
        -- for debug
        FND_FILE.PUT_LINE(FND_FILE.LOG,'�y1�z���ьv��σt���O = OFF Start');
--
        -- �o�ɂƓ��ɂňړ����ѐ��ʂ��������O��̂��ߏo�ɐ��݂̂Ŕ��f
        -- �ړ����̐��ʂ�0�̏ꍇ(���ѓo�^���Ȃ�)
-- 2009/02/24 v1.21 UPDATE START
--        IF ( move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0 ) THEN
        IF (
             ( move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0 )
             OR
             (
               (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0)
                 AND (move_target_tbl(gn_rec_idx).lot_in_actual_quantity IS NULL)
             )
             OR
             (
               (move_target_tbl(gn_rec_idx).lot_out_actual_quantity IS NULL)
                 AND (move_target_tbl(gn_rec_idx).lot_in_actual_quantity = 0)
             )
           ) THEN
-- 2009/02/24 v1.21 UPDATE END
          -- �������Ȃ�
          NULL;
--
        -- �ړ����̐��ʂ�0�łȂ��ꍇ(���ѓo�^�Ώ�)
        ELSE
--
          ln_err_flg := 0;
--
          BEGIN
            -- �g�D,���,�q�ɂ̎擾�J�[�\���I�[�v��
            OPEN xxcmn_locations_cur(
                            move_target_tbl(gn_rec_idx).shipped_locat_id     -- �o�Ɍ�
                           ,move_target_tbl(gn_rec_idx).ship_to_locat_id );  -- ���ɐ�
            <<xxcmn_locations_cur_loop>>
            LOOP
              FETCH xxcmn_locations_cur
              INTO  lv_from_orgn_code       -- �g�D�R�[�h(�o�ɗp)
                   ,lv_from_co_code         -- ��ЃR�[�h(�o�ɗp)
                   ,lv_from_whse_code       -- �q�ɃR�[�h(�o�ɗp)
                   ,lv_to_orgn_code         -- �g�D�R�[�h(���ɗp)
                   ,lv_to_co_code           -- ��ЃR�[�h(���ɗp)
                   ,lv_to_whse_code         -- �q�ɃR�[�h(���ɗp)
                   ;
              EXIT WHEN xxcmn_locations_cur%NOTFOUND;
--
            END LOOP xxcmn_locations_cur_loop;
            -- �J�[�\���N���[�Y
            CLOSE xxcmn_locations_cur;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN                             --*** �f�[�^�擾�G���[ ***
              ln_err_flg   := 1;
              -- �J�[�\���N���[�Y
              IF (xxcmn_locations_cur%ISOPEN) THEN
                CLOSE xxcmn_locations_cur;
              END IF;
              -- �G���[���b�Z�[�W���e
              lv_err_msg_value
                    := gv_c_no_data_msg || move_target_tbl(gn_rec_idx).mov_num;
--
              lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                    gv_c_msg_57a_006, -- �f�[�^�擾�G���[
                                                    gv_c_tkn_msg,     -- �g�[�N��MSG
                                                    lv_err_msg_value  -- �g�[�N���l
                                                    );
              -- �G���[���e�i�[
              out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
              -- �G���[�ړ��ԍ�PLSQL�\�Ɋi�[
              err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
              err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
              -- �X�L�b�v����
              gn_warn_cnt  := gn_warn_cnt + 1;
          END;
--
          -- �f�[�^�擾�ł����ꍇ
          IF (ln_err_flg = 0) THEN
            -- �ϑ�����̏ꍇ
            IF ( move_target_tbl(gn_rec_idx).mov_type = gv_c_move_type_y ) THEN
--
              -- ���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
              move_api_rec_tbl(ln_idx_move).orgn_code                      -- �g�D�R�[�h
                                  := lv_from_orgn_code;
              move_api_rec_tbl(ln_idx_move).item_no                        -- �i�ڃR�[�h
                                  := move_target_tbl(gn_rec_idx).item_code;
              move_api_rec_tbl(ln_idx_move).lot_no                         -- ���b�gNo
                                  := move_target_tbl(gn_rec_idx).lot_no;
              move_api_rec_tbl(ln_idx_move).source_warehouse               -- �o�ɂ��Ƒq��
                                  := lv_from_whse_code;
              move_api_rec_tbl(ln_idx_move).source_location                -- �o�Ɍ��ۊǑq��
                                  := move_target_tbl(gn_rec_idx).shipped_locat_code;
              move_api_rec_tbl(ln_idx_move).target_warehouse               -- ���ɐ�q��
                                  := lv_to_whse_code;
              move_api_rec_tbl(ln_idx_move).target_location                -- ���ɐ�ۊǑq��
                                  := move_target_tbl(gn_rec_idx).ship_to_locat_code;
-- 2008/12/25 Y.Kawano Upd Start #844
--                move_api_rec_tbl(ln_idx_move).scheduled_release_date         -- �o�ɗ\���
--                                    := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                move_api_rec_tbl(ln_idx_move).scheduled_receive_date         -- ���ɗ\���
--                                    := move_target_tbl(gn_rec_idx).schedule_arrival_date;
              move_api_rec_tbl(ln_idx_move).scheduled_release_date         -- �o�ɗ\���
                                  := move_target_tbl(gn_rec_idx).actual_ship_date;
              move_api_rec_tbl(ln_idx_move).scheduled_receive_date         -- ���ɗ\���
                                  := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
              move_api_rec_tbl(ln_idx_move).actual_release_date            -- �o�Ɏ��ѓ�
                                  := move_target_tbl(gn_rec_idx).actual_ship_date;
              move_api_rec_tbl(ln_idx_move).actual_receive_date            -- ���Ɏ��ѓ�
                                  := move_target_tbl(gn_rec_idx).actual_arrival_date;
              move_api_rec_tbl(ln_idx_move).release_quantity1              -- ����
                                  := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
              move_api_rec_tbl(ln_idx_move).attribute1                     -- �ړ�����ID
                              := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
              -- �C���N�������g
              ln_idx_move := ln_idx_move + 1;
--
            -- �ϑ��Ȃ��̏ꍇ
            ELSIF ( move_target_tbl(gn_rec_idx).mov_type = gv_c_move_type_n ) THEN
--
                -- trni���ѓo�^�p���R�[�h�Ƀf�[�^���i�[
              trni_api_rec_tbl(ln_idx_trni).item_no                        -- �i�ڃR�[�h
                                    := move_target_tbl(gn_rec_idx).item_code;
              trni_api_rec_tbl(ln_idx_trni).from_whse_code                 -- �o�ɑq��
                                    := lv_from_whse_code;
              trni_api_rec_tbl(ln_idx_trni).to_whse_code                   -- ���ɑq��
                                    := lv_to_whse_code;
              trni_api_rec_tbl(ln_idx_trni).lot_no                         -- ���b�gNo
                                    := move_target_tbl(gn_rec_idx).lot_no;
              trni_api_rec_tbl(ln_idx_trni).from_location                  -- �o�Ɍ��ۊǑq��
                                    := move_target_tbl(gn_rec_idx).shipped_locat_code;
              trni_api_rec_tbl(ln_idx_trni).to_location                    -- ���ɐ�ۊǑq��
                                    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
              trni_api_rec_tbl(ln_idx_trni).trans_qty                      -- ����
                                    := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
              trni_api_rec_tbl(ln_idx_trni).co_code                        -- ��ЃR�[�h
                                    := lv_from_co_code;
              trni_api_rec_tbl(ln_idx_trni).orgn_code                      -- �g�D�R�[�h
                                   := lv_from_orgn_code;
              trni_api_rec_tbl(ln_idx_trni).trans_date                     -- �o�Ɏ��ѓ�
                                   := move_target_tbl(gn_rec_idx).actual_ship_date;
              trni_api_rec_tbl(ln_idx_trni).attribute1
                                   := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
              -- �C���N�������g
              ln_idx_trni := ln_idx_trni + 1;
--
            END IF;  -- �ϑ�����Ȃ�
--
          END IF;  -- �f�[�^�擾�ł����ꍇ
--
        END IF;    -- ���ʂ̏�������
--
      END IF;      -- ���уt���O��������
--
    END LOOP rec_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (xxcmn_locations_cur%ISOPEN) THEN
        CLOSE xxcmn_locations_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (xxcmn_locations_cur%ISOPEN) THEN
        CLOSE xxcmn_locations_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (xxcmn_locations_cur%ISOPEN) THEN
        CLOSE xxcmn_locations_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : regist_adji_proc
   * Description      : ���ђ����S�ԏ��o�^ (A-6)
   ***********************************************************************************/
  PROCEDURE regist_adji_proc(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'regist_adji_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    l_api_version_number  NUMBER      := 3.0;
    l_init_msg_list       VARCHAR2(1) := FND_API.G_FALSE;
    l_commit              VARCHAR2(1) := FND_API.G_FALSE;
    l_validation_level    NUMBER      := FND_API.G_VALID_LEVEL_FULL;
    l_return_status       VARCHAR2(1);
    l_msg_count           NUMBER;
    l_msg_data            VARCHAR2(2000);
    l_data                VARCHAR2(2000);
    l_qty_rec             GMIGAPI.qty_rec_typ;
    l_ic_jrnl_mst_row     ic_jrnl_mst%ROWTYPE;
    l_ic_adjs_jnl_row1    ic_adjs_jnl%ROWTYPE;
    l_ic_adjs_jnl_row2    ic_adjs_jnl%ROWTYPE;
    l_setup_return_sts    BOOLEAN;
-- add start 1.3
    l_loop_cnt            NUMBER;
    l_dummy_cnt           NUMBER;
-- add end 1.3
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ***************************************
    -- �Ώۃf�[�^���[�v
    -- ***************************************
    IF adji_data_rec_tbl.exists(1) THEN
      <<adji_loop>>
      FOR gn_rec_idx IN 1 .. adji_data_rec_tbl.COUNT LOOP
--
        ------------------------
        -- �o�ɏ��
        ------------------------
        -- �쐬����݌Ƀg�����U�N�V�����f�[�^
        l_qty_rec.trans_type     := 2;      --2:��������
        l_qty_rec.item_no        := adji_data_rec_tbl(gn_rec_idx).item_no;
        l_qty_rec.journal_no     := NULL;
        l_qty_rec.from_whse_code := adji_data_rec_tbl(gn_rec_idx).from_whse_code;
        l_qty_rec.to_whse_code   := adji_data_rec_tbl(gn_rec_idx).to_whse_code;
        l_qty_rec.lot_no         := adji_data_rec_tbl(gn_rec_idx).lot_no;
        l_qty_rec.from_location  := adji_data_rec_tbl(gn_rec_idx).from_location;
        l_qty_rec.to_location    := adji_data_rec_tbl(gn_rec_idx).to_location;
        l_qty_rec.trans_qty      := adji_data_rec_tbl(gn_rec_idx).trans_qty_out;
        l_qty_rec.co_code        := adji_data_rec_tbl(gn_rec_idx).from_co_code;
        l_qty_rec.orgn_code      := adji_data_rec_tbl(gn_rec_idx).from_orgn_code;
        l_qty_rec.trans_date     := adji_data_rec_tbl(gn_rec_idx).trans_date_out;
        l_qty_rec.reason_code    := gv_reason_code_cor;
        l_qty_rec.user_name      := gv_user_name;
        l_qty_rec.attribute1     := adji_data_rec_tbl(gn_rec_idx).attribute1;
--
        -- ***************************************
        -- ���ؗp���O(2008/12/10)
        -- ***************************************
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'INV50A(A-6)-1::' );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' trans_type:'     || l_qty_rec.trans_type     );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' item_no:'        || l_qty_rec.item_no        );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' journal_no:'     || l_qty_rec.journal_no     );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' from_whse_code:' || l_qty_rec.from_whse_code );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' to_whse_code:'   || l_qty_rec.to_location    );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' lot_no:'         || l_qty_rec.lot_no         );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' from_location:'  || l_qty_rec.from_location  );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' to_location:'    || l_qty_rec.to_location    );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' trans_qty:'      || l_qty_rec.trans_qty      );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' co_code:'        || l_qty_rec.co_code        );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' orgn_code:'      || l_qty_rec.orgn_code      );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' trans_date:'     || l_qty_rec.trans_date     );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' reason_code:'    || l_qty_rec.reason_code    );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' user_name:'      || l_qty_rec.user_name      );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' attribute1:'     || l_qty_rec.attribute1     );
--
        -- API���s �݌Ƀg�����U�N�V�����̍쐬
        GMIPAPI.INVENTORY_POSTING(
                  p_api_version      =>l_api_version_number,
                  p_init_msg_list    =>l_init_msg_list,
                  p_commit           =>l_commit,
                  p_validation_level =>l_validation_level,
                  p_qty_rec          =>l_qty_rec,
                  x_ic_jrnl_mst_row  =>l_ic_jrnl_mst_row,
                  x_ic_adjs_jnl_row1 =>l_ic_adjs_jnl_row1,
                  x_ic_adjs_jnl_row2 =>l_ic_adjs_jnl_row2,
                  x_return_status    =>l_return_status,
                  x_msg_count        =>l_msg_count,
                  x_msg_data         =>l_msg_data
                  );
--
        -- API���s���ʃG���[�̏ꍇ
        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          ROLLBACK;
-- add start 1.3
          FND_FILE.PUT_LINE(FND_FILE.LOG,'GMIPAPI.INVENTORY_POSTING ���s���� = '||l_return_status);
          -- �G���[���e���O�o��
          IF l_msg_count > 0 THEN
            l_loop_cnt := 1;
            LOOP
              FND_MSG_PUB.Get(
                  p_msg_index     => l_loop_cnt,
                  p_data          => l_msg_data,
                  p_encoded       => FND_API.G_FALSE,
                  p_msg_index_out => l_dummy_cnt);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'�G���[���b�Z�[�W ='||l_msg_data);
                  l_loop_cnt := l_loop_cnt+1;
              EXIT WHEN l_loop_cnt > l_msg_count;
            END LOOP;
          END IF;
-- add end 1.3
          -- �G���[���b�Z�[�W
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                gv_c_msg_57a_003,  -- �J�����_�N���[�Y���b�Z�[�W
                                                gv_c_tkn_api,      -- �g�[�N��API_NAME
                                                gv_c_tkn_api_val_a -- �g�[�N���l
                                                );
          RAISE global_api_expt;
        END IF;
--
        ------------------------
        -- ���ɏ��
        ------------------------
        -- �쐬����݌Ƀg�����U�N�V�����f�[�^
        l_qty_rec.trans_type     := 2;      --2:��������
        l_qty_rec.item_no        := adji_data_rec_tbl(gn_rec_idx).item_no;
        l_qty_rec.journal_no     := NULL;
        l_qty_rec.from_whse_code := adji_data_rec_tbl(gn_rec_idx).to_whse_code;
        l_qty_rec.to_whse_code   := adji_data_rec_tbl(gn_rec_idx).from_whse_code;
        l_qty_rec.lot_no         := adji_data_rec_tbl(gn_rec_idx).lot_no;
        l_qty_rec.from_location  := adji_data_rec_tbl(gn_rec_idx).to_location;
        l_qty_rec.to_location    := adji_data_rec_tbl(gn_rec_idx).from_location;
        l_qty_rec.trans_qty      := (adji_data_rec_tbl(gn_rec_idx).trans_qty_in * -1);
        l_qty_rec.co_code        := adji_data_rec_tbl(gn_rec_idx).to_co_code;
        l_qty_rec.orgn_code      := adji_data_rec_tbl(gn_rec_idx).to_orgn_code;
        l_qty_rec.trans_date     := adji_data_rec_tbl(gn_rec_idx).trans_date_in;
        l_qty_rec.reason_code    := gv_reason_code_cor;
        l_qty_rec.user_name      := gv_user_name;
        l_qty_rec.attribute1     := adji_data_rec_tbl(gn_rec_idx).attribute1;
--
        -- ***************************************
        -- ���ؗp���O(2008/12/10)
        -- ***************************************
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'INV50A(A-6)-2::' );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' trans_type:'     || l_qty_rec.trans_type     );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' item_no:'        || l_qty_rec.item_no        );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' journal_no:'     || l_qty_rec.journal_no     );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' from_whse_code:' || l_qty_rec.from_whse_code );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' to_whse_code:'   || l_qty_rec.to_location    );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' lot_no:'         || l_qty_rec.lot_no         );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' from_location:'  || l_qty_rec.from_location  );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' to_location:'    || l_qty_rec.to_location    );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' trans_qty:'      || l_qty_rec.trans_qty      );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' co_code:'        || l_qty_rec.co_code        );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' orgn_code:'      || l_qty_rec.orgn_code      );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' trans_date:'     || l_qty_rec.trans_date     );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' reason_code:'    || l_qty_rec.reason_code    );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' user_name:'      || l_qty_rec.user_name      );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' attribute1:'     || l_qty_rec.attribute1     );
--
        -- API���s �݌Ƀg�����U�N�V�����̍쐬
        GMIPAPI.INVENTORY_POSTING(
                  p_api_version      =>l_api_version_number,
                  p_init_msg_list    =>l_init_msg_list,
                  p_commit           =>l_commit,
                  p_validation_level =>l_validation_level,
                  p_qty_rec          =>l_qty_rec,
                  x_ic_jrnl_mst_row  =>l_ic_jrnl_mst_row,
                  x_ic_adjs_jnl_row1 =>l_ic_adjs_jnl_row1,
                  x_ic_adjs_jnl_row2 =>l_ic_adjs_jnl_row2,
                  x_return_status    =>l_return_status,
                  x_msg_count        =>l_msg_count,
                  x_msg_data         =>l_msg_data
                  );
--
        -- API���s���ʃG���[�̏ꍇ
        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          ROLLBACK;
-- add start 1.3
          FND_FILE.PUT_LINE(FND_FILE.LOG,'GMIPAPI.INVENTORY_POSTING ���s���� = '||l_return_status);
          -- �G���[���e���O�o��
          IF l_msg_count > 0 THEN
            l_loop_cnt := 1;
            LOOP
              FND_MSG_PUB.Get(
                  p_msg_index     => l_loop_cnt,
                  p_data          => l_msg_data,
                  p_encoded       => FND_API.G_FALSE,
                  p_msg_index_out => l_dummy_cnt);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'�G���[���b�Z�[�W ='||l_msg_data);
                  l_loop_cnt := l_loop_cnt+1;
              EXIT WHEN l_loop_cnt > l_msg_count;
            END LOOP;
          END IF;
-- add end 1.3
          -- �G���[���b�Z�[�W
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                gv_c_msg_57a_003,  -- �J�����_�N���[�Y���b�Z�[�W
                                                gv_c_tkn_api,      -- �g�[�N��API_NAME
                                                gv_c_tkn_api_val_a -- �g�[�N���l
                                                );
          RAISE global_api_expt;
        END IF;
--
      END LOOP adji_loop;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
  END regist_adji_proc;
--
  /**********************************************************************************
   * Procedure Name   : regist_xfer_proc
   * Description      : �ϑ�������ѓo�^ (A-5)
   ***********************************************************************************/
  PROCEDURE regist_xfer_proc(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'regist_xfer_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    l_api_version_number  CONSTANT NUMBER := 1.0;
    l_init_msg_list       VARCHAR2(1)     := FND_API.G_FALSE;
    l_commit              VARCHAR2(1)     := FND_API.G_FALSE;
    l_validation_level    NUMBER          := FND_API.G_VALID_LEVEL_FULL;
    l_return_status       VARCHAR2(2);
    l_msg_count           NUMBER;
    l_msg_data            VARCHAR2(2000);
    l_loop_cnt            NUMBER;
    l_dummy_cnt           NUMBER;
--
    l_xfer_rec            GMIGXFR.TYPE_XFER_REC;
    l_ic_xfer_mst_row     IC_XFER_MST%ROWTYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    IF move_api_rec_tbl.exists(1) THEN
--
      <<xfer_loop>>
      FOR gn_rec_idx IN 1 .. move_api_rec_tbl.COUNT LOOP
--
        -----------------------------------
        -- Insert
        -----------------------------------
        -- �쐬����݌Ƀg�����U�N�V�����f�[�^
        l_xfer_rec.transfer_action        := 1;           --1:Insert
        l_xfer_rec.transfer_no            := NULL;
        l_xfer_rec.transfer_batch         := NULL;
        l_xfer_rec.orgn_code              := move_api_rec_tbl(gn_rec_idx).orgn_code;
        l_xfer_rec.item_no                := move_api_rec_tbl(gn_rec_idx).item_no;
        l_xfer_rec.lot_no                 := move_api_rec_tbl(gn_rec_idx).lot_no;
        l_xfer_rec.sublot_no              := NULL;
        l_xfer_rec.source_warehouse       := move_api_rec_tbl(gn_rec_idx).source_warehouse;
        l_xfer_rec.source_location        := move_api_rec_tbl(gn_rec_idx).source_location;
        l_xfer_rec.target_warehouse       := move_api_rec_tbl(gn_rec_idx).target_warehouse;
        l_xfer_rec.target_location        := move_api_rec_tbl(gn_rec_idx).target_location;
        l_xfer_rec.scheduled_release_date := move_api_rec_tbl(gn_rec_idx).scheduled_release_date;
        l_xfer_rec.scheduled_receive_date := move_api_rec_tbl(gn_rec_idx).scheduled_receive_date;
        l_xfer_rec.actual_release_date    := move_api_rec_tbl(gn_rec_idx).actual_release_date;
        l_xfer_rec.actual_receive_date    := move_api_rec_tbl(gn_rec_idx).actual_receive_date;
        l_xfer_rec.cancel_date            := NULL;
        l_xfer_rec.release_quantity1      := move_api_rec_tbl(gn_rec_idx).release_quantity1;
        l_xfer_rec.release_quantity2      := NULL;
        l_xfer_rec.reason_code            := gv_reason_code;         -- �ړ�����
        l_xfer_rec.comments               := NULL;
        l_xfer_rec.attribute1             := move_api_rec_tbl(gn_rec_idx).attribute1;
--
--2008/09/26 Y.Kawano Mod Start
--        l_xfer_rec.user_name              := gv_user_name;
        l_xfer_rec.user_name              := gv_xfer_user_name;
--2008/09/26 Y.Kawano Mod End
--
        -----------------------------------
        -- API���s Insert
        -----------------------------------
        GMIPXFR.INVENTORY_TRANSFER(
                    p_api_version      => l_api_version_number
                   ,p_init_msg_list    => l_init_msg_list
                   ,p_commit           => l_commit
                   ,p_validation_level => l_validation_level
                   ,p_xfer_rec         => l_xfer_rec
                   ,x_ic_xfer_mst_row  => l_ic_xfer_mst_row
                   ,x_return_status    => l_return_status
                   ,x_msg_count        => l_msg_count
                   ,x_msg_data         => l_msg_data
                   );
--
        -- API���s���ʃG���[�̏ꍇ
        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          ROLLBACK;
-- mod start 1.3
--          FND_FILE.PUT_LINE(FND_FILE.LOG,'GMIPAPI.INVENTORY_POSTING ���s���� = '||l_return_status);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'GMIPXFR.INVENTORY_TRANSFER ���s���� = '||l_return_status);
-- mod end 1.3
          -------------------------
          -- for debug
          IF l_msg_count > 0 THEN
           l_loop_cnt := 1;
           LOOP
             FND_MSG_PUB.Get(
                 p_msg_index     => l_loop_cnt,
                 p_data          => l_msg_data,
                 p_encoded       => FND_API.G_FALSE,
                 p_msg_index_out => l_dummy_cnt);
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'�G���[���b�Z�[�W='||l_msg_data);
                 l_loop_cnt := l_loop_cnt+1;
             EXIT WHEN l_loop_cnt > l_msg_count;
           END LOOP;
          END IF;
          ----------------------
          -- �G���[���b�Z�[�W
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                gv_c_msg_57a_003,  -- �J�����_�N���[�Y���b�Z�[�W
                                                gv_c_tkn_api,      -- �g�[�N��API_NAME
                                                gv_c_tkn_api_val_x -- �g�[�N���l
                                                );
          RAISE global_api_expt;
        END IF;
--
        -----------------------------------
        -- Release
        -----------------------------------
        -- �쐬����݌Ƀg�����U�N�V�����f�[�^
        l_xfer_rec.transfer_action             := 2;           --2:Release
        l_xfer_rec.transfer_no                 := l_ic_xfer_mst_row.transfer_no;
        l_xfer_rec.orgn_code                   := l_ic_xfer_mst_row.orgn_code;
        l_xfer_rec.reason_code                 := gv_reason_code;
--
--2008/09/26 Y.Kawano Mod Start
--        l_xfer_rec.user_name                   := gv_user_name;
        l_xfer_rec.user_name                   := gv_xfer_user_name;
--2008/09/26 Y.Kawano Mod End
--
        -----------------------------------
        -- API���s Release
        -----------------------------------
        GMIPXFR.INVENTORY_TRANSFER(
                    p_api_version      => l_api_version_number
                   ,p_init_msg_list    => l_init_msg_list
                   ,p_commit           => l_commit
                   ,p_validation_level => l_validation_level
                   ,p_xfer_rec         => l_xfer_rec
                   ,x_ic_xfer_mst_row  => l_ic_xfer_mst_row
                   ,x_return_status    => l_return_status
                   ,x_msg_count        => l_msg_count
                   ,x_msg_data         => l_msg_data
                   );
--
        -- API���s���ʃG���[�̏ꍇ
        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          ROLLBACK;
-- add start 1.3
          FND_FILE.PUT_LINE(FND_FILE.LOG,'GMIPXFR.INVENTORY_TRANSFER ���s���� = '||l_return_status);
          -- �G���[���e���O�o��
          IF l_msg_count > 0 THEN
            l_loop_cnt := 1;
            LOOP
              FND_MSG_PUB.Get(
                  p_msg_index     => l_loop_cnt,
                  p_data          => l_msg_data,
                  p_encoded       => FND_API.G_FALSE,
                  p_msg_index_out => l_dummy_cnt);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'�G���[���b�Z�[�W ='||l_msg_data);
                  l_loop_cnt := l_loop_cnt+1;
              EXIT WHEN l_loop_cnt > l_msg_count;
            END LOOP;
          END IF;
-- add end 1.3
          -- �G���[���b�Z�[�W
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                gv_c_msg_57a_003,  -- �J�����_�N���[�Y���b�Z�[�W
                                                gv_c_tkn_api,      -- �g�[�N��API_NAME
                                                gv_c_tkn_api_val_x -- �g�[�N���l
                                                );
          RAISE global_api_expt;
        END IF;
--
        -----------------------------------
        -- Receive
        -----------------------------------
        -- �쐬����݌Ƀg�����U�N�V�����f�[�^
        l_xfer_rec.transfer_action             := 3;           --3:Receive
        l_xfer_rec.transfer_no                 := l_ic_xfer_mst_row.transfer_no;
        l_xfer_rec.orgn_code                   := l_ic_xfer_mst_row.orgn_code;
        l_xfer_rec.reason_code                 := gv_reason_code;
--
--2008/09/26 Y.Kawano Mod Start
--        l_xfer_rec.user_name                   := gv_user_name;
        l_xfer_rec.user_name                   := gv_xfer_user_name;
--2008/09/26 Y.Kawano Mod End
--
--
        -----------------------------------
        -- API���s Receive
        -----------------------------------
        GMIPXFR.INVENTORY_TRANSFER(
                    p_api_version      => l_api_version_number
                   ,p_init_msg_list    => l_init_msg_list
                   ,p_commit           => l_commit
                   ,p_validation_level => l_validation_level
                   ,p_xfer_rec         => l_xfer_rec
                   ,x_ic_xfer_mst_row  => l_ic_xfer_mst_row
                   ,x_return_status    => l_return_status
                   ,x_msg_count        => l_msg_count
                   ,x_msg_data         => l_msg_data
                   );
--
        -- API���s���ʃG���[�̏ꍇ
        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          ROLLBACK;
-- add start 1.3
          FND_FILE.PUT_LINE(FND_FILE.LOG,'GMIPXFR.INVENTORY_TRANSFER ���s���� = '||l_return_status);
          -- �G���[���e���O�o��
          IF l_msg_count > 0 THEN
            l_loop_cnt := 1;
            LOOP
              FND_MSG_PUB.Get(
                  p_msg_index     => l_loop_cnt,
                  p_data          => l_msg_data,
                  p_encoded       => FND_API.G_FALSE,
                  p_msg_index_out => l_dummy_cnt);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'�G���[���b�Z�[�W ='||l_msg_data);
                  l_loop_cnt := l_loop_cnt+1;
              EXIT WHEN l_loop_cnt > l_msg_count;
            END LOOP;
          END IF;
-- add end 1.3
          -- �G���[���b�Z�[�W
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                gv_c_msg_57a_003,  -- �J�����_�N���[�Y���b�Z�[�W
                                                gv_c_tkn_api,      -- �g�[�N��API_NAME
                                                gv_c_tkn_api_val_x -- �g�[�N���l
                                                );
          RAISE global_api_expt;
        END IF;
--
      END LOOP xfer_loop;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
  END regist_xfer_proc;
--
  /**********************************************************************************
   * Procedure Name   : regist_trni_proc
   * Description      : �ϑ��Ȃ����ѓo�^ (A-8)
   ***********************************************************************************/
  PROCEDURE regist_trni_proc(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'regist_trni_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    l_api_version_number  CONSTANT NUMBER   := 3.0;
    l_init_msg_list       VARCHAR2(1)       := FND_API.G_FALSE;
    l_commit              VARCHAR2(1)       := FND_API.G_FALSE;
    l_validation_level    NUMBER            := FND_API.G_VALID_LEVEL_FULL;
    l_return_status       VARCHAR2(1);
    l_msg_count           NUMBER;
    l_msg_data            VARCHAR2(2000);
    l_data                VARCHAR2(2000);
    l_qty_rec             GMIGAPI.qty_rec_typ;
    l_ic_jrnl_mst_row     ic_jrnl_mst%ROWTYPE;
    l_ic_adjs_jnl_row1    ic_adjs_jnl%ROWTYPE;
    l_ic_adjs_jnl_row2    ic_adjs_jnl%ROWTYPE;
    l_setup_return_sts    BOOLEAN;
    l_loop_cnt            NUMBER;
    l_dummy_cnt           NUMBER;
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    IF trni_api_rec_tbl.exists(1) THEN
      <<trni_loop>>
      FOR gn_rec_idx IN 1 .. trni_api_rec_tbl.COUNT LOOP
--
        -------------------------------------
        -- �쐬����݌Ƀg�����U�N�V�����f�[�^
        -------------------------------------
        l_qty_rec.trans_type     := 3;                                       --3:�ړ�����
        l_qty_rec.item_no        := trni_api_rec_tbl(gn_rec_idx).item_no;
        l_qty_rec.journal_no     := NULL;
        l_qty_rec.from_whse_code := trni_api_rec_tbl(gn_rec_idx).from_whse_code;
        l_qty_rec.to_whse_code   := trni_api_rec_tbl(gn_rec_idx).to_whse_code;
        l_qty_rec.lot_no         := trni_api_rec_tbl(gn_rec_idx).lot_no;
        l_qty_rec.sublot_no      := NULL;
        l_qty_rec.from_location  := trni_api_rec_tbl(gn_rec_idx).from_location;
        l_qty_rec.to_location    := trni_api_rec_tbl(gn_rec_idx).to_location;
        l_qty_rec.trans_qty      := trni_api_rec_tbl(gn_rec_idx).trans_qty;
        l_qty_rec.co_code        := trni_api_rec_tbl(gn_rec_idx).co_code;
        l_qty_rec.orgn_code      := trni_api_rec_tbl(gn_rec_idx).orgn_code;
        l_qty_rec.trans_date     := trni_api_rec_tbl(gn_rec_idx).trans_date;
        l_qty_rec.reason_code    := gv_reason_code;
        l_qty_rec.user_name      := gv_user_name;
        l_qty_rec.attribute1     := trni_api_rec_tbl(gn_rec_idx).attribute1;
--
        -------------------------------------
        -- API���s �݌Ƀg�����U�N�V�����̍쐬
        -------------------------------------
        GMIPAPI.INVENTORY_POSTING(
                  p_api_version      =>l_api_version_number,
                  p_init_msg_list    =>l_init_msg_list,
                  p_commit           =>l_commit,
                  p_validation_level =>l_validation_level,
                  p_qty_rec          =>l_qty_rec,
                  x_ic_jrnl_mst_row  =>l_ic_jrnl_mst_row,
                  x_ic_adjs_jnl_row1 =>l_ic_adjs_jnl_row1,
                  x_ic_adjs_jnl_row2 =>l_ic_adjs_jnl_row2,
                  x_return_status    =>l_return_status,
                  x_msg_count        =>l_msg_count,
                  x_msg_data         =>l_msg_data
                  );
--
        -- API���s���ʃG���[�̏ꍇ
        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          ROLLBACK;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'GMIPAPI.INVENTORY_POSTING ���s���� = '||l_return_status);
          -- �G���[���e���O�o��
          IF l_msg_count > 0 THEN
            l_loop_cnt := 1;
            LOOP
              FND_MSG_PUB.Get(
                  p_msg_index     => l_loop_cnt,
                  p_data          => l_msg_data,
                  p_encoded       => FND_API.G_FALSE,
                  p_msg_index_out => l_dummy_cnt);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'�G���[���b�Z�[�W ='||l_msg_data);
                  l_loop_cnt := l_loop_cnt+1;
              EXIT WHEN l_loop_cnt > l_msg_count;
            END LOOP;
          END IF;
--
          -- �G���[���b�Z�[�W
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                gv_c_msg_57a_003,  -- �J�����_�N���[�Y���b�Z�[�W
                                                gv_c_tkn_api,      -- �g�[�N��API_NAME
                                                gv_c_tkn_api_val_a -- �g�[�N���l
                                                );
          RAISE global_api_expt;
        END IF;
--
      END LOOP trni_loop;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
  END regist_trni_proc;
--
  /**********************************************************************************
   * Procedure Name   : update_flg_proc
   * Description      : ���ьv��σt���O�X�V (A-10,A-11)
   ***********************************************************************************/
  PROCEDURE update_flg_proc(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_flg_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx   NUMBER := 1;
-- add start 1.3
    lt_pre_mov_hdr_id xxinv_mov_req_instr_headers.mov_hdr_id%TYPE;
    lt_pre_ng_flag    NUMBER;
-- add end 1.3
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    <<update_loop>>
    FOR gn_rec_idx IN 1 .. move_data_rec_tbl.COUNT LOOP
-- mod start 1.3
--      UPDATE XXINV_MOV_REQ_INSTR_HEADERS
--      SET    comp_actual_flg        = gv_c_ynkbn_y  -- ���ьv��σt���O=ON
--            ,correct_actual_flg     = gv_c_ynkbn_n  -- ���ђ����t���O=OFF
--            ,last_updated_by        = gn_user_id
--            ,last_update_date       = gd_sysdate
--            ,last_update_login      = gn_login_id
--            ,request_id             = gn_conc_request_id
--            ,program_application_id = gn_prog_appl_id
--            ,program_id             = gn_conc_program_id
--            ,program_update_date    = gd_sysdate
--      WHERE mov_hdr_id        = move_data_rec_tbl(gn_rec_idx).mov_hdr_id;
--
      IF ((lt_pre_mov_hdr_id IS NULL AND move_data_rec_tbl(gn_rec_idx).ng_flag = 0) 
        OR (lt_pre_mov_hdr_id <> move_data_rec_tbl(gn_rec_idx).mov_hdr_id AND move_data_rec_tbl(gn_rec_idx).ng_flag = 0)
        OR (lt_pre_mov_hdr_id = move_data_rec_tbl(gn_rec_idx).mov_hdr_id AND lt_pre_ng_flag = 0))THEN
--
        -- �t���O�X�V
        UPDATE XXINV_MOV_REQ_INSTR_HEADERS
        SET    comp_actual_flg        = gv_c_ynkbn_y  -- ���ьv��σt���O=ON
              ,correct_actual_flg     = gv_c_ynkbn_n  -- ���ђ����t���O=OFF
              ,last_updated_by        = gn_user_id
              ,last_update_date       = gd_sysdate
              ,last_update_login      = gn_login_id
              ,request_id             = gn_conc_request_id
              ,program_application_id = gn_prog_appl_id
              ,program_id             = gn_conc_program_id
              ,program_update_date    = gd_sysdate
        WHERE mov_hdr_id        = move_data_rec_tbl(gn_rec_idx).mov_hdr_id;
        -- �����O���ѐ��ʍX�V(�o��)
        UPDATE XXINV_MOV_LOT_DETAILS
--2008/12/17 Y.Kawano Upd Start
--        SET    before_actual_quantity = move_data_rec_tbl(gn_rec_idx).shipped_quantity
        SET    before_actual_quantity = move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity
--2008/12/17 Y.Kawano Upd End
--2008/12/13 Y.Kawano Add Start
              ,last_updated_by        = gn_user_id
              ,last_update_date       = gd_sysdate
              ,last_update_login      = gn_login_id
              ,request_id             = gn_conc_request_id
              ,program_application_id = gn_prog_appl_id
              ,program_id             = gn_conc_program_id
              ,program_update_date    = gd_sysdate
--2008/12/13 Y.Kawano Add End
        WHERE  mov_lot_dtl_id         = move_data_rec_tbl(gn_rec_idx).mov_lot_dtl_id;
--
        -- �����O���ѐ��ʍX�V(����)
        UPDATE XXINV_MOV_LOT_DETAILS
--2008/12/17 Y.Kawano Upd Start
--        SET    before_actual_quantity = move_data_rec_tbl(gn_rec_idx).ship_to_quantity
        SET    before_actual_quantity = move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity
--2008/12/17 Y.Kawano Upd End
--2008/12/13 Y.Kawano Add Start
              ,last_updated_by        = gn_user_id
              ,last_update_date       = gd_sysdate
              ,last_update_login      = gn_login_id
              ,request_id             = gn_conc_request_id
              ,program_application_id = gn_prog_appl_id
              ,program_id             = gn_conc_program_id
              ,program_update_date    = gd_sysdate
--2008/12/13 Y.Kawano Add End
        WHERE  mov_lot_dtl_id         = move_data_rec_tbl(gn_rec_idx).mov_lot_dtl_id2;
      ELSE
        lt_pre_mov_hdr_id := move_data_rec_tbl(gn_rec_idx).mov_hdr_id;
        lt_pre_ng_flag    := move_data_rec_tbl(gn_rec_idx).ng_flag;
      END IF;
-- mod end 1.3
--
    END LOOP update_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
  END update_flg_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_move_num    IN  VARCHAR2,     --   �ړ��ԍ�
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    lv_out_rep VARCHAR2(1000);  -- ���|�[�g�o��
    ln_o_ret   NUMBER;
    lv_outmsg  VARCHAR2(5000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- �K�{�o�͍���
    -- ===============================
    -- �p�����[�^�ړ��ԍ����͒l
    FND_FILE.PUT(FND_FILE.OUTPUT, '�ړ��ԍ�:');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, iv_move_num);
--
    FND_FILE.PUT_LINE(FND_FILE.LOG,'----INIT----');
--
    -- ===============================
    -- ��������
    -- ===============================
    init_proc(iv_move_num,    -- �ړ��ԍ�
              lv_errbuf,      -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,     -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 2008/12/09 �{�ԏ�Q#470,#519 Add Start -------------------
    -- ===============================
    -- �ړ��ԍ��d���`�F�b�N
    -- ===============================
    check_mov_num_proc(iv_move_num,    -- �ړ��ԍ�
                       lv_errbuf,      -- �G���[�E���b�Z�[�W           --# �Œ� #
                       lv_retcode,     -- ���^�[���E�R�[�h             --# �Œ� #
                       lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    FND_FILE.PUT_LINE(FND_FILE.LOG,'----check_mov_num_proc----');
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_target_cnt - gn_warn_cnt;
      RAISE global_process_expt;
    END IF;
    -- 2008/12/09 �{�ԏ�Q#470,#519 Add End -------------------
--
    -- ===============================
    -- �ړ��˗�/�w���f�[�^�擾 (A-2)
    -- ===============================
    get_move_data_proc(iv_move_num,    -- �ړ��ԍ�
                       lv_errbuf,      -- �G���[�E���b�Z�[�W           --# �Œ� #
                       lv_retcode,     -- ���^�[���E�R�[�h             --# �Œ� #
                       lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    FND_FILE.PUT_LINE(FND_FILE.LOG,'----get_move_data_proc----');
--
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_target_cnt - gn_warn_cnt;
      RAISE global_process_expt;
    END IF;
--
    -- �����Ώۂ̈ړ��˗�/�w���f�[�^�����݂���ꍇ
    IF gn_no_data_flg = 0 THEN
--
      FND_FILE.PUT_LINE(FND_FILE.LOG,'----check_proc----');
--
      -- ===============================
      -- �Ó����`�F�b�N (A-3)
      -- ===============================
      check_proc(lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                 lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                 lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := gn_target_cnt - gn_warn_cnt;
        RAISE global_process_expt;
      --�x���̏ꍇ
      ELSIF (lv_retcode = gv_status_warn) THEN
        -- �X�e�[�^�X�Z�b�g
        ov_retcode := gv_status_warn;
--
        -- �x���f�[�^�����݂���ꍇ
        IF (gn_warn_cnt <> 0) THEN
--
          FND_FILE.PUT_LINE(FND_FILE.LOG,'----- �x�����b�Z�[�W�o�� START -----');
--
          -- �x�����b�Z�[�W���e���[�v
          <<log_loop>>
          FOR gn_rec_idx IN 1 .. out_err_tbl.COUNT LOOP
            IF (out_err_tbl(gn_rec_idx).out_msg <> '0') THEN
              lv_outmsg := out_err_tbl(gn_rec_idx).out_msg;
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_outmsg);
            ELSE
              NULL;
            END IF;
          END LOOP log_loop;
--
        END IF;
--
        FND_FILE.PUT_LINE(FND_FILE.LOG,'----- �x�����b�Z�[�W�o�� END -----');
--
      END IF;
--
      -- ===============================
      -- �֘A�f�[�^�擾(A-4)
      -- ===============================
      IF (gn_target_cnt <> 0) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.LOG,'----get_data_proc----');
--
        get_data_proc(lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                      lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      END IF;
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
--
        -- �G���[���e������ꍇ
        IF out_err_tbl2.EXISTS(1) THEN
          -- �G���[���e���[�v
          <<log2_loop>>
          FOR gn_rec_idx IN 1 .. out_err_tbl2.COUNT LOOP
--
            IF (out_err_tbl2(gn_rec_idx).out_msg <> '0') THEN
              lv_outmsg := out_err_tbl2(gn_rec_idx).out_msg;
--
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_outmsg);
              FND_FILE.PUT_LINE(FND_FILE.LOG,lv_outmsg);
--
            ELSE
              NULL;
            END IF;
--
          END LOOP log2_loop;
        -- �G���[���e���Ȃ��ꍇ
        ELSE
          NULL;
        END IF;
--
        gn_error_cnt := gn_target_cnt - gn_warn_cnt;
        RAISE global_process_expt;
      END IF;
--
      FND_FILE.PUT_LINE(FND_FILE.LOG,'----- get_data_proc END -----');
--
--
      -- ===============================
      -- ���ђ����S�ԏ��o�^ (A-6)
      -- ===============================
      IF (gn_target_cnt <> 0) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.LOG,'---regist_adji_proc  start---');
--
        regist_adji_proc(lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                         lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                         lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      END IF;
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := gn_target_cnt - gn_warn_cnt;
        RAISE global_process_expt;
      END IF;
--
      FND_FILE.PUT_LINE(FND_FILE.LOG,'---regist_adji_proc end ---');
--
      -- ===============================
      -- �ϑ�������ѓo�^ (A-5)
      -- ===============================
      IF (gn_target_cnt <> 0) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.LOG,'----regist_xfer_proc start ----');
--
        regist_xfer_proc(lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                         lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                         lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      END IF;
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := gn_target_cnt - gn_warn_cnt;
        RAISE global_process_expt;
      END IF;
--
      FND_FILE.PUT_LINE(FND_FILE.LOG,'---regist_xfer_proc  end---');
--
      -- ===============================
      -- �ϑ��Ȃ����ѓo�^ (A-8)
      -- ===============================
      IF (gn_target_cnt <> 0) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.LOG,'----regist_trni_proc start ----');
--
        regist_trni_proc(lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                         lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                         lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      END IF;
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := gn_target_cnt - gn_warn_cnt;
        RAISE global_process_expt;
      END IF;
--
      FND_FILE.PUT_LINE(FND_FILE.LOG,'----regist_trni_proc end ----');
--
      -- ===============================
      -- ���ьv��σt���O,���ђ����t���O�X�V(A-10,A-11)
      -- ===============================
      IF (gn_target_cnt <> 0) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.LOG,'---update_flg_proc start ---');
--
        update_flg_proc(lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                        lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                        lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      END IF;
--
      FND_FILE.PUT_LINE(FND_FILE.LOG,'---update_flg_proc end  ---');
--
--
--
    END IF;  -- �����Ώۂ̈ړ��˗�/�w���f�[�^�����݂���ꍇ��IF��
    gn_normal_cnt := gn_target_cnt - gn_warn_cnt;
--
    -- �������O�o��
    FND_FILE.PUT_LINE(FND_FILE.LOG,'gn_target_cnt='||to_char(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.LOG,'gn_normal_cnt='||to_char(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.LOG,'gn_warn_cnt='||to_char(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.LOG,'gn_error_cnt='||to_char(gn_error_cnt));
--
    FND_FILE.PUT_LINE(FND_FILE.LOG,'------ submain END -------');
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf         OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode        OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_move_num    IN  VARCHAR2       --   �ړ��ԍ�
  )
--
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
    lv_outmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_move_num,    -- �ړ��ԍ�
      lv_errbuf,      -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,     -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
-- 2009/02/19 v1.20 ADD START
    IF (gb_lock_expt_flg) THEN
      lv_retcode := gv_status_warn;
    END IF;
--
-- 2009/02/19 v1.20 ADD END
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type,
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
-- 2009/02/19 v1.20 UPDATE START
/*
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) AND (gv_check_proc_retcode = gv_status_normal) THEN
*/
    --�I���X�e�[�^�X���G���[���A���b�N�G���[�̏ꍇ��ROLLBACK����
    IF (
         (
           (retcode = gv_status_error) AND (gv_check_proc_retcode = gv_status_normal)
         )
         OR
         (gb_lock_expt_flg)
       ) THEN
-- 2009/02/19 v1.20 UPDATE END
      ROLLBACK;
    END IF;
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
END xxinv570001c;
/
