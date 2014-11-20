/*============================================================================
* �t�@�C���� : XxwshUtility
* �T�v����   : �o�ׁE����/�z�ԋ��ʊ֐�
* �o�[�W���� : 1.13
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-27 1.0  �ɓ��ЂƂ�   �V�K�쐬
* 2008-06-27 1.1  �ɓ��ЂƂ�   �����s�TE080_400#157
* 2008-07-02 1.2  ��r���@   �����ύX�v���Ή�#152
* 2008-07-23 1.3  �ɓ��ЂƂ�   �����ۑ�#32 checkNumOfCases�AgetItemCode�ǉ�
* 2008-08-01 1.4  �ɓ��ЂƂ�   �����ύX�v��#176�Ή�
* 2008-08-07 1.5  ��r���@   �����ύX�v��#166�Ή�
* 2008-09-19 1.6  �ɓ��ЂƂ�   T_TE080_BPO_400�w�E76�Ή�
* 2008-10-07 1.7  �ɓ��ЂƂ�   �����e�X�g�w�E240�Ή�
* 2008-10-24 1.8  ��r���     TE080_BPO_600 No22
* 2008-12-05 1.9  �ɓ��ЂƂ�   �{�ԏ�Q#452�Ή�
* 2008-12-06 1.10 �{�c         �{�ԏ�Q#484�Ή�
* 2008-12-15 1.11 ��r���     �{�ԏ�Q#648�Ή�
* 2009-01-22 1.12 �ɓ��ЂƂ�   �{�ԏ�Q#1000�Ή�
* 2009-01-26 1.13 �ɓ��ЂƂ�   �{�ԏ�Q#936�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxwsh.util;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
/***************************************************************************
 * �o�ׁE����/�z�ԋ��ʊ֐��N���X�ł��B
 * @author  ORACLE �ɓ��ЂƂ�
 * @version 1.13
 ***************************************************************************
 */
public class XxwshUtility 
{
  public XxwshUtility()
  {
  }

  /***************************************************************************
   * ���[���o�b�N�������s�����\�b�h�ł��B
   * @param trans - �g�����U�N�V����
   ***************************************************************************
   */
  public static void rollBack(
    OADBTransaction trans
  )
  {
    // ���[���o�b�N���s
    trans.executeCommand("ROLLBACK ");
  } // rollBack

  /***************************************************************************
   * �R�~�b�g�������s�����\�b�h�ł��B
   * @param trans - �g�����U�N�V����
   ***************************************************************************
   */
  public static void commit(
    OADBTransaction trans
  )
  {
    // �R�~�b�g���s
    trans.executeCommand("COMMIT ");
  } // commit
  
  /*****************************************************************************
   * OPM���b�g�}�X�^�̑Ó����`�F�b�N���s�����\�b�h�ł��B
   * @param trans     - �g�����U�N�V����
   * @param params    - �p�����[�^
   * @return HashMap  - ���b�g�}�X�^���
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void seachOpmLotMst(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "seachOpmLotMst";

    String lotNo            = (String)params.get("lotNo");          // ���b�gNo
    Date   manufacturedDate = (Date)params.get("manufacturedDate"); // �����N����
    Date   useByDate        = (Date)params.get("useByDate");        // �ܖ�����
    String koyuCode         = (String)params.get("koyuCode");       // �ŗL�L��
    Number itemId           = (Number)params.get("itemId");         // �i��ID
    String prodClassCode    = (String)params.get("prodClassCode");  // ���i�敪
    String itemClassCode    = (String)params.get("itemClassCode");  // �i�ڋ敪

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                                            );
    sb.append("  SELECT xlsv.status_desc               status_desc             "                  ); // 1:���b�g�X�e�[�^�X����
    sb.append("        ,xlsv.raw_mate_turn_m_reserve   raw_mate_turn_m_reserve "                  ); // 2:���Y��������(�蓮����)
    sb.append("        ,xlsv.raw_mate_turn_rel         raw_mate_turn_rel       "                  ); // 3:���Y��������(����)
    sb.append("        ,xlsv.pay_provision_m_reserve   pay_provision_m_reserve "                  ); // 4:�L���x��(�蓮����)
    sb.append("        ,xlsv.pay_provision_rel         pay_provision_rel       "                  ); // 5:�L���x��(����)
    sb.append("        ,xlsv.move_inst_m_reserve       move_inst_m_reserve     "                  ); // 6:�ړ��w��(�蓮����)
    sb.append("        ,xlsv.move_inst_a_reserve       move_inst_a_reserve     "                  ); // 7:�ړ��w��(��������)
    sb.append("        ,xlsv.move_inst_rel             move_inst_rel           "                  ); // 8:�ړ��w��(����)
    sb.append("        ,xlsv.ship_req_m_reserve        ship_req_m_reserve      "                  ); // 9:�o�׈˗�(�蓮����)
    sb.append("        ,xlsv.ship_req_a_reserve        ship_req_a_reserve      "                  ); // 10:�o�׈˗�(��������)
    sb.append("        ,xlsv.ship_req_rel              ship_req_rel            "                  ); // 11:�o�׈˗�(����)
    sb.append("        ,ilm.lot_no                     lot_no                  "                  ); // 12:���b�gNo
    sb.append("        ,FND_DATE.STRING_TO_DATE(ilm.attribute1,'YYYY/MM/DD')  manufactured_date " ); // 13:�����N����
    sb.append("        ,FND_DATE.STRING_TO_DATE(ilm.attribute3,'YYYY/MM/DD')  use_by_date       " ); // 14:�ܖ�����
    sb.append("        ,ilm.attribute2                 koyu_code               "                  ); // 15:�ŗL�L��
    sb.append("        ,ilm.lot_id                     lot_id                  "                  ); // 16:���b�gID
    sb.append("  INTO   :1 "                                                                      );
    sb.append("        ,:2 "                                                                      );
    sb.append("        ,:3 "                                                                      );
    sb.append("        ,:4 "                                                                      );
    sb.append("        ,:5 "                                                                      );
    sb.append("        ,:6 "                                                                      );
    sb.append("        ,:7 "                                                                      );
    sb.append("        ,:8 "                                                                      );
    sb.append("        ,:9 "                                                                      );
    sb.append("        ,:10 "                                                                     );
    sb.append("        ,:11 "                                                                     );
    sb.append("        ,:12 "                                                                     );
    sb.append("        ,:13 "                                                                     );
    sb.append("        ,:14 "                                                                     );
    sb.append("        ,:15 "                                                                     );
    sb.append("        ,:16 "                                                                     );
    sb.append("  FROM   ic_lots_mst            ilm "                                              ); // OPM���b�g�}�X�^
    sb.append("        ,xxcmn_lot_status_v     xlsv "                                             ); // ���b�g�X�e�[�^�X���VIEW
    sb.append("  WHERE  ilm.attribute23 = xlsv.lot_status "                                       );
    sb.append("  AND    ilm.item_id = :17 "                                                       ); // �i��ID
    sb.append("  AND    xlsv.prod_class_code = :18 "                                              ); // ���i�敪
    // �i�ڋ敪��5:���i�łȂ��ꍇ
    sb.append("  AND  (((:19 <> '5') "                                                            );
    sb.append("  AND    (:20 IS NULL OR ilm.lot_no = :20)) "                                      ); // ���b�gNo      
    // �i�ڋ敪��5:���i�̏ꍇ
    sb.append("  OR    ((:19 = '5') "                                                             );
    sb.append("  AND    (:21 IS NULL OR ilm.attribute1 = TO_CHAR(:21, 'YYYY/MM/DD')) "            ); // �����N����
    sb.append("  AND    (:22 IS NULL OR ilm.attribute3 = TO_CHAR(:22, 'YYYY/MM/DD')) "            ); // �ܖ�����
    sb.append("  AND    (:23 IS NULL OR ilm.attribute2 = :23))); "                                ); // �ŗL�L��      
    sb.append("  :24 := '1'; "                                                                    );
    sb.append("EXCEPTION "                                                                        );
    sb.append("  WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN "                                       );
    sb.append("    :24 := '0'; "                                                                  );
    sb.append("END; "                                                                             );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(17,    XxcmnUtility.intValue(itemId));            // �i��ID
      cstmt.setString(18, prodClassCode);                            // ���i�敪
      cstmt.setString(19, itemClassCode);                            // �i�ڋ敪
      cstmt.setString(20, lotNo);                                    // ���b�gNo
      cstmt.setDate(21,   XxcmnUtility.dateValue(manufacturedDate)); // �����N����
      cstmt.setDate(22,   XxcmnUtility.dateValue(useByDate));        // �ܖ�����
      cstmt.setString(23, koyuCode);                                 // �ŗL�L��
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1,  Types.VARCHAR);
      cstmt.registerOutParameter(2,  Types.VARCHAR);
      cstmt.registerOutParameter(3,  Types.VARCHAR);
      cstmt.registerOutParameter(4,  Types.VARCHAR);
      cstmt.registerOutParameter(5,  Types.VARCHAR);
      cstmt.registerOutParameter(6,  Types.VARCHAR);
      cstmt.registerOutParameter(7,  Types.VARCHAR);
      cstmt.registerOutParameter(8,  Types.VARCHAR);
      cstmt.registerOutParameter(9,  Types.VARCHAR);
      cstmt.registerOutParameter(10, Types.VARCHAR);
      cstmt.registerOutParameter(11, Types.VARCHAR);
      cstmt.registerOutParameter(12, Types.VARCHAR);
      cstmt.registerOutParameter(13, Types.DATE   );
      cstmt.registerOutParameter(14, Types.DATE   );
      cstmt.registerOutParameter(15, Types.VARCHAR);
      cstmt.registerOutParameter(16, Types.INTEGER);
      cstmt.registerOutParameter(24, Types.VARCHAR);
      
      // PL/SQL���s
      cstmt.execute();

      // OUT�p�����[�^�擾
      params.put("statusDesc"          , cstmt.getString(1));           // �X�e�[�^�X�R�[�h����
      params.put("rawMateTurnMReserve" , cstmt.getString(2));           // ���Y��������(�蓮����)
      params.put("rawMateTurnRel"      , cstmt.getString(3));           // ���Y��������(����)
      params.put("payProvisionMReserve", cstmt.getString(4));           // �L���x��(�蓮����)
      params.put("payProvisionRel"     , cstmt.getString(5));           // �L���x��(����)
      params.put("moveInstMReserve"    , cstmt.getString(6));           // �ړ��w��(�蓮����)
      params.put("moveInstAReserve"    , cstmt.getString(7));           // �ړ��w��(��������)
      params.put("moveInstRel"         , cstmt.getString(8));           // �ړ��w��(����)
      params.put("shipReqMReserve"     , cstmt.getString(9));           // �o�׈˗�(�蓮����)
      params.put("shipReqAReserve"     , cstmt.getString(10));          // �o�׈˗�(��������)
      params.put("shipReqRel"          , cstmt.getString(11));          // �o�׈˗�(����)
      params.put("lotNo"               , cstmt.getString(12));          // ���b�gNo
      params.put("manufacturedDate"    , cstmt.getObject(13));          // �����N����
      params.put("useByDate"           , cstmt.getObject(14));          // �ܖ�����
      params.put("koyuCode"            , cstmt.getString(15));          // �ŗL�L��
      params.put("lotId"               , new Number(cstmt.getInt(16))); // ���b�gID
      params.put("retCode"             , cstmt.getString(24));          // �߂�l

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        //�������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // seachOpmLotMst

  /*****************************************************************************
   * �ړ����b�g�ڍ�ID�V�[�P���X���A�V�KID���擾���郁�\�b�h�ł��B
   * @param trans   - �g�����U�N�V����
   * @throws OAException - OA��O
   ****************************************************************************/
  public static Number getMovLotDtlId(
    OADBTransaction trans
  ) throws OAException
  {
    return XxcmnUtility.getSeq(trans, XxwshConstants.XXINV_MOV_LOT_S1);
  } // getMovLotDtlId
  
  /*****************************************************************************
   * �݌ɃN���[�Y�`�F�b�N���s���܂��B
   * @param trans   - �g�����U�N�V����
   * @param chkDate - ��r���t
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void chkStockClose(
    OADBTransaction trans,
    Date chkDate
  ) throws OAException
  {
    String apiName = "chkStockClose"; // API��
    
    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(100);
    sb.append("DECLARE "                                                      );
    sb.append("  lv_close_date VARCHAR2(30); "                                ); // �N���[�Y���t
    sb.append("BEGIN "                                                        );
                 // OPM�݌ɉ�v����CLOSE�N���擾
    sb.append("   lv_close_date := xxcmn_common_pkg.get_opminv_close_period; ");
    sb.append("   :1 := lv_close_date; "                                      );
                 // ��r���t���N���[�Y���t�ȑO�̏ꍇ�AN�F�N���[�Y���Z�b�g
    sb.append("   IF (lv_close_date >= TO_CHAR(:2, 'YYYYMM')) THEN "          ); 
    sb.append("     :3 := 'N'; "                                              );
                 // ��r���t���N���[�Y���t�ȍ~�̏ꍇ�AY�F�N���[�Y�O���Z�b�g
    sb.append("   ELSE "                                                      );
    sb.append("     :3 := 'Y'; "                                              );
    sb.append("   END IF; "                                                   ); 
    sb.append("END; "                                                         );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setDate(2, XxcmnUtility.dateValue(chkDate)); // ���t
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR); // CLOSE�N��
      cstmt.registerOutParameter(3, Types.VARCHAR); // �߂�l
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      String closeDate = cstmt.getString(1);
      String plSqlRet  = cstmt.getString(3);

      // �N���[�Y���Ă���ꍇ
      if (XxcmnConstants.STRING_N.equals(cstmt.getString(3)))
      {
        // �݌ɉ�v���ԃ`�F�b�N�G���[
        // �g�[�N������
        MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_DATE, cstmt.getString(1)) };
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH13304, 
          tokens);  
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        //�������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    } 
  } // chkStockClose

  /*****************************************************************************
   * �z�ԉ����֐����Ăяo���܂��B
   * @param bizType - �Ɩ���� 1:�o��,2:�x��,3:�ړ�
   * @param reqNo   - �˗�No/�ړ��ԍ�
   * @return String - �߂�l 0:����,1:�p�����[�^�`�F�b�N�G���[,-1:�z�ԉ������s
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String cancelCareersSchedile(
    OADBTransaction trans,
    String bizType,
    String reqNo
  ) throws OAException
  {
    String apiName = "cancelCareersSchedile";  // API��

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
// 2008-10-24 D.Nihei MOD START TE080_BPO_600 No22
//    sb.append("  :1 := xxwsh_common_pkg.cancel_careers_schedule(:2, :3, :4); ");
    sb.append("  :1 := xxwsh_common_pkg.cancel_careers_schedule(:2, :3, '1', :4); ");
// 2008-10-24 D.Nihei MOD END
    sb.append("END; ");

    // PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try 
    {
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR); // �߂�l

      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(2, bizType); // �Ɩ����
      cstmt.setString(3, reqNo);   // �˗�No/�ړ��ԍ�

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(4, Types.VARCHAR); // �G���[���b�Z�[�W

      // PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      String retCode = cstmt.getString(1);
      // �߂�l�����������ȊO�̓��O�ɃG���[���b�Z�[�W���o��
      if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {
        // ���[���o�b�N
        rollBack(trans);

        String errMsg = cstmt.getString(4);
        // ���O�o��
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              errMsg,
                              6);
      }

      // �߂�l�ԋp
      return retCode;

    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);

      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);

      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                             XxcmnConstants.XXCMN10123
                             );

    } finally 
    {
      try
      {
        // �������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // cancelCareersSchedile

  /*****************************************************************************
   * ���b�g�t�]�h�~�`�F�b�NAPI�����s���܂��B
   * @param trans - �g�����U�N�V����
   * @param itemNo       - �i��No
   * @param lotNo        - ���b�gNo
   * @param moveToId     - �z����ID
   * @param standardDate - ���
   * @return HashMap 
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap doCheckLotReversal(
    OADBTransaction trans,
    String itemNo,
    String lotNo,
    Number moveToId,
    Date   standardDate
  ) throws OAException
  {
    String apiName = "doCheckLotReversal"; 
    HashMap ret    = new HashMap();
    
    // OUT�p�����[�^
    String exeType = XxcmnConstants.RETURN_NOT_EXE;
    
    //PL/SQL�쐬
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                                    );
    sb.append("  xxwsh_common910_pkg.check_lot_reversal( ");
    sb.append("    iv_lot_biz_class    => '2',           ");   //  .���b�g�t�]������� 2:�o��
    sb.append("    iv_item_no          => :1,            ");   // 1.�i�ڃR�[�h
    sb.append("    iv_lot_no           => :2,            ");   // 2.���b�gNo
    sb.append("    iv_move_to_id       => :3,            ");   // 3.�z����ID/�����T�C�gID/���ɐ�ID
    sb.append("    iv_arrival_date     => NULL,          ");   //  .����
    sb.append("    id_standard_date    => :4,            ");   // 4.���(�K�p�����)
    sb.append("    ov_retcode          => :5,            ");   // 5.���^�[���R�[�h
    sb.append("    ov_errmsg_code      => :6,            ");   // 6.�G���[���b�Z�[�W�R�[�h
    sb.append("    ov_errmsg           => :7,            ");   // 7.�G���[���b�Z�[�W
    sb.append("    on_result           => :8,            ");   // 8.��������
    sb.append("    on_reversal_date    => :9);           ");   // 9.�t�]���t
    sb.append("END; "                                     );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, itemNo);                           // �i�ڃR�[�h
      cstmt.setString(2, lotNo);                            // ���b�gNo
      cstmt.setInt(3, XxcmnUtility.intValue(moveToId));     // �z����ID
      cstmt.setDate(4, XxcmnUtility.dateValue(standardDate));// ���(�K�p�����)
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(5, Types.VARCHAR); // ���^�[���R�[�h
      cstmt.registerOutParameter(6, Types.VARCHAR); // �G���[���b�Z�[�W�R�[�h
      cstmt.registerOutParameter(7, Types.VARCHAR); // �G���[���b�Z�[�W
      cstmt.registerOutParameter(8, Types.INTEGER); // ��������
      cstmt.registerOutParameter(9, Types.DATE);    // �t�]���t

      //PL/SQL���s
      cstmt.execute();

      String retCode = cstmt.getString(5);             // ���^�[���R�[�h
      String errmsgCode = cstmt.getString(6);          // �G���[���b�Z�[�W�R�[�h
      String errmsg = cstmt.getString(7);              // �G���[���b�Z�[�W

      // API����I���̏ꍇ�A�l���Z�b�g
      if (XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {
        ret.put("result",  new Number(cstmt.getInt(8))); // ��������
        ret.put("revDate", new Date(cstmt.getDate(9)));  // �t�]���t
        
      // API����I���łȂ��ꍇ�A�G���[  
      } else
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          cstmt.getString(7), // �G���[���b�Z�[�W
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);
        
    } finally
    {
      try
      {
        // PL/SQL�N���[�Y
        cstmt.close();
        
      // �N���[�Y���ɂɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    return ret;
  } // doCheckLotReversal

  /*****************************************************************************
   * �莝�݌ɐ��ʎZ�oAPI�����s���܂��B
   * @param trans   - �g�����U�N�V����
   * @param whseId  - OPM�ۊǑq��ID
   * @param itemId  - OPM�i��ID
   * @param lotId   - ���b�gID
   * @param lotCtl  - ���b�g�Ǘ��敪
   * @return Number - �莝�݌ɐ���
   * @throws OAException - OA��O
   ****************************************************************************/
  public static Number getStockQty(
    OADBTransaction trans,
    Number whseId,
    Number itemId,
    Number lotId,
    String lotCtl
  ) throws OAException
  {
    String apiName = "getStockQty";

    // OUT�p�����[�^
    Number stockQty    = new Number();
    
    //PL/SQL�쐬
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                                    );
    sb.append("  :1 := xxcmn_common_pkg.get_stock_qty( "  ); // 1.�莝�݌ɐ���
    sb.append("          in_whse_id  => :2,  "            ); // 2.OPM�ۊǑq��ID
    sb.append("          in_item_id  => :3,  "            ); // 3.OPM�i��ID
    sb.append("          in_lot_id   => :4); "            ); // 4.���b�gID
    sb.append("END; "                                     );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(whseId)); // �ۊǑq��ID
      cstmt.setInt(3, XxcmnUtility.intValue(itemId)); // �i��ID
      // ���b�g�Ǘ��O�i�̏ꍇ�A���b�gID��NULL
      if (XxwshConstants.LOT_CTL_N.equals(lotCtl))
      {
        cstmt.setNull(4, Types.INTEGER); // ���b�gID
      } else
      {
        cstmt.setInt(4, XxcmnUtility.intValue(lotId));  // ���b�gID        
      }
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.NUMERIC); // �莝�݌ɐ���

      //PL/SQL���s
      cstmt.execute();

      // OUT�p�����[�^�擾
      stockQty = new Number(cstmt.getObject(1));  // �莝�݌ɐ���

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);
        
    } finally
    {
      try
      {
        // PL/SQL�N���[�Y
        cstmt.close();
        
      // �N���[�Y���ɂɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }

    return stockQty;
    
  } // getStockQty
  
  /*****************************************************************************
   * �����\���Z�oAPI�����s���܂��B
   * @param trans - �g�����U�N�V����
   * @param whseId  - OPM�ۊǑq��ID
   * @param itemId  - OPM�i��ID
   * @param lotId   - ���b�gID
   * @param lotCtl  - ���b�g�Ǘ��敪
   * @return Number - �����\��
   * @throws OAException - OA��O
   ****************************************************************************/
  public static Number getCanEncQty(
    OADBTransaction trans,
    Number whseId,
    Number itemId,
    Number lotId,
    String lotCtl
  ) throws OAException
  {
    String apiName = "getCanEncQty";

    // OUT�p�����[�^
    Number canEncQty    = new Number();
    
    //PL/SQL�쐬
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                                    );
    sb.append("  :1 := xxcmn_common_pkg.get_can_enc_qty( "); // 1.�����\��
    sb.append("        in_whse_id  => :2,  "              ); // 2.OPM�ۊǑq��ID
    sb.append("        in_item_id  => :3,  "              ); // 3.OPM�i��ID
    sb.append("        in_lot_id   => :4,  "              ); // 4.���b�gID
    sb.append("        in_active_date => SYSDATE); "      ); //  .�L����
    sb.append("END; "                                     );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(whseId)); // �ۊǑq��ID
      cstmt.setInt(3, XxcmnUtility.intValue(itemId)); // �i��ID
      // ���b�g�Ǘ��O�i�̏ꍇ�A���b�gID��NULL
      if (XxwshConstants.LOT_CTL_N.equals(lotCtl))
      {
        cstmt.setNull(4, Types.INTEGER); // ���b�gID
      } else
      {
        cstmt.setInt(4, XxcmnUtility.intValue(lotId));  // ���b�gID        
      }
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.NUMERIC); // �����\��

      //PL/SQL���s
      cstmt.execute();

      // OUT�p�����[�^�擾
      canEncQty = new Number(cstmt.getObject(1));  // �����\��

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);
        
    } finally
    {
      try
      {
        // PL/SQL�N���[�Y
        cstmt.close();
        
      // �N���[�Y���ɂɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }

    return canEncQty;
    
  } // getCanEncQty  

  /*****************************************************************************
   * �����\���Z�oAPI�����s���܂��B(�L�����w��o�[�W����)
   * @param trans      - �g�����U�N�V����
   * @param whseId     - OPM�ۊǑq��ID
   * @param itemId     - OPM�i��ID
   * @param lotId      - ���b�gID
   * @param lotCtl     - ���b�g�Ǘ��敪
   * @param activeDate - �L����
   * @return Number - �����\��
   * @throws OAException - OA��O
   ****************************************************************************/
  public static Number getCanEncQty(
    OADBTransaction trans,
    Number whseId,
    Number itemId,
    Number lotId,
    String lotCtl,
    Date   activeDate
  ) throws OAException
  {
    String apiName = "getCanEncQty";

    // OUT�p�����[�^
    Number canEncQty    = new Number();
    
    //PL/SQL�쐬
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                                    );
    sb.append("  :1 := xxcmn_common_pkg.get_can_enc_qty( "); // 1.�����\��
    sb.append("        in_whse_id  => :2,  "              ); // 2.OPM�ۊǑq��ID
    sb.append("        in_item_id  => :3,  "              ); // 3.OPM�i��ID
    sb.append("        in_lot_id   => :4,  "              ); // 4.���b�gID
    sb.append("        in_active_date => :5); "           ); // 5.�L����
    sb.append("END; "                                     );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(whseId)); // �ۊǑq��ID
      cstmt.setInt(3, XxcmnUtility.intValue(itemId)); // �i��ID
      // ���b�g�Ǘ��O�i�̏ꍇ�A���b�gID��NULL
      if (XxwshConstants.LOT_CTL_N.equals(lotCtl))
      {
        cstmt.setNull(4, Types.INTEGER); // ���b�gID
      } else
      {
        cstmt.setInt(4, XxcmnUtility.intValue(lotId));  // ���b�gID        
      }
      
      cstmt.setDate(5, XxcmnUtility.dateValue(activeDate)); // �L����
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.NUMERIC); // �����\��

      //PL/SQL���s
      cstmt.execute();

      // OUT�p�����[�^�擾
      canEncQty = new Number(cstmt.getObject(1));  // �����\��

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);
        
    } finally
    {
      try
      {
        // PL/SQL�N���[�Y
        cstmt.close();
        
      // �N���[�Y���ɂɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }

    return canEncQty;
    
  } // getCanEncQty

 /*****************************************************************************
   * �ړ����b�g�ڍ׃A�h�I�������݂��邩�`�F�b�N���郁�\�b�h�ł��B
   * @param trans            - �g�����U�N�V����
   * @param movLineId        - �󒍖��׃A�h�I��ID
   * @param documentTypeCode - �����^�C�v(10:�o�׈˗��A30:�x���w��)
   * @param recordTypeCode   - ���R�[�h�^�C�v(10�F�w���A20�F�o�Ɏ���  30�F���Ɏ���)
   * @param lotId            - ���b�gID
   * @return boolean - true:����
   *                  - false:�Ȃ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean checkMovLotDtl(
    OADBTransaction trans,
    Number movLineId,
    String documentTypeCode,
    String recordTypeCode,
    Number lotId
  ) throws OAException
  {
    String apiName     = "checkMovLotDtl";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                        );
    sb.append("  lv_temp VARCHAR2(1); "                         );
    sb.append("BEGIN "                                          );
    sb.append("  SELECT 1  "                                    );
    sb.append("  INTO   lv_temp "                               );
    sb.append("  FROM   xxinv_mov_lot_details xmld "            ); //   �ړ����b�g�ڍ׃A�h�I��
    sb.append("  WHERE  xmld.mov_line_id        = :1 "          ); // 1.�󒍖��׃A�h�I��ID
    sb.append("  AND    xmld.document_type_code = :2 "          ); // 2.�����^�C�v
    sb.append("  AND    xmld.record_type_code   = :3 "          ); // 3.���R�[�h�^�C�v
    sb.append("  AND    xmld.lot_id             = :4 "          ); // 4.���b�gID
    sb.append("  AND    ROWNUM                  = 1; "          );
    sb.append("    :5 := 'Y'; "                                 ); // 5.�߂�lY:���b�g��񂠂�
    sb.append("EXCEPTION "                                      );
    sb.append("  WHEN NO_DATA_FOUND THEN "                      );
    sb.append("    :5 := 'N'; "                                 ); // 5.�߂�lN:���b�g���Ȃ�
    sb.append("END; "                                           );

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    { 
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1, XxcmnUtility.intValue(movLineId)); // �󒍖��׃A�h�I��ID
      cstmt.setString(2, documentTypeCode);              // �����^�C�v
      cstmt.setString(3, recordTypeCode);              // �����^�C�v
      cstmt.setInt(4, XxcmnUtility.intValue(lotId));     // ���b�gID
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(5, Types.VARCHAR);
      
      // PL/SQL���s
      cstmt.execute();

      // OUT�p�����[�^�擾
      String ret = cstmt.getString(5);  // �߂�l

      // Y�̏ꍇ�A���b�g������̂�true��Ԃ��B
      if (XxcmnConstants.STRING_Y.equals(ret))
      {
        return true;

      // N�̏ꍇ�A���b�g���Ȃ��̂�false��Ԃ��B
      } else
      {
        return false;
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
        // ���[���o�b�N
        XxwshUtility.rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        //�������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        XxwshUtility.rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // checkMovLotDtl

  /*****************************************************************************
   * �󒍃w�b�_�A�h�I�����b�N���擾���܂��B
   * @param trans          - �g�����U�N�V����
   * @param orderHeaderId  - �󒍃w�b�_�A�h�I��ID
   * @return HashMap
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap getXxwshOrderHeadersAllLock(
    OADBTransaction trans,
    Number orderHeaderId
  ) throws OAException
  {
    String apiName = "getXxwshOrderHeadersAllLock";
    HashMap ret = new HashMap();
    
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                                                          );
                 // ���[�U�[��`�G���[
    sb.append("  lock_expt             EXCEPTION; "                                               );
    sb.append("  PRAGMA EXCEPTION_INIT(lock_expt, -54); "                                         );
    sb.append("BEGIN "                                                                            );
                 // ���b�N�擾
    sb.append("  SELECT TO_CHAR(xoha.last_update_date,'YYYY/MM/DD HH24:MI:SS')  last_update_date ");
    sb.append("  INTO   :1 "                                                                      );
    sb.append("  FROM   xxwsh_order_headers_all xoha "                                            );
    sb.append("  WHERE  xoha.order_header_id = :2 "                                               );
    sb.append("  FOR UPDATE NOWAIT; "                                                             );
    sb.append("EXCEPTION "                                                                        );
    sb.append("  WHEN lock_expt THEN "                                                            );
    sb.append("    :3 := '1'; "                                                                   );
    sb.append("    :4 := SQLERRM; "                                                               );
    sb.append("END; "                                                                             );

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR);   // �ŏI�X�V��
      cstmt.registerOutParameter(3, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(4, Types.VARCHAR);   // �G���[���b�Z�[�W
      
      //PL/SQL���s
      cstmt.execute();

      // ���b�N�G���[�I���̏ꍇ  
      if ("1".equals(cstmt.getString(3)))
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          cstmt.getString(4),
          6);

        ret.put("retFlag", XxcmnConstants.RETURN_ERR1); // �߂�l E1:���b�N�G���[

      // ����I���̏ꍇ
      } else
      {
        ret.put("retFlag",        XxcmnConstants.RETURN_SUCCESS); // �߂�l 1:����
        ret.put("lastUpdateDate", cstmt.getString(1));            // �ŏI�X�V��
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);
                            
    } finally
    {
      try
      {
        // PL/SQL�N���[�Y
        cstmt.close();
        
      // close���ɗ�O�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    // �߂�l
    return ret;
  } // getXxwshOrderHeadersAllLock

  /*****************************************************************************
   * �󒍖��׃A�h�I�����b�N���擾���܂��B
   * @param trans          - �g�����U�N�V����
   * @param orderHeaderId    - �󒍃w�b�_�A�h�I��ID
   * @return HashMap
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap getXxwshOrderLinesAllLock(
    OADBTransaction trans,
    Number orderHeaderId
  ) throws OAException
  {
    String apiName = "getXxwshOrderLinesAllLock";
    HashMap ret = new HashMap();
    
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                                                               );
                 // ���[�U�[��`�G���[
    sb.append("  lock_expt             EXCEPTION; "                                                    );
    sb.append("  PRAGMA EXCEPTION_INIT(lock_expt, -54); "                                              );
    sb.append("  CURSOR lock_cur IS "                                                                  );
    sb.append("    SELECT xola.order_header_id  order_header_id "                                      );
    sb.append("    FROM   xxwsh_order_lines_all xola "                                                 );
    sb.append("    WHERE  xola.order_header_id = :1 "                                                  );
    sb.append("    FOR UPDATE NOWAIT; "                                                                );
    sb.append("  lock_rec lock_cur%ROWTYPE; "                                                          );
    sb.append("BEGIN "                                                                                 );
                 // ���b�N�擾
    sb.append("  OPEN lock_cur; "                                                                      );
    sb.append("  FETCH lock_cur INTO lock_rec; "                                                                      );
    sb.append("  CLOSE lock_cur; "                                                                     );
                 // �ŏI�X�V���ő�l���擾
    sb.append("  SELECT TO_CHAR(MAX(xola.last_update_date),'YYYY/MM/DD HH24:MI:SS')  last_update_date ");
    sb.append("  INTO   :2  "                                                                          );
    sb.append("  FROM   xxwsh_order_lines_all xola "                                                   );
    sb.append("  WHERE  xola.order_header_id = :1 "                                                    );
// 2008-07-02 D.Nihei UPD Start
//    sb.append("  AND   NVL(xola.delete_flag,'N') = 'N' ;"                                              ); // �폜�t���O
    sb.append("  ;");
// 2008-07-02 D.Nihei UPD Start
    sb.append("EXCEPTION "                                                                             );
    sb.append("  WHEN lock_expt THEN "                                                                 );
    sb.append("    :3 := '1'; "                                                                        );
    sb.append("    :4 := SQLERRM; "                                                                    );
    sb.append("END; "                                                                                  );

    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1, XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(2, Types.VARCHAR);   // �ŏI�X�V��
      cstmt.registerOutParameter(3, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(4, Types.VARCHAR);   // �G���[���b�Z�[�W
      
      //PL/SQL���s
      cstmt.execute();

      // ���b�N�G���[�I���̏ꍇ  
      if ("1".equals(cstmt.getString(3)))
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          cstmt.getString(4),
          6);

        ret.put("retFlag", XxcmnConstants.RETURN_ERR1); // �߂�l E1:���b�N�G���[

      // ����I���̏ꍇ
      } else
      {
        ret.put("retFlag",        XxcmnConstants.RETURN_SUCCESS); // �߂�l 1:����
        ret.put("lastUpdateDate", cstmt.getString(2));            // �ŏI�X�V��
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);
                            
    } finally
    {
      try
      {
        // PL/SQL�N���[�Y
        cstmt.close();
        
      // close���ɗ�O�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    // �߂�l
    return ret;
  } // getXxwshOrderLinesAllLock

  /*****************************************************************************
   * �ړ����b�g�ڍ׃A�h�I�����b�N���擾���܂��B
   * @param trans            - �g�����U�N�V����
   * @param movLineId        - �󒍖��׃A�h�I��ID
   * @param documentTypeCode - �����^�C�v(10:�o�׈˗��A30:�x���w��)
   * @param recordTypeCode   - ���R�[�h�^�C�v(10�F�w���A20�F�o�Ɏ���  30�F���Ɏ���)
   * @return String - 1:����  0:�ُ�  E1:���b�N�G���[
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String getXxinvMovLotDetailsLock(
    OADBTransaction trans,
    Number movLineId,
    String documentTypeCode,
    String recordTypeCode
  ) throws OAException
  {
    String apiName = "getXxinvMovLotDetailsLock";
    String retCode = XxcmnConstants.RETURN_NOT_EXE; // �߂�l
    
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                     );
    sb.append("  lock_expt             EXCEPTION; "          ); 
    sb.append("  PRAGMA EXCEPTION_INIT(lock_expt, -54); "    );
    sb.append("CURSOR lock_cur IS "                          );
    sb.append("  SELECT 1 "                                  );
    sb.append("  FROM   xxinv_mov_lot_details xmld "         );
    sb.append("  WHERE  xmld.mov_line_id        = :1 "       ); // 1.�󒍖��׃A�h�I��ID
    sb.append("  AND    xmld.document_type_code = :2 "       ); // 2.�����^�C�v
    sb.append("  AND    xmld.record_type_code   = :3 "       ); // 3.���R�[�h�^�C�v
    sb.append("  FOR UPDATE NOWAIT; "                        );
    sb.append("  lock_rec lock_cur%ROWTYPE; "                );
    sb.append("BEGIN "                                       );
    sb.append("  OPEN lock_cur; "                            );
    sb.append("  FETCH lock_cur INTO lock_rec; "             );
    sb.append("  CLOSE lock_cur; "                           );
    sb.append("EXCEPTION "                                   );
    sb.append("  WHEN lock_expt THEN "                       );
    sb.append("    IF (lock_cur%ISOPEN) THEN "               );
    sb.append("      CLOSE lock_cur; "                       );
    sb.append("    END IF; "                                 );
    sb.append("    :4 := '1'; "                              );
    sb.append("    :5 := SQLERRM; "                          );
    sb.append("END; "                                        );

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1,    XxcmnUtility.intValue(movLineId)); // �󒍖��׃A�h�I��ID
      cstmt.setString(2, documentTypeCode);                 // �����^�C�v
      cstmt.setString(3, recordTypeCode);                   // ���R�[�h�^�C�v
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(4, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(5, Types.VARCHAR);   // �G���[���b�Z�[�W
      
      //PL/SQL���s
      cstmt.execute();

      // ���b�N�G���[�I���̏ꍇ  
      if ("1".equals(cstmt.getString(4)))
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          cstmt.getString(5),
          6);

        retCode = XxcmnConstants.RETURN_ERR1;// �߂�l E1:���b�N�G���[

      // ����I���̏ꍇ
      } else
      {
        retCode = XxcmnConstants.RETURN_SUCCESS;// �߂�l 1:����
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);
                            
    } finally
    {
      try
      {
        // PL/SQL�N���[�Y
        cstmt.close();
        
      // close���ɗ�O�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    // �߂�l
    return retCode;
  } // getXxinvMovLotDetailsLock

  /*****************************************************************************
   * �ړ����b�g�ڍ׃A�h�I���ɒǉ��������s�����\�b�h�ł��B
   * @param trans   - �g�����U�N�V����
   * @param params  - �p�����[�^
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void insertXxinvMovLotDetails(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "insertXxinvMovLotDetails";

    Number orderLineId      = (Number)params.get("orderLineId");      // ����ID
    String documentTypeCode = (String)params.get("documentTypeCode"); // �����^�C�v
    String recordTypeCode   = (String)params.get("recordTypeCode");   // ���R�[�h�^�C�v
    Number itemId           = (Number)params.get("itemId");           // �i��ID
    String itemCode         = (String)params.get("itemCode");         // �i��
    Number lotId            = (Number)params.get("lotId");            // ���b�gID
    String lotNo            = (String)params.get("lotNo");            // ���b�gNo
    Date   actualDate       = (Date)params.get("actualDate");         // ���ѓ�
    String actualQuantity   = (String)params.get("actualQuantity");   // ���ѐ���

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                      );
    sb.append("  INSERT INTO xxinv_mov_lot_details xmld ( " ); // �ړ����b�g�ڍ׃A�h�I��
		sb.append("     xmld.mov_lot_dtl_id  "                  ); // ���b�g�ڍ�ID
		sb.append("    ,xmld.mov_line_id  "                     ); // 1.����ID
		sb.append("    ,xmld.document_type_code  "              ); // 2.�����^�C�v
		sb.append("    ,xmld.record_type_code  "                ); // 3.���R�[�h�^�C�v
		sb.append("    ,xmld.item_id  "                         ); // 4.OPM�i��ID
		sb.append("    ,xmld.item_code  "                       ); // 5.�i��
		sb.append("    ,xmld.lot_id  "                          ); // 6.���b�gID
		sb.append("    ,xmld.lot_no  "                          ); // 7.���b�gNo
		sb.append("    ,xmld.actual_date  "                     ); // 8.���ѓ�
		sb.append("    ,xmld.actual_quantity  "                 ); // 9.���ѐ���
		sb.append("    ,xmld.created_by  "                      ); // 10.�쐬��
		sb.append("    ,xmld.creation_date  "                   ); // 11.�쐬��
		sb.append("    ,xmld.last_updated_by  "                 ); // 12.�ŏI�X�V��
		sb.append("    ,xmld.last_update_date  "                ); // 13.�ŏI�X�V��
		sb.append("    ,xmld.last_update_login)  "              ); // 14.�ŏI�X�V���O�C��
    sb.append("  VALUES(  "                                 );
    sb.append("     xxinv_mov_lot_s1.NEXTVAL "              );
    sb.append("    ,:1 "                                    );
    sb.append("    ,:2 "                                    );
    sb.append("    ,:3 "                                    );
    sb.append("    ,:4 "                                    );
    sb.append("    ,:5 "                                    );
    sb.append("    ,:6 "                                    );
    sb.append("    ,:7 "                                    );
    sb.append("    ,:8 "                                    );
    sb.append("    ,TO_NUMBER(:9) "                         );
    sb.append("    ,FND_GLOBAL.USER_ID "                    ); // �쐬��          
    sb.append("    ,SYSDATE "                               ); // �쐬��          
    sb.append("    ,FND_GLOBAL.USER_ID "                    ); // �ŏI�X�V��      
    sb.append("    ,SYSDATE "                               ); // �ŏI�X�V��      
    sb.append("    ,FND_GLOBAL.LOGIN_ID); "                 ); // �ŏI�X�V���O�C��
    sb.append("END; "                                       );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1,    XxcmnUtility.intValue(orderLineId)); // ����ID
      cstmt.setString(2, documentTypeCode);                   // �����^�C�v
      cstmt.setString(3, recordTypeCode);                     // ���R�[�h�^�C�v
      cstmt.setInt(4,    XxcmnUtility.intValue(itemId));      // OPM�i��ID
      cstmt.setString(5, itemCode);                           // �i��
      cstmt.setInt(6,    XxcmnUtility.intValue(lotId));       // ���b�gID
      cstmt.setString(7, lotNo);                              // ���b�gNo
      cstmt.setDate(8,   XxcmnUtility.dateValue(actualDate)); // ���ѓ�
      cstmt.setString(9, actualQuantity);                     // ���ѐ���

      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        //�������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // insertXxinvMovLotDetails

  /*****************************************************************************
   * �󒍖��׃A�h�I���̏o�׎��ѐ��ʂ��X�V���郁�\�b�h�ł��B
   * @param trans        - �g�����U�N�V����
   * @param orderLineId  - �󒍖��׃A�h�I��ID
   * @param shippedQty   - �o�׎��ѐ���
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void updateShippedQuantity(
    OADBTransaction trans,
     Number orderLineId,
     String shippedQty
  ) throws OAException
  {
    String apiName   = "updateShippedQuantity";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
// 2008-09-19 H.Itou Add Start
    sb.append("DECLARE "                                                                        );
    sb.append("  lt_in_param_quantity      xxwsh_order_lines_all.shipped_quantity%TYPE; "       ); // IN�p�����[�^.�X�V����o�׎��ѐ���
    sb.append("  lt_in_param_order_line_id xxwsh_order_lines_all.order_line_id%TYPE; "          ); // IN�p�����[�^.�󒍖���ID
    sb.append("  lt_shipped_quantity       xxwsh_order_lines_all.shipped_quantity%TYPE; "       ); // DB�o�׎��ѐ���
    sb.append("  lt_shipping_result_if_flg xxwsh_order_lines_all.shipping_result_if_flg%TYPE; " ); // DB�o�׎��уC���^�t�F�[�X�σt���O
    sb.append("  lt_req_status             xxwsh_order_headers_all.req_status%TYPE; "           ); // DB�X�e�[�^�X
// 2008-09-19 H.Itou Add End
    sb.append("BEGIN "                                                                          );
// 2008-09-19 H.Itou Add Start
                 // IN�p�����[�^�擾
    sb.append("  lt_in_param_quantity := TO_NUMBER(:1); "                                       ); // IN�p�����[�^.�X�V����o�׎��ѐ���
    sb.append("  lt_in_param_order_line_id := :2; "                                             ); // IN�p�����[�^.�󒍖���ID

                 // �X�V�O�̏o�׎��ѐ��ʂƃX�e�[�^�X���擾
    sb.append("  SELECT xola.shipped_quantity       shipped_quantity "                          ); // DB�o�׎��ѐ���
    sb.append("        ,xola.shipping_result_if_flg shipping_result_if_flg "                    ); // DB�o�׎��уC���^�t�F�[�X�σt���O
    sb.append("        ,xoha.req_status             req_status "                                ); // DB�X�e�[�^�X
    sb.append("  INTO   lt_shipped_quantity "                                                   );
    sb.append("        ,lt_shipping_result_if_flg "                                             );
    sb.append("        ,lt_req_status "                                                         );
    sb.append("  FROM   xxwsh_order_headers_all xoha "                                          ); // �󒍃w�b�_�A�h�I��
    sb.append("        ,xxwsh_order_lines_all   xola "                                          ); // �󒍖��׃A�h�I��
    sb.append("  WHERE xoha.order_header_id = xola.order_header_id "                            );
    sb.append("  AND   xola.order_line_id   = lt_in_param_order_line_id; "                      );

                 // �o�׎��ьv���(04)���A�o�׎��ѐ��ʂ��Ⴄ�l�ɍX�V����ꍇ(�o�ׂ̃f�[�^�̂�)
// 2008-12-06 T.Miyata Add Start �{��#484 ���і��C���̃f�[�^�ɂ��Ă��C���^�[�t�F�[�X�σt���O��N�ɂ���Ђ悤������B
//    sb.append("  IF (((lt_shipped_quantity <> lt_in_param_quantity ) "                          );
//    sb.append("    OR (lt_shipped_quantity IS NULL)) "                                          );
    sb.append("  IF (lt_req_status       =  '04')                 THEN "                      );
// 2008-12-06 T.Miyata Add End �{��#484
                   // �o�׎��уC���^�t�F�[�X�σt���O��N�ɍX�V
    sb.append("    lt_shipping_result_if_flg := 'N'; "                                          );
    sb.append("  END IF; "                                                                      );
// 2008-09-19 H.Itou Add End

    sb.append("  UPDATE xxwsh_order_lines_all xola "                                            ); // �󒍖��׃A�h�I��
    sb.append("  SET    xola.shipped_quantity  = lt_in_param_quantity "                         ); // 1.�o�׎��ѐ���
    sb.append("        ,xola.last_updated_by   = FND_GLOBAL.USER_ID "                           ); // �ŏI�X�V��
    sb.append("        ,xola.last_update_date  = SYSDATE "                                      ); // �ŏI�X�V��
    sb.append("        ,xola.last_update_login = FND_GLOBAL.LOGIN_ID "                          ); // �ŏI�X�V���O�C��
// 2008-09-19 H.Itou Add Start
    sb.append("        ,xola.shipping_result_if_flg = lt_shipping_result_if_flg "               ); // �o�׎��уC���^�t�F�[�X�σt���O
// 2008-09-19 H.Itou Add End
    sb.append("  WHERE  xola.order_line_id = lt_in_param_order_line_id; "                       ); // 2.�󒍖��׃A�h�I��ID
    sb.append("END; "                                                                           );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, shippedQty);                         // �o�׎��ѐ���
      cstmt.setInt(2,    XxcmnUtility.intValue(orderLineId)); // ����ID

      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updateShippedQuantity

  /*****************************************************************************
   * �ړ����b�g���׃A�h�I���̎��ѐ��ʂ��X�V���郁�\�b�h�ł��B
   * @param trans        - �g�����U�N�V����
   * @param params       - �p�����[�^
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void updateActualQuantity(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "updateActualQuantity";

    // IN�p�����[�^�擾
    Number movLineId        = (Number)params.get("orderLineId");      // ����ID
    String documentTypeCode = (String)params.get("documentTypeCode"); // �����^�C�v
    String recordTypeCode   = (String)params.get("recordTypeCode");   // ���R�[�h�^�C�v
    Number lotId            = (Number)params.get("lotId");            // ���b�gID
    String actualQuantity   = (String)params.get("actualQuantity");        // ���ѐ���

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                 );
    sb.append("  UPDATE xxinv_mov_lot_details xmld "                   ); // �ړ����b�g���׃A�h�I��
    sb.append("  SET    xmld.actual_quantity   = TO_NUMBER(:1) "       ); // 1.���ѐ���
    sb.append("        ,xmld.last_updated_by   = FND_GLOBAL.USER_ID "  ); // �ŏI�X�V��
    sb.append("        ,xmld.last_update_date  = SYSDATE "             ); // �ŏI�X�V��
    sb.append("        ,xmld.last_update_login = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C��
    sb.append("  WHERE  xmld.mov_line_id        = :2 "                 ); // 2.�󒍖��׃A�h�I��ID
    sb.append("  AND    xmld.document_type_code = :3 "                 ); // 3.�����^�C�v
    sb.append("  AND    xmld.record_type_code   = :4 "                 ); // 4.���R�[�h�^�C�v
    sb.append("  AND    xmld.lot_id             = :5; "                ); // 5.���b�gID
    sb.append("END; "                                                  );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, actualQuantity);                   // ���ѐ���
      cstmt.setInt(2,    XxcmnUtility.intValue(movLineId)); // �󒍖��׃A�h�I��ID
      cstmt.setString(3, documentTypeCode);                 // �����^�C�v
      cstmt.setString(4, recordTypeCode);                   // ���R�[�h�^�C�v
      cstmt.setInt(5,    XxcmnUtility.intValue(lotId));     // ���b�gID

      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updateActualQuantity

  /*****************************************************************************
   * �󒍃w�b�_�A�h�I���̃X�e�[�^�X���X�V���郁�\�b�h�ł��B
   * @param trans          - �g�����U�N�V����
   * @param orderHeaderId  - �󒍃w�b�_�A�h�I��ID
   * @param reqStatus      - �X�e�[�^�X
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void updateReqStatus(
    OADBTransaction trans,
     Number orderHeaderId,
     String reqStatus
  ) throws OAException
  {
    String apiName   = "updateReqStatus";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                 );
    sb.append("  UPDATE xxwsh_order_headers_all xoha "                 ); // �󒍃w�b�_�A�h�I��
    sb.append("  SET    xoha.req_status        = :1 "                  ); // 1.�X�e�[�^�X
    sb.append("        ,xoha.last_updated_by   = FND_GLOBAL.USER_ID "  ); // �ŏI�X�V��
    sb.append("        ,xoha.last_update_date  = SYSDATE "             ); // �ŏI�X�V��
    sb.append("        ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C��
    sb.append("  WHERE xoha.order_header_id    = :2; "                 ); // 2.�󒍃w�b�_�A�h�I��ID
    sb.append("END; "                                                  );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, reqStatus);                            // �X�e�[�^�X
      cstmt.setInt(2,    XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID

      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updateReqStatus

  /*****************************************************************************
   * �󒍖��׃A�h�I���̏o�׎��ѐ��ʂ����ׂēo�^����Ă��邩�ǂ����𔻒肷�郁�\�b�h�ł��B
   * @param trans         - �g�����U�N�V����
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   * @return boolean      - true:���ׂēo�^��  false:���o�^����
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean checkShippedQuantityEntry(
    OADBTransaction trans,
     Number orderHeaderId
  ) throws OAException
  {
    String apiName   = "checkShippedQuantityEntry";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                      );
    sb.append("  SELECT COUNT(1) "                          ); // �󒍖��׃A�h�I��
    sb.append("  INTO   :1 "                                ); // 1.�o�׎��ѐ����o�^�J�E���g
    sb.append("  FROM   xxwsh_order_lines_all xola "        ); // �󒍖��׃A�h�I��
    sb.append("  WHERE xola.order_header_id    = :2 "       ); // 2.�󒍃w�b�_�A�h�I��ID
    sb.append("  AND   NVL(xola.delete_flag,'N') = 'N' "    ); // �폜�t���O
    sb.append("  AND   xola.shipped_quantity IS NULL "      ); // �o�׎��ѐ���
    sb.append("  AND   ROWNUM = 1; "                        );
    sb.append("END; "                                       );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.INTEGER);   // ���^�[���R�[�h

      // PL/SQL���s
      cstmt.execute();

      // 0���̏ꍇ�A���ׂēo�^��
      if (cstmt.getInt(1) == 0)
      {
        return true;

      // 0���ȊO�̏ꍇ�A���o�^����
      } else
      {
        return false;
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // checkShippedQuantityEntry

  /*****************************************************************************
   * �󒍖��׃A�h�I���̍ŏI�X�V�����擾���郁�\�b�h�ł��B
   * @param trans          - �g�����U�N�V����
   * @param orderHeaderId  - �󒍃w�b�_�A�h�I��ID
   * @return String        - �ŏI�X�V��
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String getOrderLineUpdateDate(
    OADBTransaction trans,
     Number orderHeaderId
  ) throws OAException
  {
    String apiName   = "getOrderLineUpdateDate";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                           );
    sb.append("  SELECT TO_CHAR(MAX(xola.last_update_date),'YYYY/MM/DD HH24:MI:SS')  last_update_date "); // 1.�ŏI�X�V��
    sb.append("  INTO   :1  "                                                                          );
    sb.append("  FROM   xxwsh_order_lines_all xola "                                                   ); // �󒍖��׃A�h�I��
    sb.append("  WHERE  xola.order_header_id = :2 "                                                    ); // 2.�󒍃w�b�_�A�h�I��ID
// 2008-07-02 D.Nihei UPD Start
//    sb.append("  AND   NVL(xola.delete_flag,'N') = 'N' ;"                                              ); // �폜�t���O
    sb.append("  ;");
// 2008-07-02 D.Nihei UPD Start
    sb.append("END; "                                                            );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR);   // �ŏI�X�V��

      // PL/SQL���s
      cstmt.execute();
      
      return cstmt.getString(1);

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getOrderLineUpdateDate

  /*****************************************************************************
   * �󒍃w�b�_�A�h�I���̍ŏI�X�V�����擾���郁�\�b�h�ł��B
   * @param trans            - �g�����U�N�V����
   * @param orderHeaderId    - �󒍃w�b�_�A�h�I��ID
   * @return String          - �ŏI�X�V��
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String getOrderHeaderUpdateDate(
    OADBTransaction trans,
     Number orderHeaderId
  ) throws OAException
  {
    String apiName   = "getOrderHeaderUpdateDate";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                           );
    sb.append("  SELECT TO_CHAR(xoha.last_update_date, 'YYYY/MM/DD HH24:Mi:SS') "); // 1.�ŏI�X�V��
    sb.append("  INTO   :1 "                                                     );
    sb.append("  FROM   xxwsh_order_headers_all xoha "                           ); // �󒍖��׃A�h�I��
    sb.append("  WHERE  xoha.order_header_id    = :2; "                          ); // 2.�󒍃w�b�_�A�h�I��ID
    sb.append("END; "                                                            );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR);   // �ŏI�X�V��

      // PL/SQL���s
      cstmt.execute();
      
      return cstmt.getString(1);

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getOrderHeaderUpdateDate

  /*****************************************************************************
   * �d�ʗe�Ϗ������X�V�֐������s���郁�\�b�h�ł��B
   * @param trans      - �g�����U�N�V����
   * @param bizType    - �Ɩ����
   * @param requestNo  - �˗�No
   * @return Number    -  1�F�G���[  0�F����
   * @throws OAException - OA��O
   ****************************************************************************/
  public static Number doUpdateLineItems(
    OADBTransaction trans,
     String bizType,
     String requestNo
  ) throws OAException
  {
    String apiName   = "doUpdateLineItems";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                      );
    sb.append("  :1 := xxwsh_common_pkg.update_line_items( "); // 1.�߂�l  1�F�G���[  0�F����
    sb.append("         iv_biz_type   => :2, "              ); // 2.�Ɩ����
    sb.append("         iv_request_no => :3 ); "            ); // 3.�˗�No
    sb.append("END; "                                       );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(2, bizType);   // �Ɩ����
      cstmt.setString(3, requestNo); // �˗�Np

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.INTEGER);   // �߂�l

      // PL/SQL���s
      cstmt.execute();
      
      return new Number(cstmt.getInt(1));

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // doUpdateLineItems

  /*****************************************************************************
   * �R���J�����g�F�o�׈˗�/�o�׎��э쐬�����𔭍s���܂��B
   * @param  trans       - �g�����U�N�V����
   * @param  requestNo   - �˗�No
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void doShipRequestAndResultEntry(
    OADBTransaction trans,
    String requestNo
  ) throws OAException
  {
    String apiName      = "doShipRequestAndResultEntry";

// 2008-12-15 D.Nihei Del Start �{�ԏ�Q#648�Ή� �R�����g��
//    //PL/SQL�̍쐬���s���܂�
//    StringBuffer sb = new StringBuffer(1000);
//    sb.append("DECLARE "   );
//    sb.append("  ln_request_id NUMBER; "                                             );
//    sb.append("BEGIN "                                                               );
//                 // �o�׈˗�/�o�׎��э쐬����(�R���J�����g)�Ăяo��
//    sb.append("  ln_request_id := fnd_request.submit_request( "                      );
//    sb.append("     application  => 'XXWSH' "                                        ); // �A�v���P�[�V������
//    sb.append("    ,program      => 'XXWSH420001C' "                                 ); // �v���O�����Z�k��
//    sb.append("    ,argument1    => NULL "                                           ); // �u���b�N
//    sb.append("    ,argument2    => NULL "                                           ); // �o�׌�
//    sb.append("    ,argument3    => :1 );"                                           ); // �˗�No
//                 // �v��ID������ꍇ�A����
//    sb.append("  IF ln_request_id > 0 THEN "                                         );
//    sb.append("    :2 := '1'; "                                                      ); // 1:����I��
//    sb.append("    :3 := ln_request_id; "                                            ); // �v��ID
//// 2008-08-01 H.Itou Del Start
////    sb.append("    COMMIT; "                                                         );
//// 2008-08-01 H.Itou Del End
//                 // �v��ID���Ȃ��ꍇ�A�ُ�
//    sb.append("  ELSE "                                                              );
//    sb.append("    :2 := '0'; "                                                      ); // 0:�ُ�I��
//    sb.append("    :3 := ln_request_id; "                                            ); // �v��ID
//    sb.append("    ROLLBACK; "                                                       );
//    sb.append("  END IF; "                                                           );
//    sb.append("END; "                                                                );
//    
//    //PL/SQL�̐ݒ�
//    CallableStatement cstmt = trans.createCallableStatement(
//                                sb.toString(),
//                                OADBTransaction.DEFAULT);
//    try
//    {
//      // �p�����[�^�ݒ�(IN�p�����[�^)
//      cstmt.setString(1, requestNo);                  // �˗�No
//      
//      // �p�����[�^�ݒ�(OUT�p�����[�^)
//      cstmt.registerOutParameter(2, Types.VARCHAR);   // ���^�[���R�[�h
//      cstmt.registerOutParameter(3, Types.INTEGER);   // �v��ID
//      
//      //PL/SQL���s
//      cstmt.execute();
//
//      // �߂�l�擾
//      String retFlag  = cstmt.getString(2); // ���^�[���R�[�h
//      int requestId  = cstmt.getInt(3); // �v��ID
//
//      // �R���J�����g�o�^���s�̏ꍇ
//      if (XxcmnConstants.RETURN_NOT_EXE.equals(retFlag)) 
//      {
//        //�g�[�N������
//        MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PRG_NAME,
//                                                   XxwshConstants.TOKEN_NAME_PGM_NAME_420001C) };
//        // �R���J�����g�o�^�G���[���b�Z�[�W�o��
//        throw new OAException(
//          XxcmnConstants.APPL_XXWSH, 
//          XxwshConstants.XXWSH13314, 
//          tokens);
//      }
//
//    // PL/SQL���s����O�̏ꍇ
//    } catch(SQLException s)
//    {
//      // ���[���o�b�N
//      rollBack(trans);
//      // ���O�o��
//      XxcmnUtility.writeLog(
//        trans,
//        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
//        s.toString(),
//        6);
//      // �G���[���b�Z�[�W�o��
//      throw new OAException(
//        XxcmnConstants.APPL_XXCMN, 
//        XxcmnConstants.XXCMN10123);
//
//    } finally
//    {
//      try
//      {
//        //�������ɃG���[�����������ꍇ��z�肷��
//        cstmt.close();
//      } catch(SQLException s)
//      {
//        // ���[���o�b�N
//        rollBack(trans);
//        // ���O�o��
//        XxcmnUtility.writeLog(
//          trans,
//          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
//          s.toString(),
//          6);
//        // �G���[���b�Z�[�W�o��
//        throw new OAException(
//          XxcmnConstants.APPL_XXCMN, 
//          XxcmnConstants.XXCMN10123);
//      }
//    }
// 2008-12-15 D.Nihei Del End
  } // doShipRequestAndResultEntry 

  /*****************************************************************************
   * �󒍏����R�s�[���郁�\�b�h�ł��B
   * @param trans          - �g�����U�N�V����
   * @param orderHeaderId  - �󒍃w�b�_�A�h�I��ID
   * @throws OAException - OA��O
   ****************************************************************************/
  public static Number copyOrderData(
    OADBTransaction trans,
     Number orderHeaderId
  ) throws OAException
  {
    String apiName   = "copyOrderData";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                           );
    sb.append("  :1 := xxwsh_common2_pkg.copy_order_data(it_header_id => :2); "    ); // 1.�V�K�󒍖��׃A�h�I��ID
    sb.append("END; "                                                            );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.INTEGER);        // �V�K�󒍃w�b�_�A�h�I��ID

      // PL/SQL���s
      cstmt.execute();
      
      return new Number(cstmt.getInt(1));

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // copyOrderData

 /*****************************************************************************
   * �ړ����b�g�ڍ׃A�h�I��������ѐ��ʂ̍��v�l���擾���郁�\�b�h�ł��B
   * @param trans            - �g�����U�N�V����
   * @param movLineId        - �󒍖��׃A�h�I��ID
   * @param documentTypeCode - �����^�C�v(10:�o�׈˗��A30:�x���w��)
   * @param recordTypeCode   - ���R�[�h�^�C�v(10�F�w���A20�F�o�Ɏ���  30�F���Ɏ���)
   * @return String          - ���ѐ��ʍ��v
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String getActualQuantitySum(
    OADBTransaction trans,
    Number movLineId,
    String documentTypeCode,
    String recordTypeCode
  ) throws OAException
  {
    String apiName     = "getActualQuantitySum";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                        );
    sb.append("  lv_temp VARCHAR2(1); "                         );
    sb.append("BEGIN "                                          );
    sb.append("  SELECT TO_CHAR(SUM(xmld.actual_quantity))  "   ); // 1.���ѐ��ʍ��v
    sb.append("  INTO   :1 "                                    );
    sb.append("  FROM   xxinv_mov_lot_details xmld "            ); //   �ړ����b�g�ڍ׃A�h�I��
    sb.append("  WHERE  xmld.mov_line_id        = :2 "          ); // 2.�󒍖��׃A�h�I��ID
    sb.append("  AND    xmld.document_type_code = :3 "          ); // 3.�����^�C�v
    sb.append("  AND    xmld.record_type_code   = :4; "         ); // 4.���R�[�h�^�C�v
    sb.append("END; "                                           );

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    { 
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(movLineId)); // �󒍖��׃A�h�I��ID
      cstmt.setString(3, documentTypeCode);              // �����^�C�v
      cstmt.setString(4, recordTypeCode);                // ���R�[�h�^�C�v
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR);      // ���ѐ��ʍ��v
      
      // PL/SQL���s
      cstmt.execute();

      // OUT�p�����[�^�擾
      return cstmt.getString(1);  // ���ѐ��ʍ��v

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
        // ���[���o�b�N
        XxwshUtility.rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        //�������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        XxwshUtility.rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getActualQuantitySum

  /*****************************************************************************
   * �󒍃w�b�_�A�h�I��ID�Ɩ��הԍ�����󒍖��׃A�h�I��ID���擾���郁�\�b�h�ł��B
   * @param trans            - �g�����U�N�V����
   * @param orderHeaderId    - �󒍃w�b�_�A�h�I��ID
   * @param orderLineNumber  - ���הԍ�
   * @return Number          - �󒍖��׃A�h�I��ID
   * @throws OAException - OA��O
   ****************************************************************************/
  public static Number getOrderLineId(
    OADBTransaction trans,
     Number orderHeaderId,
     Number orderLineNumber
  ) throws OAException
  {
    String apiName   = "getOrderLineId";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                 );
    sb.append("  SELECT xola.order_line_id  order_line_id "            ); // 1.�󒍖��׃A�h�I��ID
    sb.append("  INTO   :1 "                                           );
    sb.append("  FROM   xxwsh_order_lines_all xola "                   ); // �󒍖��׃A�h�I��
    sb.append("  WHERE  xola.order_header_id   = :2 "                  ); // 2.�󒍃w�b�_�A�h�I��ID
    sb.append("  AND    xola.order_line_number = :3  "                 ); // 3.���הԍ�
    sb.append("  AND    xola.delete_flag       = 'N'; "                );
    sb.append("END; "                                                  );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(orderHeaderId));   // �󒍃w�b�_�A�h�I��ID
      cstmt.setInt(3, XxcmnUtility.intValue(orderLineNumber)); // ���הԍ�

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.INTEGER);            // �󒍖��׃A�h�I��ID

      // PL/SQL���s
      cstmt.execute();
      
      return new Number(cstmt.getObject(1));

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getOrderLineId

  /*****************************************************************************
   * �󒍖��׃A�h�I���̓��Ɏ��ѐ��ʂ��X�V���郁�\�b�h�ł��B
   * @param trans        - �g�����U�N�V����
   * @param orderLineId  - �󒍖��׃A�h�I��ID
   * @param shipToQty    - ���Ɏ��ѐ���
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void updateShipToQuantity(
    OADBTransaction trans,
     Number orderLineId,
     String shipToQty
  ) throws OAException
  {
    String apiName   = "updateShipToQuantity";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                 );
    sb.append("  UPDATE xxwsh_order_lines_all xola "                   ); // �󒍖��׃A�h�I��
    sb.append("  SET    xola.ship_to_quantity  = TO_NUMBER(:1) "       ); // 1.���Ɏ��ѐ���
    sb.append("        ,xola.last_updated_by   = FND_GLOBAL.USER_ID "  ); // �ŏI�X�V��
    sb.append("        ,xola.last_update_date  = SYSDATE "             ); // �ŏI�X�V��
    sb.append("        ,xola.last_update_login = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C��
    sb.append("  WHERE xola.order_line_id = :2; "                      ); // 2.�󒍖��׃A�h�I��ID
    sb.append("END; "                                       );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, shipToQty);                          // ���Ɏ��ѐ���
      cstmt.setInt(2,    XxcmnUtility.intValue(orderLineId)); // ����ID

      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updateShipToQuantity
 
  /*****************************************************************************
   * �󒍖��׃A�h�I��ID����˗�No���擾���郁�\�b�h�ł��B
   * @param trans        - �g�����U�N�V����
   * @param orderLineId  - �󒍖��׃A�h�I��ID
   * @return String      - �˗�No
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String getRequestNo(
    OADBTransaction trans,
    String orderLineId
  ) throws OAException
  {
    String apiName   = "getRequestNo";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                           );
    sb.append("  SELECT xola.request_no  request_no "                            ); // 1.�˗�No
    sb.append("  INTO   :1 "                                                     );
    sb.append("  FROM   xxwsh_order_lines_all xola "                             ); // �󒍖��׃A�h�I��
    sb.append("  WHERE  xola.order_line_id     = TO_NUMBER(:2); "                ); // 2.�󒍖��׃A�h�I��ID
    sb.append("END; "                                                            );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(2, orderLineId);   // �󒍖��׃A�h�I��ID

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR); // �˗�No

      // PL/SQL���s
      cstmt.execute();
      
      return cstmt.getString(1);

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getRequestNo
  /*****************************************************************************
   * �ړ��˗�/�w�����׃A�h�I�����b�N���擾���܂��B
   * @param trans          - �g�����U�N�V����
   * @param movHeaderId    - �ړ��w�b�_ID
   * @return HashMap
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap getXxinvMovLinesLock(
    OADBTransaction trans,
    Number movHeaderId
  ) throws OAException
  {
    String apiName = "getXxinvMovLinesLock";
    HashMap ret = new HashMap();
    
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                                                                 );
                 // ���[�U�[��`�G���[
    sb.append("  lock_expt             EXCEPTION; "                                                      );
    sb.append("  PRAGMA EXCEPTION_INIT(lock_expt, -54); "                                                );
    sb.append("  CURSOR lock_cur IS "                                                                    );
    sb.append("    SELECT xmril.mov_hdr_id    mov_header_id "                                            );
    sb.append("    FROM   xxinv_mov_req_instr_lines xmril "                                              );
    sb.append("    WHERE  xmril.mov_hdr_id = :1 "                                                        );
    sb.append("    FOR UPDATE NOWAIT; "                                                                  );
    sb.append("  lock_rec lock_cur%ROWTYPE; "                                                            );
    sb.append("BEGIN "                                                                                   );
                 // ���b�N�擾
    sb.append("  OPEN lock_cur; "                                                                        );
    sb.append("  FETCH lock_cur INTO lock_rec; "                                                         );
    sb.append("  CLOSE lock_cur; "                                                                       );
                 // �ŏI�X�V���ő�l���擾
    sb.append("  SELECT TO_CHAR(MAX( xmril.last_update_date),'YYYY/MM/DD HH24:MI:SS')  last_update_date ");
    sb.append("  INTO   :2  "                                                                            );
    sb.append("  FROM   xxinv_mov_req_instr_lines xmril "                                                );
    sb.append("  WHERE  xmril.mov_hdr_id = :1 "                                                          );
    sb.append("  AND    NVL(xmril.delete_flg,'N') = 'N' ; "                                             );
    sb.append("EXCEPTION "                                                                               );
    sb.append("  WHEN lock_expt THEN "                                                                   );
    sb.append("    :3 := '1'; "                                                                          );
    sb.append("    :4 := SQLERRM; "                                                                      );
    sb.append("END; "                                                                                    );

    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1, XxcmnUtility.intValue(movHeaderId)); // �ړ��w�b�_ID
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(2, Types.VARCHAR);   // �ŏI�X�V��
      cstmt.registerOutParameter(3, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(4, Types.VARCHAR);   // �G���[���b�Z�[�W
      
      //PL/SQL���s
      cstmt.execute();

      // ���b�N�G���[�I���̏ꍇ  
      if ("1".equals(cstmt.getString(3)))
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          cstmt.getString(4),
          6);

        ret.put("retCode", XxcmnConstants.RETURN_ERR1); // �߂�l E1:���b�N�G���[

      // ����I���̏ꍇ
      } else
      {
        ret.put("retCode",        XxcmnConstants.RETURN_SUCCESS); // �߂�l 1:����
        ret.put("lastUpdateDate", cstmt.getString(2));            // �ŏI�X�V��
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);
                            
    } finally
    {
      try
      {
        // PL/SQL�N���[�Y
        cstmt.close();
        
      // close���ɗ�O�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    // �߂�l
    return ret;
  } // getXxwshMovLinesLock
  /*****************************************************************************
   * �ړ��˗�/�w���w�b�_(�A�h�I��)���b�N���擾���܂��B
   * @param OADBTransaction trans �g�����U�N�V����
   * @param Number  movHeaderId  - �ړ��w�b�_ID
   * @return HashMap
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap getXxinvMovHeadersLock(
    OADBTransaction trans,
    Number movHeaderId
  ) throws OAException
  {
    String apiName = "getXxinvMovHeadersLock";
    HashMap ret = new HashMap();
    
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                                                           );
                 // ���[�U�[��`�G���[
    sb.append("  lock_expt             EXCEPTION; "                                                );
    sb.append("  PRAGMA EXCEPTION_INIT(lock_expt, -54); "                                          );
    sb.append("BEGIN "                                                                             );
                 // ���b�N�擾
    sb.append("  SELECT TO_CHAR(xmrih.last_update_date,'YYYY/MM/DD HH24:MI:SS')  last_update_date ");
    sb.append("  INTO   :1 "                                                                       );
    sb.append("  FROM   xxinv_mov_req_instr_headers xmrih "                                        );
    sb.append("  WHERE  xmrih.mov_hdr_id = :2 "                                                    );
    sb.append("  FOR UPDATE NOWAIT; "                                                              );
    sb.append("EXCEPTION "                                                                         );
    sb.append("  WHEN lock_expt THEN "                                                             );
    sb.append("    :3 := '1'; "                                                                    );
    sb.append("    :4 := SQLERRM; "                                                                );
    sb.append("END; "                                                                              );

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(movHeaderId)); // �ړ��w�b�_ID
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR);   // �ŏI�X�V��
      cstmt.registerOutParameter(3, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(4, Types.VARCHAR);   // �G���[���b�Z�[�W
      
      //PL/SQL���s
      cstmt.execute();

      // ���b�N�G���[�I���̏ꍇ  
      if ("1".equals(cstmt.getString(3)))
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          cstmt.getString(4),
          6);

        ret.put("retCode", XxcmnConstants.RETURN_ERR1); // �߂�l E1:���b�N�G���[

      // ����I���̏ꍇ
      } else
      {
        ret.put("retCode",        XxcmnConstants.RETURN_SUCCESS); // �߂�l 1:����
        ret.put("lastUpdateDate", cstmt.getString(1));            // �ŏI�X�V��
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);
                            
    } finally
    {
      try
      {
        // PL/SQL�N���[�Y
        cstmt.close();
        
      // close���ɗ�O�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    // �߂�l
    return ret;
  } // getXxinvMovHeadersLock
  /*****************************************************************************
   * �ړ��˗�/�w������(�A�h�I��)�̍ŏI�X�V�����擾���郁�\�b�h�ł��B
   * @param OADBTransaction trans   - �g�����U�N�V����
   * @param Number movHeaderId      - �ړ��w�b�_ID
   * @return String                 - �ŏI�X�V��
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String getMovLineLastUpdateDate(
    OADBTransaction trans,
    Number movHeaderId
  ) throws OAException
  {
    String apiName   = "getMovLineLastUpdateDate";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                                 );
    sb.append("  SELECT TO_CHAR(MAX(xmril.last_update_date), 'YYYY/MM/DD HH24:MI:SS') "); // 1.�ŏI�X�V��
    sb.append("  INTO   :1 "                                                           );
    sb.append("  FROM   xxinv_mov_req_instr_lines xmril "                              ); // �ړ��˗�/�w������(�A�h�I��)
    sb.append("  WHERE  xmril.mov_hdr_id    = :2 "                                     ); // 2.�ړ��w�b�_ID
    sb.append("  WHERE  NVL(xmril.delete_flg,'N') = 'N'; "                            );
    sb.append("END; "                                                                  );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(movHeaderId)); // �ړ��w�b�_ID

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR);   // �ŏI�X�V��

      // PL/SQL���s
      cstmt.execute();
      
      return cstmt.getString(1);

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getMovLineLastUpdateDate
  /*****************************************************************************
   * ���v���ʁE���v�e�ς��Z�o���܂��B
   * @param itemNo   - �i�ڃR�[�h
   * @param quantity - ����
   * @param standardDate - ���
   * @return HashMap  - �߂�l�Q
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap calcTotalValue(
    OADBTransaction trans,
    String itemNo,
    String quantity,
// 2008-10-07 H.Itou Add Start �����e�X�g�w�E240
    Date standardDate
// 2008-10-07 H.Itou Add End
  ) throws  OAException
  {
    String apiName = "calcTotalValue";

    HashMap retHashMap = new HashMap();  // �߂�l�p

    // PL/SQL�̍쐬���s���܂��B
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  ln_sum_weight         NUMBER; ");
    sb.append("  ln_sum_capacity       NUMBER; ");
    sb.append("  ln_sum_pallet_weight  NUMBER; ");
    sb.append("BEGIN ");
    sb.append("  xxwsh_common910_pkg.calc_total_value( ");
    sb.append("    iv_item_no           => :1 ");
    sb.append("   ,in_quantity          => TO_NUMBER(:2) ");
    sb.append("   ,ov_retcode           => :3 ");
    sb.append("   ,ov_errmsg_code       => :4 ");
    sb.append("   ,ov_errmsg            => :5 ");
    sb.append("   ,on_sum_weight        => ln_sum_weight ");
    sb.append("   ,on_sum_capacity      => ln_sum_capacity ");
    sb.append("   ,on_sum_pallet_weight => ln_sum_pallet_weight ");
// 2008-10-07 H.Itou Add Start �����e�X�g�w�E240
    sb.append("   ,id_standard_date     => :6 ");
// 2008-10-07 H.Itou Add End
    sb.append("  ); ");
// 2008-10-07 H.Itou Mod Start �����e�X�g�w�E240
//    sb.append("  :6 := TO_CHAR(ln_sum_weight);        ");
//    sb.append("  :7 := TO_CHAR(ln_sum_capacity);      ");
//    sb.append("  :8 := TO_CHAR(ln_sum_pallet_weight); ");
    sb.append("  :7 := TO_CHAR(ln_sum_weight);        ");
    sb.append("  :8 := TO_CHAR(ln_sum_capacity);      ");
    sb.append("  :9 := TO_CHAR(ln_sum_pallet_weight); ");
// 2008-10-07 H.Itou Mod End
    sb.append("END; ");

    // PL/SQL�̐ݒ���s���܂��B
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      int i = 1;
      cstmt.setString(i++, itemNo);   // �i�ڃR�[�h
      cstmt.setString(i++, quantity); // ����

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1);         // �X�e�[�^�X�R�[�h
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);      // �G���[���b�Z�[�W
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);      // �V�X�e�����b�Z�[�W
// 2008-10-07 H.Itou Add Start �����e�X�g�w�E240
      cstmt.setDate(i++, XxcmnUtility.dateValue(standardDate)); // ���
// 2008-10-07 H.Itou Add End
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);

      // PL/SQL���s
      cstmt.execute();

      // ���s���ʊi�[
      String retCode         = cstmt.getString(3);  // ���^�[���R�[�h
      String errMsg          = cstmt.getString(4);  // �G���[���b�Z�[�W
      String systemMsg       = cstmt.getString(5);  // �V�X�e�����b�Z�[�W
// 2008-10-07 H.Itou Mod Start �����e�X�g�w�E240
//      String sumWeight       = cstmt.getString(6);  // �d��
//      String sumCapacity     = cstmt.getString(7);  // �e��
//      String sumPalletWeight = cstmt.getString(8);  // �p���b�g�d��
      String sumWeight       = cstmt.getString(7);  // �d��
      String sumCapacity     = cstmt.getString(8);  // �e��
      String sumPalletWeight = cstmt.getString(9);  // �p���b�g�d��
// 2008-10-07 H.Itou Mod End

      // �߂�l�擾
      retHashMap.put("retCode",         retCode);
      retHashMap.put("errMsg",          errMsg);
      retHashMap.put("sumWeight",       sumWeight);
      retHashMap.put("sumCapacity",     sumCapacity);
      retHashMap.put("sumPalletWeight", sumPalletWeight);

      // �G���[�̏ꍇ
      if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {
        // ���O�o��
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              errMsg + systemMsg,
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                               XxcmnConstants.XXCMN10123);
      }
      return retHashMap; 
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                             XxcmnConstants.XXCMN10123);

    } finally 
    {
      try 
      {
        // �������ɃG���[�����������ꍇ��z�肷��B
        cstmt.close();
      } catch(SQLException s) 
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);

      }
    }
  } // calcTotalValue
  /*****************************************************************************
   * �w�肵�����׈ȊO�̎󒍖��׃A�h�I���̊e�퐔�ʁA�d�ʁA�e�ς��T�}���[���ĕԂ��܂��B
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   * @param orderLineId   - �󒍖��׃A�h�I��ID
   * @param activeDate    - �K�p��
   * @return HashMap  - �߂�l�Q
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap getDeliverSummaryOrderLine(
    OADBTransaction trans,
    Number orderHeaderId,
    Number orderLineId,
    Date   activeDate
  ) throws  OAException
  {
    String apiName = "getDeliverSummaryOrderLine";

    HashMap retHashMap = new HashMap(); // �߂�l

    // PL/SQL�̍쐬���s���܂��B
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  SELECT TO_CHAR(SUM(NVL(xola.quantity,0))) quantity,"               ); // ����
    sb.append("         TO_CHAR(SUM(NVL(xola.weight,0))) weight,"                   ); // �d��
    sb.append("         TO_CHAR(SUM(NVL(xola.capacity,0))) capacity,"               ); // �e��
    sb.append("         TO_CHAR(SUM(NVL(xola.pallet_weight,0))) pallet_weight,"     ); // �p���b�g�d��
    sb.append("         TO_CHAR(SUM("                                               );
    sb.append("           CASE"                                                     );
    sb.append("             WHEN (NVL(xola.quantity,0) = 0)"                        );
    sb.append("             THEN 0"                                                 );
    sb.append("             WHEN (ximv.num_of_deliver IS NOT NULL)"                 );
// 2008/08/07 D.Nihei Mod Start
//    sb.append("             THEN xola.quantity / ximv.num_of_deliver"               );
    sb.append("             THEN CEIL(xola.quantity / ximv.num_of_deliver)"         );
// 2008/08/07 D.Nihei Mod End
    sb.append("             WHEN (ximv.num_of_cases IS NOT NULL)"                   );
// 2008/08/07 D.Nihei Mod Start
//    sb.append("             THEN xola.quantity / ximv.num_of_cases"                 );
//    sb.append("             ELSE xola.quantity"                                     );
    sb.append("             THEN CEIL(xola.quantity / ximv.num_of_cases)"           );
    sb.append("             ELSE CEIL(xola.quantity)"                               );
// 2008/08/07 D.Nihei Mod End
    sb.append("           END"                                                      );
    sb.append("        )) small_quantity,"                                          ); // ������
    sb.append("         TO_CHAR(SUM("                                               );
    sb.append("           CASE"                                                     );
    sb.append("             WHEN (NVL(xola.quantity,0) = 0)"                        );
    sb.append("             THEN 0"                                                 );
    sb.append("             WHEN (ximv.num_of_deliver IS NOT NULL)"                 );
// 2008/08/07 D.Nihei Mod Start
//    sb.append("             THEN xola.quantity / ximv.num_of_deliver"               );
    sb.append("             THEN CEIL(xola.quantity / ximv.num_of_deliver)"         );
// 2008/08/07 D.Nihei Mod End
    sb.append("             WHEN (ximv.num_of_cases IS NOT NULL)"                   );
// 2008/08/07 D.Nihei Mod Start
//    sb.append("             THEN xola.quantity / ximv.num_of_cases"                 );
//    sb.append("             ELSE xola.quantity"                                     );
    sb.append("             THEN CEIL(xola.quantity / ximv.num_of_cases)"           );
    sb.append("             ELSE CEIL(xola.quantity)"                               );
// 2008/08/07 D.Nihei Mod End
    sb.append("           END"                                                      );
    sb.append("        )) label_quantity"                                           ); // ���x������
    sb.append("  INTO   :1 "                                                        );
    sb.append("        ,:2 "                                                        );
    sb.append("        ,:3 "                                                        );
    sb.append("        ,:4 "                                                        );
    sb.append("        ,:5 "                                                        );
    sb.append("        ,:6 "                                                        );
    sb.append("    FROM xxwsh_order_lines_all xola,"                                );
    sb.append("         xxcmn_item_mst2_v ximv"                                     );
    sb.append("   WHERE xola.order_header_id = :7"                                  );
    sb.append("     AND xola.order_line_id <> :8"                                   );
    sb.append("     AND NVL(xola.delete_flag,'N') <> 'Y'"                           );
    sb.append("     AND ximv.item_no = xola.shipping_item_code"                     );
    sb.append("     AND :9"                                                         );
    sb.append("       BETWEEN ximv.start_date_active"                               );
    sb.append("           AND ximv.end_date_active;"                                );
    sb.append("END; "                                                               );

    // PL/SQL�̐ݒ���s���܂��B
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try 
    {
      int i = 1;

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // ����
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // �d��
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // �e��
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // �p���b�g�d��
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // ������
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // ���x������
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));
      cstmt.setInt(i++, XxcmnUtility.intValue(orderLineId));
      cstmt.setDate(i++, XxcmnUtility.dateValue(activeDate));

      // PL/SQL���s
      cstmt.execute();
      // ���s���ʊi�[
      i = 1;
      String sumQuantity      = cstmt.getString(i++);     // ����
      String sumWeight        = cstmt.getString(i++);     // �d��
      String sumCapacity      = cstmt.getString(i++);     // �e��
      String sumPalletWeight  = cstmt.getString(i++);     // �p���b�g�d��
      String sumSmallQuantity = cstmt.getString(i++);     // ������
      String sumLabelQuantity = cstmt.getString(i++);     // ���x������
      // �߂�l�ݒ�
      retHashMap.put("sumQuantity",sumQuantity);
      retHashMap.put("sumWeight",sumWeight);
      retHashMap.put("sumCapacity",sumCapacity);
      retHashMap.put("sumPalletWeight",sumPalletWeight);
      retHashMap.put("sumSmallQuantity",sumSmallQuantity);
      retHashMap.put("sumLabelQuantity",sumLabelQuantity);

      return retHashMap;
      
    } catch (SQLException s) 
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                             XxcmnConstants.XXCMN10123);

      
    } finally 
    {
      try 
      {
        // �������ɃG���[�����������ꍇ��z�肷��B
        cstmt.close();
      } catch(SQLException s) 
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
        
      }
    }
  } // getDeliverSummaryOrderLine
  /*****************************************************************************
   * �w�肵�����׈ȊO�̈ړ��˗�/�w������(�A�h�I��)��
   * �e�퐔�ʁA�d�ʁA�e�ς��T�}���[���ĕԂ��܂��B
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   * @param orderLineId   - �󒍖��׃A�h�I��ID
   * @param activeDate    - �K�p��
   * @return HashMap  - �߂�l�Q
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap getDeliverSummaryMoveLine(
    OADBTransaction trans,
    Number movHdrId,
    Number movLineId,
    Date   activeDate
  ) throws  OAException
  {
    String apiName = "getDeliverSummaryMoveLine";

    HashMap retHashMap = new HashMap(); // �߂�l

    // PL/SQL�̍쐬���s���܂��B
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  SELECT TO_CHAR(SUM(NVL(xmril.instruct_qty,0))) quantity,"          ); // ����
    sb.append("         TO_CHAR(SUM(NVL(xmril.weight,0))) weight,"                  ); // �d��
    sb.append("         TO_CHAR(SUM(NVL(xmril.capacity,0))) capacity,"              ); // �e��
    sb.append("         TO_CHAR(SUM(NVL(xmril.pallet_weight,0))) pallet_weight,"    ); // �p���b�g�d��
    sb.append("         TO_CHAR(SUM("                                               );
    sb.append("           CASE"                                                     );
    sb.append("             WHEN (NVL(xmril.instruct_qty,0) = 0)"                   );
    sb.append("             THEN 0"                                                 );
    sb.append("             WHEN (ximv.num_of_deliver IS NOT NULL)"                 );
    sb.append("             THEN xmril.instruct_qty / ximv.num_of_deliver"          );
    sb.append("             WHEN (ximv.num_of_cases IS NOT NULL)"                   );
    sb.append("             THEN xmril.instruct_qty / ximv.num_of_cases"            );
    sb.append("             ELSE xmril.instruct_qty"                                );
    sb.append("           END"                                                      );
    sb.append("        )) small_quantity,"                                          ); // ������
    sb.append("         TO_CHAR(SUM("                                               );
    sb.append("           CASE"                                                     );
    sb.append("             WHEN (NVL(xmril.instruct_qty,0) = 0)"                   );
    sb.append("             THEN 0"                                                 );
    sb.append("             WHEN (ximv.num_of_deliver IS NOT NULL)"                 );
    sb.append("             THEN xmril.instruct_qty / ximv.num_of_deliver"           );
    sb.append("             WHEN (ximv.num_of_cases IS NOT NULL)"                   );
    sb.append("             THEN xmril.instruct_qty / ximv.num_of_cases"            );
    sb.append("             ELSE xmril.instruct_qty"                                );
    sb.append("           END"                                                      );
    sb.append("        )) label_quantity"                                           ); // ���x������
    sb.append("  INTO   :1 "                                                        );
    sb.append("        ,:2 "                                                        );
    sb.append("        ,:3 "                                                        );
    sb.append("        ,:4 "                                                        );
    sb.append("        ,:5 "                                                        );
    sb.append("        ,:6 "                                                        );
    sb.append("    FROM xxinv_mov_req_instr_lines xmril,"                           );
    sb.append("         xxcmn_item_mst2_v ximv"                                     );
    sb.append("   WHERE xmril.mov_hdr_id = :7"                                      );
    sb.append("     AND xmril.mov_line_id <> :8"                                    );
    sb.append("     AND NVL(xmril.delete_flg,'N') <> 'Y'"                           );
    sb.append("     AND ximv.item_no = xmril.item_code"                             );
    sb.append("     AND :9"                                                         );
    sb.append("       BETWEEN ximv.start_date_active"                               );
    sb.append("           AND ximv.end_date_active;"                                );
    sb.append("END; "                                                               );

    // PL/SQL�̐ݒ���s���܂��B
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try 
    {
      int i = 1;

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // ����
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // �d��
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // �e��
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // �p���b�g�d��
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // ������
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // ���x������
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(i++, XxcmnUtility.intValue(movHdrId));
      cstmt.setInt(i++, XxcmnUtility.intValue(movLineId));
      cstmt.setDate(i++, XxcmnUtility.dateValue(activeDate));

      // PL/SQL���s
      cstmt.execute();
      // ���s���ʊi�[
      i = 1;
      String sumQuantity      = cstmt.getString(i++);     // ����
      String sumWeight        = cstmt.getString(i++);     // �d��
      String sumCapacity      = cstmt.getString(i++);     // �e��
      String sumPalletWeight  = cstmt.getString(i++);     // �p���b�g�d��
      String sumSmallQuantity = cstmt.getString(i++);     // ������
      String sumLabelQuantity = cstmt.getString(i++);     // ���x������
      // �߂�l�ݒ�
      retHashMap.put("sumQuantity",sumQuantity);
      retHashMap.put("sumWeight",sumWeight);
      retHashMap.put("sumCapacity",sumCapacity);
      retHashMap.put("sumPalletWeight",sumPalletWeight);
      retHashMap.put("sumSmallQuantity",sumSmallQuantity);
      retHashMap.put("sumLabelQuantity",sumLabelQuantity);

      return retHashMap;
      
    } catch (SQLException s) 
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                             XxcmnConstants.XXCMN10123);

      
    } finally 
    {
      try 
      {
        // �������ɃG���[�����������ꍇ��z�肷��B
        cstmt.close();
      } catch(SQLException s) 
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
        
      }
    }
  } // getDeliverSummaryMoveLine
  /*****************************************************************************
   * �ő�z���敪�̎Z�o���s���܂��B
   * @param trans - �g�����U�N�V����
   * @param codeClass1 - �R�[�h�敪1
   * @param whseCode1  - ���o�ɏꏊ�R�[�h1
   * @param codeClass2 - �R�[�h�敪2
   * @param whseCode2  - ���o�ɏꏊ�R�[�h2
   * @param weightCapacityClass - �d�ʗe�ϋ敪
   * @param prodClass  - ���i�敪
   * @param autoProcessType - �����z�ԑΏۋ敪
   * @param originalDate    - ���(Null�̏ꍇSYSDATE)
   * @return HashMap - �߂�l�Q
   * @throws OAException OA��O
   ****************************************************************************/
  public static HashMap getMaxShipMethod(
    OADBTransaction trans,
    String codeClass1,
    String whseCode1,
    String codeClass2,
    String whseCode2,
    String weightCapacityClass,
    String prodClass,
    String autoProcessType,
    Date   originalDate
  ) throws OAException
  {
    String apiName   = "getMaxShipMethod";

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lv_prod_class             VARCHAR2(2); ");
    sb.append("  ln_drink_deadweight       xxcmn_ship_methods.drink_deadweight%TYPE; ");
    sb.append("  ln_leaf_deadweight        xxcmn_ship_methods.leaf_deadweight%TYPE; ");
    sb.append("  ln_drink_loading_capacity xxcmn_ship_methods.drink_loading_capacity%TYPE; ");
    sb.append("  ln_leaf_loading_capacity  xxcmn_ship_methods.leaf_loading_capacity%TYPE; ");
    sb.append("  ln_palette_max_qty        xxcmn_ship_methods.palette_max_qty%TYPE; ");
    sb.append("  lv_weight_capacity_class  VARCHAR2(1); ");
    sb.append("  ln_deadweight             NUMBER; ");
    sb.append("  ln_loading_capacity       NUMBER; ");
    sb.append("BEGIN ");
    sb.append("  lv_prod_class := :1; ");
    sb.append("  lv_weight_capacity_class := :2;   ");
    sb.append("  ln_deadweight            := null; ");
    sb.append("  ln_loading_capacity      := null; ");
    sb.append("  :3 := xxwsh_common_pkg.get_max_ship_method( ");
    sb.append("          :4    "); // �R�[�h�敪1
    sb.append("         ,:5    "); // ���o�ɏꏊ�R�[�h1
    sb.append("         ,:6    "); // �R�[�h�敪2
    sb.append("         ,:7    "); // ���o�ɏꏊ�R�[�h2
    sb.append("         ,lv_prod_class            "); // ���i�敪
    sb.append("         ,lv_weight_capacity_class "); // �d�ʗe�ϋ敪
    sb.append("         ,:8    "); // �����z�ԑΏۋ敪
    sb.append("         ,:9    "); // ���
    sb.append("         ,:10   "); // �ő�z���敪
    sb.append("         ,ln_drink_deadweight       "); // �h�����N�ύڏd��
    sb.append("         ,ln_leaf_deadweight        "); // ���[�t�ύڏd��
    sb.append("         ,ln_drink_loading_capacity "); // �h�����N�ύڗe��
    sb.append("         ,ln_leaf_loading_capacity  "); // ���[�t�ύڗe��
    sb.append("         ,ln_palette_max_qty); "); // �p���b�g�ő喇��
    // ���[�t�E�d�ʂ̏ꍇ
    sb.append("  IF (('1' = lv_prod_class) AND ('1' = lv_weight_capacity_class)) THEN ");
    sb.append("    ln_deadweight := ln_leaf_deadweight; ");
    // ���[�t�E�e�ς̏ꍇ
    sb.append("  ELSIF (('1' = lv_prod_class) AND ('2' = lv_weight_capacity_class)) THEN ");
    sb.append("    ln_loading_capacity := ln_leaf_loading_capacity; ");
    // �h�����N�E�d�ʂ̏ꍇ
    sb.append("  ELSIF (('2' = lv_prod_class) AND ('1' = lv_weight_capacity_class)) THEN ");
    sb.append("    ln_deadweight       := ln_drink_deadweight; ");
    // �h�����N�E�e�ς̏ꍇ
    sb.append("  ELSIF (('2' = lv_prod_class) AND ('2' = lv_weight_capacity_class)) THEN ");
    sb.append("    ln_loading_capacity := ln_leaf_loading_capacity; ");
    // ����ȊO
    sb.append("  ELSE ");
    sb.append("    ln_deadweight := null; ");
    sb.append("    ln_loading_capacity := null; ");
    sb.append("  END IF; ");
    sb.append("  :11 := TO_CHAR(ln_palette_max_qty,  'FM9,999,990'); ");
    sb.append("  :12 := TO_CHAR(ln_deadweight,       'FM9,999,990'); ");
    sb.append("  :13 := TO_CHAR(ln_loading_capacity, 'FM9,999,990'); ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      int i = 1;
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(i++, prodClass);              // ���i�敪
      cstmt.setString(i++, weightCapacityClass);    // �d�ʗe�ϋ敪

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(i++, Types.INTEGER); // �߂�l

      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(i++, codeClass1);   // �R�[�h�敪1
      cstmt.setString(i++, whseCode1);    // ���o�ɏꏊ�R�[�h1
      cstmt.setString(i++, codeClass2);   // �R�[�h�敪2
      cstmt.setString(i++, whseCode2);    // ���o�ɏꏊ�R�[�h2
      cstmt.setString(i++, autoProcessType);        // �����z�ԑΏۋ敪
      cstmt.setDate(i++, originalDate.dateValue()); // ���

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(i++, Types.VARCHAR); // �ő�z���敪
      cstmt.registerOutParameter(i++, Types.VARCHAR); // �p���b�g�ő喇��
      cstmt.registerOutParameter(i++, Types.VARCHAR); // �ύڏd��
      cstmt.registerOutParameter(i++, Types.VARCHAR); // �ύڗe��

      // PL/SQL���s
      cstmt.execute();
      if (cstmt.getInt(3) == 1) 
      {
        // ���O�ɏo��
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              "�߂�l���G���[�ŕԂ�܂����B",
                              6);
        // �G���[�ɂ����߂�l�ɃG���[�R�[�h�ȊO�͂��ׂ�null���Z�b�g���Ė߂��B
        HashMap paramsRet = new HashMap();
        paramsRet.put("maxShipMethods",  null); 
        paramsRet.put("paletteMaxQty",   null);
        paramsRet.put("deadWeight",      null);
        paramsRet.put("loadingCapacity", null);
        return paramsRet;
      }

      // �߂�l�擾
      String retMaxShipMethods  = cstmt.getString(10);
      String retPaletteMaxQty   = cstmt.getString(11);
      String retDeadWeight      = cstmt.getString(12);
      String retLoadingCapacity = cstmt.getString(13);

      HashMap paramsRet = new HashMap();
      paramsRet.put("maxShipMethods",  retMaxShipMethods);
      paramsRet.put("paletteMaxQty",   retPaletteMaxQty);
      paramsRet.put("deadWeight",      retDeadWeight);
      paramsRet.put("loadingCapacity", retLoadingCapacity);

      return paramsRet;
      
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���O�ɏo��
      XxcmnUtility.writeLog(trans,
                            XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[�ɂ����߂�l�ɂ��ׂ�null���Z�b�g���Ė߂��B
      HashMap paramsRet = new HashMap();
      paramsRet.put("maxShipMethods",  null); 
      paramsRet.put("paletteMaxQty",   null);
      paramsRet.put("deadWeight",      null);
      paramsRet.put("loadingCapacity", null);
      return paramsRet;

    } finally
    {
      try
      {
        //�������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getMaxShipMethod
  /*****************************************************************************
   * �ύڌ����`�F�b�N���s���A�ύڗ����Z�o���܂��B
   * @param sumWeight     - ���v�d��
   * @param sumCapacity   - ���v�e��
   * @param code1         - �R�[�h�敪�P
   * @param whseCode1     - ���o�ɏꏊ�R�[�h�P
   * @param code2         - �R�[�h�敪�Q
   * @param whseCode2     - ���o�ɏꏊ�R�[�h�Q
   * @param maxShipToCode - �z���敪
   * @param originalDate  - ���
   * @param prodClass     - ���i�敪
   * @return HashMap  - �߂�l�Q
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap calcLoadEfficiency(
    OADBTransaction trans,
    String sumWeight,
    String sumCapacity,
    String code1,
    String whseCode1,
    String code2,
    String whseCode2,
    String maxShipToCode,
    Date originalDate,
    String prodClass
    ) throws  OAException
  {
    String apiName = "calcLoadEfficiency";

    HashMap retHashMap = new HashMap();  // �߂�l�p
    // PL/SQL�̍쐬���s���܂��B
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  ln_load_efficiency_weight         NUMBER; ");
    sb.append("  ln_load_efficiency_capacity       NUMBER; ");
    sb.append("BEGIN ");
    sb.append("  xxwsh_common910_pkg.calc_load_efficiency( ");
    sb.append("    in_sum_weight                 => TO_NUMBER(:1)  "); // 1.���v�d��
    sb.append("   ,in_sum_capacity               => TO_NUMBER(:2)  "); // 2.���v�e��
    sb.append("   ,iv_code_class1                => :3  "); // 3.�R�[�h�敪�P
    sb.append("   ,iv_entering_despatching_code1 => :4  "); // 4.���o�ɏꏊ�R�[�h�P
    sb.append("   ,iv_code_class2                => :5  "); // 5.�R�[�h�敪�Q
    sb.append("   ,iv_entering_despatching_code2 => :6  "); // 6.���o�ɏꏊ�R�[�h�Q
    sb.append("   ,iv_ship_method                => :7  "); // 7.�o�ו��@(�ő�z���敪)
    sb.append("   ,iv_prod_class                 => :8 ");  // 8.���i�敪
    sb.append("   ,iv_auto_process_type          => null  "); // 9.�����z�ԑΏۋ敪
    sb.append("   ,id_standard_date              => :9  "); // 10.���(�K�p�����)
    sb.append("   ,ov_retcode                    => :10  "); // 11.���^�[���R�[�h
    sb.append("   ,ov_errmsg_code                => :11 "); // 12.�G���[���b�Z�[�W�R�[�h
    sb.append("   ,ov_errmsg                     => :12 "); // 13.�G���[���b�Z�[�W
    sb.append("   ,ov_loading_over_class         => :13 "); // 14.�ύڃI�[�o�[�敪
    sb.append("   ,ov_ship_methods               => :14 "); // 15.�o�ו��@
    sb.append("   ,on_load_efficiency_weight     => ln_load_efficiency_weight "); // 16.�d�ʐύڌ���
    sb.append("   ,on_load_efficiency_capacity   => ln_load_efficiency_capacity "); // 17.�e�ϐύڌ���
    sb.append("   ,ov_mixed_ship_method          => :15 "); // 18.���ڔz���敪
    sb.append("   ); ");
    sb.append("  :16 := TO_CHAR(ln_load_efficiency_weight);   ");
    sb.append("  :17 := TO_CHAR(ln_load_efficiency_capacity); ");
    sb.append("END; ");

    // PL/SQL�̐ݒ���s���܂��B
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      int i = 1;
      cstmt.setString(i++, sumWeight);    // 1.���v�d��
      cstmt.setString(i++, sumCapacity);  // 2.���v�e��
      cstmt.setString(i++, code1);        // 3.�R�[�h�敪�P
      cstmt.setString(i++, whseCode1);    // 4.���o�ɏꏊ�R�[�h�P
      cstmt.setString(i++, code2);        // 5.�R�[�h�敪�Q
      cstmt.setString(i++, whseCode2);    // 6.���o�ɏꏊ�R�[�h�Q
      cstmt.setString(i++, maxShipToCode); // 7.�z���敪
      cstmt.setString(i++, prodClass); // 8.���i�敪
      cstmt.setDate(i++, XxcmnUtility.dateValue(originalDate)); // 9.���

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(i++, Types.VARCHAR);            // 10.�X�e�[�^�X�R�[�h
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);      // 11.�G���[���b�Z�[�W
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);      // 12.�V�X�e�����b�Z�[�W
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);

      // PL/SQL���s
      cstmt.execute();

      // ���s���ʊi�[
      String retCode   = cstmt.getString(10);   // ���^�[���R�[�h
      String errMsg    = cstmt.getString(11);  // �G���[���b�Z�[�W
      String systemMsg = cstmt.getString(12);  // �V�X�e�����b�Z�[�W
      String loadingOverClass = cstmt.getString(13);  // �ύڃI�[�o�[�敪
      String shipMethod       = cstmt.getString(14);  // �z���敪
      String mixedShipMethod  = cstmt.getString(15);  // ���ڔz���敪
      String loadEfficiencyWeight    = cstmt.getString(16);  // �d�ʐύڌ���
      String loadEfficiencyCapacity  = cstmt.getString(17);  // �e�ϐύڌ���

      // �߂�l�擾
      retHashMap.put("loadingOverClass",       loadingOverClass);
      retHashMap.put("shipMethod",             shipMethod);
      retHashMap.put("mixedShipMethod",        mixedShipMethod);
      retHashMap.put("loadEfficiencyWeight",   loadEfficiencyWeight);
      retHashMap.put("loadEfficiencyCapacity", loadEfficiencyCapacity);
      retHashMap.put("retCode",        retCode);
      retHashMap.put("errMsg",   errMsg);
      retHashMap.put("systemMsg", systemMsg);

      // �G���[�̏ꍇ
      if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              errMsg + systemMsg,
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                               XxcmnConstants.XXCMN10123);
      }
      // �ύڃI�[�o�[�̏ꍇ�̓G���[�ɂ�������I������B�i�G���[���b�Z�[�W�����H����K�v�����邽��)
      return retHashMap; 
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                             XxcmnConstants.XXCMN10123);

    } finally 
    {
      try 
      {
        // �������ɃG���[�����������ꍇ��z�肷��B
        cstmt.close();
      } catch(SQLException s) 
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);

      }
    }
  } // calcLoadEfficiency
  /*****************************************************************************
   * �w�肵���z���敪�ɂ�菬���敪���Z�o
   * @param maxShipToCode - �z���敪
   * @param originalDate  - ���
   * @return String  - �����敪
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String getSmallKbn(
    OADBTransaction trans,
    String shipToCode,
    Date originalDate
    ) throws  OAException
  {
    String apiName = "getSmallKbn";

    HashMap retHashMap = new HashMap();  // �߂�l�p

    // PL/SQL�̍쐬���s���܂��B
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  SELECT xsmv.small_amount_class "            ); // �����敪
    sb.append("    INTO :1 "                                 );
    sb.append("    FROM xxwsh_ship_method2_v xsmv "          );
    sb.append("   WHERE xsmv.ship_method_code = :2 "         );
    sb.append("     AND :3 "                                 );
    sb.append("       BETWEEN xsmv.start_date_active "       );
    sb.append("           AND NVL(xsmv.end_date_active,:4); ");
    sb.append("END; "                                        );

    // PL/SQL�̐ݒ���s���܂��B
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      int i = 1;
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1);         // �����敪

      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(i++, shipToCode);    // �z���敪
      cstmt.setDate(i++, XxcmnUtility.dateValue(originalDate)); // ���
      cstmt.setDate(i++, XxcmnUtility.dateValue(originalDate)); // ���

      // PL/SQL���s
      cstmt.execute();

      // ���s���ʊi�[
      String small_amount_class   = cstmt.getString(1);   // �����敪

      return small_amount_class; 
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                             XxcmnConstants.XXCMN10123);

    } finally 
    {
      try 
      {
        // �������ɃG���[�����������ꍇ��z�肷��B
        cstmt.close();
      } catch(SQLException s) 
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);

      }
    }
  } // getSmallKbn
  /*****************************************************************************
   * �o�ׂƈړ��̃��b�g�t�]�h�~�`�F�b�NAPI�����s���܂��B
   * @param trans - �g�����U�N�V����
   * @param lotBizClass  - ���b�g�t�]�������
   * @param itemNo       - �i��No
   * @param lotNo        - ���b�gNo
   * @param moveToId     - �z����ID/���ɐ�ID
   * @param arrivalDate  - ����
   * @param standardDate - ���
   * @return HashMap 
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap doCheckLotReversalMov(
    OADBTransaction trans,
    String lotBizClass,
    String itemNo,
    String lotNo,
    Number moveToId,
    Date   arrivalDate,
// 2009-01-22 H.Itou MOD START �{�ԏ�Q#1000�Ή�
//    Date   standardDate
    Date   standardDate,
    String requestNo
// 2009-01-22 H.Itou MOD END
  ) throws OAException
  {
    String apiName = "doCheckLotReversalMov";
    HashMap ret    = new HashMap();
    
    // OUT�p�����[�^
    String exeType = XxcmnConstants.RETURN_NOT_EXE;
    
    //PL/SQL�쐬
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                                    );
// 2009-01-22 H.Itou MOD START �{�ԏ�Q#1000�Ή�
//    sb.append("  xxwsh_common910_pkg.check_lot_reversal( ");
//    sb.append("    iv_lot_biz_class    => :1,            ");   // 1.���b�g�t�]������� 1:�o��(�w��)�A5:�ړ�(�w��)
//    sb.append("    iv_item_no          => :2,            ");   // 2.�i�ڃR�[�h
//    sb.append("    iv_lot_no           => :3,            ");   // 3.���b�gNo
//    sb.append("    iv_move_to_id       => :4,            ");   // 4.�z����ID/�����T�C�gID/���ɐ�ID
//    sb.append("    iv_arrival_date     => :5,            ");   // 5.����
//    sb.append("    id_standard_date    => :6,            ");   // 6.���(�K�p�����)
//    sb.append("    ov_retcode          => :7,            ");   // 7.���^�[���R�[�h
//    sb.append("    ov_errmsg_code      => :8,            ");   // 8.�G���[���b�Z�[�W�R�[�h
//    sb.append("    ov_errmsg           => :9,            ");   // 9.�G���[���b�Z�[�W
//    sb.append("    on_result           => :10,           ");   // 10.��������
//    sb.append("    on_reversal_date    => :11);          ");   // 11.�t�]���t
    sb.append("  xxwsh_common910_pkg.check_lot_reversal2( ");
    sb.append("    iv_lot_biz_class    => :1,            ");   // 1.���b�g�t�]������� 1:�o��(�w��)�A5:�ړ�(�w��)
    sb.append("    iv_item_no          => :2,            ");   // 2.�i�ڃR�[�h
    sb.append("    iv_lot_no           => :3,            ");   // 3.���b�gNo
    sb.append("    iv_move_to_id       => :4,            ");   // 4.�z����ID/�����T�C�gID/���ɐ�ID
    sb.append("    iv_arrival_date     => :5,            ");   // 5.����
    sb.append("    id_standard_date    => :6,            ");   // 6.���(�K�p�����)
    sb.append("    iv_request_no       => :7,            ");   // 7.�˗�No
    sb.append("    ov_retcode          => :8,            ");   // 8.���^�[���R�[�h
    sb.append("    ov_errmsg_code      => :9,            ");   // 9.�G���[���b�Z�[�W�R�[�h
    sb.append("    ov_errmsg           => :10,           ");   // 10.�G���[���b�Z�[�W
    sb.append("    on_result           => :11,           ");   // 11.��������
    sb.append("    on_reversal_date    => :12);          ");   // 12.�t�]���t
// 2009-01-22 H.Itou MOD END
    sb.append("END; "                                     );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, lotBizClass);                         // ���b�g�t�]�������
      cstmt.setString(2, itemNo);                              // �i�ڃR�[�h
      cstmt.setString(3, lotNo);                               // ���b�gNo
      cstmt.setInt(4,    XxcmnUtility.intValue(moveToId));     // �z����ID
      cstmt.setDate(5,   XxcmnUtility.dateValue(arrivalDate)); // ����
      cstmt.setDate(6,   XxcmnUtility.dateValue(standardDate));// ���(�K�p�����)
// 2009-01-22 H.Itou ADD START �{�ԏ�Q#1000�Ή�
      cstmt.setString(7, requestNo);                            // �˗�No
// 2009-01-22 H.Itou ADD END
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
// 2009-01-22 H.Itou MOD START �{�ԏ�Q#1000�Ή�
//      cstmt.registerOutParameter(7,  Types.VARCHAR); // ���^�[���R�[�h
//      cstmt.registerOutParameter(8,  Types.VARCHAR); // �G���[���b�Z�[�W�R�[�h
//      cstmt.registerOutParameter(9,  Types.VARCHAR); // �G���[���b�Z�[�W
//      cstmt.registerOutParameter(10, Types.INTEGER); // ��������
//      cstmt.registerOutParameter(11, Types.DATE);    // �t�]���t
      cstmt.registerOutParameter(8,  Types.VARCHAR); // ���^�[���R�[�h
      cstmt.registerOutParameter(9,  Types.VARCHAR); // �G���[���b�Z�[�W�R�[�h
      cstmt.registerOutParameter(10,  Types.VARCHAR); // �G���[���b�Z�[�W
      cstmt.registerOutParameter(11, Types.INTEGER); // ��������
      cstmt.registerOutParameter(12, Types.DATE);    // �t�]���t
// 2009-01-22 H.Itou MOD END

      //PL/SQL���s
      cstmt.execute();
      
// 2009-01-22 H.Itou MOD START �{�ԏ�Q#1000�Ή�
//      String retCode    = cstmt.getString(7);               // ���^�[���R�[�h
//      String errmsgCode = cstmt.getString(8);               // �G���[���b�Z�[�W�R�[�h
//      String errmsg     = cstmt.getString(9);               // �G���[���b�Z�[�W
      String retCode    = cstmt.getString(8);               // ���^�[���R�[�h
      String errmsgCode = cstmt.getString(9);               // �G���[���b�Z�[�W�R�[�h
      String errmsg     = cstmt.getString(10);               // �G���[���b�Z�[�W
// 2009-01-22 H.Itou MOD END

      // API����I���̏ꍇ�A�l���Z�b�g
      if (XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {
// 2009-01-22 H.Itou MOD START �{�ԏ�Q#1000�Ή�
//        ret.put("result",  new Number(cstmt.getInt(10))); // ��������
//        ret.put("revDate", new Date(cstmt.getDate(11)));  // �t�]���t
        ret.put("result",  new Number(cstmt.getInt(11))); // ��������
        ret.put("revDate", new Date(cstmt.getDate(12)));  // �t�]���t
// 2009-01-22 H.Itou MOD END
        
      // API����I���łȂ��ꍇ�A�G���[  
      } else
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
// 2009-01-22 H.Itou MOD START �{�ԏ�Q#1000�Ή�
//          cstmt.getString(9), // �G���[���b�Z�[�W
          errmsg,
// 2009-01-22 H.Itou MOD END
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);
        
    } finally
    {
      try
      {
        // PL/SQL�N���[�Y
        cstmt.close();
        
      // �N���[�Y���ɂɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    return ret;
  } // doCheckLotReversalMov
  /*****************************************************************************
   * �N�x�����`�F�b�NAPI�����s���܂��B
   * @param trans - �g�����U�N�V����
   * @param moveToId     - �z����ID
   * @param lotId        - ���b�gId
   * @param arrivalDate  - ����
   * @param standard_date  - ���(�K�p�����)
   * @return HashMap 
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap doCheckFreshCondition(
    OADBTransaction trans,
    Number moveToId,
    Number lotId,
    Date   arrivalDate,
    Date   standard_date
  ) throws OAException
  {
    String apiName = "doCheckFreshCondition";
    HashMap ret    = new HashMap();
    
    // OUT�p�����[�^
    String exeType = XxcmnConstants.RETURN_NOT_EXE;
    
    //PL/SQL�쐬
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                                    );
    sb.append("  xxwsh_common910_pkg.check_fresh_condition( ");
    sb.append("    iv_move_to_id       => :1,            ");   // 1.�z����ID
    sb.append("    iv_lot_id           => :2,            ");   // 2.���b�gId
    sb.append("    iv_arrival_date     => :3,            ");   // 3.����
    sb.append("    id_standard_date    => :4,            ");   // 4.���
    sb.append("    ov_retcode          => :5,            ");   // 5.���^�[���R�[�h
    sb.append("    ov_errmsg_code      => :6,            ");   // 6.�G���[���b�Z�[�W�R�[�h
    sb.append("    ov_errmsg           => :7,            ");   // 7.�G���[���b�Z�[�W
    sb.append("    on_result           => :8,            ");   // 8.��������
    sb.append("    od_standard_date    => :9);           ");   // 9.����t
    sb.append("END; "                                     );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1,    XxcmnUtility.intValue(moveToId));     // �z����ID
      cstmt.setInt(2,    XxcmnUtility.intValue(lotId));        // ���b�gId
      cstmt.setDate(3,   XxcmnUtility.dateValue(arrivalDate)); // ����
      cstmt.setDate(4,   XxcmnUtility.dateValue(standard_date)); // ���
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(5,  Types.VARCHAR); // ���^�[���R�[�h
      cstmt.registerOutParameter(6,  Types.VARCHAR); // �G���[���b�Z�[�W�R�[�h
      cstmt.registerOutParameter(7,  Types.VARCHAR); // �G���[���b�Z�[�W
      cstmt.registerOutParameter(8,  Types.INTEGER); // ��������
      cstmt.registerOutParameter(9,  Types.DATE);    // ����t

      //PL/SQL���s
      cstmt.execute();

      String retCode    = cstmt.getString(5);               // ���^�[���R�[�h
      String errmsgCode = cstmt.getString(6);               // �G���[���b�Z�[�W�R�[�h
      String errmsg     = cstmt.getString(7);               // �G���[���b�Z�[�W

      // API����I���̏ꍇ�A�l���Z�b�g
      if (XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {
        ret.put("result",       new Number(cstmt.getInt(8))); // ��������
        ret.put("standardDate", new Date(cstmt.getDate(9)));  // �t�]���t
        
      // API����I���łȂ��ꍇ�A�G���[  
      } else
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          errmsg, // �G���[���b�Z�[�W
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);
        
    } finally
    {
      try
      {
        // PL/SQL�N���[�Y
        cstmt.close();
        
      // �N���[�Y���ɂɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    return ret;
  } // doCheckFreshCondition


  /*****************************************************************************
   * �ړ����b�g�ڍ׃A�h�I��������ѐ��ʂ��擾���郁�\�b�h�ł��B
   * @param trans            - �g�����U�N�V����
   * @param movLineId        - �󒍖��׃A�h�I��ID
   * @param documentTypeCode - �����^�C�v(10:�o�׈˗��A30:�x���w��)
   * @param recordTypeCode   - ���R�[�h�^�C�v(10�F�w���A20�F�o�Ɏ���  30�F���Ɏ���)
   * @param lotId            - ���b�gID
   * @return Number          - ���ѐ���
   * @throws OAException - OA��O
   ****************************************************************************/
  public static Number getActualQuantity(
    OADBTransaction trans,
    Number movLineId,
    String documentTypeCode,
    String recordTypeCode,
    Number lotId
  ) throws OAException
  {
    String apiName     = "getActualQuantity";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                          );
    sb.append("  SELECT xmld.actual_quantity actual_quantity "  ); // ���ѐ���
    sb.append("  INTO   :1 "                                    );
    sb.append("  FROM   xxinv_mov_lot_details xmld "            ); //   �ړ����b�g�ڍ׃A�h�I��
    sb.append("  WHERE  xmld.mov_line_id        = :2 "          ); // 2.�󒍖��׃A�h�I��ID
    sb.append("  AND    xmld.document_type_code = :3 "          ); // 3.�����^�C�v
    sb.append("  AND    xmld.record_type_code   = :4 "          ); // 4.���R�[�h�^�C�v
    sb.append("  AND    xmld.lot_id             = :5; "         ); // 5.���b�gID
    sb.append("END; "                                           );

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    { 
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2,    XxcmnUtility.intValue(movLineId)); // �󒍖��׃A�h�I��ID
      cstmt.setString(3, documentTypeCode);              // �����^�C�v
      cstmt.setString(4, recordTypeCode);                // ���R�[�h�^�C�v
      cstmt.setInt(5,    XxcmnUtility.intValue(lotId));     // ���b�gID
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
// 2008-12-05 H.Itou Mod Start �{�ԏ�Q#481 �����_���l��
//      cstmt.registerOutParameter(1, Types.INTEGER);
      cstmt.registerOutParameter(1, Types.NUMERIC);
// 2008-12-05 H.Itou Mod End
      
      // PL/SQL���s
      cstmt.execute();
// 2008-12-05 H.Itou Mod Start �{�ԏ�Q#481 �����_���l��
//      return new Number(cstmt.getInt(1));  // ���ѐ��ʂ�Ԃ��B
      return new Number(cstmt.getObject(1));  // ���ѐ��ʂ�Ԃ��B
// 2008-12-05 H.Itou Mod End

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        //�������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getActualQuantity
  /*****************************************************************************
   * �ړ����b�g�ڍ׃A�h�I���ɒǉ��������s�����\�b�h�ł��B
   * @param trans   - �g�����U�N�V����
   * @param params  - �p�����[�^
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void insXxinvMovLotDetails(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "insXxinvMovLotDetails";

    Number orderLineId            = (Number)params.get("orderLineId");            // ����ID
    String documentTypeCode       = (String)params.get("documentTypeCode");       // �����^�C�v
    String recordTypeCode         = (String)params.get("recordTypeCode");         // ���R�[�h�^�C�v
    Number itemId                 = (Number)params.get("itemId");                 // �i��ID
    String itemCode               = (String)params.get("itemCode");               // �i��
    Number lotId                  = (Number)params.get("lotId");                  // ���b�gID
    String lotNo                  = (String)params.get("lotNo");                  // ���b�gNo
    String actualQuantity         = (String)params.get("actualQuantity");         // ���ѐ���
    Date   actualDate             = (Date)params.get("actualDate");               // ���ѓ�
    String automanualReserveClass = (String)params.get("automanualReserveClass"); // �����蓮�����敪
    

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                      );
    sb.append("  INSERT INTO xxinv_mov_lot_details xmld ( " ); // �ړ����b�g�ڍ׃A�h�I��
    sb.append("     xmld.mov_lot_dtl_id  "                  ); // ���b�g�ڍ�ID
    sb.append("    ,xmld.mov_line_id  "                     ); // 1.����ID
    sb.append("    ,xmld.document_type_code  "              ); // 2.�����^�C�v
    sb.append("    ,xmld.record_type_code  "                ); // 3.���R�[�h�^�C�v
    sb.append("    ,xmld.item_id  "                         ); // 4.OPM�i��ID
    sb.append("    ,xmld.item_code  "                       ); // 5.�i��
    sb.append("    ,xmld.lot_id  "                          ); // 6.���b�gID
    sb.append("    ,xmld.lot_no  "                          ); // 7.���b�gNo
    sb.append("    ,xmld.actual_date  "                     ); // 8.���ѓ�
    sb.append("    ,xmld.actual_quantity  "                 ); // 9.���ѐ���
    sb.append("    ,xmld.automanual_reserve_class "         ); // 10.�����蓮�����敪
    sb.append("    ,xmld.created_by  "                      ); // 11.�쐬��
    sb.append("    ,xmld.creation_date  "                   ); // 12.�쐬��
    sb.append("    ,xmld.last_updated_by  "                 ); // 13.�ŏI�X�V��
    sb.append("    ,xmld.last_update_date  "                ); // 14.�ŏI�X�V��
    sb.append("    ,xmld.last_update_login)  "              ); // 15.�ŏI�X�V���O�C��
    sb.append("  VALUES(  "                                 );
    sb.append("     xxinv_mov_lot_s1.NEXTVAL "              );
    sb.append("    ,:1 "                                    );
    sb.append("    ,:2 "                                    );
    sb.append("    ,:3 "                                    );
    sb.append("    ,:4 "                                    );
    sb.append("    ,:5 "                                    );
    sb.append("    ,:6 "                                    );
    sb.append("    ,:7 "                                    );
    sb.append("    ,:8 "                                    );
    sb.append("    ,TO_NUMBER(:9) "                         );
    sb.append("    ,:10 "                                   );
    sb.append("    ,FND_GLOBAL.USER_ID "                    ); // �쐬��          
    sb.append("    ,SYSDATE "                               ); // �쐬��          
    sb.append("    ,FND_GLOBAL.USER_ID "                    ); // �ŏI�X�V��      
    sb.append("    ,SYSDATE "                               ); // �ŏI�X�V��      
    sb.append("    ,FND_GLOBAL.LOGIN_ID); "                 ); // �ŏI�X�V���O�C��
    sb.append("END; "                                       );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1,     XxcmnUtility.intValue(orderLineId)); // ����ID
      cstmt.setString(2,  documentTypeCode);                   // �����^�C�v
      cstmt.setString(3,  recordTypeCode);                     // ���R�[�h�^�C�v
      cstmt.setInt(4,     XxcmnUtility.intValue(itemId));      // OPM�i��ID
      cstmt.setString(5,  itemCode);                           // �i��
      cstmt.setInt(6,     XxcmnUtility.intValue(lotId));       // ���b�gID
      cstmt.setString(7,  lotNo);                              // ���b�gNo
      cstmt.setDate(8,    XxcmnUtility.dateValue(actualDate)); // ���ѓ�
      cstmt.setString(9,  actualQuantity);                     // ���ѐ���
      cstmt.setString(10, automanualReserveClass);            // �����蓮�����敪

      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        //�������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // insXxinvMovLotDetails
  /*****************************************************************************
   * �ړ����b�g�ڍ׃A�h�I���̎��ѐ��ʂ��X�V���郁�\�b�h�ł��B
   * @param trans        - �g�����U�N�V����
   * @param params       - �p�����[�^
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void updActualQuantity(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "updActualQuantity";

    // IN�p�����[�^�擾
    Number movLotDtlId            = (Number)params.get("movLotDtlId");            // �ړ����b�g�ڍ�ID
    String actualQuantity         = (String)params.get("actualQuantity");         // ���ѐ���
    String automanualReserveClass = (String)params.get("automanualReserveClass"); // �����蓮�����敪

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                            );
    sb.append("  UPDATE xxinv_mov_lot_details xmld "                              ); // �ړ����b�g���׃A�h�I��
    sb.append("  SET    xmld.actual_quantity              = TO_NUMBER(:1) "       ); // 1.���ѐ���
    sb.append("        ,xmld.automanual_reserve_class     = :2 "                  ); // 2.�����蓮�����敪
    sb.append("        ,xmld.last_updated_by              = FND_GLOBAL.USER_ID "  ); // �ŏI�X�V��
    sb.append("        ,xmld.last_update_date             = SYSDATE "             ); // �ŏI�X�V��
    sb.append("        ,xmld.last_update_login            = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C��
    sb.append("  WHERE  xmld.mov_lot_dtl_id               = :3 ;"                 ); // 3.�ړ����b�g�ڍ�ID
    sb.append("END; "                                                             );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, actualQuantity);                     // ���ѐ���
      cstmt.setString(2, automanualReserveClass);             // ���R�[�h�^�C�v
      cstmt.setInt(3,    XxcmnUtility.intValue(movLotDtlId)); // ���b�g�ڍ�ID

      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updActualQuantity
  /*****************************************************************************
   * �ړ����b�g�ڍ׃A�h�I�����폜���郁�\�b�h�ł��B
   * @param trans        - �g�����U�N�V����
   * @param movLotDtlId  - �ړ����b�g�ڍ�ID
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void deleteActualQuantity(
    OADBTransaction trans,
    Number movLotDtlId
  ) throws OAException
  {
    String apiName   = "deleteActualQuantity";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                             );
    sb.append("  DELETE xxinv_mov_lot_details xmld "                ); // �ړ����b�g�ڍ׃A�h�I��
    sb.append("  WHERE  xmld.mov_lot_dtl_id = :1 ;"                ); // 1.���b�g�ڍ�ID
    sb.append("END; "                                              );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1, XxcmnUtility.intValue(movLotDtlId)); // �ړ����b�g�ڍ�ID

      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // deleteActualQuantity
  /*****************************************************************************
   * �󒍖��׃A�h�I���̎w�����ʂ��X�V���郁�\�b�h�ł��B
   * @param trans        - �g�����U�N�V����
   * @param params       - �p�����[�^
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void updOrderLineInstructQty(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "updOrderLineInstructQty";

    // IN�p�����[�^�擾
    Number orderLineId            = (Number)params.get("orderLineId");            // �󒍖��׃A�h�I��ID
    String reservedQuantity       = (String)params.get("reservedQuantity");       // ��������
    String warningClass           = (String)params.get("warningClass");           // �x���敪
    Date warningDate              = (Date)params.get("warningDate");              // �x�����t
    String automanualReserveClass = (String)params.get("automanualReserveClass"); // �����蓮�����敪
    String instructQty            = (String)params.get("instructQty");            // �w������
    String weight                 = (String)params.get("weight");                 // �d��
    String capacity               = (String)params.get("capacity");               // �e��
    
    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                 );
    sb.append("  UPDATE xxwsh_order_lines_all xola "                   ); // �󒍖��׃A�h�I��
    sb.append("  SET    xola.reserved_quantity = TO_NUMBER(:1) "       ); // 1.��������
    sb.append("        ,xola.warning_class = :2 "                      ); // 2.�x���敪
    sb.append("        ,xola.warning_date = :3 "                       ); // 3.�x�����t
    sb.append("        ,xola.automanual_reserve_class = :4 "           ); // 4.�����蓮�����敪
    sb.append("        ,xola.quantity = TO_NUMBER(:5) "                ); // 5.�w������
    sb.append("        ,xola.weight = TO_NUMBER(:6) "                  ); // 6.�d��
    sb.append("        ,xola.capacity = TO_NUMBER(:7) "                ); // 7.�e��
    sb.append("        ,xola.last_updated_by = FND_GLOBAL.USER_ID "    ); // �ŏI�X�V��
    sb.append("        ,xola.last_update_date = SYSDATE "              ); // �ŏI�X�V��
    sb.append("        ,xola.last_update_login = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C��
    sb.append("  WHERE xola.order_line_id = :8; "                      ); // 8.�󒍖��׃A�h�I��ID
    sb.append("END; "                                                  );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, reservedQuantity);                    // ��������
      cstmt.setString(2, warningClass);                        // �x���敪
      cstmt.setDate(3,   XxcmnUtility.dateValue(warningDate)); // �x�����t
      cstmt.setString(4, automanualReserveClass);              // �����蓮�����敪
      cstmt.setString(5, instructQty);                         // �w������
      cstmt.setString(6, weight);                             // �d��        
      cstmt.setString(7, capacity);                            // �e��
      cstmt.setInt(8,    XxcmnUtility.intValue(orderLineId));  // ����ID
      

      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updOrderLineInstructQty
  /*****************************************************************************
   * �󒍖��׃A�h�I���̈������ʂ��X�V���郁�\�b�h�ł��B
   * @param trans        - �g�����U�N�V����
   * @param params       - �p�����[�^
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void updOrderLineReservedQty(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "updOrderLineReservedQty";

    // IN�p�����[�^�擾
    Number orderLineId            = (Number)params.get("orderLineId");            // �󒍖��׃A�h�I��ID
    String reservedQuantity       = (String)params.get("reservedQuantity");       // ��������
    String warningClass           = (String)params.get("warningClass");           // �x���敪
    Date warningDate              = (Date)params.get("warningDate");              // �x�����t
    String automanualReserveClass = (String)params.get("automanualReserveClass"); // �����蓮�����敪
    
    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                 );
    sb.append("  UPDATE xxwsh_order_lines_all xola "                   ); // �󒍖��׃A�h�I��
    sb.append("  SET    xola.reserved_quantity = TO_NUMBER(:1) "       ); // 1.��������
    sb.append("        ,xola.warning_class = :2 "                      ); // 2.�x���敪
    sb.append("        ,xola.warning_date = :3 "                       ); // 3.�x�����t
    sb.append("        ,xola.automanual_reserve_class = :4 "           ); // 4.�����蓮�����敪
    sb.append("        ,xola.last_updated_by = FND_GLOBAL.USER_ID "    ); // �ŏI�X�V��
    sb.append("        ,xola.last_update_date = SYSDATE "              ); // �ŏI�X�V��
    sb.append("        ,xola.last_update_login = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C��
    sb.append("  WHERE xola.order_line_id = :5; "                      ); // 5.�󒍖��׃A�h�I��ID
    sb.append("END; "                                       );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, reservedQuantity);                    // ��������
      cstmt.setString(2, warningClass);                        // �x���敪
      cstmt.setDate(3,   XxcmnUtility.dateValue(warningDate)); // �x�����t
      cstmt.setString(4, automanualReserveClass);              // �����蓮�����敪
      cstmt.setInt(5,    XxcmnUtility.intValue(orderLineId));  // ����ID
      

      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updOrderLineReservedQty
 /*****************************************************************************
   * �󒍃w�b�_�A�h�I���̔z�Ԋ֘A�f�[�^���X�V���郁�\�b�h�ł��B
   * @param trans        - �g�����U�N�V����
   * @param params       - �p�����[�^
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void updOrderHeaderDelivery(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "updOrderHeaderDelivery";

    // IN�p�����[�^�擾
    Number orderHeaderId             = (Number)params.get("orderHeaderId");             // �󒍃w�b�_�A�h�I��ID
    String sumQuantity               = (String)params.get("sumQuantity");               // ���v����
    String smallQuantity             = (String)params.get("smallQuantity");             // ������
    String labelQuantity             = (String)params.get("labelQuantity");             // ���x������
    String loadingEfficiencyWeight   = (String)params.get("loadingEfficiencyWeight");   // �d�ʐύڌ���
    String loadingEfficiencyCapacity = (String)params.get("loadingEfficiencyCapacity"); // �e�ϐύڌ���
    String sumWeight                 = (String)params.get("sumWeight");                 // �ύڏd�ʍ��v
    String sumCapacity               = (String)params.get("sumCapacity");               // �ύڗe�ύ��v
    
    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                    );
    sb.append("  UPDATE xxwsh_order_headers_all xoha "                    ); // �󒍃w�b�_�A�h�I��
    sb.append("  SET    xoha.sum_quantity = TO_NUMBER(:1) "               ); // 1.���v����
    sb.append("        ,xoha.small_quantity = TO_NUMBER(:2) "             ); // 2.������
    sb.append("        ,xoha.label_quantity = TO_NUMBER(:3) "             ); // 3.���x������
    sb.append("        ,xoha.loading_efficiency_weight = TO_NUMBER(:4) "  ); // 4.�d�ʐύڌ���
    sb.append("        ,xoha.loading_efficiency_capacity = TO_NUMBER(:5) "); // 5.�e�ϐύڌ���
    sb.append("        ,xoha.sum_weight = TO_NUMBER(:6) "                 ); // 6.�ύڏd�ʍ��v
    sb.append("        ,xoha.sum_capacity = TO_NUMBER(:7) "               ); // 7.�ύڗe�ύ��v
    sb.append("        ,xoha.screen_update_by = FND_GLOBAL.USER_ID "      ); // ��ʍX�V��
    sb.append("        ,xoha.screen_update_date = SYSDATE "               ); // ��ʍX�V����
    sb.append("        ,xoha.last_updated_by = FND_GLOBAL.USER_ID "       ); // �ŏI�X�V��
    sb.append("        ,xoha.last_update_date = SYSDATE "                 ); // �ŏI�X�V��
    sb.append("        ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID "    ); // �ŏI�X�V���O�C��
    sb.append("  WHERE xoha.order_header_id = :8; "                       ); // 8.�󒍃w�b�_�A�h�I��ID
    sb.append("END; "                                                     );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, sumQuantity);                          // ���v����
      cstmt.setString(2, smallQuantity);                        // ������
      cstmt.setString(3, labelQuantity);                        // ���x������
      cstmt.setString(4, loadingEfficiencyWeight);              // �d�ʐύڌ���
      cstmt.setString(5, loadingEfficiencyCapacity);            // �e�ϐύڌ���
      cstmt.setString(6, sumWeight);                            // �ύڏd�ʍ��v
      cstmt.setString(7, sumCapacity);                          // �ύڗe�ύ��v
      cstmt.setInt(8,    XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_ID

      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updOrderHeaderDelivery
  /*****************************************************************************
   * �󒍃w�b�_�A�h�I���̉�ʍX�V�����X�V���郁�\�b�h�ł��B
   * @param trans         - �g�����U�N�V����
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   * @throws OAException  - OA��O
   ****************************************************************************/
  public static void updOrderHeaderScreen(
    OADBTransaction trans,
    Number orderHeaderId
  ) throws OAException
  {
    String apiName   = "updOrderHeaderScreen";

    // IN�p�����[�^�擾
    
    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                  );
    sb.append("  UPDATE xxwsh_order_headers_all xoha "                  ); // �󒍃w�b�_�A�h�I��
    sb.append("     SET xoha.screen_update_by = FND_GLOBAL.USER_ID "    ); // ��ʍX�V��
    sb.append("        ,xoha.screen_update_date = SYSDATE "             ); // ��ʍX�V����
    sb.append("        ,xoha.last_updated_by = FND_GLOBAL.USER_ID "     ); // �ŏI�X�V��
    sb.append("        ,xoha.last_update_date = SYSDATE "               ); // �ŏI�X�V��
    sb.append("        ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID "  ); // �ŏI�X�V���O�C��
    sb.append("  WHERE xoha.order_header_id = :1; "                     ); // 8.�󒍃w�b�_�A�h�I��ID
    sb.append("END; "                                                   );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1, XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_ID

      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updOrderHeaderScreen
  /*****************************************************************************
   * �ړ��˗�/�w������(�A�h�I��)�̎w�����ʂ��X�V���郁�\�b�h�ł��B
   * @param trans        - �g�����U�N�V����
   * @param params       - �p�����[�^
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void updMoveLineInstructQty(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "updMoveLineInstructQty";

    // IN�p�����[�^�擾
    Number movLineId              = (Number)params.get("movLineId");              // �ړ�����ID
    String reservedQuantity       = (String)params.get("reservedQuantity");       // ��������
    String warningClass           = (String)params.get("warningClass");           // �x���敪
    Date warningDate              = (Date)params.get("warningDate");              // �x�����t
    String automanualReserveClass = (String)params.get("automanualReserveClass"); // �����蓮�����敪
    String instructQty            = (String)params.get("instructQty");            // �w������
    String weight                 = (String)params.get("weight");                 // �d��
    String capacity               = (String)params.get("capacity");               // �e��
    
    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                  );
    sb.append("  UPDATE xxinv_mov_req_instr_lines xmril "               ); // �ړ��˗�/�w������(�A�h�I��)
    sb.append("  SET    xmril.reserved_quantity = TO_NUMBER(:1) "       ); // 1.��������
    sb.append("        ,xmril.warning_class = :2 "                      ); // 2.�x���敪
    sb.append("        ,xmril.warning_date = :3 "                       ); // 3.�x�����t
    sb.append("        ,xmril.automanual_reserve_class = :4 "           ); // 4.�����蓮�����敪
    sb.append("        ,xmril.instruct_qty = TO_NUMBER(:5) "            ); // 5.�w������
    sb.append("        ,xmril.weight = TO_NUMBER(:6) "                  ); // 6.�d��
    sb.append("        ,xmril.capacity = TO_NUMBER(:7) "                ); // 7.�e��
    sb.append("        ,xmril.last_updated_by = FND_GLOBAL.USER_ID "    ); // �ŏI�X�V��
    sb.append("        ,xmril.last_update_date = SYSDATE "              ); // �ŏI�X�V��
    sb.append("        ,xmril.last_update_login = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C��
    sb.append("  WHERE  xmril.mov_line_id = :8; "                       ); // 8.�ړ�����ID
    sb.append("END; "                                                   );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, reservedQuantity);                    // ��������
      cstmt.setString(2, warningClass);                        // �x���敪
      cstmt.setDate(3,   XxcmnUtility.dateValue(warningDate)); // �x�����t
      cstmt.setString(4, automanualReserveClass);              // �x���敪
      cstmt.setString(5, instructQty);                         // �w������
      cstmt.setString(6, weight);                              // �d��
      cstmt.setString(7, capacity);                            // �e��
      cstmt.setInt(8,    XxcmnUtility.intValue(movLineId));    // ����ID
      

      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updMoveLineInstructQty
  /*****************************************************************************
   * �ړ��˗�/�w������(�A�h�I��)�̈������ʂ��X�V���郁�\�b�h�ł��B
   * @param trans        - �g�����U�N�V����
   * @param params       - �p�����[�^
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void updMoveLineReservedQty(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "updMoveLineReservedQty";

    // IN�p�����[�^�擾
    Number movLineId              = (Number)params.get("movLineId");              // �ړ�����ID
    String reservedQuantity       = (String)params.get("reservedQuantity");       // ��������
    String warningClass           = (String)params.get("warningClass");           // �x���敪
    Date warningDate              = (Date)params.get("warningDate");              // �x�����t
    String automanualReserveClass = (String)params.get("automanualReserveClass"); // �����蓮�����敪
    
    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                  );
    sb.append("  UPDATE xxinv_mov_req_instr_lines xmril "               ); // �ړ��˗�/�w������(�A�h�I��)
    sb.append("  SET    xmril.reserved_quantity = TO_NUMBER(:1) "       ); // 1.��������
    sb.append("        ,xmril.warning_class = :2 "                      ); // 2.�x���敪
    sb.append("        ,xmril.warning_date = :3 "                       ); // 3.�x�����t
    sb.append("        ,xmril.automanual_reserve_class = :4 "           ); // 4.�����蓮�����敪
    sb.append("        ,xmril.last_updated_by = FND_GLOBAL.USER_ID "    ); // �ŏI�X�V��
    sb.append("        ,xmril.last_update_date = SYSDATE "              ); // �ŏI�X�V��
    sb.append("        ,xmril.last_update_login = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C��
    sb.append("  WHERE  xmril.mov_line_id = :5; "                       ); // 5.�ړ�����ID
    sb.append("END; "                                                   );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, reservedQuantity);                    // ��������
      cstmt.setString(2, warningClass);                        // �x���敪
      cstmt.setDate(3,   XxcmnUtility.dateValue(warningDate)); // �x�����t
      cstmt.setString(4, automanualReserveClass);              // �����蓮�����敪
      cstmt.setInt(5,    XxcmnUtility.intValue(movLineId));    // ����ID
      

      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // uupdMoveLineReservedQty
 /*****************************************************************************
   * �ړ��˗�/�w���w�b�_(�A�h�I��)�̔z�Ԋ֘A�f�[�^���X�V���郁�\�b�h�ł��B
   * @param trans        - �g�����U�N�V����
   * @param params       - �p�����[�^
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void updMoveHeaderDelivery(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "updMoveHeaderDelivery";

    // IN�p�����[�^�擾
    Number movHdrId                  = (Number)params.get("movHdrId");                  // �ړ��w�b�_ID
    String sumQuantity               = (String)params.get("sumQuantity");               // ���v����
    String smallQuantity             = (String)params.get("smallQuantity");             // ������
    String labelQuantity             = (String)params.get("labelQuantity");             // ���x������
    String loadingEfficiencyWeight   = (String)params.get("loadingEfficiencyWeight");   // �d�ʐύڌ���
    String loadingEfficiencyCapacity = (String)params.get("loadingEfficiencyCapacity"); // �e�ϐύڌ���
    String sumWeight                 = (String)params.get("sumWeight");                 // �ύڏd�ʍ��v
    String sumCapacity               = (String)params.get("sumCapacity");               // �ύڗe�ύ��v
    
    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                     );
    sb.append("  UPDATE xxinv_mov_req_instr_headers xmrih "                ); // �ړ��˗�/�w���w�b�_(�A�h�I��)
    sb.append("  SET    xmrih.sum_quantity = TO_NUMBER(:1) "               ); // 1.���v����
    sb.append("        ,xmrih.small_quantity = TO_NUMBER(:2) "             ); // 2.������
    sb.append("        ,xmrih.label_quantity = TO_NUMBER(:3) "             ); // 3.���x������
    sb.append("        ,xmrih.loading_efficiency_weight = TO_NUMBER(:4) "  ); // 4.�d�ʐύڌ���
    sb.append("        ,xmrih.loading_efficiency_capacity = TO_NUMBER(:5) "); // 5.�e�ϐύڌ���
    sb.append("        ,xmrih.sum_weight = TO_NUMBER(:6) "                 ); // 6.�ύڏd�ʍ��v
    sb.append("        ,xmrih.sum_capacity = TO_NUMBER(:7) "               ); // 7.�ύڗe�ύ��v
    sb.append("        ,xmrih.screen_update_by = FND_GLOBAL.USER_ID "      ); // ��ʍX�V��
    sb.append("        ,xmrih.screen_update_date = SYSDATE "               ); // ��ʍX�V����
    sb.append("        ,xmrih.last_updated_by = FND_GLOBAL.USER_ID "       ); // �ŏI�X�V��
    sb.append("        ,xmrih.last_update_date = SYSDATE "                 ); // �ŏI�X�V��
    sb.append("        ,xmrih.last_update_login = FND_GLOBAL.LOGIN_ID "    ); // �ŏI�X�V���O�C��
    sb.append("  WHERE  xmrih.mov_hdr_id = :8; "                           ); // 8.�ړ��w�b�_ID
    sb.append("END; "                                                      );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, sumQuantity);                          // ���v����
      cstmt.setString(2, smallQuantity);                        // ������
      cstmt.setString(3, labelQuantity);                        // ���x������
      cstmt.setString(4, loadingEfficiencyWeight);              // �d�ʐύڌ���
      cstmt.setString(5, loadingEfficiencyCapacity);            // �e�ϐύڌ���
      cstmt.setString(6, sumWeight);                            // �ύڏd�ʍ��v
      cstmt.setString(7, sumCapacity);                          // �ύڗe�ύ��v
      cstmt.setInt   (8, XxcmnUtility.intValue(movHdrId));      // �ړ��w�b�_ID
      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updMoveHeaderDelivery
 /*****************************************************************************
   * �ړ��˗�/�w���w�b�_(�A�h�I��)�̉�ʍX�V�����X�V���郁�\�b�h�ł��B
   * @param trans        - �g�����U�N�V����
   * @param movHdrId      - �ړ��w�b�_ID
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void updMoveHeaderScreen(
    OADBTransaction trans,
    Number movHdrId
  ) throws OAException
  {
    String apiName   = "updMoveHeaderScreen";
    
    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                   );
    sb.append("  UPDATE xxinv_mov_req_instr_headers xmrih "              ); // �ړ��˗�/�w���w�b�_(�A�h�I��)
    sb.append("  SET    xmrih.screen_update_by = FND_GLOBAL.USER_ID "    ); // ��ʍX�V��
    sb.append("        ,xmrih.screen_update_date = SYSDATE "             ); // ��ʍX�V����
    sb.append("        ,xmrih.last_updated_by = FND_GLOBAL.USER_ID "     ); // �ŏI�X�V��
    sb.append("        ,xmrih.last_update_date = SYSDATE "               ); // �ŏI�X�V��
    sb.append("        ,xmrih.last_update_login = FND_GLOBAL.LOGIN_ID "  ); // �ŏI�X�V���O�C��
    sb.append("  WHERE  xmrih.mov_hdr_id = :1; "                         ); // 1.�ړ��w�b�_ID
    sb.append("END; "                                                    );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1, XxcmnUtility.intValue(movHdrId));      // �ړ��w�b�_ID

      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updMoveHeaderScreen
  /*****************************************************************************
   * �z�ԉ����֐������s���܂��B
   * @param trans        - �g�����U�N�V����
   * @param bizType      - �Ɩ����
   * @param requestNo    - �˗�No/�ړ��ԍ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void doCancelCareersSchedule(
    OADBTransaction trans,
    String bizType,
    String requestNo
  ) throws OAException
  {
    String apiName = "doCancelCareersSchedule";
    HashMap ret    = new HashMap();
    
    //PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  :1 := xxwsh_common_pkg.cancel_careers_schedule( ");
    sb.append("         iv_biz_type     => :2, "); // 2.�Ɩ����
    sb.append("         iv_request_no   => :3, "); // 3.�˗�No/�ړ��ԍ�
// 2008-10-24 D.Nihei ADD START TE080_BPO_600 No22
    sb.append("          iv_calcel_flag => '1', "); // 4.�z�ԉ����t���O
// 2008-10-24 D.Nihei ADD END
    sb.append("         ov_errmsg       => :4); "); // 5.�G���[���b�Z�[�W
    sb.append("END; ");


    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1,  Types.VARCHAR); // 1.���^�[���R�[�h
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(2, bizType);                   // 2.�Ɩ����
      cstmt.setString(3, requestNo);                 // 3.�˗�No/�ړ��ԍ�

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(4,  Types.VARCHAR); // �G���[���b�Z�[�W
      
      //PL/SQL���s
      cstmt.execute();

      String retCode    = cstmt.getString(1);               // ���^�[���R�[�h
      String errmsg     = cstmt.getString(4);               // �G���[���b�Z�[�W

      // API����I���łȂ��ꍇ�A�G���[  
      if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode))
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          errmsg, // �G���[���b�Z�[�W
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);
        
    } finally
    {
      try
      {
        // PL/SQL�N���[�Y
        cstmt.close();
        
      // �N���[�Y���ɂɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // doCancelCareersSchedule
  
  /*****************************************************************************
   * �ړ��˗�/�w������(�A�h�I��)�̍ŏI�X�V�����擾���郁�\�b�h�ł��B
   * @param trans          - �g�����U�N�V����
   * @param movHdrId       - �ړ��w�b�_ID
   * @return String        - �ŏI�X�V��
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String getMoveLineUpdateDate(
    OADBTransaction trans,
     Number movHdrId
  ) throws OAException
  {
    String apiName   = "getMoveLineUpdateDate";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                                                  );
    sb.append("  SELECT TO_CHAR(MAX(xmril.last_update_date),'YYYY/MM/DD HH24:MI:SS')  last_update_date "); // 1.�ŏI�X�V��
    sb.append("  INTO   :1  "                                                                           );
    sb.append("  FROM   xxinv_mov_req_instr_lines xmril"                                                ); // �󒍖��׃A�h�I��
    sb.append("  WHERE  xmril.mov_hdr_id = :2 "                                                         ); // 2.�ړ��w�b�_ID
    sb.append("  AND    NVL(xmril.delete_flg,'N') = 'N'; "                                             ); // �폜�t���O
    sb.append("END; "                                                            );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(movHdrId)); // �ړ��w�b�_ID

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR);   // �ŏI�X�V��

      // PL/SQL���s
      cstmt.execute();
      
      return cstmt.getString(1);

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getMoveLineUpdateDate

  /*****************************************************************************
   * �ړ��˗�/�w���w�b�_(�A�h�I��)�̍ŏI�X�V�����擾���郁�\�b�h�ł��B
   * @param trans            - �g�����U�N�V����
   * @param movHdrId         - �ړ��w�b�_ID
   * @return String          - �ŏI�X�V��
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String getMoveHeaderUpdateDate(
    OADBTransaction trans,
     Number movHdrId
  ) throws OAException
  {
    String apiName   = "getMoveHeaderUpdateDate";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                            );
    sb.append("  SELECT TO_CHAR(xmrih.last_update_date, 'YYYY/MM/DD HH24:Mi:SS') "); // 1.�ŏI�X�V��
    sb.append("  INTO   :1 "                                                      );
    sb.append("  FROM   xxinv_mov_req_instr_headers xmrih "                       ); // �ړ��˗�/�w���w�b�_(�A�h�I��)
    sb.append("  WHERE  xmrih.mov_hdr_id    = :2; "                               ); // 2.�ړ��w�b�_ID
    sb.append("END; "                                                             );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(movHdrId)); // �ړ��w�b�_ID

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR);   // �ŏI�X�V��

      // PL/SQL���s
      cstmt.execute();
      
      return cstmt.getString(1);

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getMoveHeaderUpdateDate

// 2008-06-27 H.Itou ADD Start
 /*****************************************************************************
   * �󒍃w�b�_�A�h�I�����������g�̃R���J�����g�N���ɂ��X�V���ꂽ���ǂ����`�F�b�N���郁�\�b�h�ł��B
   * @param trans            - �g�����U�N�V����
   * @param orderHeaderId    - �󒍃w�b�_�A�h�I��ID
   * @param concName         - �R���J�����g��
   * @return boolean  - true:�������N�������R���J�����g���X�V����Ă���
   *                   - false:�������N�������R���J�����g���X�V����Ă��Ȃ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean isOrderHdrUpdForOwnConc(
    OADBTransaction trans,
    Number orderHeaderId,
    String concName
  ) throws OAException
  {
    String apiName     = "isOrderHdrUpdForOwnConc";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN                                                                       ");
    sb.append("  SELECT TO_CHAR(COUNT(1))                                                  ");
    sb.append("  INTO   :1                                                                 "); // 1:����
    sb.append("  FROM   xxwsh_order_headers_all xoha                                       "); // �󒍃w�b�_�A�h�I��
    sb.append("  WHERE  xoha.order_header_id  = :2                                         "); // 2:�󒍃w�b�_�A�h�I��ID
    sb.append("  AND    xoha.last_updated_by  = FND_GLOBAL.USER_ID                         "); // ���[�U�[ID
    sb.append("  AND    xoha.last_update_date = xoha.program_update_date                   "); // �ŏI�X�V���ƃv���O�����X�V��������
    sb.append("  AND    EXISTS (                                                           "); // �w�肵���R���J�����g�ōX�V���ꂽ���R�[�h
    sb.append("           SELECT 1                                                         ");
    sb.append("           FROM   fnd_concurrent_programs     fcp                           "); // �R���J�����g�v���O�����e�[�u��
    sb.append("           WHERE  fcp.concurrent_program_name = :3                          "); // 3:�R���J�����g��
    sb.append("           AND    fcp.concurrent_program_id   = xoha.program_id             "); // �R���J�����g�v���O����ID
    sb.append("           AND    fcp.application_id          = xoha.program_application_id "); // �A�v���P�[�V����ID
    sb.append("           )                                                                ");
    sb.append("  AND    ROWNUM = 1;                                                        ");
    sb.append("END;                                                                        ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    { 
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR);
      
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID
      cstmt.setString(3, concName);                          // �R���J�����g��
      
      // PL/SQL���s
      cstmt.execute();

      // OUT�p�����[�^�擾
      String cnt = cstmt.getString(1);  // �߂�l

      // 0���̏ꍇ�A�������N�������R���J�����g���X�V����Ă��Ȃ��̂ŁAfalse��Ԃ��B
      if (XxcmnConstants.STRING_ZERO.equals(cnt))
      {
        return false;

      // 1���̏ꍇ�A�������N�������R���J�����g���X�V����Ă���̂ŁAtrue��Ԃ��B
      } else
      {
        return true;
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
        // ���[���o�b�N
        XxwshUtility.rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        //�������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        XxwshUtility.rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // isOrderHdrUpdForOwnConc

 /*****************************************************************************
   * �󒍖��׃A�h�I�����������g�̃R���J�����g�N���ɂ��X�V���ꂽ���ǂ����`�F�b�N���郁�\�b�h�ł��B
   * @param trans            - �g�����U�N�V����
   * @param orderHeaderId    - �󒍃w�b�_�A�h�I��ID
   * @param concName         - �R���J�����g��
   * @return boolean  - true:�������N�������R���J�����g���X�V����Ă���
   *                   - false:�������N�������R���J�����g���X�V����Ă��Ȃ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean isOrderLineUpdForOwnConc(
    OADBTransaction trans,
    Number orderHeaderId,
    String concName
  ) throws OAException
  {
    String apiName     = "isOrderLineUpdForOwnConc";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN                                                                       ");
    sb.append("  SELECT TO_CHAR(COUNT(1))                                                  ");
    sb.append("  INTO   :1                                                                 "); // 1:����
    sb.append("  FROM   xxwsh_order_lines_all  xola                                        "); // �󒍖��׃A�h�I��
    sb.append("  WHERE  xola.order_header_id  = :2                                         "); // 2:�󒍃w�b�_�A�h�I��ID
    sb.append("  AND    xola.last_updated_by  = FND_GLOBAL.USER_ID                         "); // ���[�U�[ID
    sb.append("  AND    xola.last_update_date = xola.program_update_date                   "); // �ŏI�X�V���ƃv���O�����X�V��������
    sb.append("  AND    EXISTS (                                                           "); // �w�肵���R���J�����g�ōX�V���ꂽ���R�[�h
    sb.append("           SELECT 1                                                         ");
    sb.append("           FROM   fnd_concurrent_programs     fcp                           "); // �R���J�����g�v���O�����e�[�u��
    sb.append("           WHERE  fcp.concurrent_program_name = :3                          "); // 3:�R���J�����g��
    sb.append("           AND    fcp.concurrent_program_id   = xola.program_id             "); // �R���J�����g�v���O����ID
    sb.append("           AND    fcp.application_id          = xola.program_application_id "); // �A�v���P�[�V����ID
    sb.append("           )                                                                ");
    sb.append("  AND    xola.last_update_date IN (                                         "); // ����w�b�_ID���A�ő�ŏI�X�V���������R�[�h
    sb.append("           SELECT MAX(xola1.last_update_date)                               ");
    sb.append("           FROM   xxwsh_order_lines_all  xola1                              ");
    sb.append("           WHERE  xola1.order_header_id = :4                                ");
    sb.append("           GROUP BY xola1.order_header_id                                   ");
    sb.append("           )                                                                ");
    sb.append("  AND    ROWNUM = 1;                                                        ");
    sb.append("END;                                                                        ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    { 
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR);
      
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID
      cstmt.setString(3, concName);                          // �R���J�����g��
      cstmt.setInt(4, XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID
      
      // PL/SQL���s
      cstmt.execute();

      // OUT�p�����[�^�擾
      String cnt = cstmt.getString(1);  // �߂�l

      // 0���̏ꍇ�A�������N�������R���J�����g���X�V����Ă��Ȃ��̂ŁAfalse��Ԃ��B
      if (XxcmnConstants.STRING_ZERO.equals(cnt))
      {
        return false;

      // 1���̏ꍇ�A�������N�������R���J�����g���X�V����Ă���̂ŁAtrue��Ԃ��B
      } else
      {
        return true;
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
        // ���[���o�b�N
        XxwshUtility.rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        //�������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        XxwshUtility.rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // isOrderLineUpdForOwnConc
// 2008-06-27 H.Itou ADD End
// 2008-07-23 H.Itou ADD Start
 /*****************************************************************************
   * �i�ڂ̃P�[�X�����ɐ��������l�������Ă��邩�`�F�b�N���郁�\�b�h�ł��B
   * @param trans            - �g�����U�N�V����
   * @param itemCode         - �i�ڃR�[�h
   * @return boolean         - true :������
   *                         - false:�G���[
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean checkNumOfCases(
    OADBTransaction trans,
    String itemCode
  ) throws OAException
  {
    String apiName     = "checkNumOfCases";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    // �i�ڋ敪��5�F���i���A���i�敪��1�F���[�tOR 2�F�h�����N���A���o�Ɋ��Z�P�ʂ�NULL�łȂ��ꍇ
    // �P�[�X������NULL��0�ȉ��́A�G���[�B
    sb.append("BEGIN                                           ");
    sb.append("  SELECT COUNT(1) cnt                           ");
    sb.append("  INTO   :1                                     ");
    sb.append("  FROM   xxcmn_item_mst_v         ximv          "); // OPM�i�ڃ}�X�^
    sb.append("        ,xxcmn_item_categories5_v xicv          "); // �i�ڃJ�e�S���������VIEW5
    sb.append("  WHERE  /** �������� **/                       ");
    sb.append("         ximv.item_id = xicv.item_id            ");
    sb.append("         /** ���o���� **/                       ");
    sb.append("  AND    xicv.item_class_code       = '5'       "); // �i�ڋ敪��5�F���i
    sb.append("  AND    xicv.prod_class_code       IN ('1','2')"); // ���i�敪��1�F���[�tOR 2�F�h�����N
    sb.append("  AND    ximv.conv_unit             IS NOT NULL "); // ���o�Ɋ��Z�P�ʂ�NULL�łȂ�
    sb.append("  AND    NVL(ximv.num_of_cases, 0) <= 0         "); // �P�[�X������0�ȉ�
    sb.append("  AND    ximv.item_no               = :2        ");
    sb.append("  AND    ROWNUM = 1;                            ");
    sb.append("END;                                            ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    { 
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(2, itemCode);                    // �i�ڃR�[�h
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.INTEGER);
      
      // PL/SQL���s
      cstmt.execute();

      // OUT�p�����[�^�擾
      int cnt = cstmt.getInt(1);  // �߂�l

      // �f�[�^���擾�ł���ꍇ�A���Z�̕K�v������̂ɃP�[�X������0�ȉ��Ȃ̂ŁAfalse��Ԃ��B
      if (cnt == 1)
      {
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          "�P�[�X������NULL��0�ł��B�i�ڃR�[�h�F"+ itemCode,
          6);

        return false;

      // 0�̏ꍇ�A����Ȃ̂�true��Ԃ��B
      } else
      {
        return true;
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
        // ���[���o�b�N
        XxwshUtility.rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        //�������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        XxwshUtility.rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // checkNumOfCases
  
 /*****************************************************************************
   * �󒍖��ׂ���i�ڃR�[�h���擾���郁�\�b�h�ł��B
   * @param trans            - �g�����U�N�V����
   * @param orderLlineId     - �󒍖���ID
   * @return String          - �i�ڃR�[�h
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String getItemCode(
    OADBTransaction trans,
    String orderLlineId
  ) throws OAException
  {
    String apiName     = "getItemCode";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN                                                             ");
    sb.append("  SELECT xola.shipping_item_code  item_code                       ");
    sb.append("  INTO   :1                                                       ");
    sb.append("  FROM   xxwsh_order_lines_all    xola                            "); // �󒍖��׃A�h�I��
    sb.append("  WHERE  xola.order_line_id = TO_NUMBER(:2);                      ");
    sb.append("END;                                                              ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    { 
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(2, orderLlineId);  // �󒍖���ID
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR);
      
      // PL/SQL���s
      cstmt.execute();

      // OUT�p�����[�^�擾
      String itemCode = cstmt.getString(1);  // �߂�l

      return itemCode;

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
        // ���[���o�b�N
        XxwshUtility.rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        //�������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        XxwshUtility.rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getItemCode
// 2008-07-23 H.Itou ADD End
// 2008-10-24 D.Nihei ADD START TE080_BPO_600 No22
  /*****************************************************************************
   * �ʒm�X�e�[�^�X�X�V�֐��i�z�ԉ����֐��j�����s���܂��B
   * @param trans        - �g�����U�N�V����
   * @param bizType      - �Ɩ����
   * @param requestNo    - �˗�No/�ړ��ԍ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void updateNotifStatus(
    OADBTransaction trans,
    String bizType,
    String requestNo
  ) throws OAException
  {
    String apiName = "updateNotifStatus";
    HashMap ret    = new HashMap();
    
    //PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  :1 := xxwsh_common_pkg.cancel_careers_schedule( ");
    sb.append("          iv_biz_type    => :2,  "); // 2.�Ɩ����
    sb.append("          iv_request_no  => :3,  "); // 3.�˗�No/�ړ��ԍ�
    sb.append("          iv_calcel_flag => '0', "); // 4.�z�ԉ����t���O
    sb.append("          ov_errmsg      => :4); "); // 5.�G���[���b�Z�[�W
    sb.append("END; ");


    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1,  Types.VARCHAR); // 1.���^�[���R�[�h
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(2, bizType);                   // 2.�Ɩ����
      cstmt.setString(3, requestNo);                 // 3.�˗�No/�ړ��ԍ�

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(4,  Types.VARCHAR); // �G���[���b�Z�[�W
      
      //PL/SQL���s
      cstmt.execute();

      String retCode    = cstmt.getString(1);               // ���^�[���R�[�h
      String errmsg     = cstmt.getString(4);               // �G���[���b�Z�[�W

      // API����I���łȂ��ꍇ�A�G���[  
      if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode))
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          errmsg, // �G���[���b�Z�[�W
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);
        
    } finally
    {
      try
      {
        // PL/SQL�N���[�Y
        cstmt.close();
        
      // �N���[�Y���ɂɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // doCancelCareersSchedule
// 2008-10-24 D.Nihei ADD END
// 2009-01-26 H.Itou ADD START �{�ԏ�Q��936�Ή�
  /*****************************************************************************
   * �N�x�������i���������擾���܂��B
   * @param trans - �g�����U�N�V����
   * @param moveToId     - �z����ID
   * @param itemNo       - �i�ڃR�[�h
   * @param arrivalDate  - ����
   * @param standard_date  - ���(�K�p�����)
   * @return HashMap 
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap getFreshPassDate(
    OADBTransaction trans,
    Number moveToId,
    String itemNo,
    Date   arrivalDate,
    Date   standardDate
  ) throws OAException
  {
    String apiName = "getFreshPassDate";
    HashMap ret    = new HashMap();
    
    // OUT�p�����[�^
    String exeType = XxcmnConstants.RETURN_NOT_EXE;

    // �o�C���h�ϐ�
    int paramBind  = 1;
    //PL/SQL�쐬
    StringBuffer sb = new StringBuffer(100);
    sb.append("DECLARE                                              ");
    sb.append("  it_move_to_id       NUMBER;                        ");
    sb.append("  it_item_no          xxcmn_item_mst_v.item_no%TYPE; ");
    sb.append("  id_arrival_date     DATE;                          ");
    sb.append("  id_standard_date    DATE;                          ");
    sb.append("  od_manufacture_date DATE;                          ");
    sb.append("  ov_retcode          VARCHAR2(5000);                ");
    sb.append("  ov_errmsg           VARCHAR2(5000);                ");
    sb.append("BEGIN                                                ");
                 // IN�p�����[�^�ݒ�
    sb.append("  it_move_to_id     := :" + paramBind++ + ";         "); // IN:�z����ID
    sb.append("  it_item_no        := :" + paramBind++ + ";         "); // IN:�i�ڃR�[�h
    sb.append("  id_arrival_date   := :" + paramBind++ + ";         "); // IN:���ח\���
    sb.append("  id_standard_date  := :" + paramBind++ + ";         "); // IN:���(�K�p�����)
    sb.append("  xxwsh_common910_pkg.get_fresh_pass_date(           ");
    sb.append("    it_move_to_id       => it_move_to_id             ");
    sb.append("   ,it_item_no          => it_item_no                ");
    sb.append("   ,id_arrival_date     => id_arrival_date           ");
    sb.append("   ,id_standard_date    => id_standard_date          ");
    sb.append("   ,od_manufacture_date => od_manufacture_date       ");
    sb.append("   ,ov_retcode          => ov_retcode                ");
    sb.append("   ,ov_errmsg           => ov_errmsg                 ");
    sb.append("   );                                                ");
                 // OUT�p�����[�^�ݒ�
    sb.append("   :" + paramBind++ + " := ov_retcode;               "); // OUT:���^�[���R�[�h
    sb.append("   :" + paramBind++ + " := ov_errmsg;                "); // OUT:�G���[���b�Z�[�W
    sb.append("   :" + paramBind++ + " := od_manufacture_date;      "); // OUT:�N�x�������i������
    sb.append("END;                                                 ");

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // IN�p�����[�^�ݒ�
      paramBind  = 1;
      cstmt.setInt   (paramBind++, XxcmnUtility.intValue(moveToId));      // IN:�z����ID
      cstmt.setString(paramBind++, itemNo);                               // IN:�i�ڃR�[�h
      cstmt.setDate  (paramBind++, XxcmnUtility.dateValue(arrivalDate));  // IN:���ח\���
      cstmt.setDate  (paramBind++, XxcmnUtility.dateValue(standardDate)); // IN:���(�K�p�����)

      // OUT�p�����[�^�ݒ�
      int outParamStart = paramBind; // OUT�p�����[�^�J�n��ێ��B
      cstmt.registerOutParameter(paramBind++, Types.VARCHAR); // OUT:���^�[���R�[�h
      cstmt.registerOutParameter(paramBind++, Types.VARCHAR); // OUT:�G���[���b�Z�[�W
      cstmt.registerOutParameter(paramBind++, Types.DATE);    // OUT:�N�x�������i������

      //PL/SQL���s
      cstmt.execute();

      // OUT�p�����[�^�擾
      paramBind  = outParamStart;
      String retCode         = cstmt.getString(paramBind++);         // OUT:���^�[���R�[�h
      String errMsg          = cstmt.getString(paramBind++);         // OUT:�G���[���b�Z�[�W
      Date   manufactureDate = new Date(cstmt.getDate(paramBind++)); // OUT:�N�x�������i������

      // API�G���[�I���łȂ��ꍇ
      if (!XxcmnConstants.API_RETURN_ERROR.equals(retCode))
      {
        ret.put("retCode",         retCode);         // OUT:���^�[���R�[�h
        ret.put("manufactureDate", manufactureDate); // OUT:�N�x�������i������

      // API����I���łȂ��ꍇ�A�G���[  
      } else
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          errMsg, // �G���[���b�Z�[�W
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
        XxcmnConstants.XXCMN10123);
        
    } finally
    {
      try
      {
        // PL/SQL�N���[�Y
        cstmt.close();
        
      // �N���[�Y���ɂɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    return ret;
  } // getFreshPassDate
// 2009-01-26 H.Itou ADD END
}