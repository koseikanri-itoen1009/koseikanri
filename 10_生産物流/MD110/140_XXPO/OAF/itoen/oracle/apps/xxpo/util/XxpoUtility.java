/*============================================================================
* �t�@�C���� : XxpoUtility
* �T�v����   : �d�����ʊ֐�
* �o�[�W���� : 1.38
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-10 1.0  �ɓ��ЂƂ�   �V�K�쐬
* 2008-06-11 1.1  �g������     ST�s����O#72��Ή�
* 2008-06-17 1.2  ��r���     ST�s����O#126��Ή�
* 2008-06-18 1.3  �ɓ��ЂƂ�   �����o�O ��������IF�̒P���A�d���艿��
*                              �d��/�W���P���w�b�_�̓��󍇌v�ɕύX�B
* 2008-06-30 1.4  �g������     ST�s����O#41��Ή�
* 2008-07-02 1.5  �g������     ST�s����O#104��Ή�
* 2008-07-11 1.6  ��r���     ST�s����O#421�Ή�
* 2008-07-17 1.7  �ɓ��ЂƂ�   ST�s����O#83�Ή�
* 2008-07-29 1.8  ��r���     �����ύX�v��#164,166,173�A�ۑ�#32
* 2008-08-07 1.9  ��r���     �����ύX�v��#166�C��
* 2008-08-19 1.10 ��r���     ST�s�#249�Ή�
* 2008-10-07 1.11 �ɓ��ЂƂ�   �����e�X�g�w�E240�Ή�
* 2008-10-21 1.12 ��r���     ������Q#384
* 2008-10-22 1.13 �ɓ��ЂƂ�   �ύX�v��#217,238,�����e�X�g�w�E49�Ή�
* 2008-10-22 1.14 �g������     �����e�X�g�w�E426�Ή�
* 2008-10-23 1.15 �ɓ��ЂƂ�   T_TE080_BPO_340 �w�E5
* 2008-11-04 1.16 ��r���     ������Q#51,103�A104�Ή�
* 2008-12-05 1.17 �ɓ��ЂƂ�   �{�ԏ�Q#481�Ή�
* 2008-12-06 1.18 �g������     �{�ԏ�Q#788�Ή�
* 2008-12-24 1.19 ��r���     �{�ԏ�Q#743�Ή�
* 2008-12-26 1.20 �ɓ��ЂƂ�   �{�ԏ�Q#809�Ή�
* 2009-01-16 1.21 �g������     �{�ԏ�Q#1006�Ή�
* 2009-01-20 1.22 �g������     �{�ԏ�Q#739,985�Ή�
* 2009-02-06 1.23 �ɓ��ЂƂ�   �{�ԏ�Q#1147�Ή�
* 2009-02-18 1.24 �ɓ��ЂƂ�   �{�ԏ�Q#1096�Ή�
* 2009-02-27 1.25 �ɓ��ЂƂ�   �{�ԏ�Q#32�Ή�
* 2009-05-13 1.26 �g������     �{�ԏ�Q#1282�Ή�
* 2009-07-08 1.27 �ɓ��ЂƂ�   �{�ԏ�Q#1566�Ή�
* 2011-06-01 1.28 �E�a�d       �{�ԏ�Q#1786�Ή�
* 2015-10-05 1.29 �R���đ�     E_�{�ғ�_13238�Ή�
* 2016-02-12 1.30 �R���đ�     E_�{�ғ�_13451�Ή�
* 2016-05-16 1.31 �R���đ�     E_�{�ғ�_13563�Ή�
* 2016-07-06 1.32 �R���đ�     E_�{�ғ�_13563�ǉ��Ή�
* 2017-06-07 1.33 �ː��a�K     E_�{�ғ�_14244�Ή�
* 2017-06-30 1.34 �ː��a�K     E_�{�ғ�_14267�Ή�
* 2017-08-10 1.35 �R���đ�     E_�{�ғ�_14243�Ή�
* 2018-01-09 1.36 �ː��a�K     E_�{�ғ�_14243�Ή��i���b�Z�[�W�ǉ��j
* 2018-02-22 1.37 �ː��a�K     E_�{�ғ�_14859�Ή�
* 2019-02-28 1.38 ���X�ؑ�a   E_�{�ғ�_15597�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.util;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
// 2009-02-27 H.Itou Add Start �{�ԏ�Q#32
import java.math.BigDecimal;
// 2009-02-27 H.Itou Add End
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
/***************************************************************************
 * �d�����ʊ֐��N���X�ł��B
 * @author  ORACLE �ɓ��ЂƂ�
 * @version 1.29
 ***************************************************************************
 */
public class XxpoUtility 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoUtility()
  {
  }

  /*****************************************************************************
   * SYSDATE���擾���܂��B
   * @param trans - �g�����U�N�V����
   * @return Date SYSDATE
   * @throws OAException - OA��O
   ****************************************************************************/
  public static Date getSysdate(
    OADBTransaction trans
  ) throws OAException
  {
    String apiName   = "getSysdate";
    Date   sysdate = null;

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                  );
    sb.append("   SELECT SYSDATE "      ); // SYSDATE
    sb.append("   INTO   :1 "           );
    sb.append("   FROM   DUAL; "        );
    sb.append("END; "                   );

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.DATE); // SYSDATE

      // PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      sysdate = new Date(cstmt.getDate(1));

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return sysdate;
  } // getSysdate
  
  /*****************************************************************************
   * �ܖ��������̎Z�o���s���܂��B
   * @param trans - �g�����U�N�V����
   * @param itemId - �i��ID
   * @param productedDate - ������
   * @param itemCode - �i�ڃR�[�h
   * @return Date �ܖ�������
   * @throws OAException - OA��O
   ****************************************************************************/
  public static Date getUseByDate(
    OADBTransaction trans,
    Number itemId,
    Date productedDate,
// 2009-02-06 H.Itou Mod Start �{�ԏ�Q#1147�Ή�
//    String expirationDay
    String itemCode
// 2009-02-06 H.Itou Mod End
  ) throws OAException
  {
    String apiName   = "getUseByDate";
    Date   useByDate = null;

    // �i��ID�A��������Null�̏ꍇ�͏������s��Ȃ��B
    if (XxcmnUtility.isBlankOrNull(itemId) 
      || XxcmnUtility.isBlankOrNull(productedDate)
// 2009-02-06 H.Itou Mod Start �{�ԏ�Q#1147
//      || XxcmnUtility.isBlankOrNull(expirationDay)) 
        )
// 2009-02-06 H.Itou Mod End
    {
      // �ܖ������̌v�Z�͂��܂���B
      return null;      
    }

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(100);
// 2018-02-22 K.Kiriu Add Start
    sb.append("DECLARE "                                                        );
    sb.append("  lt_expiration_type  xxcmn_item_mst2_v.expiration_type%TYPE; "  );
    sb.append("  lt_expiration_day   xxcmn_item_mst2_v.expiration_day%TYPE; "   );
    sb.append("  lt_expiration_month xxcmn_item_mst2_v.expiration_month%TYPE; " );
// 2018-02-22 K.Kiriu Add End
    sb.append("BEGIN "                                     );
// 2017-06-07 K.Kiriu Mod Start
//    sb.append("   SELECT :1 + NVL(ximv.expiration_day, 0) "); // �ܖ�����
//    sb.append("   INTO   :2 "                              );
// 2018-02-22 K.Kiriu Mod Start
//    sb.append("   SELECT NVL2( ximv.expiration_month "                                                                                );
//    sb.append("               , CASE "                                                                                                );
//    sb.append("                   WHEN ximv.expiration_type = '10' THEN "                                                             ); //�N���\��
//    sb.append("                     LAST_DAY(ADD_MONTHS(:1, NVL(ximv.expiration_month, 0) -1)) "                                      );
//    sb.append("                   ELSE "                                                                                              ); //��E���E���{�\��
//    sb.append("                     CASE "                                                                                            );
//    sb.append("                       WHEN TO_NUMBER(TO_CHAR(:1, 'DD')) >= 21 THEN "                                                  ); //��������21���ȍ~
//    sb.append("                         TO_DATE(TO_CHAR(ADD_MONTHS(:1, NVL(ximv.expiration_month, 0)),'YYYYMM') || '20','YYYYMMDD') " );
//    sb.append("                       WHEN TO_NUMBER(TO_CHAR(:1, 'DD')) >= 11 THEN "                                                  ); //��������11���`20��
//    sb.append("                         TO_DATE(TO_CHAR(ADD_MONTHS(:1, NVL(ximv.expiration_month, 0)),'YYYYMM') || '10','YYYYMMDD') " );
//    sb.append("                       ELSE "                                                                                          ); //��������10�ȑO
//    sb.append("                           LAST_DAY(ADD_MONTHS(:1, NVL(ximv.expiration_month, 0) -1)) "                                );
//    sb.append("                       END "                                                                                           );
//    sb.append("                   END "                                                                                               );
//    sb.append("               , :1 + NVL(ximv.expiration_day, 0) ) expiration "                                                       );
//    sb.append("   INTO   :2 "                              );
//// 2017-06-07 K.Kiriu Mod End
    sb.append("   SELECT expiration_type  expiration_type "  ); // �\���敪
    sb.append("         ,expiration_day   expiration_day "   ); // �ܖ�����
    sb.append("         ,expiration_month expiration_month " ); // �ܖ�����(��)
    sb.append("   INTO   lt_expiration_type "                );
    sb.append("         ,lt_expiration_day "                 );
    sb.append("         ,lt_expiration_month "               );
// 2018-02-22 K.Kiriu Mod End
// 2009-02-06 H.Itou Add Start �{�ԏ�Q#1147
//    sb.append("   FROM   xxcmn_item_mst_v ximv "           ); // OPM�i�ڏ��V
    sb.append("   FROM   xxcmn_item_mst2_v ximv "          ); // OPM�i�ڏ��V
// 2009-02-06 H.Itou Add End
// 2018-02-22 K.Kiriu Mod Start
//    sb.append("   WHERE  ximv.item_id = :3     "           ); // �i��ID
//// 2009-02-06 H.Itou Add Start �{�ԏ�Q#1147
//    sb.append("   AND    ximv.start_date_active <= :4 "    ); // �K�p�J�n��
//    sb.append("   AND    ximv.end_date_active   >= :5 "    ); // �K�p�I����
//// 2009-02-06 H.Itou Add End
    sb.append("   WHERE  ximv.item_id            = :1 "    ); // �i��ID
    sb.append("   AND    ximv.start_date_active <= :2 "    ); // �K�p�J�n��
    sb.append("   AND    ximv.end_date_active   >= :3 "    ); // �K�p�I����
// 2018-02-22 K.Kiriu Mod End
    sb.append("   ; "                                      );
// 2009-02-06 H.Itou Add Start �{�ԏ�Q#1147
// 2018-02-22 K.Kiriu Add Start
    sb.append("   :4 := xxcmn_common5_pkg.get_use_by_date( " ); // �ܖ������擾�֐�CALL
    sb.append("            :5 "                              ); // ������
    sb.append("           ,lt_expiration_type "              ); // �\���敪
    sb.append("           ,lt_expiration_day "               ); // �ܖ�����
    sb.append("           ,lt_expiration_month "             ); // �ܖ�����(��)
    sb.append("         ); "                                 );
// 2018-02-22 K.Kiriu Add End
    sb.append("EXCEPTION "                                 );
    sb.append("  WHEN NO_DATA_FOUND THEN "                 );
    sb.append("    NULL; "                                 );
// 2009-02-06 H.Itou Add End
    sb.append("END; "                                      );

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
// 2018-02-22 K.Kiriu Mod Start
//      cstmt.setDate(1, XxcmnUtility.dateValue(productedDate)); // ������
//      cstmt.setInt(3, XxcmnUtility.intValue(itemId));          // �i��ID
//// 2009-02-06 H.Itou Add Start �{�ԏ�Q#1147
//      cstmt.setDate(4, XxcmnUtility.dateValue(productedDate)); // ������
//      cstmt.setDate(5, XxcmnUtility.dateValue(productedDate)); // ������
//// 2009-02-06 H.Itou Add End
      cstmt.setInt(1, XxcmnUtility.intValue(itemId));          // �i��ID
      cstmt.setDate(2, XxcmnUtility.dateValue(productedDate)); // ������
      cstmt.setDate(3, XxcmnUtility.dateValue(productedDate)); // ������
      cstmt.setDate(5, XxcmnUtility.dateValue(productedDate)); // ������
// 2018-02-22 K.Kiriu Mod End

      // �p�����[�^�ݒ�(OUT�p�����[�^)
// 2018-02-22 K.Kiriu Mod Start
//      cstmt.registerOutParameter(2, Types.DATE);               // �ܖ�����
      cstmt.registerOutParameter(4, Types.DATE);               // �ܖ�����
// 2018-02-22 K.Kiriu Mod End

      // PL/SQL���s
      cstmt.execute();

// 2009-02-06 H.Itou Add Start �{�ԏ�Q#1147
      // �ܖ�������NULL�̏ꍇ(�K�p�����ɕi�ڃf�[�^���Ȃ��ꍇ)
// 2018-02-22 K.Kiriu Mod Start
//      if (XxcmnUtility.isBlankOrNull(cstmt.getDate(2)))
      if (XxcmnUtility.isBlankOrNull(cstmt.getDate(4)))
// 2018-02-22 K.Kiriu Mod End
      {
        // �i�ڎ擾���s�G���[
        MessageToken[] tokens = {new MessageToken(XxpoConstants.ITEM_VALUE, itemCode)};
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                               XxpoConstants.XXPO10278,
                               tokens);
      } else
      {
        // �߂�l�擾
// 2018-02-22 K.Kiriu Mod Start
//        useByDate = new Date(cstmt.getDate(2));
        useByDate = new Date(cstmt.getDate(4));
// 2018-02-22 K.Kiriu Mod End
      }
// 2009-02-06 H.Itou Add End

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return useByDate;
  } // getUseByDate

  /*****************************************************************************
   * �w���S���ҏ]�ƈ��R�[�h���擾���܂��B
   * @param trans - �g�����U�N�V����
   * @return String - �w���S���ҏ]�ƈ��R�[�h
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String getPurchaseEmpNumber(
    OADBTransaction trans
  ) throws OAException
  {
    String apiName   = "getPurchaseEmpNumber";
    String   purchaseEmpNumber = null;

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                                                                 );
    sb.append("   SELECT papf.employee_number "                                        );
    sb.append("   INTO   :1 "                                                          );
    sb.append("   FROM  per_all_people_f papf "                                        );
    sb.append("   WHERE papf.person_id  = FND_PROFILE.VALUE('XXPO_PURCHASE_EMP_ID') "  );
    sb.append("   AND   papf.effective_start_date <= TRUNC(SYSDATE) "                  ); // �K�p�J�n��
    sb.append("   AND   papf.effective_end_date   >= TRUNC(SYSDATE); "                 ); // �K�p�I����
    sb.append("END; "                                                                  );

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR); // purchaseEmpNumber

      // PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      purchaseEmpNumber = cstmt.getString(1);

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return purchaseEmpNumber;
  } // getPurchaseEmpNumber
  
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
    // �ύX�Ɋւ���x�����N���A
    trans.setPlsqlState(OADBTransaction.STATUS_UNMODIFIED);
  } // commit

  /***************************************************************************
   * ���[���o�b�N�������s�����\�b�h�ł��B
   * @param trans - �g�����U�N�V����
   * @param savePointName - �Z�[�u�|�C���g��
   ***************************************************************************
   */
  public static void rollBack(
    OADBTransaction trans,
    String savePointName)
  {
    // ���[���o�b�N
    trans.executeCommand("ROLLBACK ");
  } // rollBack
  
  /*****************************************************************************
   * �݌ɃN���[�Y�`�F�b�N���s���܂��B
   * @param trans   - �g�����U�N�V����
   * @param chkDate - ��r���t
   * @return boolean  - �N���[�Y�̏ꍇ true
   *                   - �N���[�Y�O�̏ꍇ false
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean chkStockClose(
    OADBTransaction trans,
    Date chkDate
  ) throws OAException
  {
    String apiName = "chkStockClose"; // API��
    String plSqlRet;                  // PL/SQL�߂�l
    
    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(100);
    sb.append("DECLARE "                                                      );
    sb.append("  lv_close_date VARCHAR2(30); "                                ); // �N���[�Y���t
    sb.append("BEGIN "                                                        );
                 // OPM�݌ɉ�v����CLOSE�N���擾
    sb.append("   lv_close_date := xxcmn_common_pkg.get_opminv_close_period; ");
                 // ��r���t���N���[�Y���t�ȑO�̏ꍇ�AY�F�N���[�Y���Z�b�g
    sb.append("   IF (lv_close_date >= TO_CHAR(:1, 'YYYYMM')) THEN "          ); 
    sb.append("     :2 := 'Y'; "                                              );
                 // ��r���t���N���[�Y���t�ȍ~�̏ꍇ�AN�F�N���[�Y�O���Z�b�g
    sb.append("   ELSE "                                                      );
    sb.append("     :2 := 'N'; "                                              );
    sb.append("   END IF; "                                                   ); 
    sb.append("END; "                                                         );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setDate(1, XxcmnUtility.dateValue(chkDate)); // ���t
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(2, Types.VARCHAR); // �߂�l
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      plSqlRet = cstmt.getString(2);

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    // PL/SQL�߂�l��Y�F�N���[�Y�̏ꍇtrue
    if ("Y".equals(plSqlRet))
    {
      return true;
    
    // PL/SQL�߂�l��N�F�N���[�Y�O�̏ꍇfalse
    } else
    {
      return false;
    }    
  } // chkStockClose

  /*****************************************************************************
   * ���b�g���݊m�F�`�F�b�N���s���܂��B
   * @param trans            - �g�����U�N�V����
   * @param itemId           - �i��ID
   * @param manufacturedDate - ������
   * @param koyuCode         - �ŗL�L��
   * @return boolean  - ���b�g�����݂���ꍇ   true
   *                   - ���b�g�����݂��Ȃ��ꍇ false
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean chkLotMst(
    OADBTransaction trans,
    Number itemId,
    Date   manufacturedDate,
    String koyuCode
  ) throws OAException
  {
    String apiName   = "chkLotMst"; // API��
    String plSqlRet;                // PL/SQL�߂�l
    
    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                               );
    sb.append("   SELECT TO_CHAR(COUNT(1)) "                         ); // ���b�g�J�E���g��
    sb.append("   INTO   :1 "                                        ); 
    sb.append("   FROM   ic_lots_mst ilm "                           ); // OPM���b�g�}�X�^
    sb.append("   WHERE  ilm.item_id    = :2 "                       ); // �i��ID
    sb.append("   AND    ilm.attribute1 = TO_CHAR(:3, 'YYYY/MM/DD') "); // ������
    sb.append("   AND    ilm.attribute2 = :4; "                      ); // �ŗL�L��
    sb.append("END; "                                                );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(itemId));             // �i��ID
      cstmt.setDate(3, XxcmnUtility.dateValue(manufacturedDate)); // ������
      cstmt.setString(4, koyuCode);                               // �ŗL�L��
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR); // ���b�g�J�E���g��
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      plSqlRet = cstmt.getString(1);

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    // PL/SQL�߂�l��0�̏ꍇ false
    if ("0".equals(plSqlRet))
    {
      return false;
    
    // PL/SQL�߂�l��0�ȊO�̏ꍇ true
    } else
    {
      return true;
    }
  } // chkLotMst
// 2016-02-12 S.Yamashita Add Start
  /*****************************************************************************
   * ���b�g�d���`�F�b�N���s���܂��B
   * @param trans            - �g�����U�N�V����
   * @param itemId           - �i��ID
   * @param manufacturedDate - ������
   * @param koyuCode         - �ŗL�L��
   * @param factoryCode      - �H��R�[�h
   * @param useByDate        - �ܖ�����
   * @param changedUseByDate - �ύX�ܖ�����
   * @return boolean  - ���b�g�����݂���ꍇ   true
   *                  - ���b�g�����݂��Ȃ��ꍇ false
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean chkLotFactory(
    OADBTransaction trans,
    Number itemId,
    Date   manufacturedDate,
    String koyuCode,
    String factoryCode
// 2016-05-16 v1.31 S.Yamashita Add Start
   ,Date   useByDate
   ,Date   changedUseByDate
// 2016-05-16 v1.31 S.Yamashita Add End
  ) throws OAException
  {
    String apiName   = "chkLotFactory"; // API��
    String plSqlRet;                   // PL/SQL�߂�l
    
    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                              );
    sb.append("  SELECT TO_CHAR(COUNT(1)) "                         ); // ���b�g�J�E���g��
    sb.append("  INTO   :1 "                                        ); 
    sb.append("  FROM   xxpo_vendor_supply_txns xvst "              ); // �O���o��������
// 2016-05-16 v1.31 S.Yamashita Add Start
    sb.append("        ,ic_lots_mst ilm "                           ); // OPM���b�g�}�X�^
// 2016-05-16 v1.31 S.Yamashita Add End
    sb.append("  WHERE  xvst.item_id    = :2 "                      ); // �i��ID
    sb.append("  AND    xvst.producted_date = :3 "                  ); // ������
    sb.append("  AND    xvst.koyu_code = :4 "                       ); // �ŗL�L��
// 2016-05-16 v1.31 S.Yamashita Mod Start
//    sb.append("  AND    xvst.factory_code = :5; "                   ); // �H��R�[�h
    sb.append("  AND    xvst.factory_code = :5 "                    ); // �H��R�[�h
    sb.append("  AND    ilm.attribute3 = TO_CHAR( :6, 'YYYY/MM/DD' ) " ); // �ύX�ܖ�����
    sb.append("  AND    xvst.lot_id = ilm.lot_id "                  );
    sb.append("  ; "                                                );
// 2016-05-16 v1.31 S.Yamashita Mod End
    sb.append("END; "                                               );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(itemId));             // �i��ID
      cstmt.setDate(3, XxcmnUtility.dateValue(manufacturedDate)); // ������
      cstmt.setString(4, koyuCode);                               // �ŗL�L��
      cstmt.setString(5, factoryCode);                            // �H��R�[�h
// 2016-05-16 v1.31 S.Yamashita Add Start
      if (!XxcmnUtility.isBlankOrNull(changedUseByDate))
      {
        // �ύX�ܖ�������NULL�łȂ��ꍇ
        cstmt.setDate(6, XxcmnUtility.dateValue(changedUseByDate));                     // �ύX�ܖ�����
      }else
      {
        // �ύX�ܖ�������NULL�̏ꍇ
        cstmt.setDate(6, XxcmnUtility.dateValue(useByDate));                           // �ܖ�����
      }
// 2016-05-16 v1.31 S.Yamashita Add End
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR); // ���b�g�J�E���g��
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      plSqlRet = cstmt.getString(1);

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    // PL/SQL�߂�l��0�̏ꍇ(�d�����b�g�����݂��Ȃ��ꍇ) false
    if ("0".equals(plSqlRet))
    {
      return false;
    
    // PL/SQL�߂�l��0�ȊO�̏ꍇ(�d�����b�g�����݂���ꍇ) true
    } else
    {
      return true;
    }
  } // chkLotFactory
// 2016-02-12 S.Yamashita Add End
// 2016-07-06 S.Yamashita Add Start
  /*****************************************************************************
   * �����ܖ������`�F�b�N���s���܂��B
   * @param trans            - �g�����U�N�V����
   * @param itemId           - �i��ID
   * @param manufacturedDate - ������
   * @param koyuCode         - �ŗL�L��
   * @return string   - �`�F�b�NNG�̏ꍇ   �������b�g�̏ܖ�����
   *                  - �`�F�b�NOK�̏ꍇ   null
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String chkUseByDate(
    OADBTransaction trans,
    Number itemId,            // �i��ID
    Date   manufacturedDate,  // ������
    String koyuCode           // �ŗL�L��
  ) throws OAException
  {
    String  apiName       = "chkUseByDate";  // API��
    String  useByDate     = ""; // �ܖ�����
    String  prodClassCode = ""; // ���i�敪
    
    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                    );
    sb.append("  SELECT ilm.attribute3 AS use_by_date "                   ); // �ܖ�����
    sb.append("        ,xicv.prod_class_code AS prod_class_code "         ); // ���i�敪
    sb.append("  INTO   :1 "                                              );
    sb.append("        ,:2 "                                              );
    sb.append("  FROM   ic_lots_mst ilm "                                 ); // ���b�g�}�X�^
    sb.append("        ,xxcmn_item_categories5_v xicv "                   ); // �i�ڃJ�e�S���r���[
    sb.append("  WHERE  xicv.item_id = :3 "                               ); // �i��ID
    sb.append("  AND    xicv.item_id = ilm.item_id(+) "                   );
    sb.append("  AND    ilm.attribute1(+) = TO_CHAR( :4, 'YYYY/MM/DD' ) " ); // ������
    sb.append("  AND    ilm.attribute2(+) = :5 "                          ); // �ŗL�L��
    sb.append("  AND    ROWNUM = 1 "                                      );
    sb.append("  ; "                                                      );
    sb.append("END; "                                                     );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(3, XxcmnUtility.intValue(itemId));             // �i��ID
      cstmt.setDate(4, XxcmnUtility.dateValue(manufacturedDate)); // ������
      cstmt.setString(5, koyuCode);                               // �ŗL�L��
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR); // �ܖ�����
      cstmt.registerOutParameter(2, Types.VARCHAR); // ���i�敪
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      useByDate     = cstmt.getString(1); // �ܖ�����
      prodClassCode = cstmt.getString(2); // ���i�敪

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    // ���i�敪�����[�t�̏ꍇ null
    if ("1".equals(prodClassCode))
    {
      return null;
    
    // ���i�敪���h�����N�̏ꍇ
    } else
    {
      // ���b�g���擾�ł��Ȃ��ꍇ null
      if (XxcmnUtility.isBlankOrNull(useByDate))
      {
        return null;
      }else
      // ���b�g���擾�ł����ꍇ �������b�g�̏ܖ�����
      {
        return useByDate;
      }
    }
  } // chkUseByDate
// 2016-07-06 S.Yamashita Add End
// 2015-10-05 S.Yamashita Add Start
  /*****************************************************************************
   * ���b�g�����擾���܂��B
   * @param  trans            - �g�����U�N�V����
   * @param  itemId           - �i��ID
   * @param  manufacturedDate - ������
   * @param  koyuCode         - �ŗL�L��
   * @param  useByDate        - �ܖ�����
   * @param  changedUseByDate - �ύX�ܖ�����
   * @return HashMap          - ���b�g���
   * @throws OAException      - OA��O
   ****************************************************************************/
  public static HashMap getLotMst(
    OADBTransaction trans,
    Number itemId,
    Date   manufacturedDate,
    String koyuCode
// 2016-05-16 v1.31 S.Yamashita Add Start
   ,Date   useByDate
   ,Date   changedUseByDate
// 2016-05-16 v1.31 S.Yamashita Add End
  ) throws OAException
  {
    String  apiName    = "getLotMst";   // API��
    HashMap retHashMap = new HashMap(); // PL/SQL�߂�l
    
    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                 );
    sb.append("  SELECT ilm.lot_no lot_no "                            ); // ���b�gNo
    sb.append("        ,ilm.lot_id lot_id "                            ); // ���b�gID
    sb.append("        ,ilm.attribute23 lot_status "                   ); // ���b�g�X�e�[�^�X
    sb.append("        ,ilm.attribute22 qt_inspect_req_no "            ); // �i�������˗�No
    sb.append("  INTO   :1 "                                           ); 
    sb.append("        ,:2 "                                           ); 
    sb.append("        ,:3 "                                           ); 
    sb.append("        ,:4 "                                           ); 
    sb.append("  FROM   ic_lots_mst ilm "                              ); // OPM���b�g�}�X�^
    sb.append("  WHERE  ilm.item_id    = :5 "                          ); // �i��ID
    sb.append("  AND    ilm.attribute1 = TO_CHAR( :6, 'YYYY/MM/DD' ) " ); // ������
    sb.append("  AND    ilm.attribute2 = :7 "                         ); // �ŗL�L��
// 2016-05-16 v1.31 S.Yamashita Add Start
    sb.append("  AND   ilm.attribute3  = TO_CHAR( :8, 'YYYY/MM/DD' ); " ); // �ܖ�����
// 2016-05-16 v1.31 S.Yamashita Add End
    sb.append("EXCEPTION "                                             );
    sb.append("  WHEN NO_DATA_FOUND THEN "                             );
    sb.append("    NULL; "                                             );
    sb.append("END; "                                                  );

    // PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(5, XxcmnUtility.intValue(itemId));             // �i��ID
      cstmt.setDate(6, XxcmnUtility.dateValue(manufacturedDate)); // ������
      cstmt.setString(7, koyuCode);                               // �ŗL�L��

// 2016-05-16 v1.31 S.Yamashita Add Start
    if (!XxcmnUtility.isBlankOrNull(changedUseByDate))
    {
      // �ύX�ܖ�������NULL�łȂ��ꍇ
      cstmt.setDate(8, XxcmnUtility.dateValue(changedUseByDate)); // �ύX�ܖ�����
    }else
    {
      // �ύX�ܖ�������NULL�̏ꍇ
      cstmt.setDate(8, XxcmnUtility.dateValue(useByDate));        // �ܖ�����
    }
// 2016-05-16 v1.31 S.Yamashita Add End
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR); // ���b�gNo
      cstmt.registerOutParameter(2, Types.VARCHAR); // ���b�gID
      cstmt.registerOutParameter(3, Types.VARCHAR); // ���b�g�X�e�[�^�X
      cstmt.registerOutParameter(4, Types.VARCHAR); // �i�������˗�No
      
      // PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      retHashMap.put("LotNumber"     , cstmt.getString(1)); // ���b�gNo
      retHashMap.put("LotId"         , cstmt.getString(2)); // ���b�gID
      retHashMap.put("LotStatus"     , cstmt.getString(3)); // ���b�g�X�e�[�^�X
      retHashMap.put("QtInspectReqNo", cstmt.getString(4)); // �i�������˗�No
      
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    // PL/SQL�߂�l
    return retHashMap;
  } // getLotMst
// 2015-10-05 S.Yamashita Add End

  /*****************************************************************************
   * �����\���ʃ`�F�b�N���s���܂��B
   * @param trans             - �g�����U�N�V����
   * @param productedQuantity - ����
   * @param txnsId            - ����ID
   * @return HashMap
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap chkReservedQuantity(
    OADBTransaction trans,
    String          productedQuantity,
    Number          txnsId
  ) throws OAException
  {
    String apiName      = "chkReservedQuantity";
    HashMap paramsRet = new HashMap();
 
    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                                                                );
                 // �ϐ��錾
    sb.append("  ln_can_enc_in_time_qty  NUMBER; "                                                      ); // �L�����x�[�X�����\��
    sb.append("  ln_can_enc_total_qty    NUMBER; "                                                      ); // �������\��
    sb.append("  ln_can_encl_qty         NUMBER; "                                                      ); // �����\��
                 // �J�[�\���錾
    sb.append("  CURSOR xxpo_vendor_supply_txns_cur IS "                                                );
    sb.append("    SELECT xvst.quantity - "                                                             ); 
    sb.append("           TO_NUMBER(:1) * "                                                             ); 
    sb.append("           xvst.conversion_factor  gap_qty "                                             ); // ������  = DB.���� - RN.����
    sb.append("          ,xvst.item_id            item_id "                                             ); // DB.�i��ID
    sb.append("          ,ximv.item_short_name    item_name "                                           ); // DB.�i�ږ�
    sb.append("          ,xvst.lot_id             lot_id "                                              ); // DB.���b�gID
    sb.append("          ,xvst.lot_number         lot_number "                                          ); // DB.���b�g�ԍ�
    sb.append("          ,xvst.location_id        location_id"                                          ); // DB.�[����ID
    sb.append("          ,xilv.description        location_name "                                       ); // DB.�ۊǏꏊ��
    sb.append("    FROM   xxpo_vendor_supply_txns xvst "                                                ); // �O���o��������
    sb.append("          ,xxcmn_item_mst2_v       ximv "                                                ); // OPM�i�ڏ��2V
    sb.append("          ,xxcmn_item_locations_v  xilv "                                                ); // OPM�ۊǏꏊ���V
    sb.append("    WHERE  xvst.txns_id   = :2 "                                                         ); // ����ID
    sb.append("    AND    xvst.item_id   = ximv.item_id "                                               ); // �i��ID
    sb.append("    AND    xvst.location_code = xilv.segment1 "                                          ); // �[����R�[�h    
    sb.append("    AND    ximv.start_date_active <= TRUNC(xvst.manufactured_date) "                     ); // �K�p�J�n��
    sb.append("    AND    ximv.end_date_active   >= TRUNC(xvst.manufactured_date); "                    ); // �K�p�I����    
    sb.append("  xxpo_vendor_supply_txns_rec xxpo_vendor_supply_txns_cur%ROWTYPE; "                     );   
    sb.append("BEGIN "                                                                                  );
                 // DB�̊O���o�������ʂ��擾
    sb.append("  OPEN  xxpo_vendor_supply_txns_cur; "                                                   );
    sb.append("  FETCH xxpo_vendor_supply_txns_cur INTO xxpo_vendor_supply_txns_rec; "                  );
    sb.append("  CLOSE xxpo_vendor_supply_txns_cur; "                                                   );
                 // �L�����x�[�X�����\�����擾
    sb.append("  ln_can_enc_in_time_qty := xxcmn_common_pkg.get_can_enc_in_time_qty( "                  );
    sb.append("                              in_whse_id     => xxpo_vendor_supply_txns_rec.location_id "); // OPM�ۊǑq��ID
    sb.append("                             ,in_item_id     => xxpo_vendor_supply_txns_rec.item_id "    ); // OPM�i��ID
    sb.append("                             ,in_lot_id      => xxpo_vendor_supply_txns_rec.lot_id "     ); // ���b�gID
    sb.append("                             ,in_active_date => SYSDATE                           );"    ); // �L����
                 // �������\�����擾
    sb.append("  ln_can_enc_total_qty   := xxcmn_common_pkg.get_can_enc_total_qty( "                    );
    sb.append("                              in_whse_id     => xxpo_vendor_supply_txns_rec.location_id "); // OPM�ۊǑq��ID
    sb.append("                             ,in_item_id     => xxpo_vendor_supply_txns_rec.item_id "    ); // OPM�i��ID
    sb.append("                             ,in_lot_id      => xxpo_vendor_supply_txns_rec.lot_id );"   ); // ���b�gID
                 // �����\���擾 �L�����x�[�X�����\���Ƒ������\���Ő��̏��Ȃ��ق��������\���Ƃ���B
    sb.append("  IF (ln_can_enc_in_time_qty > ln_can_enc_total_qty) THEN "                              );
    sb.append("      ln_can_encl_qty := ln_can_enc_total_qty; "                                         );
    sb.append("  ELSE "                                                                                 );
    sb.append("      ln_can_encl_qty := ln_can_enc_in_time_qty; "                                       );
    sb.append("  END IF; "                                                                              );
                 // ��������0�ȉ�(���ʂ��ύX����Ă��Ȃ����A���ʂ��ꂽ�ꍇ)�͍������`�F�b�N���s��Ȃ��B
    sb.append("  IF (xxpo_vendor_supply_txns_rec.gap_qty <= 0) THEN "                                   );
    sb.append("    :3 := '1'; "                                                                         );
    sb.append("    :4 := xxpo_vendor_supply_txns_rec.item_name; "                                       );
    sb.append("    :5 := xxpo_vendor_supply_txns_rec.lot_number; "                                      );
    sb.append("    :6 := xxpo_vendor_supply_txns_rec.location_name; "                                   );
                 // �����\���`�F�b�N �����������ʂň����\���𒴂���ꍇ�A�x��
    sb.append("  ELSIF (xxpo_vendor_supply_txns_rec.gap_qty > ln_can_encl_qty) THEN "                   );
    sb.append("    :3 := '2'; "                                                                         );
    sb.append("    :4 := xxpo_vendor_supply_txns_rec.item_name; "                                       );
    sb.append("    :5 := xxpo_vendor_supply_txns_rec.lot_number; "                                      );
    sb.append("    :6 := xxpo_vendor_supply_txns_rec.location_name; "                                   );
                 // �����\���`�F�b�N �����������ʂň����\���𒴂��Ȃ��ꍇ�A����
    sb.append("  ELSE "                                                                                 );
    sb.append("    :3 := '1'; "                                                                         );
    sb.append("    :4 := xxpo_vendor_supply_txns_rec.item_name; "                                       );
    sb.append("    :5 := xxpo_vendor_supply_txns_rec.lot_number; "                                      );
    sb.append("    :6 := xxpo_vendor_supply_txns_rec.location_name; "                                   );
    sb.append("  END IF; "                                                                              );
    sb.append("END; "                                                                                   );

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, productedQuantity); // RN�o��������
      cstmt.setInt(2, XxcmnUtility.intValue(txnsId)); // ����ID
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(3, Types.VARCHAR); // ��������
      cstmt.registerOutParameter(4, Types.VARCHAR); // �i�ږ�
      cstmt.registerOutParameter(5, Types.VARCHAR); // ���b�g�ԍ�
      cstmt.registerOutParameter(6, Types.VARCHAR); // �ۊǏꏊ��
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      paramsRet.put("PlSqlRet", cstmt.getString(3)); // ��������
      paramsRet.put("ItemName", cstmt.getString(4)); // �i�ږ�
      paramsRet.put("LotNumber", cstmt.getString(5)); // ���b�g�ԍ�
      paramsRet.put("LocationName", cstmt.getString(6)); // �ۊǏꏊ��

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return paramsRet;
  } // chkReservedQuantity

  /*****************************************************************************
   * ���[�U�[�����擾���܂��B
   * @param trans            - �g�����U�N�V����
   * @return HashMap         - �[������
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap getUserData(
    OADBTransaction trans
  ) throws OAException
  {
    String apiName  = "getUserData"; // API��

    HashMap retHashMap = new HashMap();  // �߂�l�p

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                             );
    sb.append("  SELECT papf.attribute4          vendor_code "                     ); // �d����R�[�h
    sb.append("        ,papf.attribute3          people_code "                     ); // �]�ƈ��敪
    sb.append("        ,xvv.vendor_id            vendor_id "                       ); // �d����ID
    sb.append("        ,xvv.vendor_short_name    vendor_name "                     ); // �d���於
    sb.append("        ,xvv.product_result_type  product_result_type "             ); // �����^�C�v
    sb.append("        ,xvv.department           department "                      ); // ����
    sb.append("        ,papf.attribute6          factory_code "                    ); // �H��R�[�h
    sb.append("  INTO   :1 "                                                       );
    sb.append("        ,:2 "                                                       );
    sb.append("        ,:3 "                                                       );
    sb.append("        ,:4 "                                                       );
    sb.append("        ,:5 "                                                       );
    sb.append("        ,:6 "                                                       );
    sb.append("        ,:7 "                                                       );
    sb.append("  FROM   fnd_user              fu "                                 ); // ���[�U�[�}�X�^
    sb.append("        ,per_all_people_f      papf "                               ); // �]�ƈ��}�X�^
    sb.append("        ,xxcmn_vendors_v       xvv "                                ); // �d������V
    sb.append("  WHERE  fu.employee_id              = papf.person_id "             ); // �]�ƈ�ID
    sb.append("  AND    papf.attribute4             = xvv.segment1(+) "            ); // �d����R�[�h
    sb.append("  AND    fu.start_date <= TRUNC(SYSDATE) "                          ); // �K�p�J�n��
    sb.append("  AND    ((fu.end_date IS NULL) OR (fu.end_date >= TRUNC(SYSDATE))) " ); // �K�p�I����
    sb.append("  AND    papf.effective_start_date <= TRUNC(SYSDATE) "              ); // �K�p�J�n��
    sb.append("  AND    papf.effective_end_date   >= TRUNC(SYSDATE) "              ); // �K�p�I����
    sb.append("  AND    fu.user_id                  = FND_GLOBAL.USER_ID; "        ); // ���[�U�[ID
    sb.append("END; "                                                              );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR); // �d����R�[�h
      cstmt.registerOutParameter(2, Types.VARCHAR); // �]�ƈ��敪
      cstmt.registerOutParameter(3, Types.INTEGER); // �d����ID
      cstmt.registerOutParameter(4, Types.VARCHAR); // �d���於
      cstmt.registerOutParameter(5, Types.VARCHAR); // �����^�C�v
      cstmt.registerOutParameter(6, Types.VARCHAR); // ����
      cstmt.registerOutParameter(7, Types.VARCHAR); // �H��R�[�h
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      retHashMap.put("VendorCode",        cstmt.getObject(1)); // �d����R�[�h
      retHashMap.put("PeopleCode",        cstmt.getObject(2)); // �]�ƈ��敪
      retHashMap.put("VendorId",          cstmt.getObject(3)); // �d����ID
      retHashMap.put("VendorName",        cstmt.getObject(4)); // �d���於
      retHashMap.put("ProductResultType", cstmt.getObject(5)); // �����^�C�v
      retHashMap.put("Department",        cstmt.getObject(6)); // ����
      retHashMap.put("FactoryCode",       cstmt.getString(7)); // �H��R�[�h

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // getUserData
  
  /*****************************************************************************
   * �݌ɒP�����擾���܂��B
   * @param trans            - �g�����U�N�V����
   * @param params           - �p�����[�^
   * @return String          - �݌ɒP��
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String getStockValue(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName    = "getStockValue"; // API��
    String stockValue = "";    // �݌ɒP��

    // �p�����[�^�l�擾
    String costManageCode    = (String)params.get("CostManageCode");   // �����Ǘ��敪
    String productResultType = (String)params.get("ProductResultType");// �����^�C�v
    String unitPriceCalcCode = (String)params.get("UnitPriceCalcCode");// �d���P�����o���^�C�v
    Number itemId            = (Number)params.get("ItemId");           // �i��ID
    Number vendorId          = (Number)params.get("VendorId");         // �����ID
    Number factoryId         = (Number)params.get("FactoryId");        // �H��ID
    Date   manufacturedDate  = (Date)params.get("ManufacturedDate");   // ���Y��
    Date   productedDate     = (Date)params.get("ProductedDate");      // ������

    // �����Ǘ��敪��1:�W�������̏ꍇ�A�݌ɒP����NULL
    if (XxpoConstants.COST_MANAGE_CODE_N.equals(costManageCode))
    {
      stockValue = null;
    
    // �����Ǘ��敪��0:���ی����̏ꍇ
    } else if (XxpoConstants.COST_MANAGE_CODE_R.equals(costManageCode))
    {
        // �����^�C�v��1:�����݌ɂ̏ꍇ�A�݌ɒP����0
        if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType))
        {
          stockValue = "0";
        
      // �����^�C�v��2:�����d���̏ꍇ�A�d��/�W���P���w�b�_����擾
      } else if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(productResultType))
      {
        // PL/SQL�쐬
        StringBuffer sb = new StringBuffer(1000);
        sb.append("DECLARE "                                                 );
        sb.append("  lt_total_amount  xxpo_price_headers.total_amount%TYPE; ");
        sb.append("BEGIN "                                                   );
        sb.append("  SELECT xph.total_amount    total_amount "               ); // ���󍇌v
        sb.append("  INTO   lt_total_amount "                                );
        sb.append("  FROM   xxpo_price_headers  xph "                        ); // �d����W���P���w�b�_
        sb.append("  WHERE  xph.item_id             = :1 "                   ); // �i��ID
        sb.append("  AND    xph.vendor_id           = :2 "                   ); // �����ID
        sb.append("  AND    xph.factory_id          = :3 "                   ); // �H��ID
        sb.append("  AND    xph.futai_code          = '0' "                  ); // �t�уR�[�h
        sb.append("  AND    xph.price_type          = '1' "                  ); // �}�X�^�敪1:�d��
// 20080702 yoshimoto add Start
        sb.append("  AND    xph.supply_to_code IS NULL "                     ); // �x����R�[�h IS NULL
// 20080702 yoshimoto add End
        sb.append("  AND    (((:4                   = '1') "                 ); // �d���P���������^�C�v��1:�������̏ꍇ�A������������
        sb.append("    AND  (xph.start_date_active <= :5) "                  ); // �K�p�J�n�� <= ������
        sb.append("    AND  (xph.end_date_active   >= :5)) "                 ); // �K�p�I���� >= ������
        sb.append("  OR     ((:4                    = '2') "                 ); // �d���P���������^�C�v��2:�[�����̏ꍇ�A���������Y��
        sb.append("    AND  (xph.start_date_active <= :6) "                  ); // �K�p�J�n�� <= ���Y��
        sb.append("    AND  (xph.end_date_active   >= :6))); "               ); // �K�p�I���� >= ���Y��
        sb.append("  :7 := TO_CHAR(lt_total_amount); "                       );
        sb.append("EXCEPTION "                                               );
        sb.append("  WHEN OTHERS THEN "                                      ); // �f�[�^���Ȃ��ꍇ��0
        sb.append("    :7 := '0'; "                                          );
        sb.append("END; "                                                    );

        //PL/SQL�ݒ�
        CallableStatement cstmt
          = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

        try
        {
          // �p�����[�^�ݒ�(IN�p�����[�^)
          cstmt.setInt(1, XxcmnUtility.intValue(itemId));            // �i��ID
          cstmt.setInt(2, XxcmnUtility.intValue(vendorId));          // �����ID
          cstmt.setInt(3, XxcmnUtility.intValue(factoryId));         // �H��ID
          cstmt.setString(4, unitPriceCalcCode);                     // �d���P�������^�C�v
          cstmt.setDate(5, XxcmnUtility.dateValue(productedDate));   // ������
          cstmt.setDate(6, XxcmnUtility.dateValue(manufacturedDate));// ���Y��
          
          // �p�����[�^�ݒ�(OUT�p�����[�^)
          cstmt.registerOutParameter(7, Types.VARCHAR); // �݌ɒP��
          
          //PL/SQL���s
          cstmt.execute();
          
          // �߂�l�擾
          stockValue = cstmt.getString(7);

        // PL/SQL���s����O�̏ꍇ
        } catch(SQLException s)
        {
          // ���[���o�b�N
          rollBack(trans);
          XxcmnUtility.writeLog(trans,
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
            XxcmnUtility.writeLog(trans,
                                  XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                  s.toString(),
                                  6);
            // �G���[���b�Z�[�W�o��
            throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                  XxcmnConstants.XXCMN10123);
          }
        }
      }
    }
    return stockValue;
  } // getStockValue

  /*****************************************************************************
   * �����ԍ����擾���܂��B
   * @param trans            - �g�����U�N�V����
   * @return String          - �����ԍ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String getPoNumber(
    OADBTransaction trans
  ) throws OAException
  {
    String apiName  = "getPoNumber"; // API��
    String poNumber;  // �����ԍ�
    String errBuf;    // �G���[���b�Z�[�W
    String retCode;   // ���^�[���R�[�h
    String errMsg;    // ���[�U�[�E�G���[�E���b�Z�[�W
    
    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                          );
    sb.append("  xxcmn_common_pkg.get_seq_no( " );
    sb.append("    iv_seq_class  => '2' "       ); // �̔Ԃ���ԍ���\���敪 2:�����ԍ�
    sb.append("   ,ov_seq_no     => :1 "        ); // �����ԍ�
    sb.append("   ,ov_errbuf     => :2 "        ); // �G���[���b�Z�[�W
    sb.append("   ,ov_retcode    => :3 "        ); // ���^�[���R�[�h
    sb.append("   ,ov_errmsg     => :4 ); "     ); // ���[�U�[�E�G���[�E���b�Z�[�W
    sb.append("END; "                           );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR); // �����ԍ�
      cstmt.registerOutParameter(2, Types.VARCHAR); // �G���[���b�Z�[�W
      cstmt.registerOutParameter(3, Types.VARCHAR); // ���^�[���R�[�h
      cstmt.registerOutParameter(4, Types.VARCHAR); // ���[�U�[�E�G���[�E���b�Z�[�W
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      poNumber = cstmt.getString(1); // �����ԍ�
      errBuf   = cstmt.getString(2); // �G���[���b�Z�[�W
      retCode  = cstmt.getString(3); // ���^�[���R�[�h
      errMsg   = cstmt.getString(4); // ���[�U�[�E�G���[�E���b�Z�[�W
      
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return poNumber;
  } // getPoNumber

  /*****************************************************************************
   * ���b�g�ԍ����擾���܂��B
   * @param trans            - �g�����U�N�V����
   * @param itemId           - �p�����[�^
   * @return String          - ���b�g�ԍ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String getLotNumber(
    OADBTransaction trans,
    Number itemId,
    String itemCode
  ) throws OAException
  {
    String apiName = "getLotNumber"; // API��
    String lotNumber;    // ���b�g�ԍ�
    String subLotNumber; // �T�u���b�g�ԍ�
    int returnStatus;   // ���^�[���R�[�h

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                             );
    sb.append("  lv_lot_no     VARCHAR2(5000); "     );
    sb.append("  lv_sublot_no  VARCHAR2(5000); "     );
    sb.append("  ln_lot_status VARCHAR2(5000); "     );
    sb.append("BEGIN "                               );
                 // ���b�g�̔ԃ��[���A�h�I��
    sb.append("  gmi_autolot.generate_lot_number( "  );
    sb.append("    p_item_id        => :1 "          ); // IN:�i��ID
    sb.append("   ,p_in_lot_no      => NULL "        ); // IN:�d����W���P���w�b�_
    sb.append("   ,p_orgn_code      => NULL "        ); // IN:�i��ID
    sb.append("   ,p_doc_id         => NULL "        ); // IN:�����ID
    sb.append("   ,p_line_id        => NULL "        ); // IN:�H��ID
    sb.append("   ,p_doc_type       => NULL "        ); // IN:�t�уR�[�h
    sb.append("   ,p_out_lot_no     => :2 "          ); // OUT:���b�g�ԍ�
    sb.append("   ,p_sublot_no      => :3 "          ); // OUT:�T�u���b�g�ԍ�
    sb.append("   ,p_return_status  => :4); "        ); // OUT:���^�[���R�[�h
    sb.append("END; "                                );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1, XxcmnUtility.intValue(itemId)); // �i��ID
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(2, Types.VARCHAR); // ���b�g�ԍ�
      cstmt.registerOutParameter(3, Types.VARCHAR); // �T�u���b�g�ԍ�
      cstmt.registerOutParameter(4, Types.INTEGER); // ���^�[���R�[�h
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      lotNumber    = cstmt.getString(2); // ���b�g�ԍ�
      subLotNumber = cstmt.getString(3); // �T�u���b�g�ԍ�
      returnStatus = cstmt.getInt(4);    // ���^�[���R�[�h 

      // ���b�g�ԍ���NULL�̏ꍇ�A�G���[
      if (XxcmnUtility.isBlankOrNull(lotNumber))
      {
        //�g�[�N���������܂��B
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_ITEM_NO, itemCode) };
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                               XxpoConstants.XXPO10110, 
                               tokens);        
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return lotNumber;
  } // getLotNumber

  /*****************************************************************************
   * �[��������擾���܂��B
   * @param trans            - �g�����U�N�V����
   * @param locationCode     - �[����R�[�h
   * @return HashMap         - �[������
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap getLocationData(
    OADBTransaction trans,
    String locationCode
  ) throws OAException
  {
    String apiName  = "getLocationData"; // API��

    HashMap retHashMap = new HashMap();  // �߂�l�p

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                    );
    sb.append("  SELECT xilv.inventory_location_id inventory_location_id "); // 1:�[����ID
    sb.append("        ,xilv.whse_code             whse_code "            ); // 2:�q�ɃR�[�h
    sb.append("        ,somb.co_code               co_code "              ); // 3:��ЃR�[�h
    sb.append("        ,somb.orgn_code             orgn_code "            ); // 4:�g�D�R�[�h
    sb.append("        ,haou.location_id           ship_to_location_id "  ); // 5:�[���掖�Ə�ID
    sb.append("        ,xilv.mtl_organization_id   organization_id "      ); // 6:�݌ɑg�DID
// 2008-10-23 H.Itou Add Start T_TE080_BPO_340 �w�E5 �����݌ɊǗ��Ώۃ`�F�b�N�ǉ�
    sb.append("        ,xilv.customer_stock_whse   customer_stock_whse "  ); // 7:�����݌ɊǗ��Ώ�
// 2008-10-23 H.Itou Add End
    sb.append("  INTO   :1 "                                              );
    sb.append("        ,:2 "                                              );
    sb.append("        ,:3 "                                              );
    sb.append("        ,:4 "                                              );
    sb.append("        ,:5 "                                              );
    sb.append("        ,:6 "                                              );
// 2008-10-23 H.Itou Add Start T_TE080_BPO_340 �w�E5 �����݌ɊǗ��Ώۃ`�F�b�N�ǉ�
    sb.append("        ,:7 "                                              );
// 2008-10-23 H.Itou Add End
    sb.append("  FROM   xxcmn_item_locations_v     xilv "                 ); // OPM�ۊǏꏊ���V
    sb.append("        ,ic_whse_mst                iwm "                  ); // OPM�q�Ƀ}�X�^
    sb.append("        ,sy_orgn_mst_b              somb "                 ); // OPM�v�����g�}�X�^
    sb.append("        ,hr_all_organization_units  haou "                 ); // �g�D�}�X�^
    sb.append("  WHERE  xilv.whse_code = iwm.whse_code "                  ); // �q�ɃR�[�h
    sb.append("  AND    iwm.orgn_code  = somb.orgn_code "                 ); // �v�����g�R�[�h
    sb.append("  AND    xilv.mtl_organization_id  = haou.organization_id "); // �g�DID
    sb.append("  AND    xilv.segment1  = :7 "                             ); // �ۊǏꏊ�R�[�h
    sb.append("  AND    haou.date_from <= TRUNC(SYSDATE) "                ); // �K�p�� <= SYSDATE
    sb.append("  AND  ((haou.date_to >= TRUNC(SYSDATE))  "                ); // �K�p�� >= SYSDATE
    sb.append("        OR (haou.date_to IS NULL)); "                      );
    sb.append("END; "                                                     );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(7, locationCode); // �[����R�[�h
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.INTEGER); // �[����ID
      cstmt.registerOutParameter(2, Types.VARCHAR); // �q�ɃR�[�h
      cstmt.registerOutParameter(3, Types.VARCHAR); // ��ЃR�[�h
      cstmt.registerOutParameter(4, Types.VARCHAR); // �g�D�R�[�h
      cstmt.registerOutParameter(5, Types.INTEGER); // �[���掖�Ə�ID
      cstmt.registerOutParameter(6, Types.INTEGER); // �݌ɑg�DID
// 2008-10-23 H.Itou Add Start T_TE080_BPO_340 �w�E5 �����݌ɊǗ��Ώۃ`�F�b�N�ǉ�
      cstmt.registerOutParameter(7, Types.VARCHAR); // �����݌ɊǗ��Ώ�
// 2008-10-23 H.Itou Add End

      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      retHashMap.put("LocationId",       cstmt.getObject(1)); // �[����ID
      retHashMap.put("WhseCode",         cstmt.getObject(2)); // �q�ɃR�[�h
      retHashMap.put("CoCode",           cstmt.getObject(3)); // ��ЃR�[�h
      retHashMap.put("OrgnCode",         cstmt.getObject(4)); // �g�D�R�[�h
      retHashMap.put("ShipToLocationId", cstmt.getObject(5)); // �[���掖�Ə�ID
      retHashMap.put("OrganizationId",   cstmt.getObject(6)); // �݌ɑg�DID
// 2008-10-23 H.Itou Add Start T_TE080_BPO_340 �w�E5 �����݌ɊǗ��Ώۃ`�F�b�N�ǉ�
      retHashMap.put("CustomerStockWhse", cstmt.getObject(7)); // �����݌ɊǗ��Ώ�
// 2008-10-23 H.Itou Add End

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // getLocationData

  /*****************************************************************************
   * �����˗�No���擾���܂��B
   * @param trans            - �g�����U�N�V����
   * @param params     - 
   * @return Object    - �����˗�No
   * @throws OAException - OA��O
   ****************************************************************************/
  public static Object getQtInspectReqNo(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName  = "getQtInspectReqNo"; // API��

    // IN�p�����[�^�擾
    Number itemId  = (Number)params.get("ItemId"); // �i��ID
    Number lotId   = (Number)params.get("LotId");  // ���b�gID
    
    Object qtInspectReqNo = new Object();  // �߂�l�p

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                     );
    sb.append("  SELECT ilm.attribute22 qt_inspect_req_no "); // �����˗�No
    sb.append("  INTO   :1 "                               );
    sb.append("  FROM   ic_lots_mst ilm "                  ); // OPM���b�g�}�X�^
    sb.append("  WHERE  ilm.item_id = :2 "                 ); // �i��ID
    sb.append("  AND    ilm.lot_id = :3; "                 ); // ���b�gID
    sb.append("END; "                                      );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(itemId)); // �i��ID
      cstmt.setInt(3, XxcmnUtility.intValue(lotId));  // ���b�gID
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR);   // �����˗�No
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      qtInspectReqNo = cstmt.getObject(1); // �����˗�No

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return qtInspectReqNo;
  } // getQtInspectReqNo
  
  /*****************************************************************************
   * ���b�g�쐬API���N�����܂��B
   * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @return HashMap
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap insertLotMst(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertLotMst"; // API��

    // IN�p�����[�^�擾
    String itemNo            = (String)params.get("ItemCode");   // �i��
    String lotNo             = (String)params.get("LotNumber");  // ���b�g�ԍ�
    Date productedDate       = (Date)params.get("ProductedDate");// �����N����
    String koyuCode          = (String)params.get("KoyuCode");   // �ŗL�L��
    Date useByDate           = (Date)params.get("UseByDate");    // �ܖ�����
    String stockQty          = (String)params.get("StockQty");   // �݌ɓ���
    String stockValue        = (String)params.get("StockValue"); // �݌ɒP��
    String lotStatus         = (String)params.get("LotStatus");  // ���b�g�X�e�[�^�X
    String vendorCode        = (String)params.get("VendorCode"); // �����R�[�h
    String productResultType = (String)params.get("ProductResultType"); // �����^�C�v
// 2016-05-16 v1.31 S.Yamashita Add Start
    Date changedUseByDate    = (Date)params.get("ChangedUseByDate"); // �ύX�ܖ�����
// 2016-05-16 v1.31 S.Yamashita Add End

    HashMap retHashMap = new HashMap(); // �߂�l
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lr_lot_in              GMIGAPI.lot_rec_typ; "                  );
    sb.append("  lr_lot_out             ic_lots_mst%ROWTYPE; "                  );
    sb.append("  lr_lot_cpg_out         ic_lots_cpg%ROWTYPE; "                  );
    sb.append("  ln_api_version_number  CONSTANT NUMBER := 3.0; "               );
    sb.append("  lb_setup_return_sts    BOOLEAN; "                              );
    sb.append("BEGIN "                                                          );
                 // GMI�nAPI�O���[�o���萔�̐ݒ�
    sb.append("  lb_setup_return_sts  :=  GMIGUTL.Setup(FND_GLOBAL.USER_NAME); "); 
                 // �p�����[�^�쐬
    sb.append("  lr_lot_in.item_no          := :1; "                            ); // �i��
    sb.append("  lr_lot_in.lot_no           := :2; "                            ); // ���b�g�ԍ�
    sb.append("  lr_lot_in.lot_created      := SYSDATE; "                       ); // �쐬��
// 2008-12-24 v.1.6 D.Nihei Add Start �{�ԏ�Q#743
    sb.append("  lr_lot_in.expaction_date   := TO_DATE('2099/12/31', 'YYYY/MM/DD'); "); // �ăe�X�g���t
    sb.append("  lr_lot_in.expire_date      := TO_DATE('2099/12/31', 'YYYY/MM/DD'); "); // �������t
// 2008-12-24 v.1.6 D.Nihei Add End
    sb.append("  lr_lot_in.attribute1       := TO_CHAR(:3,'YYYY/MM/DD'); "      ); // �����N����
    sb.append("  lr_lot_in.attribute2       := :4; "                            ); // �ŗL�L��
    sb.append("  lr_lot_in.attribute3       := TO_CHAR(:5,'YYYY/MM/DD'); "      ); // �ܖ�����
    sb.append("  lr_lot_in.attribute6       := :6; "                            ); // �݌ɓ���
    sb.append("  lr_lot_in.attribute7       := :7; "                            ); // �݌ɒP��
    sb.append("  lr_lot_in.attribute23      := :8; "                            ); // ���b�g�X�e�[�^�X
    sb.append("  lr_lot_in.attribute8       := :9; "                            ); // �����R�[�h
    // �����^�C�v��1:�����݌ɊǗ��̏ꍇ
    if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType)) 
    {
      sb.append("  lr_lot_in.attribute24      := '2'; "                         ); // �쐬�敪

    // �����^�C�v��2:�����d���̏ꍇ
    } else if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(productResultType))
    {
      sb.append("  lr_lot_in.attribute24      := '3'; "                         ); // �쐬�敪
    }    
// 2016-05-16 v1.31 S.Yamashita Add Start
    // �ύX�ܖ��������ݒ肳��Ă���ꍇ���A�ܖ�����!=�ύX�ܖ������̏ꍇ
    if ((!XxcmnUtility.isBlankOrNull(changedUseByDate))
       && (!changedUseByDate.equals(useByDate)))
    {
      sb.append("  lr_lot_in.attribute25      := TO_CHAR(:10,'YYYY/MM/DD'); "   ); // �ύX�ܖ�����
    }else
    {
      sb.append("  lr_lot_in.attribute25      := :10; "                         ); // �ύX�ܖ�����
    }
// 2016-05-16 v1.31 S.Yamashita Add End
                 // API:���b�g�쐬���s
    sb.append("  GMIPAPI.CREATE_LOT(  "                                         );
    sb.append("     p_api_version      => ln_api_version_number "               ); // IN:API�̃o�[�W�����ԍ�
    sb.append("    ,p_init_msg_list    => FND_API.G_FALSE "                     ); // IN:���b�Z�[�W�������t���O
    sb.append("    ,p_commit           => FND_API.G_FALSE "                     ); // IN:�����m��t���O
    sb.append("    ,p_validation_level => FND_API.G_VALID_LEVEL_FULL "          ); // IN:���؃��x��
    sb.append("    ,p_lot_rec          => lr_lot_in "                           ); // IN:�쐬���郍�b�g�����w��
    sb.append("    ,x_ic_lots_mst_row  => lr_lot_out "                          ); // OUT:�쐬���ꂽ���b�g��񂪕ԋp
    sb.append("    ,x_ic_lots_cpg_row  => lr_lot_cpg_out "                      ); // OUT:�쐬���ꂽ���b�g��񂪕ԋp
// 2016-05-16 v1.31 S.Yamashita Mod Start
//    sb.append("    ,x_return_status    => :10 "                                  ); // OUT:�I���X�e�[�^�X( 'S'-����I��, 'E'-��O����, 'U'-�V�X�e����O����)
//    sb.append("    ,x_msg_count        => :11 "                                 ); // OUT:���b�Z�[�W�E�X�^�b�N��
//    sb.append("    ,x_msg_data         => :12); "                               ); // OUT:���b�Z�[�W   
//    sb.append("  :13 := lr_lot_out.lot_id; "                                    ); // ���b�gID  
    sb.append("    ,x_return_status    => :11 "                                  ); // OUT:�I���X�e�[�^�X( 'S'-����I��, 'E'-��O����, 'U'-�V�X�e����O����)
    sb.append("    ,x_msg_count        => :12 "                                 ); // OUT:���b�Z�[�W�E�X�^�b�N��
    sb.append("    ,x_msg_data         => :13); "                               ); // OUT:���b�Z�[�W   
    sb.append("  :14 := lr_lot_out.lot_id; "                                    ); // ���b�gID  
// 2016-05-16 v1.31 S.Yamashita Mod End
    sb.append("END; "                                                           );
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, itemNo);                              // �i�ڃR�[�h
      cstmt.setString(2, lotNo);                               // ���b�g�ԍ�
      cstmt.setDate(3, XxcmnUtility.dateValue(productedDate)); // ������
      cstmt.setString(4, koyuCode);                            // �ŗL�L��
      cstmt.setDate(5, XxcmnUtility.dateValue(useByDate));     // �ܖ�����
      cstmt.setString(6, stockQty);                            // �݌ɓ���
      cstmt.setString(7, stockValue);                          // �݌ɒP��
      cstmt.setString(8, lotStatus);                           // ���b�g�X�e�[�^�X
      cstmt.setString(9, vendorCode);                          // �����R�[�h
// 2016-05-16 v1.31 S.Yamashita Add Start
    // �ύX�ܖ��������ݒ肳��Ă���ꍇ���A�ܖ�����!=�ύX�ܖ������̏ꍇ
    if ((!XxcmnUtility.isBlankOrNull(changedUseByDate))
       && (!changedUseByDate.equals(useByDate)))
    {
      cstmt.setDate(5 , XxcmnUtility.dateValue(changedUseByDate)); // �ܖ�����
      cstmt.setDate(10, XxcmnUtility.dateValue(changedUseByDate)); // �ύX�ܖ�����
    }else
    {
      cstmt.setString(10, ""); // �ύX�ܖ�����
    }
// 2016-05-16 v1.31 S.Yamashita Add End
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
// 2016-05-16 v1.31 S.Yamashita Mod Start
//      cstmt.registerOutParameter(10,  Types.VARCHAR); // ���^�[���X�e�[�^�X
//      cstmt.registerOutParameter(11, Types.INTEGER); // ���b�Z�[�W�J�E���g
//      cstmt.registerOutParameter(12, Types.VARCHAR); // ���b�Z�[�W
//      cstmt.registerOutParameter(13, Types.INTEGER); // ���b�gID
      cstmt.registerOutParameter(11,  Types.VARCHAR); // ���^�[���X�e�[�^�X
      cstmt.registerOutParameter(12, Types.INTEGER); // ���b�Z�[�W�J�E���g
      cstmt.registerOutParameter(13, Types.VARCHAR); // ���b�Z�[�W
      cstmt.registerOutParameter(14, Types.INTEGER); // ���b�gID
// 2016-05-16 v1.31 S.Yamashita Mod End

      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
// 2016-05-16 v1.31 S.Yamashita Mod Start
//      String retStatus = cstmt.getString(10);  // ���^�[���X�e�[�^�X
//      int msgCnt       = cstmt.getInt(11);   // ���b�Z�[�W�J�E���g
//      String msgData   = cstmt.getString(12); // ���b�Z�[�W
      String retStatus = cstmt.getString(11);  // ���^�[���X�e�[�^�X
      int msgCnt       = cstmt.getInt(12);   // ���b�Z�[�W�J�E���g
      String msgData   = cstmt.getString(13); // ���b�Z�[�W
// 2016-05-16 v1.31 S.Yamashita Mod End

      // ����I���̏ꍇ
      if (XxcmnConstants.API_STATUS_SUCCESS.equals(retStatus)) 
      {
        // ���b�gID�A���^�[���R�[�h������Z�b�g
// 2016-05-16 v1.31 S.Yamashita Mod Start
//        retHashMap.put("LotId", cstmt.getObject(13));
        retHashMap.put("LotId", cstmt.getObject(14));
// 2016-05-16 v1.31 S.Yamashita Mod End
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);

      // ����I���łȂ��ꍇ�A�G���[  
      } else
      {
        // API�G���[���o�͂���B
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              msgData,
                              6);
        //�g�[�N������
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                   XxpoConstants.TAB_IC_LOTS_MST) };
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                               XxpoConstants.XXPO10007, 
                               tokens);
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
          XxcmnUtility.writeLog(trans,
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // insertLotMst

  /*****************************************************************************
   * �����݌Ƀg�����U�N�V����API���N�����܂��B
   * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @return String -   XxcmnConstants.RETURN_SUCCESS:1 ����
   *                    XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String insertInventoryPosting(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertInventoryPosting";

    // IN�p�����[�^�擾
    String itemNo            = (String)params.get("ItemCode");          // �i��
    String fromWhseCode      = (String)params.get("WhseCode");          // �q�ɃR�[�h
    String fromLocation      = (String)params.get("LocationCode");      // �����݌ɓ��ɐ�
    String itemUm            = (String)params.get("Uom");               // ����(�P�ʃR�[�h)
    String lotNo             = (String)params.get("LotNumber");         // ���b�g�ԍ�
    String productedQuantity = (String)params.get("ProductedQuantity"); // �o��������
    Number quantity          = (Number)params.get("Quantity");          // ����
    Number conversionFactor  = (Number)params.get("ConversionFactor");  // ���Z����
    Date   transDate         = (Date)params.get("ManufacturedDate");    // ���Y��
    String coCode            = (String)params.get("CoCode");            // ��ЃR�[�h
    String orgnCode          = (String)params.get("OrgnCode");          // �g�D�R�[�h
    Number txnsId            = (Number)params.get("TxnsId");            // ����ID
    String processFlag       = (String)params.get("ProcessFlag");       // �����t���O

    // API�߂�l
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; 

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                                                    );
    sb.append("  lr_qty_in              GMIGAPI.qty_rec_typ; "                              );
    sb.append("  ic_jrnl_out            ic_jrnl_mst%ROWTYPE; "                              );
    sb.append("  ic_adjs_jnl_out1       ic_adjs_jnl%ROWTYPE; "                              );
    sb.append("  ic_adjs_jnl_out2       ic_adjs_jnl%ROWTYPE; "                              );
    sb.append("  ln_api_version_number  CONSTANT NUMBER := 3.0; "                           );
    sb.append("  lb_setup_return_sts    BOOLEAN; "                                          );
    sb.append("  ln_quantity            NUMBER; "                                           );
    sb.append("BEGIN "                                                                      );
                 // GMI�nAPI�O���[�o���萔�̐ݒ�
    sb.append("  lb_setup_return_sts  :=  GMIGUTL.Setup(FND_GLOBAL.USER_NAME); "            ); 
                 // �p�����[�^�쐬
    sb.append("  lr_qty_in.trans_type     := 2;  "                                          ); // ����^�C�v
    sb.append("  lr_qty_in.item_no        := :1; "                                          ); // �i��
    sb.append("  lr_qty_in.from_whse_code := :2; "                                          ); // �q��
    sb.append("  lr_qty_in.item_um        := :3; "                                          ); // �P��
    sb.append("  lr_qty_in.lot_no         := :4; "                                          ); // ���b�g
    sb.append("  lr_qty_in.from_location  := :5; "                                          ); // �ۊǏꏊ
    sb.append("  ln_quantity  := :6; "                                                      ); // �ۊǏꏊ
    sb.append("  IF (:7 = '1') THEN "                                                       ); // �o�^�̏ꍇ�A���ʂ͉�ʏo�������� * ���Z����
    sb.append("    lr_qty_in.trans_qty    := TO_NUMBER(:8) * "                              );
    sb.append("                              :9; "                                          );    
    sb.append("  ELSE "                                                                     ); // �X�V�̏ꍇ�A���ʂ͓o�^�ϐ��� - ��ʏo�������� * ���Z����
    sb.append("    lr_qty_in.trans_qty    := TO_NUMBER(:8) * "                              );
    sb.append("                              :9 "                                           );    
    sb.append("                              - NVL(ln_quantity,0); "                        );
    sb.append("  END IF; "                                                                  ); 
    sb.append("  lr_qty_in.co_code        := :10; "                                         ); // ��ЃR�[�h
    sb.append("  lr_qty_in.orgn_code      := :11; "                                         ); // �g�D�R�[�h
    sb.append("  lr_qty_in.trans_date     := :12; "                                         ); // �����
    sb.append("  lr_qty_in.reason_code    := FND_PROFILE.VALUE('XXPO_CTPTY_INV_RCV_RSN'); " ); // ���R�R�[�h
    sb.append("  lr_qty_in.user_name      := FND_GLOBAL.USER_NAME; "                        ); // ���[�U�[��
    sb.append("  lr_qty_in.attribute1     := TO_CHAR(:13); "                                ); // �\�[�X����ID
// 2008-12-26 H.Itou Add Start ����(�����݌Ɏd��)�Ƌ�ʂ��邽�߁A�O���o�����̏ꍇ��DFF4��Y�𗧂Ă�B
    sb.append("  lr_qty_in.attribute4     := 'Y'; "                                         );
// 2008-12-26 H.Itou Add End
                 // API:�����݌Ƀg�����U�N�V�������s 
    sb.append("  GMIPAPI.INVENTORY_POSTING(  "                                              );
    sb.append("     p_api_version      => ln_api_version_number "                           ); // IN:API�̃o�[�W�����ԍ�
    sb.append("    ,p_init_msg_list    => FND_API.G_FALSE "                                 ); // IN:���b�Z�[�W�������t���O
    sb.append("    ,p_commit           => FND_API.G_FALSE "                                 ); // IN:�����m��t���O
    sb.append("    ,p_validation_level => FND_API.G_VALID_LEVEL_FULL"                       ); // IN:���؃��x��
    sb.append("    ,p_qty_rec          => lr_qty_in "                                       ); // IN:��������݌ɐ��ʏ����w��
    sb.append("    ,x_ic_jrnl_mst_row  => ic_jrnl_out "                                     ); // OUT:�������ꂽ�݌ɐ��ʏ�񂪕ԋp
    sb.append("    ,x_ic_adjs_jnl_row1  => ic_adjs_jnl_out1 "                               ); // OUT:�������ꂽ�݌ɐ��ʏ�񂪕ԋp
    sb.append("    ,x_ic_adjs_jnl_row2  => ic_adjs_jnl_out2 "                               ); // OUT:
    sb.append("    ,x_return_status    => :14 "                                             ); // OUT:�I���X�e�[�^�X( 'S'-����I��, 'E'-��O����, 'U'-�V�X�e����O����)
    sb.append("    ,x_msg_count        => :15 "                                             ); // OUT:���b�Z�[�W�E�X�^�b�N��
    sb.append("    ,x_msg_data         => :16); "                                           ); // OUT:���b�Z�[�W   
    sb.append("END; "                                                                       );
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, itemNo);                                   // �i��
      cstmt.setString(2, fromWhseCode);                             // �q��
      cstmt.setString(3, itemUm);                                   // �P��
      cstmt.setString(4, lotNo);                                    // ���b�g�ԍ�
      cstmt.setString(5, fromLocation);                             // �ۊǏꏊ�R�[�h
// 2009-07-08 H.Itou Mod Start �{�ԏ�Q#1566�Ή� �����_���v�Z�ɓ����B
//      cstmt.setInt(6, XxcmnUtility.intValue(quantity));             // ����
      cstmt.setDouble(6, XxcmnUtility.doubleValue(quantity));             // ����
// 2009-07-08 H.Itou Mod End
      cstmt.setString(7, processFlag);                              // �����t���O
      cstmt.setString(8, productedQuantity);                        // �o��������
      cstmt.setInt(9, XxcmnUtility.intValue(conversionFactor));     // ���Z����
      cstmt.setString(10, coCode);                                  // ��ЃR�[�h
      cstmt.setString(11, orgnCode);                                // �g�D�R�[�h
      cstmt.setDate(12, XxcmnUtility.dateValue(transDate));         // ���Y��        
      cstmt.setInt(13, XxcmnUtility.intValue(txnsId));              // ����ID

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(14, Types.VARCHAR); // ���^�[���R�[�h
      cstmt.registerOutParameter(15, Types.INTEGER); // ���b�Z�[�W�J�E���g
      cstmt.registerOutParameter(16, Types.VARCHAR); // ���b�Z�[�W
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      String retStatus = cstmt.getString(14); // ���^�[���R�[�h
      int msgCnt    = cstmt.getInt(15);       // ���b�Z�[�W�J�E���g
      String msgData   = cstmt.getString(16); // ���b�Z�[�W

      // ����I���̏ꍇ�A�t���O��1:����ɁB
      if (XxcmnConstants.API_STATUS_SUCCESS.equals(retStatus)) 
      {
        // ���^�[���R�[�h������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;

      // ����I���łȂ��ꍇ�A�G���[  
      } else
      {

        // API�G���[���o�͂���B
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              msgData,
                              6);
        //�g�[�N������
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                   XxpoConstants.TAB_IC_TRAN_CMP) };
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                               XxpoConstants.XXPO10007, 
                               tokens);
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
          XxcmnUtility.writeLog(trans,
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // insertInventoryPosting

  /*****************************************************************************
   * ���b�g����API���N�����܂��B
   * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @return String -   XxcmnConstants.RETURN_SUCCESS:1 ����
   *                     XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String insertLotCostAdjustment(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertLotCostAdjustment";

    // IN�p�����[�^�擾
    String coCode   = (String)params.get("CoCode");  // ��ЃR�[�h
    Number itemId   = (Number)params.get("ItemId");  // �i��ID
    String whseCode = (String)params.get("WhseCode");// �q�ɃR�[�h
    Number lotId    = (Number)params.get("LotId");   // ���b�gID
    
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // �߂�l

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                                                                       );
    sb.append("  lr_lc_adjustment_header  GMF_LotCostAdjustment_PUB.Lc_Adjustment_Header_Rec_Type; "           );
    sb.append("  lr_lc_adjustment_dtls    GMF_LOTCOSTADJUSTMENT_PUB.Lc_adjustment_dtls_Tbl_Type; "             );
    sb.append("  ln_api_version_number    CONSTANT NUMBER := 1.0; "                                            );
    sb.append("  lb_setup_return_sts      BOOLEAN; "                                                           );
    sb.append("  lv_ret_status            VARCHAR2(1); "                                                       );
    sb.append("  ln_msg_cnt               NUMBER; "                                                            );
    sb.append("  lv_msg_data              VARCHAR2(5000); "                                                    );
    sb.append("  lv_errbuf                VARCHAR2(5000); "                                                    );
    sb.append("  lv_retcode               VARCHAR2(1); "                                                       );
    sb.append("  lv_errmsg                VARCHAR2(5000); "                                                    );
    sb.append("BEGIN "                                                                                         );    
                 // GMI�nAPI�O���[�o���萔�̐ݒ�
    sb.append("  lb_setup_return_sts  :=  GMIGUTL.Setup(FND_GLOBAL.USER_NAME); "                               ); 
                 // �p�����[�^�쐬
    sb.append("  lr_lc_adjustment_header.co_code          := :1; "                                             ); // 1:��ЃR�[�h
    sb.append("  lr_lc_adjustment_header.cost_mthd_code   := FND_PROFILE.VALUE('XXPO_COST_MTHD_CODE'); "       ); // ���b�g�������@
    sb.append("  lr_lc_adjustment_header.item_id          := :2; "                                             ); // 2:�i��ID
    sb.append("  lr_lc_adjustment_header.whse_code        := :3; "                                             ); // 3:�ۊǏꏊ
    sb.append("  lr_lc_adjustment_header.lot_id           := :4; "                                             ); // 4:���b�gID
    sb.append("  lr_lc_adjustment_header.adjustment_date  := SYSDATE; "                                        ); // 
    sb.append("  lr_lc_adjustment_header.reason_code      := FND_PROFILE.VALUE('XXPO_CTPTY_COST_RSN'); "       ); // ���R�R�[�h
    sb.append("  lr_lc_adjustment_header.delete_mark      := 0; "                                              ); // 
    sb.append("  lr_lc_adjustment_header.user_name        := FND_GLOBAL.USER_NAME; "                           ); // ���[�U�[��
    sb.append("  lr_lc_adjustment_dtls(0).cost_cmpntcls_code := FND_PROFILE.VALUE('XXPO_COST_CMPNTCLS_CODE'); "); // �R���|�[�l���g�敪�R�[�h
    sb.append("  lr_lc_adjustment_dtls(0).cost_analysis_code := FND_PROFILE.VALUE('XXPO_COST_ANALYSIS_CODE'); "); // ���̓R�[�h
    sb.append("  lr_lc_adjustment_dtls(0).adjustment_cost    := 0; "                                           ); // ����
                 // API:���b�g�쐬���s 
    sb.append("  GMF_LotCostAdjustment_PUB.Create_LotCost_Adjustment(  "                                       );
    sb.append("     p_api_version      => ln_api_version_number "                                              ); // IN:API�̃o�[�W�����ԍ�
    sb.append("    ,p_init_msg_list    => FND_API.G_FALSE "                                                    ); // IN:���b�Z�[�W�������t���O
    sb.append("    ,p_commit           => FND_API.G_FALSE "                                                    ); // IN:�����m��t���O
    sb.append("    ,x_return_status    => lv_ret_status "                                                      ); // OUT:�I���X�e�[�^�X( 'S'-����I��, 'E'-��O����, 'U'-�V�X�e����O����)
    sb.append("    ,x_msg_count        => ln_msg_cnt "                                                         ); // OUT:���b�Z�[�W�E�X�^�b�N��
    sb.append("    ,x_msg_data         => lv_msg_data "                                                        ); // OUT:���b�Z�[�W   
    sb.append("    ,p_header_rec       => lr_lc_adjustment_header "                                            ); // IN OUT:�o�^���郍�b�g�����w�b�_�����w��A�ԋp
    sb.append("    ,p_dtl_tbl       => lr_lc_adjustment_dtls); "                                               ); // IN OUT:�o�^���郍�b�g�������׏����w��A�ԋp
                 // �G���[���b�Z�[�W��FND_LOG_MESSAGES�ɏo��
    sb.append("  IF (ln_msg_cnt > 0) THEN "                                                                    ); 
    sb.append("    xxcmn_common_pkg.put_api_log( "                                                             );
    sb.append("       ov_errbuf  => lv_errbuf"                                                                 );
    sb.append("      ,ov_retcode => lv_retcode"                                                                );
    sb.append("      ,ov_errmsg  => lv_errmsg );"                                                              );
    sb.append("  END IF; "                                                                                     );
                 // OUT�p�����[�^�o��
    sb.append("  :5 := lv_ret_status;"                                                                         );
    sb.append("  :6 := ln_msg_cnt;"                                                                            );
    sb.append("  :7 := lv_msg_data;"                                                                           );
    sb.append("END; "                                                                                          );
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, coCode);                     // ��ЃR�[�h
      cstmt.setInt(2, XxcmnUtility.intValue(itemId)); // �i��
      cstmt.setString(3, whseCode);                   // �q�ɃR�[�h
      cstmt.setInt(4, XxcmnUtility.intValue(lotId));  // ���b�gID
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(5, Types.VARCHAR); // ���^�[���R�[�h
      cstmt.registerOutParameter(6, Types.INTEGER); // ���b�Z�[�W��
      cstmt.registerOutParameter(7, Types.VARCHAR); // ���b�Z�[�W
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      String retStatus = cstmt.getString(5); // ���^�[���R�[�h
      int msgCnt    = cstmt.getInt(6);    // ���b�Z�[�W��
      String msgData   = cstmt.getString(7); // ���b�Z�[�W

      // ����I���̏ꍇ�A�t���O��1:����ɁB
      if (XxcmnConstants.API_STATUS_SUCCESS.equals(retStatus)) 
      {
        // ���^�[���R�[�h������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;

      // ����I���łȂ��ꍇ�A�G���[  
      } else
      {
        // API�G���[���o�͂���B
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              msgData,
                              6);
        //�g�[�N������
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                   XxpoConstants.TAB_GMF_LOT_COST_ADJUSTMENTS) };
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                               XxpoConstants.XXPO10007, 
                               tokens);
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
          XxcmnUtility.writeLog(trans,
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // insertLotCostAdjustment

  /*****************************************************************************
   * �O���o�������тɃf�[�^��ǉ����܂��B
   * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @return HashMap -   
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap insertXxpoVendorSupplyTxns(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertXxpoVendorSupplyTxns";

    // IN�p�����[�^�擾
    String txnsType          = (String)params.get("ProductResultType"); // �����^�C�v
    Date   manufacturedDate  = (Date)params.get("ManufacturedDate");    // ���Y��
    Number vendorId          = (Number)params.get("VendorId");          // �����ID
    String vendorCode        = (String)params.get("VendorCode");        // �����
    Number factoryId         = (Number)params.get("FactoryId");         // �H��ID
    String factoryCode       = (String)params.get("FactoryCode");       // �H��R�[�h
    Number locationId        = (Number)params.get("LocationId");        // �[����ID
    String locationCode      = (String)params.get("LocationCode");      // �[����R�[�h
    Number itemId            = (Number)params.get("ItemId");            // �i��ID
    String itemCode          = (String)params.get("ItemCode");          // �i�ڃR�[�h
    Number lotId             = (Number)params.get("LotId");             // ���b�gID    
    String lotNumber         = (String)params.get("LotNumber");         // ���b�g�ԍ�
    Date   productedDate     = (Date)params.get("ProductedDate");       // ������
    String koyuCode          = (String)params.get("KoyuCode");          // �ŗL�L��
    String productedQuantity = (String)params.get("ProductedQuantity"); // �o��������
    Number conversionFactor  = (Number)params.get("ConversionFactor");  // ���Z����
    String uom               = (String)params.get("Uom");               // ����(�P�ʃR�[�h)
    String productedUom      = (String)params.get("ProductedUom");      // �o��������(�P�ʃR�[�h)
    String description       = (String)params.get("Description");       // ���l
// S.Yamashita Ver.1.35 Add Start
    String poNumber          = (String)params.get("PoNumber");          // �����ԍ�
// S.Yamashita Ver.1.35 Add End
    
    // OUT�p�����[�^�p
    HashMap retHashMap = new HashMap();
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                            );
    sb.append("  lt_txns_id xxpo_vendor_supply_txns.txns_id%TYPE; " );
    sb.append("BEGIN "                                              );
    sb.append("  SELECT xxpo_vendor_supply_txns_s1.NEXTVAL  "       );
    sb.append("  INTO   lt_txns_id  "                               );
    sb.append("  FROM   DUAL;  "                                    );
                 // �O���o�������ѓo�^
    sb.append("  INSERT INTO xxpo_vendor_supply_txns xvst( "        );
    sb.append("     xvst.txns_id "                                  ); //   ����ID
    sb.append("    ,xvst.txns_type "                                ); // 1:�����^�C�v
    sb.append("    ,xvst.manufactured_date "                        ); // 2:���Y��
    sb.append("    ,xvst.vendor_id "                                ); // 3:�����ID
    sb.append("    ,xvst.vendor_code "                              ); // 4:�����R�[�h
    sb.append("    ,xvst.factory_id "                               ); // 5:�H��ID
    sb.append("    ,xvst.factory_code "                             ); // 6:�H��R�[�h
    sb.append("    ,xvst.location_id "                              ); // 7:�[����ID
    sb.append("    ,xvst.location_code "                            ); // 8:�[����R�[�h
    sb.append("    ,xvst.item_id "                                  ); // 9:�i��ID
    sb.append("    ,xvst.item_code "                                ); // 10:�i�ڃR�[�h
    sb.append("    ,xvst.lot_id "                                   ); // 11:���b�gID
    sb.append("    ,xvst.lot_number "                               ); // 12:���b�gNo
    sb.append("    ,xvst.producted_date "                           ); // 13:������
    sb.append("    ,xvst.koyu_code "                                ); // 14:�ŗL�L��
    sb.append("    ,xvst.producted_quantity "                       ); // 15:�o��������
    sb.append("    ,xvst.conversion_factor "                        ); // 16:���Z����
    sb.append("    ,xvst.quantity "                                 ); //    ����
    sb.append("    ,xvst.uom "                                      ); // 17:�P�ʃR�[�h
    sb.append("    ,xvst.producted_uom "                            ); // 18:�o�����P�ʃR�[�h
    sb.append("    ,xvst.order_created_flg "                        ); //    �����쐬�t���O
    sb.append("    ,xvst.order_created_date "                       ); //    �����쐬��
    sb.append("    ,xvst.description "                              ); // 19:�E�v
// S.Yamashita Ver.1.35 Add Start
    sb.append("    ,xvst.po_number "                                ); // 20:�����ԍ�
// S.Yamashita Ver.1.35 Add End
    sb.append("    ,xvst.created_by "                               ); //   �쐬��
    sb.append("    ,xvst.creation_date "                            ); //   �쐬��
    sb.append("    ,xvst.last_updated_by "                          ); //   �ŏI�X�V��
    sb.append("    ,xvst.last_update_date "                         ); //   �ŏI�X�V��
    sb.append("    ,xvst.last_update_login) "                       ); //   �ŏI�X�V���O�C��
    sb.append("  VALUES( "                                          );
    sb.append("     lt_txns_id "                                    ); // ����ID
    sb.append("    ,:1 "                                            ); // �����^�C�v  
    sb.append("    ,:2 "                                            ); // ���Y��  
    sb.append("    ,:3 "                                            ); // �����ID  
    sb.append("    ,:4 "                                            ); // �����R�[�h  
    sb.append("    ,:5 "                                            ); // �H��ID  
    sb.append("    ,:6 "                                            ); // �H��R�[�h  
    sb.append("    ,:7 "                                            ); // �[����ID  
    sb.append("    ,:8 "                                            ); // �[����R�[�h  
    sb.append("    ,:9 "                                            ); // �i��ID  
    sb.append("    ,:10 "                                           ); // �i�ڃR�[�h  
    sb.append("    ,:11 "                                           ); // ���b�gID
    sb.append("    ,:12 "                                           ); // ���b�gNo
    sb.append("    ,:13 "                                           ); // ������
    sb.append("    ,:14 "                                           ); // �ŗL�L��
    sb.append("    ,TO_NUMBER(:15) "                                ); // �o��������
    sb.append("    ,:16 "                                           ); // ���Z����
    sb.append("    ,TO_NUMBER(:15) * TO_NUMBER(:16) "               ); // ���� = �o�������� �~ ���Z����
    sb.append("    ,:17 "                                           ); // �P�ʃR�[�h
    sb.append("    ,:18 "                                           ); // �o�����P�ʃR�[�h
    // �����^�C�v��1:�����݌ɊǗ��̏ꍇ
    if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(txnsType)) 
    {
      sb.append("  ,'N' "                                           ); // �����쐬�t���O
      sb.append("  ,NULL "                                          ); // �����쐬��

    // �����^�C�v��2:�����d���̏ꍇ
    } else if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(txnsType))
    {
      sb.append("  ,'Y' "                                           ); // �����쐬�t���O
      sb.append("  ,SYSDATE "                                       ); // �����쐬��     
    }
    sb.append("    ,:19 "                                           ); // �E�v
// S.Yamashita Ver.1.35 Add Start
    sb.append("    ,:20 "                                           ); // �����ԍ�(�̔ԍ�)
// S.Yamashita Ver.1.35 Add End
    sb.append("    ,FND_GLOBAL.USER_ID "                            ); // �쐬��
    sb.append("    ,SYSDATE "                                       ); // �쐬��
    sb.append("    ,FND_GLOBAL.USER_ID "                            ); // �ŏI�X�V��
    sb.append("    ,SYSDATE "                                       ); // �ŏI�X�V��
    sb.append("    ,FND_GLOBAL.LOGIN_ID); "                         ); // �ŏI�X�V���O�C��
                 // OUT�p�����[�^
// S.Yamashita Ver.1.35 Mod Start
//    sb.append("  :20 := '1'; "                                      ); // 1:����I��
//    sb.append("  :21 := lt_txns_id; "                               ); // ����ID
    sb.append("  :21 := '1'; "                                      ); // 1:����I��
    sb.append("  :22 := lt_txns_id; "                               ); // ����ID
// S.Yamashita Ver.1.35 Mod End
    sb.append("END; "                                               );
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1,  txnsType);                               // �����^�C�v
      cstmt.setDate(2,  XxcmnUtility.dateValue(manufacturedDate)); // ���Y��
      cstmt.setInt(3,  XxcmnUtility.intValue(vendorId));           // �����ID
      cstmt.setString(4,  vendorCode);                             // �����
      cstmt.setInt(5,  XxcmnUtility.intValue(factoryId));          // �H��ID
      cstmt.setString(6,  factoryCode);                            // �H��R�[�h
      cstmt.setInt(7,  XxcmnUtility.intValue(locationId));         // �[����ID
      cstmt.setString(8,  locationCode);                           // �[����R�[�h
      cstmt.setInt(9,  XxcmnUtility.intValue(itemId));             // �i��ID
      cstmt.setString(10, itemCode);                               // �i�ڃR�[�h
      cstmt.setInt(11, XxcmnUtility.intValue(lotId));              // ���b�gID
      cstmt.setString(12, lotNumber);                              // ���b�g�ԍ�
      cstmt.setDate(13, XxcmnUtility.dateValue(productedDate));    // ������
      cstmt.setString(14, koyuCode);                               // �ŗL�L��
      cstmt.setString(15, productedQuantity);                      // �o��������
      cstmt.setInt(16, XxcmnUtility.intValue(conversionFactor));   // ���Z����
      cstmt.setString(17, uom);                                    // ����(�P�ʃR�[�h)
      cstmt.setString(18, productedUom);                           // �o��������(�P�ʃR�[�h)
      cstmt.setString(19, description);                            // ���l
// S.Yamashita Ver.1.35 Add Start
      cstmt.setString(20, poNumber);                               // �����ԍ�
// S.Yamashita Ver.1.35 Add End
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
// S.Yamashita Ver.1.35 Mod Start
//      cstmt.registerOutParameter(20, Types.VARCHAR);   // ���^�[���R�[�h
//      cstmt.registerOutParameter(21, Types.INTEGER);   // ����ID
      cstmt.registerOutParameter(21, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(22, Types.INTEGER);   // ����ID
// S.Yamashita Ver.1.35 Mod End
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
// S.Yamashita Ver.1.35 Mod Start
//      String retFlag = cstmt.getString(20);
      String retFlag = cstmt.getString(21);
// S.Yamashita Ver.1.35 Mod End

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // ���^�[���R�[�h�F������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);
// S.Yamashita Ver.1.35 Mod Start
//        retHashMap.put("TxnsId", cstmt.getObject(21));
        retHashMap.put("TxnsId", cstmt.getObject(22));
// S.Yamashita Ver.1.35 Mod End
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //�g�[�N������
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_XXPO_VENDOR_SUPPLY_TXNS) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // insertXxpoVendorSupplyTxns

  /*****************************************************************************
   * �����w�b�_�A�h�I���Ƀf�[�^��ǉ����܂��B
   * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @return String - XxcmnConstants.RETURN_SUCCESS:1 ����
   *                   XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String insertXxpoHeadersAll(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertXxpoHeadersAll";

    // IN�p�����[�^�擾
    String poHeaderNumber    = (String)params.get("PoNumber");       // �����ԍ�
    Date   orderCreatedDate  = (Date)params.get("ManufacturedDate"); // ���Y��

    // OUT�p�����[�^�p
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // �߂�l

    // �w���S���ҏ]�ƈ��R�[�h���擾���܂�
    String purchaseEmpNumber = getPurchaseEmpNumber(trans);
  
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                           );
                 // �����w�b�_(�A�h�I��)�o�^
    sb.append("  INSERT INTO xxpo_headers_all xha( "             );
    sb.append("     xha.xxpo_header_id   "                       ); // �����w�b�_(�A�h�I��ID)
    sb.append("    ,xha.po_header_number   "                     ); // 1:�����ԍ�
    sb.append("    ,xha.order_created_by_code   "                ); // �쐬�҃R�[�h
    sb.append("    ,xha.order_created_date   "                   ); // 2:�쐬��
    sb.append("    ,xha.order_approved_flg   "                   ); // ���������t���O
    sb.append("    ,xha.purchase_approved_flg   "                ); // �d�������t���O
    sb.append("    ,xha.created_by   "                           ); // �쐬��
    sb.append("    ,xha.creation_date   "                        ); // �쐬��
    sb.append("    ,xha.last_updated_by   "                      ); // �ŏI�X�V��
    sb.append("    ,xha.last_update_date   "                     ); // �ŏI�X�V��
    sb.append("    ,xha.last_update_login)   "                   ); // �ŏI�X�V���O�C��
    sb.append("  VALUES( "                                       );
    sb.append("     xxpo_headers_all_s1.NEXTVAL "                ); // �����w�b�_(�A�h�I��ID)
    sb.append("    ,:1 "                                         ); // �����ԍ�  
    sb.append("    ,:2 "                                         ); // �쐬�҃R�[�h  
    sb.append("    ,:3 "                                         ); // �쐬��  
    sb.append("    ,'N' "                                        ); // ���������t���O  
    sb.append("    ,'N' "                                        ); // �d�������t���O  
    sb.append("    ,FND_GLOBAL.USER_ID "                         ); // �쐬��
    sb.append("    ,SYSDATE "                                    ); // �쐬��
    sb.append("    ,FND_GLOBAL.USER_ID "                         ); // �ŏI�X�V��
    sb.append("    ,SYSDATE "                                    ); // �ŏI�X�V��
    sb.append("    ,FND_GLOBAL.LOGIN_ID); "                      ); // �ŏI�X�V���O�C��
                 // OUT�p�����[�^
    sb.append("  :4 := '1'; "                                    ); // 1:����I��
    sb.append("END; "                                            );

    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1,  poHeaderNumber);                         // �����ԍ�
      cstmt.setString(2,  purchaseEmpNumber);                      // �w���S���ҏ]�ƈ��R�[�h
      cstmt.setDate(3,  XxcmnUtility.dateValue(orderCreatedDate)); // ���Y��
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(4, Types.VARCHAR);   // ���^�[���R�[�h
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      retFlag = cstmt.getString(4); // ���^�[���R�[�h

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        retFlag = XxcmnConstants.RETURN_SUCCESS;
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //�g�[�N������
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_XXPO_HEADERS_ALL) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }

    return retFlag;
  } // insertXxpoHeadersAll

  /*****************************************************************************
   * �����w�b�_�I�[�v��IF�Ƀf�[�^��ǉ����܂��B
   * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @return String - XxcmnConstants.RETURN_SUCCESS:1 ����
   *                   XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String insertPoHeadersIf(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertPoHeadersIf";

    // IN�p�����[�^�擾
    String poHeaderNumber   = (String)params.get("PoNumber");         // �����ԍ�
    Number vendorId         = (Number)params.get("VendorId");         // �����ID
    Number vendorSiteId     = (Number)params.get("FactoryId");        // �H��ID
    Number shipToLocationId = (Number)params.get("ShipToLocationId"); // �[����ID
    Date   manufacturedDate = (Date)params.get("ManufacturedDate");   // ���Y��
    String locationCode     = (String)params.get("LocationCode");     // �[����R�[�h
    String department       = (String)params.get("Department");       // ����

    // OUT�p�����[�^�p
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // �߂�l

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                 );
                 // �����w�b�_�I�[�v��IF�o�^
    sb.append("  INSERT INTO po_headers_interface phi  ( "             ); // �����w�b�_�I�[�v��IF
    sb.append("     phi.interface_header_id "                          ); //   IF�w�b�_ID
    sb.append("    ,phi.batch_id "                                     ); // 1:�o�b�`ID 
    sb.append("    ,phi.process_code "                                 ); //   ����
    sb.append("    ,phi.action "                                       ); //   ����
    sb.append("    ,phi.org_id "                                       ); //   �c�ƒP��ID
    sb.append("    ,phi.document_type_code "                           ); //   �����^�C�v
    sb.append("    ,phi.document_num "                                 ); // 1:�����ԍ�
    sb.append("    ,phi.agent_id "                                     ); //   �w���S����ID
    sb.append("    ,phi.vendor_id "                                    ); // 2:�d����ID
    sb.append("    ,phi.vendor_site_id "                               ); // 3:�d����T�C�gID
    sb.append("    ,phi.ship_to_location_id "                          ); // 4:�[���掖�Ə�ID
    sb.append("    ,phi.bill_to_location_id "                          ); //   �����掖�Ə�ID
    sb.append("    ,phi.approval_status "                              ); //   ���F�X�e�[�^�X
    sb.append("    ,phi.attribute1 "                                   ); //   �X�e�[�^�X
    sb.append("    ,phi.attribute2 "                                   ); //   �d���揳���v�t���O
    sb.append("    ,phi.attribute4 "                                   ); // 5:�[����
    sb.append("    ,phi.attribute5 "                                   ); // 6:�[����R�[�h
    sb.append("    ,phi.attribute6 "                                   ); //   �����敪
    sb.append("    ,phi.attribute10 "                                  ); // 7:�����R�[�h
    sb.append("    ,phi.attribute11 "                                  ); //   �����敪
    sb.append("    ,phi.load_sourcing_rules_flag "                     ); //   �\�[�X���[���쐬�t���O
    sb.append("    ,phi.created_by "                                   ); //   �쐬��
    sb.append("    ,phi.creation_date "                                ); //   �쐬��
    sb.append("    ,phi.last_updated_by "                              ); //   �ŏI�X�V��
    sb.append("    ,phi.last_update_date "                             ); //   �ŏI�X�V��
    sb.append("    ,phi.last_update_login) "                           ); //   �ŏI�X�V���O�C��
    sb.append("  VALUES( "                                             );
    sb.append("     po_headers_interface_s.NEXTVAL "                   ); // IF�w�b�_ID
    sb.append("    ,TO_CHAR(po_headers_interface_s.CURRVAL) ||  :1 "   ); // �o�b�`ID = IF�w�b�_ID || �����ԍ�
    sb.append("    ,'PENDING' "                                        ); // ����
    sb.append("    ,'ORIGINAL' "                                       ); // ����
    sb.append("    ,FND_PROFILE.VALUE('ORG_ID') "                      ); // �c�ƒP��ID
    sb.append("    ,'STANDARD' "                                       ); // �����^�C�v
    sb.append("    ,:1 "                                               ); // �����ԍ�(�����ԍ�)
    sb.append("    ,FND_PROFILE.VALUE('XXPO_PURCHASE_EMP_ID') "        ); // �w���S����ID
    sb.append("    ,:2 "                                               ); // �d����ID
    sb.append("    ,:3 "                                               ); // �d����T�C�gID
    sb.append("    ,:4 "                                               ); // �[���掖�Ə�ID
    sb.append("    ,FND_PROFILE.VALUE('XXPO_BILL_TO_LOCATION_ID') "    ); // �����掖�Ə�ID
    sb.append("    ,'APPROVED' "                                       ); // ���F�X�e�[�^�X
    sb.append("    ,'20' "                                             ); // �X�e�[�^�X
    sb.append("    ,'N' "                                              ); // �d���揳���v�t���O
    sb.append("    ,TO_CHAR(:5,'YYYY/MM/DD') "                         ); // �[����
    sb.append("    ,:6 "                                               ); // �[����R�[�h
    sb.append("    ,'1' "                                              ); // �����敪
    sb.append("    ,:7 "                                               ); // �����R�[�h
    sb.append("    ,'1' "                                              ); // �����敪 1:�V�K
    sb.append("    ,'N' "                                              ); // �\�[�X���[���쐬�t���O
    sb.append("    ,FND_GLOBAL.USER_ID "                               ); // �쐬��
    sb.append("    ,SYSDATE "                                          ); // �쐬��
    sb.append("    ,FND_GLOBAL.USER_ID "                               ); // �ŏI�X�V��
    sb.append("    ,SYSDATE "                                          ); // �ŏI�X�V��
    sb.append("    ,FND_GLOBAL.LOGIN_ID); "                            ); // �ŏI�X�V���O�C��
                 // OUT�p�����[�^
    sb.append("  :8 := '1'; "                                          ); // 1:����I��
    sb.append("END; "                                                  );

    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, poHeaderNumber);                         // �����ԍ�
      cstmt.setInt(2, XxcmnUtility.intValue(vendorId));           // �����ID
      cstmt.setInt(3, XxcmnUtility.intValue(vendorSiteId));       // �H��ID
      cstmt.setInt(4, XxcmnUtility.intValue(shipToLocationId));   // �[����ID
      cstmt.setDate(5, XxcmnUtility.dateValue(manufacturedDate)); // ���Y��
      cstmt.setString(6, locationCode);                           // �[����R�[�h
      cstmt.setString(7, department);                             // ����
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(8, Types.VARCHAR);   // ���^�[���R�[�h
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      retFlag = cstmt.getString(8); // ���^�[���R�[�h

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // ���^�[���R�[�h�F����A����ID���Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //�g�[�N������
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_PO_HEADERS_INTERFACE) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // insertPoHeadersIf 

  /*****************************************************************************
   * �������׃I�[�v��IF�Ƀf�[�^��ǉ����܂��B
   * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @return String - XxcmnConstants.RETURN_SUCCESS:1 ����
   *                   XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String insertPoLinesIf(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertPoLinesIf";

    // IN�p�����[�^�擾
    String poHeaderNumber    = (String)params.get("PoNumber");          // �����ԍ�
    Number itemId            = (Number)params.get("InventoryItemId");   // INV�i��ID
    String uomCode           = (String)params.get("Uom");               // �P�ʃR�[�h
    String productedQuantity = (String)params.get("ProductedQuantity"); // �o��������
    Number conversionFactor  = (Number)params.get("ConversionFactor");  // ���Z����    
// 2008-06-18 H.Itou MOD START
//    String unitPrice         = (String)params.get("StockValue");        // �݌ɒP��    
    String unitPrice         = getTotalAmount(trans, params);           // ���󍇌v
// 2008-06-18 H.Itou MOD END
    Date   promisedDate      = (Date)params.get("ManufacturedDate");    // ���Y��
    String lotNumber         = (String)params.get("LotNumber");         // ���b�g�ԍ�
    String factoryCode       = (String)params.get("FactoryCode");       // �H��R�[�h
    String stockQty          = (String)params.get("StockQty");          // �݌ɓ���
    String productedUom      = (String)params.get("ProductedUom");      // �o�������ʒP�ʃR�[�h
    Number organizationId    = (Number)params.get("OrganizationId");    // �݌ɑg�DID

    // OUT�p�����[�^�p
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // �߂�l

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
// 2008-07-11 D.Nihei ADD START
    sb.append("DECLARE "                    );
    sb.append("  lt_quantity      po_lines_interface.quantity%TYPE; " ); // ����
    sb.append("  lt_po_quantity   po_lines_interface.line_attribute11%TYPE; " ); // ��������
    sb.append("  ln_unit_price    NUMBER; " );
    sb.append("  ln_kobiki_price  NUMBER; " );
    sb.append("  ln_kobiki_amount NUMBER; " );
// 2008-07-11 D.Nihei ADD END
    sb.append("BEGIN "                                          );
// 2008-07-11 D.Nihei ADD START
    sb.append("  lt_po_quantity   := :1;                              "); // ��������
    sb.append("  lt_quantity      := TO_NUMBER(lt_po_quantity) * :2;  "); // ����
    sb.append("  ln_unit_price    := :3;                              "); // �P��
    sb.append("  ln_kobiki_price  := ln_unit_price * (100 - 0) / 100; "); // ������P��
    sb.append("  ln_kobiki_amount := ln_kobiki_price * lt_quantity;   "); // ��������z
// 2008-07-11 D.Nihei ADD END
                 // �������׃I�[�v��IF�o�^
    sb.append("  INSERT INTO po_lines_interface pli  ("         ); // �������׃I�[�v��IF
    sb.append("     pli.interface_line_id "                     ); //    IF����ID
    sb.append("    ,pli.interface_header_id "                   ); //    IF�w�b�_ID
    sb.append("    ,pli.line_num "                              ); //    ���הԍ�
    sb.append("    ,pli.shipment_num "                          ); //    �[���ԍ�
    sb.append("    ,pli.line_type_id "                          ); //    ���׃^�C�vID
    sb.append("    ,pli.item_id "                               ); //  1:�i��ID
    sb.append("    ,pli.uom_code "                              ); //  2:�P��
    sb.append("    ,pli.quantity "                              ); //    ���� 3:�o�������ʁ~ 4:���Z����
    sb.append("    ,pli.unit_price "                            ); //  5:���i
    sb.append("    ,pli.promised_date "                         ); //  6:�[����
    sb.append("    ,pli.line_attribute1 "                       ); //  7:���b�g�ԍ�
    sb.append("    ,pli.line_attribute2 "                       ); //  8:�H��R�[�h
    sb.append("    ,pli.line_attribute3 "                       ); //    �t�уR�[�h
    sb.append("    ,pli.line_attribute4 "                       ); //  9:�݌ɓ���
    sb.append("    ,pli.line_attribute8 "                       ); //  5:�d���艿
    sb.append("    ,pli.line_attribute10 "                      ); // 10:�����P��
    sb.append("    ,pli.line_attribute11 "                      ); //  3:��������(�o��������)
    sb.append("    ,pli.line_attribute13 "                      ); //    ���ʊm��t���O
    sb.append("    ,pli.line_attribute14 "                      ); //    ���z�m��t���O
// 2008-07-11 D.Nihei ADD START
    sb.append("    ,pli.shipment_attribute2 "                   ); //    ������P��
// 2008-07-11 D.Nihei ADD END
    sb.append("    ,pli.shipment_attribute3 "                   ); //    ���K�敪
    sb.append("    ,pli.shipment_attribute6 "                   ); //    ���ۋ��敪
// 2008-07-11 D.Nihei ADD START
    sb.append("    ,pli.shipment_attribute9 "                   ); //    ��������z
// 2008-07-11 D.Nihei ADD END
    sb.append("    ,pli.ship_to_organization_id "               ); //  11:�݌ɑg�DID(����)
    sb.append("    ,pli.created_by "                            ); //    �쐬��
    sb.append("    ,pli.creation_date "                         ); //    �쐬��
    sb.append("    ,pli.last_updated_by "                       ); //    �ŏI�X�V��
    sb.append("    ,pli.last_update_date "                      ); //    �ŏI�X�V��
    sb.append("    ,pli.last_update_login) "                    ); //    �ŏI�X�V���O�C��
    sb.append("  VALUES( "                                      );
    sb.append("     po_lines_interface_s.NEXTVAL  "             ); // IF����ID
    sb.append("    ,po_headers_interface_s.CURRVAL "            ); // IF�w�b�_ID
    sb.append("    ,1 "                                         ); // ���הԍ�
    sb.append("    ,1 "                                         ); // �[���ԍ�
    sb.append("    ,FND_PROFILE.VALUE('XXPO_PO_LINE_TYPE_ID') " ); // ���׃^�C�vID
// 2008-07-11 D.Nihei MOD START
//    sb.append("    ,:1 "                                        ); // �i��ID
//    sb.append("    ,:2 "                                        ); // �P�ʃR�[�h
//    sb.append("    ,TO_NUMBER(:3) * :4 "                        ); // ����
//    sb.append("    ,:5  "                                       ); // ���i
//    sb.append("    ,:6  "                                       ); // �[����
//    sb.append("    ,:7  "                                       ); // ���b�g�ԍ�
//    sb.append("    ,:8  "                                       ); // �H��R�[�h
//    sb.append("    ,0   "                                       ); // �t�уR�[�h
//    sb.append("    ,:9  "                                       ); // �݌ɓ���
//    sb.append("    ,:5  "                                       ); // �d���艿
//    sb.append("    ,:10 "                                       ); // �����P��
//    sb.append("    ,:3  "                                       ); // ��������
//    sb.append("    ,'N' "                                       ); // ���ʊm��t���O
//    sb.append("    ,'N' "                                       ); // ���z�m��t���O
//    sb.append("    ,'3'  "                                      ); // ���K�敪
//    sb.append("    ,'3'  "                                      ); // ���ۋ��敪
//    sb.append("    ,:11  "                                      ); // �݌ɑg�DID(����)
    sb.append("    ,:4  "                                       ); // �i��ID
    sb.append("    ,:5  "                                       ); // �P��
    sb.append("    ,lt_quantity "                               ); // ����
    sb.append("    ,ln_unit_price "                             ); // ���i
    sb.append("    ,:6  "                                       ); // �[����
    sb.append("    ,:7  "                                       ); // ���b�g�ԍ�
    sb.append("    ,:8  "                                       ); // �H��R�[�h
    sb.append("    ,'0' "                                       ); // �t�уR�[�h
    sb.append("    ,:9  "                                       ); // �݌ɓ���
    sb.append("    ,ln_unit_price "                             ); // �d���艿
    sb.append("    ,:10 "                                       ); // �����P��
    sb.append("    ,lt_po_quantity "                            ); // ��������
    sb.append("    ,'N' "                                       ); // ���ʊm��t���O
    sb.append("    ,'N' "                                       ); // ���z�m��t���O
    sb.append("    ,ln_kobiki_price "                           ); // ������P��
    sb.append("    ,'3' "                                       ); // ���K�敪
    sb.append("    ,'3' "                                       ); // ���ۋ��敪
    sb.append("    ,ln_kobiki_amount "                          ); // ��������z
    sb.append("    ,:11 "                                       ); // �݌ɑg�DID(����)
// 2008-07-11 D.Nihei MOD END
    sb.append("    ,FND_GLOBAL.USER_ID "                        ); // �쐬��
    sb.append("    ,SYSDATE "                                   ); // �쐬��
    sb.append("    ,FND_GLOBAL.USER_ID "                        ); // �ŏI�X�V��
    sb.append("    ,SYSDATE "                                   ); // �ŏI�X�V��
    sb.append("    ,FND_GLOBAL.LOGIN_ID); "                     ); // �ŏI�X�V���O�C��
                 // OUT�p�����[�^
    sb.append("  :12 := '1'; "                                  ); // 1:����I��
    sb.append("END; "                                           );

    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
// 2008-07-11 D.Nihei MOD START
//      cstmt.setInt(1, XxcmnUtility.intValue(itemId));             // �i��ID
//      cstmt.setString(2, uomCode);                                // �P�ʃR�[�h
//      cstmt.setString(3, productedQuantity);                      // �o��������
//      cstmt.setInt(4, XxcmnUtility.intValue(conversionFactor));   // ���Z����    
//      cstmt.setString(5, unitPrice);                              // �݌ɒP��    
//      cstmt.setDate(6, XxcmnUtility.dateValue(promisedDate));     // ���Y��
//      cstmt.setString(7, lotNumber);                              // ���b�g�ԍ�
//      cstmt.setString(8, factoryCode);                            // �H��R�[�h
//      cstmt.setString(9, stockQty);                               // �݌ɓ���
//      cstmt.setString(10, productedUom);                          // �o�������ʒP�ʃR�[�h
//      cstmt.setInt(11, XxcmnUtility.intValue(organizationId));    // �݌ɑg�DID(����)
//      
//      // �p�����[�^�ݒ�(OUT�p�����[�^)
//      cstmt.registerOutParameter(12, Types.VARCHAR);   // ���^�[���R�[�h
      int i = 1;
      cstmt.setString(i++, productedQuantity);                      // �o��������
      cstmt.setInt(i++, XxcmnUtility.intValue(conversionFactor));   // ���Z����    
      cstmt.setString(i++, unitPrice);                              // �݌ɒP��    
      cstmt.setInt(i++, XxcmnUtility.intValue(itemId));             // �i��ID
      cstmt.setString(i++, uomCode);                                // �P��
      cstmt.setDate(i++, XxcmnUtility.dateValue(promisedDate));     // ���Y��
      cstmt.setString(i++, lotNumber);                              // ���b�g�ԍ�
      cstmt.setString(i++, factoryCode);                            // �H��R�[�h
      cstmt.setString(i++, stockQty);                               // �݌ɓ���
      cstmt.setString(i++, productedUom);                           // �o�������ʒP�ʃR�[�h
      cstmt.setInt(i++, XxcmnUtility.intValue(organizationId));     // �݌ɑg�DID(����)
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(i++, Types.VARCHAR);   // ���^�[���R�[�h
// 2008-07-11 D.Nihei MOD END
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      retFlag = cstmt.getString(12); // ���^�[���R�[�h

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // ���^�[���R�[�h������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //�g�[�N������
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_PO_LINES_INTERFACE) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // insertPoLinesIf 

  /*****************************************************************************
   * �������׃I�[�v��IF�Ƀf�[�^��ǉ����܂��B
   * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @return String - XxcmnConstants.RETURN_SUCCESS:1 ����
   *                   XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String insertPoDistributionsIf(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertPoDistributionsIf";

    // IN�p�����[�^�擾
    String productedQuantity = (String)params.get("ProductedQuantity"); // �o��������
    Number conversionFactor  = (Number)params.get("ConversionFactor");  // ���Z����    

    // OUT�p�����[�^�p
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // �߂�l

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                          );
                 // �������׃I�[�v��IF�o�^
    sb.append("  INSERT INTO po_distributions_interface pdi ( " ); // �������׃I�[�v��IF
    sb.append("     pdi.interface_header_id "                   ); // IF�w�b�_ID
    sb.append("    ,pdi.interface_line_id "                     ); // IF����ID
    sb.append("    ,pdi.interface_distribution_id "             ); // IF��������ID
    sb.append("    ,pdi.distribution_num "                      ); // ���הԍ�
    sb.append("    ,pdi.quantity_ordered "                      ); // ���� 1:�o�������ʁ~ 2:���Z����
    sb.append("    ,pdi.created_by "                            ); // �쐬��
    sb.append("    ,pdi.creation_date "                         ); // �쐬��
    sb.append("    ,pdi.last_updated_by "                       ); // �ŏI�X�V��
    sb.append("    ,pdi.last_update_date "                      ); // �ŏI�X�V��
    sb.append("    ,pdi.last_update_login "                     ); // �ŏI�X�V���O�C��
    sb.append("    ,pdi.recovery_rate) "                        ); // 
    sb.append("  VALUES( "                                      );
    sb.append("     po_headers_interface_s.CURRVAL "            ); // IF�����w�b�_ID
    sb.append("    ,po_lines_interface_s.CURRVAL  "             ); // IF��������ID
    sb.append("    ,po_distributions_interface_s.NEXTVAL  "     ); // IF��������ID
    sb.append("    ,1 "                                         ); // ���הԍ�
    sb.append("    ,TO_NUMBER(:1) * :2 "                        ); // ����
    sb.append("    ,FND_GLOBAL.USER_ID "                        ); // �쐬��
    sb.append("    ,SYSDATE "                                   ); // �쐬��
    sb.append("    ,FND_GLOBAL.USER_ID "                        ); // �ŏI�X�V��
    sb.append("    ,SYSDATE "                                   ); // �ŏI�X�V��
    sb.append("    ,FND_GLOBAL.LOGIN_ID "                       ); // �ŏI�X�V���O�C��
    sb.append("    ,100); "                                     ); //
                 // OUT�p�����[�^
    sb.append("  :3 := '1'; "                                   ); // 1:����I��
    sb.append("END; "                                           );

    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, productedQuantity);                      // �o��������
      cstmt.setInt(2, XxcmnUtility.intValue(conversionFactor));   // ���Z����    
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(3, Types.VARCHAR);   // ���^�[���R�[�h
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      retFlag = cstmt.getString(3); // ���^�[���R�[�h

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // ���^�[���R�[�h������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //�g�[�N������
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_PO_DISTRIBUTIONS_INTERFACE) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // insertPoDistributionsIf 

  /*****************************************************************************
   * �i�������˗����쐬���������s���܂��B
   * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @return String - XxcmnConstants.RETURN_SUCCESS:1 ����
   *                   XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String doQtInspection(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName = "doQtInspection";
    // IN�p�����[�^�擾
    String division       = (String)params.get("Division");            // �敪
// 2009-02-27 H.Itou Add Start �{�ԏ�Q#32
//    String disposalDiv    = (String)params.get("ProcessFlag");         // �����敪
    String disposalDiv    = null;
// 2009-02-27 H.Itou Add End
    Number lotId          = (Number)params.get("LotId");               // ���b�gID
    Number itemId         = (Number)params.get("ItemId");              // �i��ID
    String qtObject       = (String)params.get("QtObject");            // �Ώې�
    Number batchId        = (Number)params.get("BatchId");             // ���Y�o�b�`ID
    String qty            = (String)params.get("ProductedQuantity");   // �O���o��������
    Number conversionFactor  = (Number)params.get("ConversionFactor"); // ���Z����        
    Date   prodDelyDate   = (Date)params.get("ManufacturedDate");      // ���Y��
    String vendorLine     = (String)params.get("VendorCode");          // �����R�[�h
// 2009-02-18 H.Itou Mod Start �{�ԏ�Q#1096
//    Number qtInspectReqNo = (Number)params.get("QtInspectReqNo");      // �����˗�No
    String qtInspectReqNo = (String)params.get("QtInspectReqNo");      // �����˗�No
// 2009-02-18 H.Itou Mod End
// 2009-02-27 H.Itou Add Start �{�ԏ�Q#32
    BigDecimal beforeQty = new BigDecimal(0); // �O��o�^����
    BigDecimal inQty = new BigDecimal(0); // �i������API�ɓn������
    // �X�V�̏ꍇ�A�O�񐔗ʂ��擾
  	if (!XxcmnUtility.isBlankOrNull(params.get("Quantity")))
  	{
      beforeQty = XxcmnUtility.bigDecimalValue(params.get("Quantity").toString());   // �O��o�^����
    }
    
    // �����˗�No�ɒl������ꍇ����i�������X�V
    if (!XxcmnUtility.isBlankOrNull(qtInspectReqNo))
    {
      disposalDiv = "2";  // �����敪:�X�V
      // ���� �� ����o�^���� �| �O��o�^����
      inQty = XxcmnUtility.bigDecimalValue(qty).multiply(XxcmnUtility.bigDecimalValue(conversionFactor.toString())).subtract(beforeQty);


    // �����˗�No�ɒl���Ȃ��ꍇ����i�������ǉ�
    } else
    {
      disposalDiv = "1";  // �����敪:�ǉ�
      // ���� �� ����o�^����
      inQty = XxcmnUtility.bigDecimalValue(qty).multiply(XxcmnUtility.bigDecimalValue(conversionFactor.toString()));
    }
// 2009-02-27 H.Itou Add End
    
    // OUT�p�����[�^
    String exeType = XxcmnConstants.RETURN_NOT_EXE;
    
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(100);
// 2009-02-27 H.Itou Mod Start �{�ԏ�Q#32
    int bindCount = 1;

    sb.append("DECLARE ");
    // IN�p�����[�^�ݒ�
    sb.append("  it_division          VARCHAR2(1) := :" + bindCount++ + "; "             ); // IN  1.�敪         �K�{�i1:���Y 2:���� 3:���b�g��� 4:�O���o���� 5:�r�������j
    sb.append("  iv_disposal_div      VARCHAR2(1) := :" + bindCount++ + "; "             ); // IN  2.�����敪     �K�{�i1:�ǉ� 2:�X�V 3:�폜�j
    sb.append("  it_lot_id            NUMBER      := :" + bindCount++ + "; "             ); // IN  3.���b�gID     �K�{
    sb.append("  it_item_id           NUMBER      := :" + bindCount++ + "; "             ); // IN  4.�i��ID       �K�{
    sb.append("  iv_qt_object         VARCHAR2(1) := :" + bindCount++ + "; "             ); // IN  5.�Ώې�       �敪:5�̂ݕK�{�i1:�r���i�� 2:���Y���P 3:���Y���Q 4:���Y���R�j
    sb.append("  it_batch_id          NUMBER      := :" + bindCount++ + "; "             ); // IN  6.���Y�o�b�`ID �����敪3�ȊO���敪:1�̂ݕK�{
    sb.append("  it_qty               NUMBER      := :" + bindCount++ + "; "             ); // IN  7.����         �����敪3�ȊO���敪:2�̂ݕK�{
    sb.append("  it_prod_dely_date    DATE        := :" + bindCount++ + "; "             ); // IN  8.�[����       �����敪3�ȊO���敪:2�̂ݕK�{
    sb.append("  it_vendor_line       VARCHAR2(50):= :" + bindCount++ + "; "             ); // IN  9.�d����R�[�h �����敪3�ȊO���敪:2�̂ݕK�{    
    sb.append("  it_qt_inspect_req_no NUMBER      := TO_NUMBER(:" + bindCount++ + "); "  ); // IN 10.�����˗�No   �����敪:2�A3�̂ݕK�{
    sb.append("  ot_qt_inspect_req_no NUMBER; "                                          ); // OUT11.�����˗�No
    sb.append("  ov_errbuf            VARCHAR2(5000); "                                  ); // OUT12.�G���[�E���b�Z�[�W           --# �Œ� #
    sb.append("  ov_retcode           VARCHAR2(1); "                                     ); // OUT13.���^�[���E�R�[�h             --# �Œ� #
    sb.append("  ov_errmsg            VARCHAR2(5000); "                                  ); // OUT14.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    sb.append("BEGIN "                                                                   );
    sb.append("  xxwip_common_pkg.make_qt_inspection( "                                  );
    sb.append("    it_division          => it_division "                                 );
    sb.append("   ,iv_disposal_div      => iv_disposal_div "                             );
    sb.append("   ,it_lot_id            => it_lot_id "                                   );
    sb.append("   ,it_item_id           => it_item_id "                                  );
    sb.append("   ,iv_qt_object         => iv_qt_object "                                );
    sb.append("   ,it_batch_id          => it_batch_id "                                 );
    sb.append("   ,it_batch_po_id       => NULL "                                        );
    sb.append("   ,it_qty               => it_qty "                                      );
    sb.append("   ,it_prod_dely_date    => it_prod_dely_date "                           );
    sb.append("   ,it_vendor_line       => it_vendor_line "                              );
    sb.append("   ,it_qt_inspect_req_no => it_qt_inspect_req_no "                        );
    sb.append("   ,ot_qt_inspect_req_no => ot_qt_inspect_req_no "                        );
    sb.append("   ,ov_errbuf            => ov_errbuf "                                   );
    sb.append("   ,ov_retcode           => ov_retcode "                                  );
    sb.append("   ,ov_errmsg            => ov_errmsg); "                                 );
    sb.append("  :" + bindCount++ + ":= ot_qt_inspect_req_no; "                          );
    // OUT�p�����[�^�ݒ�
    sb.append("  :" + bindCount++ + ":= ov_errbuf; "                                     );
    sb.append("  :" + bindCount++ + ":= ov_retcode; "                                    );
    sb.append("  :" + bindCount++ + ":= ov_errmsg; "                                     );
    sb.append("END; "                                                                    );
//    sb.append("BEGIN ");
//    sb.append("  xxwip_common_pkg.make_qt_inspection( "          );
//    sb.append("    it_division          => :1 "                  ); // IN  1.�敪         �K�{�i1:���Y 2:���� 3:���b�g��� 4:�O���o���� 5:�r�������j
//    sb.append("   ,iv_disposal_div      => :2 "                  ); // IN  2.�����敪     �K�{�i1:�ǉ� 2:�X�V 3:�폜�j
//    sb.append("   ,it_lot_id            => :3 "                  ); // IN  3.���b�gID     �K�{
//    sb.append("   ,it_item_id           => :4 "                  ); // IN  4.�i��ID       �K�{
//    sb.append("   ,iv_qt_object         => :5 "                  ); // IN  5.�Ώې�       �敪:5�̂ݕK�{�i1:�r���i�� 2:���Y���P 3:���Y���Q 4:���Y���R�j
//    sb.append("   ,it_batch_id          => :6 "                  ); // IN  6.���Y�o�b�`ID �����敪3�ȊO���敪:1�̂ݕK�{
//    sb.append("   ,it_batch_po_id       => NULL "                ); // IN    ���הԍ� NULL
//    sb.append("   ,it_qty               => TO_NUMBER(:7) * :8 "  ); // IN    ���� 7.�O���o�������� �~ 8.���Z����        �����敪3�ȊO���敪:2�̂ݕK�{
//    sb.append("   ,it_prod_dely_date    => :9 "                  ); // IN  9.�[����       �����敪3�ȊO���敪:2�̂ݕK�{
//    sb.append("   ,it_vendor_line       => :10 "                 ); // IN 10.�d����R�[�h �����敪3�ȊO���敪:2�̂ݕK�{
//// 2009-02-18 H.Itou Mod Start �{�ԏ�Q#1096
////    sb.append("   ,it_qt_inspect_req_no => :11 "                 ); // IN 11.�����˗�No   �����敪:2�A3�̂ݕK�{            
//    sb.append("   ,it_qt_inspect_req_no => TO_NUMBER(:11) "      ); // IN 11.�����˗�No   �����敪:2�A3�̂ݕK�{            
//// 2009-02-18 H.Itou Mod End
//    sb.append("   ,ot_qt_inspect_req_no => :12 "                 ); // OUT 12.�����˗�No
//    sb.append("   ,ov_errbuf            => :13 "                 ); // �G���[�E���b�Z�[�W           --# �Œ� #
//    sb.append("   ,ov_retcode           => :14 "                 ); // ���^�[���E�R�[�h             --# �Œ� #
//    sb.append("   ,ov_errmsg            => :15); "               ); // ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
//    sb.append("END; "                                            );
// 2009-02-27 H.Itou Mod End

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
// 2009-02-27 H.Itou Mod Start �{�ԏ�Q#32
      bindCount = 1;
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString    (bindCount++, division);                      // �敪
      cstmt.setString    (bindCount++, disposalDiv);                   // �����敪
      cstmt.setInt       (bindCount++, XxcmnUtility.intValue(lotId));  // ���b�gID
      cstmt.setInt       (bindCount++, XxcmnUtility.intValue(itemId)); // �i��ID
      cstmt.setNull      (bindCount++, Types.VARCHAR);                 // �Ώې�
      cstmt.setNull      (bindCount++, Types.INTEGER);                 // ���Y�o�b�`ID
      cstmt.setBigDecimal(bindCount++, inQty);                         // ����
      // �敪��2:�����̏ꍇ
      if (XxpoConstants.DIVISION_PO.equals(division))
      {
        cstmt.setDate  (bindCount++, XxcmnUtility.dateValue(prodDelyDate));   // �[����
        cstmt.setString(bindCount++, vendorLine);      // �d����R�[�h
        
      // �敪��4:�O���o�����̏ꍇ
      } else if (XxpoConstants.DIVISION_SPL.equals(division))
      {
        cstmt.setNull(bindCount++, Types.DATE);    // �[����
        cstmt.setNull(bindCount++, Types.INTEGER); // �d����R�[�h
      }
      // �����˗�No�ɒl������ꍇ����i�������X�V
      if (!XxcmnUtility.isBlankOrNull(qtInspectReqNo))
      {
        cstmt.setString(bindCount++, qtInspectReqNo); // �����˗�No

      // �����˗�No�ɒl���Ȃ��ꍇ����i�������ǉ�
      } else
      {
        cstmt.setNull(bindCount++, Types.VARCHAR); // NULL
      }
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      int outBindStart = bindCount;
      cstmt.registerOutParameter(bindCount++, Types.INTEGER); // �����˗�No
      cstmt.registerOutParameter(bindCount++, Types.VARCHAR); // �G���[�E���b�Z�[�W
      cstmt.registerOutParameter(bindCount++, Types.VARCHAR); // ���^�[���E�R�[�h
      cstmt.registerOutParameter(bindCount++, Types.VARCHAR); // ���[�U�[�E�G���[�E���b�Z�[�W

//      // �p�����[�^�ݒ�(IN�p�����[�^)
//      cstmt.setString(1, division);                            // �敪
//// 2009-02-18 H.Itou Del Start �{�ԏ�Q#1096
////      cstmt.setString(2, disposalDiv);                         // �����敪
//// 2009-02-18 H.Itou Del End
//      cstmt.setInt(3, XxcmnUtility.intValue(lotId));           // ���b�gID
//      cstmt.setInt(4, XxcmnUtility.intValue(itemId));          // �i��ID
//      // �敪��2:�����̏ꍇ
//      if (XxpoConstants.DIVISION_PO.equals(division))
//      {
//        cstmt.setNull(5, Types.VARCHAR);                          // �Ώې�    
//        cstmt.setNull(6, Types.INTEGER);                          // ���Y�o�b�`ID
//// 2009-02-18 H.Itou Add Start �{�ԏ�Q#1096
//        // �����˗�No�ɒl������ꍇ����i�������X�V �O���o���������d���͐��ʂ��X�V�ł��Ȃ��̂ŁA��ɍ���0��n���B
//        if (!XxcmnUtility.isBlankOrNull(qtInspectReqNo))
//        {
//          cstmt.setString(7, "0");  // �O���o��������
//          cstmt.setInt(8, 0);       // ���Z����
//
//        // �����˗�No�ɒl���Ȃ��ꍇ����i�������ǉ�
//        } else
//        { 
//// 2009-02-18 H.Itou Add End
//          cstmt.setString(7, qty);                                  // �O���o��������
//          cstmt.setInt(8, XxcmnUtility.intValue(conversionFactor)); // ���Z����
//// 2009-02-18 H.Itou Add Start �{�ԏ�Q#1096
//        }
//// 2009-02-18 H.Itou Add End
//
//        cstmt.setDate(9, XxcmnUtility.dateValue(prodDelyDate));   // �[����
//        cstmt.setString(10, vendorLine);      // �d����R�[�h
//      // �敪��4:�O���o�����̏ꍇ
//      } else if (XxpoConstants.DIVISION_SPL.equals(division))
//      {
//        cstmt.setNull(5, Types.VARCHAR);  // �Ώې�    
//        cstmt.setNull(6, Types.INTEGER);  // ���Y�o�b�`ID
//        cstmt.setNull(7, Types.VARCHAR);  // �O���o��������
//        cstmt.setNull(8, Types.INTEGER);  // ���Z����
//        cstmt.setNull(9, Types.DATE);     // �[����
//        cstmt.setNull(10, Types.INTEGER); // �d����R�[�h
//      }
//// 2009-02-18 H.Itou Mod Start �{�ԏ�Q#1096
////      // �ǉ��ȊO�̏ꍇ
////      if (XxpoConstants.PROCESS_FLAG_I.equals(disposalDiv) == false)
//      // �����˗�No�ɒl������ꍇ����i�������X�V
//      if (!XxcmnUtility.isBlankOrNull(qtInspectReqNo))
//// 2009-02-18 H.Itou Mod End
//      {
//// 2009-02-18 H.Itou Add Start �{�ԏ�Q#1096
//        cstmt.setString(2, "2");                         // �����敪:�X�V
//// 2009-02-18 H.Itou Add End
//// 2009-02-18 H.Itou Mod Start �{�ԏ�Q#1096
////        cstmt.setInt(11, XxcmnUtility.intValue(qtInspectReqNo)); // �����˗�No
//        cstmt.setString(11, qtInspectReqNo); // �����˗�No
//// 2009-02-18 H.Itou Mod End
//
//      // �����˗�No�ɒl���Ȃ��ꍇ����i�������ǉ�
//      } else
//      {
//// 2009-02-18 H.Itou Add Start �{�ԏ�Q#1096
//        cstmt.setString(2, "1");                         // �����敪:�ǉ�
//// 2009-02-18 H.Itou Add End
//// 2009-02-18 H.Itou Mod Start �{�ԏ�Q#1096
////        cstmt.setNull(11, Types.INTEGER); // NULL
//        cstmt.setNull(11, Types.VARCHAR); // NULL
//// 2009-02-18 H.Itou Mod End
//      }
//      
//      // �p�����[�^�ݒ�(OUT�p�����[�^)
//      cstmt.registerOutParameter(12, Types.INTEGER);           // �����˗�No
//      cstmt.registerOutParameter(13, Types.VARCHAR, 5000);     // �G���[�E���b�Z�[�W
//      cstmt.registerOutParameter(14, Types.VARCHAR, 1);        // ���^�[���E�R�[�h
//      cstmt.registerOutParameter(15, Types.VARCHAR, 5000);     // ���[�U�[�E�G���[�E���b�Z�[�W
// 2009-02-27 H.Itou Mod End

      //PL/SQL���s
      cstmt.execute();

// 2009-02-27 H.Itou Mod Start �{�ԏ�Q#32
      bindCount = outBindStart;
      int outQtInspectReqNo = cstmt.getInt(bindCount++); // �����˗�No
      String errbuf  = cstmt.getString(bindCount++);     // �G���[�E���b�Z�[�W
      String retCode = cstmt.getString(bindCount++);     // ���^�[���E�R�[�h
      String errmsg  = cstmt.getString(bindCount++);     // ���[�U�[�E�G���[�E���b�Z�[�W

//      int outQtInspectReqNo = cstmt.getInt(12); // �����˗�No
//      String errbuf = cstmt.getString(13);      // �G���[�E���b�Z�[�W
//      String retCode = cstmt.getString(14);     // ���^�[���E�R�[�h
//      String errmsg = cstmt.getString(15);      // ���[�U�[�E�G���[�E���b�Z�[�W
// 2009-02-27 H.Itou Mod End
      
      // ����I���̏ꍇ
      if (XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {
        exeType = XxcmnConstants.RETURN_SUCCESS;
      
      // �x���I���̏ꍇ
      } else if (XxcmnConstants.API_RETURN_WARN.equals(retCode))
      {
        exeType = XxcmnConstants.RETURN_WARN;
      
      // �ُ�I���̏ꍇ
      } else if (XxcmnConstants.API_RETURN_ERROR.equals(retCode)) 
      {
        // ���[���o�b�N
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              errbuf,
                              6);
        // �ǉ��̏ꍇ
        if (XxpoConstants.PROCESS_FLAG_I.equals(disposalDiv))
        {
          //�g�[�N������
          MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                     XxpoConstants.TAB_XXWIP_QT_INSPECTION) };

          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXPO, 
                                 XxpoConstants.XXPO10007, 
                                 tokens);

        // �X�V�̏ꍇ
        } else if (XxpoConstants.PROCESS_FLAG_U.equals(disposalDiv))
        {
          //�g�[�N������
          MessageToken[] tokens = new MessageToken[3];
          tokens[0] = new MessageToken(XxpoConstants.TOKEN_INFO_NAME, XxpoConstants.TAB_XXWIP_QT_INSPECTION);
          tokens[1] = new MessageToken(XxpoConstants.TOKEN_PARAMETER, XxpoConstants.COL_QT_INSPECT_REQ_NO);
// 2009-02-18 H.Itou Mod Start �{�ԏ�Q#1096
//          tokens[2] = new MessageToken(XxpoConstants.TOKEN_VALUE,  XxcmnUtility.stringValue(qtInspectReqNo));
          tokens[2] = new MessageToken(XxpoConstants.TOKEN_VALUE,  qtInspectReqNo);
// 2009-02-18 H.Itou Mod End

          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXPO, 
                                 XxpoConstants.XXPO10006, 
                                 tokens);          
        }
      }
      
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return exeType;
  } // doQtInspection

  /*****************************************************************************
   * �R���J�����g�F�W�������C���|�[�g�𔭍s���܂��B
   * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @return String - XxcmnConstants.RETURN_SUCCESS:1 ����
   *                   XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String doImportStandardPurchaseOrders(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "doImportStandardPurchaseOrders";

    // IN�p�����[�^�擾
    String poHeaderNumber    = (String)params.get("PoNumber");          // �����ԍ�

    // OUT�p�����[�^�p
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // �߂�l

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "   );
    sb.append("  ln_request_id NUMBER; "                                             );
    sb.append("  lv_batch_id   VARCHAR2(5000); "                                     );
    sb.append("BEGIN "                                                               );
                 // �o�b�`ID�擾
    sb.append("  SELECT TO_CHAR(po_headers_interface_s.CURRVAL) "                    );
    sb.append("  INTO   lv_batch_id "                                                );
    sb.append("  FROM   DUAL; "                                                      );
    sb.append("  lv_batch_id := lv_batch_id ||  :1; "                                );
                 // �W�������C���|�[�g(�R���J�����g)�Ăяo��
    sb.append("  ln_request_id := fnd_request.submit_request( "                      );
    sb.append("     application  => 'PO' "                                           ); // �A�v���P�[�V������
    sb.append("    ,program      => 'POXPOPDOI' "                                    ); // �v���O�����Z�k��
    sb.append("    ,argument1    => NULL "                                           ); // �w���S��ID
    sb.append("    ,argument2    => 'STANDARD' "                                     ); // �����^�C�v
    sb.append("    ,argument3    => NULL "                                           ); // �����T�u�^�C�v
    sb.append("    ,argument4    => 'N' "                                            ); // �i�ڂ̍쐬 N:�s��Ȃ�
    sb.append("    ,argument5    => NULL "                                           ); // �\�[�X�E���[���̍쐬
    sb.append("    ,argument6    => 'APPROVED' "                                     ); // ���F�X�e�[�^�X APPROVAL:���F
    sb.append("    ,argument7    => NULL "                                           ); // �����[�X�������@
    sb.append("    ,argument8    => lv_batch_id "                                    ); // �o�b�`ID = IF�w�b�_ID || �����ԍ�
    sb.append("    ,argument9    => NULL "                                           ); // �c�ƒP��
    sb.append("    ,argument10   => NULL); "                                         ); // �O���[�o���_��
                 // �v��ID������ꍇ�A����
    sb.append("  IF ln_request_id > 0 THEN "                                         );
    sb.append("    :2 := '1'; "                                                      ); // 1:����I��
    sb.append("    :3 := ln_request_id; "                                            ); // �v��ID
    sb.append("    COMMIT; "                                                         );
                 // �v��ID���Ȃ��ꍇ�A�ُ�
    sb.append("  ELSE "                                                              );
    sb.append("    :2 := '0'; "                                                      ); // 0:�ُ�I��
    sb.append("    :3 := ln_request_id; "                                            ); // �v��ID
    sb.append("    ROLLBACK; "                                                       );
    sb.append("  END IF; "                                                           );
    sb.append("END; "                                                                );

    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, poHeaderNumber);             // �����ԍ�
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(2, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(3, Types.INTEGER);   // �v��ID
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      retFlag = cstmt.getString(2); // ���^�[���R�[�h
      int requestId = cstmt.getInt(3); // �v��ID

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // ���^�[���R�[�h������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        
      // ����I���łȂ��ꍇ�A�G���[  
      } else
      {
        //�g�[�N������
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PRG_NAME,
                                                   "�W�������C���|�[�g") };
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                               XxpoConstants.XXPO10025, 
                               tokens);
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
          XxcmnUtility.writeLog(trans,
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }

    return retFlag;
  } // doImportStandardPurchaseOrders 

  /*****************************************************************************
   * �O���o�������тɃf�[�^���X�V���܂��B
   * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @return String - XxcmnConstants.RETURN_SUCCESS:1 ����
   *                  XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String updateXxpoVendorSupplyTxns(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "updateXxpoVendorSupplyTxns";

    // IN�p�����[�^�擾
    String txnsType          = (String)params.get("ProductResultType"); // �����^�C�v
    String productedQuantity = (String)params.get("ProductedQuantity"); // �o��������
    Number conversionFactor  = (Number)params.get("ConversionFactor");  // ���Z����
    String correctedQuantity = (String)params.get("CorrectedQuantity"); // ��������
    String description       = (String)params.get("Description");       // �K�v
    Number txnsId            = (Number)params.get("TxnsId");            // ����ID
    String lastUpdateDate    = (String)params.get("LastUpdateDate");    // �ŏI�X�V��
    // �X�V�G���[���b�Z�[�W�p�L�[
    Date   manufacturedDate  = (Date)params.get("ManufacturedDate");    // ���Y��
    String vendorCode        = (String)params.get("VendorCode");        // �����
    String factoryCode       = (String)params.get("FactoryCode");       // �H��R�[�h
    String itemCode          = (String)params.get("ItemCode");          // �i�ڃR�[�h
    String lotNumber         = (String)params.get("LotNumber");         // ���b�g�ԍ�
    // �X�V�G���[���b�Z�[�W�p�L�[�쐬
    StringBuffer errKey = new StringBuffer(1000);
    errKey.append(XxpoConstants.COL_MANUFACTURED_DATE); // ���Y��
    errKey.append(XxpoConstants.COLON);
    errKey.append(XxcmnUtility.stringValue(manufacturedDate));
    errKey.append(XxpoConstants.COMMA);
    errKey.append(XxpoConstants.SPACE);
    errKey.append(XxpoConstants.COL_VENDOR_CODE); // �����
    errKey.append(XxpoConstants.COLON);
    errKey.append(String.valueOf(vendorCode));
    errKey.append(XxpoConstants.COMMA);
    errKey.append(XxpoConstants.SPACE);
    errKey.append(XxpoConstants.COL_FACTORY_CODE); // �H��
    errKey.append(XxpoConstants.COLON);
    errKey.append(String.valueOf(factoryCode));
    errKey.append(XxpoConstants.COMMA);
    errKey.append(XxpoConstants.SPACE);
    errKey.append(XxpoConstants.COL_ITEM_CODE); // �i��
    errKey.append(XxpoConstants.COLON);
    errKey.append(String.valueOf(itemCode));
    errKey.append(XxpoConstants.COMMA);
    errKey.append(XxpoConstants.SPACE);
    errKey.append(XxpoConstants.COL_LOT_NUMBER); // ���b�g�ԍ�
    errKey.append(XxpoConstants.COLON);
    errKey.append(String.valueOf(lotNumber));

    // OUT�p�����[�^�p
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // �߂�l

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                                                                    );
    sb.append("  lt_producted_quantity   xxpo_vendor_supply_txns.producted_quantity%TYPE := TO_NUMBER(:1); "); // �o��������
    sb.append("  lt_corrected_quantity   xxpo_vendor_supply_txns.corrected_quantity%TYPE := TO_NUMBER(:2); "); // ��������
    sb.append("  lt_conversion_factor    xxpo_vendor_supply_txns.conversion_factor%TYPE  := :3; "           ); // ���Z����
    sb.append("  lt_description          xxpo_vendor_supply_txns.description%TYPE        := :4; "           ); // �K�v
    sb.append("  lt_txns_id              xxpo_vendor_supply_txns.txns_id%TYPE            := :5; "           ); // ����ID
    sb.append("  lv_last_update_date     VARCHAR2(100) := :6; "                                             ); // �ŏI�X�V��
    sb.append("  lv_temp_date            VARCHAR2(100) ; "                                                  ); // �ŏI�X�V��
                 // ���[�U�[��`�G���[
    sb.append("  lock_expt             EXCEPTION; "                                                         ); // ���b�N�G���[
    sb.append("  exclusive_expt        EXCEPTION; "                                                         ); // �r���G���[
    sb.append("  PRAGMA EXCEPTION_INIT(lock_expt, -54); "                                                   ); // 
    
    sb.append("BEGIN "                                                                                      );
                 // ���b�N�擾
    sb.append("  SELECT TO_CHAR(xvst.last_update_date,'YYYY/MM/DD HH24:MI:SS')  last_update_date "          );
    sb.append("  INTO   lv_temp_date "                                                                      );
    sb.append("  FROM   xxpo_vendor_supply_txns xvst "                                                      );
    sb.append("  WHERE  xvst.txns_id = lt_txns_id "                                                         );
    sb.append("  FOR UPDATE NOWAIT; "                                                                       );
                 // �r���`�F�b�N�E�E�E���̃��[�U�[�ɍX�V����Ă��Ȃ����`�F�b�N
    sb.append("  IF (lv_temp_date <> lv_last_update_date) THEN "                                            );
    sb.append("    RAISE exclusive_expt; "                                                                  );
    sb.append("  END IF; "                                                                                  );
                 // �O���o�������эX�V
    sb.append("  UPDATE xxpo_vendor_supply_txns xvst "                                                      );
    sb.append("  SET    xvst.description        = lt_description "                                          ); // �E�v
    // �����^�C�v��1:�����݌ɊǗ��̏ꍇ
    if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(txnsType)) 
    {
      sb.append("      ,xvst.quantity           = lt_producted_quantity * lt_conversion_factor "            ); // ���� = �o�������� �~ ���Z����
      sb.append("      ,xvst.producted_quantity = lt_producted_quantity "                                   ); // �o�������� 
      
    // �����^�C�v��2:�����d���̏ꍇ
    } else if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(txnsType))
    {
      sb.append("      ,xvst.corrected_quantity = lt_corrected_quantity "                                   ); // ��������
    }
    sb.append("        ,xvst.last_updated_by    = FND_GLOBAL.USER_ID "                                      ); // �ŏI�X�V��
    sb.append("        ,xvst.last_update_date   = SYSDATE "                                                 ); // �ŏI�X�V��
    sb.append("        ,xvst.last_update_login  = FND_GLOBAL.LOGIN_ID "                                     ); // �ŏI�X�V���O�C��
    sb.append("  WHERE  xvst.txns_id = lt_txns_id; "                                                        ); // ����ID
                 // OUT�p�����[�^
    sb.append("  :7 := '1'; "                                                                               ); // 1:����I��
    sb.append("EXCEPTION "                                                                                  );
    sb.append("  WHEN lock_expt THEN "                                                                      );
    sb.append("    :7 := '2'; "                                                                             ); // 2:���b�N�G���[
    sb.append("    :8 := SQLERRM; "                                                                         ); // SQLERR���b�Z�[�W    
    sb.append("  WHEN exclusive_expt THEN "                                                                 );
    sb.append("    :7 := '3'; "                                                                             ); // 3:�r���`�F�b�N�G���[
    sb.append("END; "                                                                                       );

    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, productedQuantity);                    // �o��������
      cstmt.setString(2, correctedQuantity);                    // ��������
      cstmt.setInt(3, XxcmnUtility.intValue(conversionFactor)); // ���Z����
      cstmt.setString(4, description);                          // �E�v
      cstmt.setInt(5, XxcmnUtility.intValue(txnsId));           // ����ID
      cstmt.setString(6, lastUpdateDate);                       // �ŏI�X�V��
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(7, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(8, Types.VARCHAR);   // �G���[���b�Z�[�W
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      retFlag = cstmt.getString(7); // ���^�[���R�[�h
      String sqlErrMsg = cstmt.getString(8); // �G���[���b�Z�[�W

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // ���^�[���R�[�h�F������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        
      // ���b�N�G���[�I���̏ꍇ  
      } else if ("2".equals(retFlag))
      {
        // ���[���o�b�N
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              sqlErrMsg,
                              6);
        // ���b�N�G���[
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                               XxpoConstants.XXPO10138);
       // �r���G���[�I���̏ꍇ  
      } else if ("3".equals(retFlag))
      {
        rollBack(trans);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10147); 
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //�g�[�N������
      MessageToken[] tokens = new MessageToken[2];
      tokens[0] = new MessageToken(XxpoConstants.TOKEN_INFO_NAME, XxpoConstants.TAB_XXPO_VENDOR_SUPPLY_TXNS);
      tokens[1] = new MessageToken(XxpoConstants.TOKEN_ERRKEY,  errKey.toString());

      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10008, 
                             tokens);
                               
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // updateXxpoVendorSupplyTxns

    /*****************************************************************************
   * �ŗL�L�����擾���܂��B
   * @param trans - �g�����U�N�V����
   * @param itemId - �i��ID
   * @param factoryId - �H��ID
   * @param manufacturedDate - ���Y��
   * @return String �ŗL�L��
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String getKoyuCode(
    OADBTransaction trans,
    Number itemId,
    Number factoryId,
    Date manufacturedDate
  ) throws OAException
  {
    String apiName   = "getKoyuCode";
    String   koyuCode = null;
    // �i��ID�A�H��ID�A���������Âꂩ����Null�̏ꍇ�̓u�����N��Ԃ��B
    if (XxcmnUtility.isBlankOrNull(itemId) 
      || XxcmnUtility.isBlankOrNull(factoryId)
      || XxcmnUtility.isBlankOrNull(manufacturedDate)) 
    {
      return "";
    }
    
    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                                   );
    sb.append("   SELECT xph.koyu_code       koyu_code " ); // �ŗL�L��
    sb.append("   INTO   :1                            " );
    sb.append("   FROM   xxpo_price_headers  xph  "      ); // �d����W���P���w�b�_
    sb.append("   WHERE  xph.item_id            = :2   " ); // �i��ID
    sb.append("   AND    xph.factory_id         = :3   " ); // �H��ID
    sb.append("   AND    xph.price_type         = '1'  " ); // �}�X�^�敪 1(�d��)
// 2008-07-11 D.Nihei ADD START
    sb.append("   AND    xph.futai_code         = '0'  " ); // �t�уR�[�h
// 2008-07-11 D.Nihei ADD END
// 20080702 yoshimoto add Start
    sb.append("   AND    xph.supply_to_code IS NULL    " ); // �x����R�[�h IS NULL
// 20080702 yoshimoto add End
    sb.append("   AND    xph.start_date_active <= :4   " ); // �K�p�J�n��
    sb.append("   AND    xph.end_date_active   >= :4;  " ); // �K�p�I����
               // �擾�Ɏ��s�����ꍇ
    sb.append("EXCEPTION                               " );
    sb.append("  WHEN OTHERS THEN                      " );
    sb.append("    :1 := '';                           " );
    sb.append("END; "                                    );

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      
      cstmt.setInt(2, XxcmnUtility.intValue(itemId));             // �i��ID
      cstmt.setInt(3, XxcmnUtility.intValue(factoryId));          // �H��ID
      cstmt.setDate(4, XxcmnUtility.dateValue(manufacturedDate)); // ���Y��
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR);               // �ŗL�L��

      // PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      koyuCode = cstmt.getString(1);

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return koyuCode;
  } // getKoyuCode

  /*****************************************************************************
   * �����w�b�_�[Tbl�Ƀf�[�^���X�V���܂��B
   * @param trans �g�����U�N�V����
   * @param params �p�����[�^�pHashMap
   * @return String XxcmnConstants.RETURN_SUCCESS:1 ����
   *                  XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException OA��O
   ****************************************************************************/
  public static String updatePoHeadersAllTxns(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "updatePoHeadersAllTxns";

    // IN�p�����[�^�擾
    String headerId    = (String)params.get("HeaderId");    // �w�b�_ID
    String description = (String)params.get("Description"); // �E�v

    // OUT�p�����[�^�p
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // �߂�l

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    
    sb.append("BEGIN ");
    sb.append("  UPDATE po_headers_all pha      ");   // �����w�b�_
    sb.append("  SET    pha.attribute15  = :1   ");   // �E�v(�w�b�_)
    sb.append("        ,pha.last_updated_by   = FND_GLOBAL.USER_ID "); // �ŏI�X�V��
    sb.append("        ,pha.last_update_date  = SYSDATE            "); // �ŏI�X�V��
    sb.append("        ,pha.last_update_login = FND_GLOBAL.LOGIN_ID"); // �ŏI�X�V���O�C��
    sb.append("  WHERE  pha.po_header_id = :2;  ");   // �w�b�_�[ID

//20080225 del Start
                 // OUT�p�����[�^
    //sb.append("  :3 := '1'; "                    ); // 1:����I��
    //sb.append("EXCEPTION "                       );
    //sb.append("  WHEN OTHERS THEN "              ); 
    //sb.append("  :3 := '0'; "                    );  // 0:�ُ�I��
//20080225 del End

    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
                                
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, description);                // �K�p(�w�b�_�[)
      cstmt.setString(2, headerId);                   // �w�b�_�[ID
      
//20080225 del Start
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      //cstmt.registerOutParameter(3, Types.VARCHAR);   // ���^�[���R�[�h
//20080225 del End
    
      //PL/SQL���s
      cstmt.execute();

//20080225 del Start
      // �߂�l�擾
      //cstmt.getString(3); // ���^�[���R�[�h
//20080225 del End

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
                            
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }

    // ����ɏ������ꂽ�ꍇ�A"SUCCESS"(1)��ԋp
    return XxcmnConstants.RETURN_SUCCESS;

  } // updatePoHeadersAllTxns

  /*****************************************************************************
   * ��������Tbl�Ƀf�[�^���X�V���܂��B
   * @param trans �g�����U�N�V����
   * @param params �p�����[�^�pHashMap
   * @return String XxcmnConstants.RETURN_SUCCESS:1 ����
   *                  XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException OA��O
   ****************************************************************************/
  public static String updatePoLinesAllTxns(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "updatePoLinesAllTxns";

    // IN�p�����[�^�擾
    String headerId           = (String)params.get("HeaderId");          // �w�b�_ID
    String lineId             = (String)params.get("LineId");            // ����ID
    String itemAmount         = (String)params.get("ItemAmount");        // ����
    Date   deliveryDate       = (Date)params.get("DeliveryDate");        // �[����
// 20080521 yoshimoto mod Start
    //String sDeliveryDate      = deliveryDate.toString();
    String sDeliveryDate      = XxcmnUtility.stringValue(deliveryDate);
// 20080521 yoshimoto mod End
    String leavingShedAmount  = (String)params.get("LeavingShedAmount"); // �o�ɐ�
    Date   appointmentDate    = (Date)params.get("AppointmentDate");     // ���t�w��

    String sAppointmentDate   = null;
    if (!XxcmnUtility.isBlankOrNull(appointmentDate)) 
    {
// 20080521 yoshimoto mod Start
      //sAppointmentDate   = appointmentDate.toString();                   // ���t�w��
      sAppointmentDate      = XxcmnUtility.stringValue(appointmentDate); // ���t�w��
// 20080521 yoshimoto mod End
    }

    String description        = (String)params.get("Description");       // �K�p(����)

    // OUT�p�����[�^�p
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // �߂�l

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);

    sb.append("BEGIN ");
    sb.append("  UPDATE po_lines_all pla       ");                       // ��������
    sb.append("  SET    pla.attribute4  = :1   ");                       // �݌ɓ���
    sb.append("        ,pla.attribute5  = :2   ");                       // �d����o�ד�
    sb.append("        ,pla.attribute6  = :3   ");                       // �d����o�א���
    sb.append("        ,pla.attribute9  = :4   ");                       // ���t�w��
    sb.append("        ,pla.attribute15 = :5   ");                       // �E�v   
    sb.append("        ,pla.last_updated_by   = FND_GLOBAL.USER_ID ");   // �ŏI�X�V��
    sb.append("        ,pla.last_update_date  = SYSDATE            ");   // �ŏI�X�V��
    sb.append("        ,pla.last_update_login = FND_GLOBAL.LOGIN_ID ");   // �ŏI�X�V���O�C��
    sb.append("  WHERE  pla.po_header_id = :6   ");   // �w�b�_�[ID
    sb.append("  AND    pla.po_line_id   = :7;  ");   // ����ID
                 // OUT�p�����[�^
//20080225 del Start
    //sb.append("  :8 := '1'; "                    );   // 1:����I��
    //sb.append("EXCEPTION "                       );
    //sb.append("  WHEN OTHERS THEN "              ); 
    //sb.append("  :8 := '0'; "                    );   // 0:�ُ�I��
//20080225 del End

    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
                                
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      if (XxcmnUtility.isBlankOrNull(itemAmount)) 
      {
        cstmt.setNull(1, Types.VARCHAR);        // ���� 
        
      } else
      {
        cstmt.setString(1, itemAmount);         // ����
      }
      
      cstmt.setString(2, sDeliveryDate);       // �[����
      cstmt.setString(3, leavingShedAmount);  // �o�ɐ�

      if (XxcmnUtility.isBlankOrNull(sAppointmentDate)) 
      {
        cstmt.setNull(4, Types.VARCHAR);       // ���t�w�� 
        
      } else
      {
        cstmt.setString(4, sAppointmentDate);    // ���t�w��
      }

      if (XxcmnUtility.isBlankOrNull(description)) 
      {
        cstmt.setNull(5, Types.VARCHAR);       // �E�v 
        
      } else
      {
        cstmt.setString(5, description);        // �E�v
      }
      
      cstmt.setString(6, headerId);           // �w�b�_�[ID
      cstmt.setString(7, lineId);             // ���׍s�ԍ�

      
//20080225 del Start      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      //cstmt.registerOutParameter(8, Types.VARCHAR);   // ���^�[���R�[�h
//20080225 del End
    
      //PL/SQL���s
      cstmt.execute();

//20080225 del Start
      // �߂�l�擾
      //cstmt.getString(8); // ���^�[���R�[�h
//20080225 del End

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);

        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }

    // ����ɏ������ꂽ�ꍇ�A"SUCCESS"(1)��ԋp
    return XxcmnConstants.RETURN_SUCCESS;    
  }

  /*****************************************************************************
   * OPM���b�g�}�X�^Tbl�Ƀf�[�^���X�V���܂��B
   * @param trans �g�����U�N�V����
   * @param params �p�����[�^�pHashMap
   * @return String XxcmnConstants.RETURN_SUCCESS:1 ����
   *                  XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException OA��O
   ****************************************************************************/
  public static String updateIcLotsMstTxns(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
  
    String apiName      = "updateIcLotsMstTxns";

    // ����
    String itemAmount        = (String)params.get("ItemAmount");
    // ������
    Date   productionDate    = (Date)params.get("ProductionDate");
// 20080521 yoshimoto mod Start  
    //String sProductionDate   = productionDate.toString();
    String sProductionDate      = XxcmnUtility.stringValue(productionDate);
// 20080521 yoshimoto mod End    
    // �ܖ�����
    Date   useByDate          = (Date)params.get("UseByDate");
// 20080521 yoshimoto mod Start 
    //String sUseByDate         = useByDate.toString();
    String sUseByDate      = XxcmnUtility.stringValue(useByDate);
// 20080521 yoshimoto mod End

    // �����N1
    String rank              = (String)params.get("Rank");
// 2008-11-04 v1.16 D.Nihei Add Start ������Q#51�Ή� 
    // �����N2
    String rank2             = (String)params.get("Rank2");
// 2008-11-04 v1.16 D.Nihei Add End
    // �i��ID
    Number itemId            = (Number)params.get("ItemId");
    // ���b�gNo
    String lotNo             = (String)params.get("LotNo");
    // �ŏI�X�V��
    String lotLastUpdateDate = (String)params.get("LotLastUpdateDate");

    // OUT�p�����[�^�p
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // �߂�l

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);

    sb.append("DECLARE "                                            );
    sb.append("  ln_api_version_number    CONSTANT NUMBER := 1.0; " );
    sb.append("  lv_ret_status            VARCHAR2(1); "            );
    sb.append("  ln_msg_cnt               NUMBER; "                 );
    sb.append("  lv_msg_data              VARCHAR2(5000); "         );
    sb.append("  lv_errbuf                VARCHAR2(5000); "         );
    sb.append("  lv_retcode               VARCHAR2(1); "            );
    sb.append("  lv_errmsg                VARCHAR2(5000); "         );
  
    // OPM���b�g�}�X�^�J�[�\��
    sb.append("  CURSOR p_lot_cur "                                 );
    sb.append("  IS "                                               );
    sb.append("    SELECT ilm.item_id "                             );
    sb.append("          ,ilm.lot_id "                              );
    sb.append("          ,ilm.lot_no "                              );
    sb.append("          ,ilm.sublot_no "                           );
    sb.append("          ,ilm.lot_desc "                            );
    sb.append("          ,ilm.qc_grade "                            );
    sb.append("          ,ilm.expaction_code "                      );
    sb.append("          ,ilm.expaction_date "                      );
    sb.append("          ,ilm.lot_created "                         );
    sb.append("          ,ilm.expire_date "                         );
    sb.append("          ,ilm.retest_date "                         );
    sb.append("          ,ilm.strength "                            );
    sb.append("          ,ilm.inactive_ind "                        );
    sb.append("          ,ilm.origination_type "                    );
    sb.append("          ,ilm.shipvend_id "                         );
    sb.append("          ,ilm.vendor_lot_no "                       );
    sb.append("          ,ilm.creation_date "                       );
    sb.append("          ,ilm.last_update_date "                    );
    sb.append("          ,ilm.created_by "                          );
    sb.append("          ,ilm.last_updated_by "                     );
    sb.append("          ,ilm.trans_cnt "                           );
    sb.append("          ,ilm.delete_mark "                         );
    sb.append("          ,ilm.text_code "                           );
    sb.append("          ,ilm.last_update_login "                   );
    sb.append("          ,ilm.program_application_id "              );
    sb.append("          ,ilm.program_id "                          );
    sb.append("          ,ilm.program_update_date "                 );
    sb.append("          ,ilm.request_id "                          );
    sb.append("          ,ilm.attribute1 "                          );  // �����N����
    sb.append("          ,ilm.attribute2 "                          );  // �ŗL�L��
    sb.append("          ,ilm.attribute3 "                          );  // �ܖ�����
    sb.append("          ,ilm.attribute4 "                          );  // �[�����i����j
    sb.append("          ,ilm.attribute5 "                          );  // �[�����i�ŏI�j
    sb.append("          ,ilm.attribute6 "                          );  // �݌ɓ���
    sb.append("          ,ilm.attribute7 "                          );  // �݌ɒP��
    sb.append("          ,ilm.attribute8 "                          );  // �����
    sb.append("          ,ilm.attribute9 "                          );  // �d���`��
    sb.append("          ,ilm.attribute10 "                         );  // �����敪
    sb.append("          ,ilm.attribute11 "                         );  // �N�x
    sb.append("          ,ilm.attribute12 "                         );  // �Y�n
    sb.append("          ,ilm.attribute13 "                         );  // �^�C�v
    sb.append("          ,ilm.attribute14 "                         );  // �����N�P
    sb.append("          ,ilm.attribute15 "                         );  // �����N�Q
    sb.append("          ,ilm.attribute16 "                         );  // ���Y�`�[�敪
    sb.append("          ,ilm.attribute17 "                         );  // ���C����
    sb.append("          ,ilm.attribute18 "                         );  // �E�v
    sb.append("          ,ilm.attribute19 "                         );  // �����N�R
    sb.append("          ,ilm.attribute20 "                         );  // ���������H��
    sb.append("          ,ilm.attribute22 "                         );  // �������������b�g�ԍ�
    sb.append("          ,ilm.attribute21 "                         );  // �����˗�No
    sb.append("          ,ilm.attribute23 "                         );  // ���b�g�X�e�[�^�X
    sb.append("          ,ilm.attribute24 "                         );  // �쐬�敪
    sb.append("          ,ilm.attribute25 "                         );  // DFF����25
    sb.append("          ,ilm.attribute26 "                         );  // DFF����26
    sb.append("          ,ilm.attribute27 "                         );  // DFF����27
    sb.append("          ,ilm.attribute28 "                         );  // DFF����28
    sb.append("          ,ilm.attribute29 "                         );  // DFF����29
    sb.append("          ,ilm.attribute30 "                         );  // DFF����30
    sb.append("          ,ilm.attribute_category "                  );  // DFF�J�e�S��
    sb.append("          ,ilm.odm_lot_number "                      );
    sb.append("    FROM   ic_lots_mst ilm "                           );
    sb.append("    WHERE  ilm.item_id = :1 "                         );  // �i��ID(35)
    sb.append("    AND    ilm.lot_no  = :2; "                        );  // ���b�gNo(238)
    sb.append("  p_lot_rec ic_lots_mst%ROWTYPE; "                   );
  
    sb.append("  CURSOR p_lot_cpg_cur( "                            );
    sb.append("    p_lot_id  ic_lots_cpg.lot_id%TYPE) "             );
    sb.append("  IS "                                               );
    sb.append("    SELECT ilc.item_id "                             );
    sb.append("          ,ilc.lot_id "                              );
    sb.append("          ,ilc.ic_matr_date "                        );
    sb.append("          ,ilc.ic_hold_date "                        );
    sb.append("          ,ilc.created_by "                          );
    sb.append("          ,ilc.creation_date "                       );
    sb.append("          ,ilc.last_update_date "                    );
    sb.append("          ,ilc.last_updated_by "                     );
    sb.append("          ,ilc.last_update_login "                   );
    sb.append("    FROM   ic_lots_cpg ilc "                           );
    sb.append("    WHERE  ilc.item_id = :1 "                         );  // �i��ID(35)
    sb.append("    AND    ilc.lot_id  = p_lot_id; "                  );  // ���b�gID(338)
    sb.append("  p_lot_cpg_rec ic_lots_cpg%ROWTYPE; "               );

    sb.append("BEGIN "                                              );

    // OPM���b�gMST�J�[�\�� OPEN
    sb.append("  OPEN p_lot_cur; "                                  );
    sb.append("  FETCH p_lot_cur INTO p_lot_rec; "                  );

    sb.append("  OPEN p_lot_cpg_cur(p_lot_rec.lot_id); "           );
    sb.append("  FETCH p_lot_cpg_cur INTO p_lot_cpg_rec; "          );

    // �X�V����������ꍇ�A�X�V�f�[�^���i�[
    sb.append("  p_lot_rec.attribute6       := :3; "                 );  // �݌ɓ���
    sb.append("  p_lot_rec.attribute1       := :4; "                 );  // �����N����
    sb.append("  p_lot_rec.attribute3       := :5; "                 );  // �ܖ�����
    sb.append("  p_lot_rec.attribute14      := :6; "                 );  // �����N1
// 2008-11-04 v1.16 D.Nihei Add Start ������Q#51�Ή� 
    sb.append("  p_lot_rec.attribute15      := :7; "                 );  // �����N2
// 2008-11-04 v1.16 D.Nihei Add End
    sb.append("  p_lot_rec.last_updated_by  := FND_GLOBAL.USER_ID; " );  // �ŏI�X�V��
    sb.append("  p_lot_rec.last_update_date := SYSDATE; "            );  // �ŏI�X�V��

    // ���b�g�X�VAPI�Ăяo��
    sb.append("  GMI_LOTUPDATE_PUB.UPDATE_LOT( "                                       );
    sb.append("                     p_api_version      => ln_api_version_number "      );  // IN  API�̃o�[�W�����ԍ�
    sb.append("                    ,p_init_msg_list    => FND_API.G_FALSE "            );  // IN  ���b�Z�[�W�������t���O
    sb.append("                    ,p_commit           => FND_API.G_FALSE "            );  // IN  �����m��t���O
    sb.append("                    ,p_validation_level => FND_API.G_VALID_LEVEL_FULL " );  // IN  ���؃��x��
    sb.append("                    ,x_return_status    => lv_ret_status "              );  // OUT �I���X�e�[�^�X('S'-����I��,'E'-��O����,'U'-�V�X�e����O����)
    sb.append("                    ,x_msg_count        => ln_msg_cnt "                 );  // OUT ���b�Z�[�W�E�X�^�b�N��
    sb.append("                    ,x_msg_data         => lv_msg_data "                );  // OUT ���b�Z�[�W
    sb.append("                    ,p_lot_rec          => p_lot_rec "                  );  // IN  �X�V���郍�b�g�����w��
    sb.append("                    ,p_lot_cpg_rec      => p_lot_cpg_rec); "            );  // IN  �X�V���郍�b�g�����w��

    sb.append("  CLOSE p_lot_cur; "                );
    sb.append("  CLOSE p_lot_cpg_cur; "            );

    // �G���[���b�Z�[�W��FND_LOG_MESSAGES�ɏo��
    sb.append("  IF (ln_msg_cnt > 0) THEN "        );
    sb.append("    xxcmn_common_pkg.put_api_log( " );
    sb.append("       ov_errbuf  => lv_errbuf "    );
    sb.append("      ,ov_retcode => lv_retcode "   );
    sb.append("      ,ov_errmsg  => lv_errmsg ); " );
    sb.append("  END IF; "                         );

    // OUT�p�����[�^�o��
    sb.append("  :8 := lv_ret_status; "            );
    sb.append("  :9 := ln_msg_cnt; "               );
    sb.append("  :10 := lv_msg_data; "              );

    sb.append("END; "                              );


    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
                                
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      int i = 1;
      cstmt.setInt(i++, XxcmnUtility.intValue(itemId)); // �i��ID
      cstmt.setString(i++, lotNo);                      // ���b�gNo
      cstmt.setString(i++, itemAmount);                 // �݌ɓ���
      cstmt.setString(i++, sProductionDate);            // �����N����
      cstmt.setString(i++, sUseByDate);                 // �ܖ�����
      cstmt.setString(i++, rank);                       // �����N1
// 2008-11-04 v1.16 D.Nihei Add Start ������Q#51�Ή� 
      cstmt.setString(i++, rank2);                       // �����N2
// 2008-11-04 v1.16 D.Nihei Add End

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(i++, Types.VARCHAR); // ���^�[���R�[�h
      cstmt.registerOutParameter(i++, Types.INTEGER); // ���b�Z�[�W��
      cstmt.registerOutParameter(i++, Types.VARCHAR); // ���b�Z�[�W
    
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      String retStatus = cstmt.getString(8);  // ���^�[���R�[�h
      int msgCnt       = cstmt.getInt(9);     // ���b�Z�[�W��
      String msgData   = cstmt.getString(10); // ���b�Z�[�W

//20080225 add Start
      // ����I���̏ꍇ�A�t���O��1:����ɁB
      if (XxcmnConstants.API_STATUS_SUCCESS.equals(retStatus)) 
      {
        // ���^�[���R�[�h������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;

      // ����I���łȂ��ꍇ�A�G���[  
      } else
      {
        // API�G���[���o�͂���B
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              msgData,
                              6);

        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);

      }
//20080225 add End      

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }

    // ����ɏ������ꂽ�ꍇ�A"SUCCESS"(1)��ԋp
    return XxcmnConstants.RETURN_SUCCESS;    
  } // updateIcLotsMstTxns

  /*****************************************************************************
   * �R���J�����g�F�����d���E�o�׎��э쐬�����𔭍s���܂��B
   * @param trans �g�����U�N�V����
   * @param params �p�����[�^�pHashMap
   * @return String XxcmnConstants.RETURN_SUCCESS:1 ����
   *                   XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException OA��O
   ****************************************************************************/
  public static String doDropShipResultsMake(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "doDropShipResultsMake";

    // IN�p�����[�^�擾
    String headerNumber    = (String)params.get("HeaderNumber");          // �����ԍ�

    // OUT�p�����[�^�p
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // �߂�l

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "   );
    sb.append("  ln_request_id NUMBER; "                                       );
    sb.append("BEGIN "                                                         );
                 // �����d���E�o�׎��э쐬����(�R���J�����g)�Ăяo��
    sb.append("  ln_request_id := FND_REQUEST.SUBMIT_REQUEST( "                );
    sb.append("     application  => 'XXPO' "                                   ); // �A�v���P�[�V������
    sb.append("    ,program      => 'XXPO320001C' "                            ); // �v���O�����Z�k��
    sb.append("    ,argument1    => :1 ); "                                    ); // ����No.
                 // �v��ID������ꍇ�A����
    sb.append("  IF ln_request_id > 0 THEN "                                   );
    sb.append("    :2 := '1'; "                                                ); // 1:����I��
    sb.append("    :3 := ln_request_id; "                                      ); // �v��ID
    //sb.append("    COMMIT; "                                                   );
                 // �v��ID������ꍇ�A����
    sb.append("  ELSE "                                                        );
    sb.append("    :2 := '0'; "                                                ); // 0:�ُ�I��
    sb.append("    :3 := ln_request_id; "                                      ); // �v��ID
    sb.append("    ROLLBACK; "                                                 );
    sb.append("  END IF; "                                                     );
    sb.append("END; "                                                          );

    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, headerNumber);               // �����ԍ�
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(2, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(3, Types.INTEGER);   // �v��ID

      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      retFlag = cstmt.getString(2); // ���^�[���R�[�h
      int requestId = cstmt.getInt(3); // �v��ID

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // ���^�[���R�[�h������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        
      // ����I���łȂ��ꍇ�A�G���[  
      } else
      {
        //�g�[�N������
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                   XxpoConstants.TOKEN_NAME_DS_RESULTS_MAKE) };
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                               XxcmnConstants.XXCMN05002, 
                               tokens);
      }
      
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }

    return retFlag;
  } // doDropShipResultsMake. 

// 20080226 add Start
  /*****************************************************************************
   * �ܖ��������̎Z�o���s���܂��B
   * @param trans �g�����U�N�V����
   * @param itemId INV�i��ID
   * @param productedDate ������
   * @param expirationDay �ܖ�����
   * @return Date �ܖ�������
   * @throws OAException OA��O
   ****************************************************************************/
  public static Date getUseByDateInvItem(
    OADBTransaction trans,
    Number itemId,
    Date productedDate,
    String expirationDay
  ) throws OAException
  {
    String apiName   = "getUseByDateInvItem";
    Date   useByDate = null;
    // �i��ID�A��������Null�̏ꍇ�͏������s��Ȃ��B
    if (XxcmnUtility.isBlankOrNull(itemId) 
      || XxcmnUtility.isBlankOrNull(productedDate)
      || XxcmnUtility.isBlankOrNull(expirationDay)) 
    {
      return null;
    }
    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                                     );
    sb.append("   SELECT :1 + NVL(ximv.expiration_day, 0) "); // �ܖ�����
    sb.append("   INTO   :2 "                              );
    sb.append("   FROM   xxcmn_item_mst_v ximv "           ); // OPM�i�ڏ��V
    sb.append("   WHERE  ximv.inventory_item_id = :3;    " ); // INV�i��ID
    sb.append("END; "                                      );

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setDate(1, XxcmnUtility.dateValue(productedDate)); // ���Y��
      cstmt.setInt(3, XxcmnUtility.intValue(itemId));          // �i��ID
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(2, Types.DATE);               // �ܖ�����

      // PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      useByDate = new Date(cstmt.getDate(2));

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return useByDate;
  } // getUseByDateInvItem
// 20080226 add End

  /*****************************************************************************
   * �����w�b�_�A�h�I�����b�N���擾���܂��B�r���G���[�`�F�b�N���s���܂��B
   * @param trans �g�����U�N�V����
   * @param xxpoHeaderId - �����w�b�_�A�h�I��ID
   * @param lastUpdateDate - �ŏI�X�V��
   * @return String XxcmnConstants.RETURN_SUCCESS:1  ����
   *                 XxcmnConstants.RETURN_NOT_EXE:0  �V�X�e���G���[
   *                 XxcmnConstants.RETURN_ERR1:   E1 ���b�N�G���[
   *                 XxcmnConstants.RETURN_ERR2:   E2 �r���G���[
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String getXxpoPoHeadersAllLock(
    OADBTransaction trans,
    Number xxpoHeaderId,
    String lastUpdateDate
  ) throws OAException
  {
    String apiName = "getXxpoPoHeadersAllLock";
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // �߂�l
    
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                                                          );
    sb.append("  lv_temp_date          VARCHAR2(100) ; "                                          ); // �ŏI�X�V��
                 // ���[�U�[��`�G���[
    sb.append("  lock_expt             EXCEPTION; "                                               ); // ���b�N�G���[
    sb.append("  exclusive_expt        EXCEPTION; "                                               ); // �r���G���[
    sb.append("  PRAGMA EXCEPTION_INIT(lock_expt, -54); "                                         );
    
    sb.append("BEGIN "                                                                            );
                 // ���b�N�擾
    sb.append("  SELECT TO_CHAR(xpha.last_update_date,'YYYY/MM/DD HH24:MI:SS')  last_update_date ");
    sb.append("  INTO   lv_temp_date "                                                            );
    sb.append("  FROM   xxpo_headers_all xpha "                                                   );
    sb.append("  WHERE  xpha.xxpo_header_id = :1 "                                                );
    sb.append("  FOR UPDATE NOWAIT; "                                                             );
                 // �r���`�F�b�N�E�E�E���̃��[�U�[�ɍX�V����Ă��Ȃ����`�F�b�N
    sb.append("  IF (lv_temp_date <> :2) THEN "                                                   );
    sb.append("    RAISE exclusive_expt; "                                                        );
    sb.append("  END IF; "                                                                        );
    sb.append("EXCEPTION "                                                                        );
    sb.append("  WHEN lock_expt THEN "                                                            );
    sb.append("    :3 := '1'; "                                                                   ); // 1:���b�N�G���[
    sb.append("    :4 := SQLERRM; "                                                               ); // SQLERR���b�Z�[�W
    sb.append("  WHEN exclusive_expt THEN "                                                       );
    sb.append("    :3 := '2'; "                                                                   ); // 2:�r���`�F�b�N�G���[
    sb.append("    :4 := SQLERRM; "                                                               ); // SQLERR���b�Z�[�W
    sb.append("END; "                                                                             );

    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1, XxcmnUtility.intValue(xxpoHeaderId));     // �����w�b�_�A�h�I��ID
      cstmt.setString(2, lastUpdateDate);                         // �ŏI�X�V��
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(3, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(4, Types.VARCHAR);   // �G���[���b�Z�[�W
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      String ret = cstmt.getString(3); // ���^�[���R�[�h

      // ���b�N�G���[�I���̏ꍇ  
      if ("1".equals(ret))
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(4),
                              6);
        // �߂�l E1:���b�N�G���[���Z�b�g
        retFlag = XxcmnConstants.RETURN_ERR1;

       // �r���G���[�I���̏ꍇ  
      } else if ("2".equals(ret))
      {
        // ���[���o�b�N
        rollBack(trans);
        // �߂�l E2:�r���G���[���Z�b�g
        retFlag = XxcmnConstants.RETURN_ERR2;

      // ����I���̏ꍇ
      } else
      {
        // �߂�l 1:������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
                              
      }
    }
    // �߂�l
    return retFlag;
  } // getXxpoPoHeadersAllLock
  
  /*****************************************************************************
   * �����w�b�_�A�h�I���̔��������t���O���X�V���܂��B
   * @param trans �g�����U�N�V����
   * @param xxpoHeaderId - �����w�b�_�A�h�I��ID
   * @return String XxcmnConstants.RETURN_SUCCESS:1 ����
   *                 XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String doOrderApproving(
    OADBTransaction trans,
    Number          xxpoHeaderId
  ) throws OAException
  {
    String apiName = "doOrderApproving";
  
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                    );
                 // �����w�b�_(�A�h�I��)�o�^
    sb.append("  UPDATE xxpo_headers_all xha "                            );
    sb.append("  SET    xha.last_updated_by       = FND_GLOBAL.USER_ID "  ); // �ŏI�X�V��
    sb.append("        ,xha.last_update_date      = SYSDATE "             ); // �ŏI�X�V��
    sb.append("        ,xha.last_update_login     = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C��
    sb.append("        ,xha.order_approved_flg    = 'Y'  "                ); // ���������t���O
    sb.append("        ,xha.order_approved_by     = FND_GLOBAL.USER_ID  " ); // ���������҃��[�U�[ID
    sb.append("        ,xha.order_approved_date   = SYSDATE  "            ); // �����������t
    sb.append("  WHERE  xha.xxpo_header_id        = :1;  "                ); // �����w�b�_�A�h�I��ID
    sb.append("END; "                                                     );

    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1,  XxcmnUtility.intValue(xxpoHeaderId));    // �����w�b�_�A�h�I��ID

      //PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return XxcmnConstants.RETURN_SUCCESS;
  } // doOrderApproving

  /*****************************************************************************
   * �����w�b�_�A�h�I���̎d�������t���O���X�V���܂��B
   * @param trans �g�����U�N�V����
   * @return String XxcmnConstants.RETURN_SUCCESS:1 ����
   *                 XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String doPurchaseApproving(
    OADBTransaction trans,
    Number          xxpoHeaderId
  )throws OAException
  {
    String apiName = "doPurchaseApproving";
    
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                    );
                 // �����w�b�_(�A�h�I��)�o�^
    sb.append("  UPDATE xxpo_headers_all xha "                            );
    sb.append("  SET    xha.last_updated_by       = FND_GLOBAL.USER_ID "  ); // �ŏI�X�V��
    sb.append("        ,xha.last_update_date      = SYSDATE "             ); // �ŏI�X�V��
    sb.append("        ,xha.last_update_login     = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C��
    sb.append("        ,xha.purchase_approved_flg = 'Y'  "                ); // �d�������t���O
    sb.append("        ,xha.purchase_approved_by  = FND_GLOBAL.USER_ID  " ); // �d�������҃��[�U�[ID
    sb.append("        ,xha.purchase_approved_date= SYSDATE  "            ); // �d���������t
    sb.append("  WHERE  xha.xxpo_header_id        = :1;  "                ); // �����w�b�_�A�h�I��ID
    sb.append("END; "                                                     );

    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1,  XxcmnUtility.intValue(xxpoHeaderId)); // �����w�b�_�A�h�I��ID

      //PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        // PL/SQL�N���[�Y
        cstmt.close();

      // �N���[�Y���ɗ�O�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return XxcmnConstants.RETURN_SUCCESS;
  } // doPurchaseApproving

  /*****************************************************************************
   * �󒍃w�b�_�A�h�I���̃X�e�[�^�X���X�V���܂��B
   * @param trans         - �g�����U�N�V����
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   * @param transStatus   - �X�V�ΏۃX�e�[�^�X
   * @throws OAException  - OA��O
   ****************************************************************************/
  public static void updateTransStatus(
    OADBTransaction trans,
    Number orderHeaderId,
    String transStatus
    ) throws OAException
  {
    String apiName = "updateTransStatus";
  
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                    );
    sb.append("  UPDATE xxwsh_order_headers_all xoha"); // �󒍃w�b�_�A�h�I��
    sb.append("  SET    xoha.req_status        = :1 ");                  // �X�e�[�^�X
    sb.append("        ,xoha.last_updated_by   = FND_GLOBAL.USER_ID ");  // �ŏI�X�V��
    sb.append("        ,xoha.last_update_date  = SYSDATE ");             // �ŏI�X�V��
    sb.append("        ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID "); // �ŏI�X�V���O�C��
    sb.append("  WHERE  xoha.order_header_id   = :2;  ");                // �����w�b�_�A�h�I��ID
    // �X�V�X�e�[�^�X���u����v�̏ꍇ
    if (XxpoConstants.PROV_STATUS_CAN.equals(transStatus)) 
    {
      // ���׍s�̍폜�t���O���X�V���܂��B
      sb.append("  UPDATE xxwsh_order_lines_all xola"); // �󒍖��׃A�h�I��
      sb.append("  SET    xola.delete_flag       = 'Y' ");                 // �폜�t���O
      sb.append("        ,xola.last_updated_by   = FND_GLOBAL.USER_ID ");  // �ŏI�X�V��
      sb.append("        ,xola.last_update_date  = SYSDATE ");             // �ŏI�X�V��
      sb.append("        ,xola.last_update_login = FND_GLOBAL.LOGIN_ID "); // �ŏI�X�V���O�C��
      sb.append("  WHERE  xola.order_header_id   = :3;  ");                // �����w�b�_�A�h�I��ID
    }
    sb.append("END; ");
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, transStatus);                        // �X�e�[�^�X
      cstmt.setInt(2,  XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID
      if (XxpoConstants.PROV_STATUS_CAN.equals(transStatus)) 
      {
        cstmt.setInt(3,  XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID
      }
      //PL/SQL���s
      cstmt.execute();
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateTransStatus

  /*****************************************************************************
   * �󒍃w�b�_�A�h�I���̒ʒm�X�e�[�^�X���X�V���܂��B
   * @param trans           - �g�����U�N�V����
   * @param orderHeaderId   - �󒍃w�b�_�A�h�I��ID
   * @param notifStatus     - �X�V�Ώےʒm�X�e�[�^�X
   * @throws OAException    - OA��O
   ****************************************************************************/
  public static void updateNotifStatus(
    OADBTransaction trans,
    Number orderHeaderId,
    String notifStatus
    ) throws OAException
  {
    String apiName = "updateNotifStatus";
  
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                    );
    sb.append("  UPDATE xxwsh_order_headers_all xoha "); // �󒍃w�b�_�A�h�I��
    sb.append("  SET    xoha.notif_status      = :1 ");                   // �ʒm�X�e�[�^�X
    sb.append("        ,xoha.prev_notif_status = xoha.notif_status   ");  // �O��ʒm�X�e�[�^�X
    sb.append("        ,xoha.notif_date        = SYSDATE             ");  // �m��ʒm���{����
    sb.append("        ,xoha.last_updated_by   = FND_GLOBAL.USER_ID  ");  // �ŏI�X�V��
    sb.append("        ,xoha.last_update_date  = SYSDATE             ");  // �ŏI�X�V��
    sb.append("        ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID ");  // �ŏI�X�V���O�C��
    sb.append("  WHERE  xoha.order_header_id   = :2;  ");                 // �����w�b�_�A�h�I��ID
    sb.append("END; ");
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, notifStatus);                        // �X�e�[�^�X
      cstmt.setInt(2,  XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID
      //PL/SQL���s
      cstmt.execute();
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateNotifStatus

  /*****************************************************************************
   * �󒍃w�b�_�A�h�I���̗L�����z�m��敪���X�V���܂��B
   * @param trans         - �g�����U�N�V����
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   * @param fixClass      - �L�����z�m��敪
   * @throws OAException  - OA��O
   ****************************************************************************/
  public static void updateFixClass(
    OADBTransaction trans,
    Number orderHeaderId,
    String fixClass
    ) throws OAException
  {
    String apiName = "updateFixClass";
  
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
// 2009-05-13 v1.26 T.Yoshimoto Mod Start �{��#1282
/*
    sb.append("BEGIN "                                                    );
    sb.append("  UPDATE xxwsh_order_headers_all xoha "); // �󒍃w�b�_�A�h�I��
    sb.append("  SET    xoha.amount_fix_class  = :1  "); // �L�����z�m��敪
// 2009-01-20 v1.22 T.Yoshimoto Add Start �{��#739
    sb.append("        ,xoha.performance_management_dept = xxcmn_common_pkg.get_user_dept_code(FND_GLOBAL.USER_ID, NULL) " );
// 2009-01-20 v1.22 T.Yoshimoto Add Start �{��#739
    sb.append("        ,xoha.last_updated_by   = FND_GLOBAL.USER_ID  ");  // �ŏI�X�V��
    sb.append("        ,xoha.last_update_date  = SYSDATE             ");  // �ŏI�X�V��
    sb.append("        ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID ");  // �ŏI�X�V���O�C��
    sb.append("  WHERE  xoha.order_header_id   = :2;  ");                 // �����w�b�_�A�h�I��ID
    sb.append("END; ");
*/
    sb.append("DECLARE "                                                  );
    sb.append("  ln_count   NUMBER; "                                     ); 
    sb.append("BEGIN "                                                    );

    sb.append("  SELECT COUNT(header_id) "                                );
    sb.append("  INTO ln_count "                                          );
    sb.append("  FROM xxwsh_order_headers_all "                           );
    sb.append("  WHERE order_header_id = :1 "                             );  // �󒍃w�b�_�A�h�I��ID
    sb.append("  ; "                                                      );

    sb.append("  IF ( ln_count = 0) THEN "                                );
    sb.append("    UPDATE xxwsh_order_headers_all xoha "                  );  // �󒍃w�b�_�A�h�I��
    sb.append("    SET    xoha.amount_fix_class  = :2  "                  );  // �L�����z�m��敪
    sb.append("          ,xoha.performance_management_dept = xxcmn_common_pkg.get_user_dept_code(FND_GLOBAL.USER_ID, NULL) " );
    sb.append("          ,xoha.last_updated_by   = FND_GLOBAL.USER_ID  "  );  // �ŏI�X�V��
    sb.append("          ,xoha.last_update_date  = SYSDATE             "  );  // �ŏI�X�V��
    sb.append("          ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID "  );  // �ŏI�X�V���O�C��
    sb.append("    WHERE  xoha.order_header_id   = :3;  "                 );  // �󒍃w�b�_�A�h�I��ID
    sb.append("  ELSE "                                                   );
    sb.append("    UPDATE xxwsh_order_headers_all xoha "                  );  // �󒍃w�b�_�A�h�I��
    sb.append("    SET    xoha.amount_fix_class  = :4  "                  );  // �L�����z�m��敪
    sb.append("          ,xoha.performance_management_dept = xxcmn_common_pkg.get_user_dept_code(FND_GLOBAL.USER_ID, NULL) " );
    sb.append("          ,xoha.last_updated_by   = FND_GLOBAL.USER_ID  "  );  // �ŏI�X�V��
    sb.append("          ,xoha.last_update_date  = SYSDATE             "  );  // �ŏI�X�V��
    sb.append("          ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID "  );  // �ŏI�X�V���O�C��
    sb.append("    WHERE  xoha.order_header_id   = :5;  "                 );  // �󒍃w�b�_�A�h�I��ID

    sb.append("    UPDATE oe_order_headers_all o "                        );  // EBS�W��.�󒍃w�b�_
    sb.append("    SET    o.attribute11  = xxcmn_common_pkg.get_user_dept_code(FND_GLOBAL.USER_ID, NULL) " );
    sb.append("    WHERE  o.header_id    = (SELECT header_id "             );
    sb.append("                             FROM xxwsh_order_headers_all " );
    sb.append("                             WHERE order_header_id = :6); " );  // �󒍃w�b�_�A�h�I��ID
    sb.append("  END IF; "                                                 );
    sb.append("END; "                                                      );
// 2009-05-13 v1.26 T.Yoshimoto Mod End �{��#1282

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
// 2009-05-13 v1.26 T.Yoshimoto Mod Start �{��#1282
/*
      cstmt.setString(1, fixClass);                           // �L�����z�m��敪
      cstmt.setInt(2,  XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID
*/
      cstmt.setInt(1,  XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID
      cstmt.setString(2, fixClass);                           // �L�����z�m��敪
      cstmt.setInt(3,  XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID
      cstmt.setString(4, fixClass);                           // �L�����z�m��敪
      cstmt.setInt(5,  XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID
      cstmt.setInt(6,  XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID
// 2009-05-13 v1.26 T.Yoshimoto Mod End �{��#1282
      //PL/SQL���s
      cstmt.execute();
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateFixClass

  /*****************************************************************************
   * �󒍃w�b�_�E���׃A�h�I�����b�N���擾���܂��B
   * @param trans �g�����U�N�V����
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean getXxwshOrderLock(
    OADBTransaction trans,
    Number orderHeaderId
  ) throws OAException
  {
    String apiName = "getXxwshOrderLock";
    boolean retFlag = true; // �߂�l
    
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  CURSOR xo_cur ");
    sb.append("  IS ");
    sb.append("    SELECT xoha.order_header_id ");
    sb.append("    FROM   xxwsh_order_headers_all xoha   "); // �󒍃w�b�_�A�h�I��
    sb.append("          ,xxwsh_order_lines_all   xola   "); // �󒍖��׃A�h�I��
    sb.append("    WHERE  xoha.order_header_id = xola.order_header_id(+) ");
    sb.append("    AND    xoha.order_header_id = :1   ");
    sb.append("    FOR UPDATE OF xoha.order_header_id ");
    sb.append("                 ,xola.order_header_id NOWAIT; ");
    sb.append("BEGIN ");
    sb.append("  OPEN  xo_cur; ");
    sb.append("  CLOSE xo_cur; ");
    sb.append("END; ");
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1, XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID
      
      //PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // ���b�N�G���[
      retFlag = false;
                            
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
                              
      }
    }
    return retFlag;
  } // getXxwshOrderLock

  /***************************************************************************
   * �󒍃w�b�_�E���׃A�h�I���̔r������`�F�b�N���s�����\�b�h�ł��B
   * @param trans �g�����U�N�V����
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   * @param xohaLastUpdateDate - �󒍃w�b�_�ŏI�X�V��
   * @param xolaLastUpdateDate - �󒍖��ׂ̍ő�ŏI�X�V��
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public static boolean chkExclusiveXxwshOrder(
    OADBTransaction trans,
    Number orderHeaderId,
    String xohaLastUpdateDate,
    String xolaLastUpdateDate
  )
  {
    String apiName  = "chkExclusiveXxwshOrder";
    CallableStatement cstmt = null;
    boolean retFlag = true; // �߂�l

    try
    {
      // PL/SQL�̍쐬���s���܂�
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT TO_CHAR(xoha.last_update_date, 'YYYY/MM/DD HH24:MI:SS') ");
      sb.append("        ,TO_CHAR(xola.last_update_date, 'YYYY/MM/DD HH24:MI:SS') ");
      sb.append("  INTO   :1 ");
      sb.append("        ,:2 ");
      sb.append("  FROM   xxwsh_order_headers_all xoha "); // �󒍃w�b�_�A�h�I��
      sb.append("        ,(SELECT xol.order_header_id       order_header_id  ");
      sb.append("                ,MAX(xol.last_update_date) last_update_date ");
      sb.append("          FROM   xxwsh_order_lines_all xol   ");
      sb.append("          GROUP BY xol.order_header_id) xola "); // �󒍖��׃A�h�I��
      sb.append("  WHERE  xoha.order_header_id = xola.order_header_id ");
      sb.append("  AND    xoha.order_header_id = :3 ");
      sb.append("  AND    ROWNUM               = 1  ");
      sb.append("  ;  ");
      sb.append("END; ");

      // PL/SQL�̐ݒ���s���܂�
      cstmt = trans.createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);
      // PL/SQL�����s���܂�
      int i = 1;
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));
      // SQL���s
      cstmt.execute();

      String dbXohaLastUpdateDate = cstmt.getString(1);
      String dbXolaLastUpdateDate = cstmt.getString(2);
      // �r���G���[�̏ꍇ
      if (!XxcmnUtility.isEquals(xohaLastUpdateDate, dbXohaLastUpdateDate)
       || !XxcmnUtility.isEquals(xolaLastUpdateDate, dbXolaLastUpdateDate)) 
      {
        retFlag = false;
      }
    } catch (SQLException s) 
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally 
    {
      try 
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s) 
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
    return retFlag;
  } // chkExclusiveXxwshOrder

  /*****************************************************************************
   * �󒍖��ׂ̎��ѐ��ʃ`�F�b�N���s���܂��B
   * @param trans �g�����U�N�V����
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   * @param rec - ���R�[�h�^�C�v
   * @return boolean - ���эσt���O true:���і�����
   *                              false:���їL
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean chkOrderResult(
    OADBTransaction trans,
    Number orderHeaderId,
    String rec
  ) throws OAException
  {
    String apiName = "chkOrderResult";
    boolean retFlag = true; // �߂�l

    // ���ѐ��ʊm�F�p��PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  SELECT COUNT(1) ");
    sb.append("  INTO   :1 ");
    sb.append("  FROM   xxwsh_order_lines_all xola  "); // �󒍖��׃A�h�I��
    sb.append("  WHERE  xola.order_header_id  = :2  ");
    // ���R�[�h�^�C�v��'20'(�o��)
    if (XxpoConstants.REC_TYPE_20.equals(rec)) 
    {
      sb.append("  AND    xola.shipped_quantity IS NOT NULL ");

    // ���R�[�h�^�C�v��'30'(����)
    } else if (XxpoConstants.REC_TYPE_30.equals(rec)) 
    {
      sb.append("  AND    xola.ship_to_quantity IS NOT NULL ");
    }
    sb.append("  AND    xola.delete_flag = 'N' ");
    sb.append("  AND    ROWNUM           = 1;  ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

     try
    {
      //�o�C���h�ϐ��ɒl���Z�b�g
      cstmt.registerOutParameter(1, Types.INTEGER);
      cstmt.setInt(2, XxcmnUtility.intValue(orderHeaderId));

      // PL/SQL���s
      cstmt.execute();

      // �p�����[�^�̎擾
      int cnt = cstmt.getInt(1);

      // 1���ł����݂����ꍇ
      if (cnt == 1)
      {
        // ���ѓ��͗L
        retFlag = false; 

      }
     
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // chkOrderResult

  /*****************************************************************************
   * �����\���ʎ擾���s���܂��B
   * @param trans �g�����U�N�V����
   * @param itemId OPM�i��ID
   * @param locationCode �[����R�[�h
   * @param lotId ���b�gID
   * @param orderDivision �����敪
   * @return HashMap
   * @throws OAException OA��O
   ****************************************************************************/
  public static HashMap getReservedQuantity(
    OADBTransaction trans,
    Number itemId,
    String locationCode,
    Number lotId,
    String orderDivision
  ) throws OAException
  {

    String apiName    = "getReservedQuantity";
    HashMap paramsRet = new HashMap();

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" DECLARE                                                        ");
    // �ϐ��錾
    sb.append("   ln_can_enc_in_time_qty  NUMBER;                              ");   // �L�����x�[�X�����\��
    sb.append("   ln_can_enc_total_qty    NUMBER;                              ");   // �������\��
    sb.append("   ln_can_encl_qty         NUMBER;                              ");   // �����\��
    sb.append("   ln_location_id          NUMBER;                              ");   // OPM�ۊǑq��ID
    sb.append(" BEGIN ");
    
// 20080630 yoshimoto add Start
// 2008-10-22 H.Itou Del Start �����e�X�g�w�E49,�ύX�v��#238
//    if (XxpoConstants.PO_TYPE_3.equals(orderDivision)) 
//    {
// 2008-10-22 H.Itou Del End
    sb.append("   SELECT xcilv.inventory_location_id                           ");
    sb.append("   INTO  ln_location_id                                         ");
    sb.append("   FROM xxcmn_item_locations_v xcilv                            ");
    sb.append("   WHERE xcilv.segment1 = :1;                                   ");     // IN�p�����[�^1(�����݌ɓ��ɐ�R�[�h)
// 2008-10-22 H.Itou Del Start �����e�X�g�w�E49,�ύX�v��#238
//    } else 
//    {
//// 20080630 yoshimoto add Start
//      // OPM�ۊǑq��ID���擾
//      sb.append("   SELECT xcilv.location_id                                     ");
//      sb.append("   INTO  ln_location_id                                         ");
//      sb.append("   FROM xxcmn_item_locations_v xcilv                            ");
//      sb.append("   WHERE xcilv.segment1 = :1;                                   ");     // IN�p�����[�^1(�[����R�[�h)
//    }
// 2008-10-22 H.Itou Del End

    // �L�����x�[�X�����\�����擾
    sb.append("   :2 := xxcmn_common_pkg.get_can_enc_in_time_qty(              ");     // OUT�p�����[�^4(�L�����x�[�X�����\��)
    sb.append("                               in_whse_id     => ln_location_id ");     // OPM�ۊǑq��ID
    sb.append("                              ,in_item_id     => :3             ");     // IN�p�����[�^2(OPM�i��ID)
    sb.append("                              ,in_lot_id      => :4             ");     // IN�p�����[�^3(���b�gID)
    sb.append("                              ,in_active_date => SYSDATE);      ");     // �L����

    // �������\�����擾
    sb.append("   :5 := xxcmn_common_pkg.get_can_enc_total_qty(                ");     // OUT�p�����[�^5(�������\��)
    sb.append("                               in_whse_id     => ln_location_id ");     // OPM�ۊǑq��ID
    sb.append("                              ,in_item_id     => :6             ");     // IN�p�����[�^2(OPM�i��ID)
    sb.append("                              ,in_lot_id      => :7);           ");     // IN�p�����[�^3(���b�gID)
    sb.append(" END;                                                           ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // ************************************** //
      // * �L�����x�[�X�����\���ւ̃o�C���h * //
      // ************************************** //
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, locationCode);               // �[����R�[�h
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(2, Types.INTEGER);   // �L�����x�[�X�����\��

      cstmt.setInt(3, XxcmnUtility.intValue(itemId)); // OPM�i��ID

      if (XxcmnUtility.isBlankOrNull(lotId))
      {
        cstmt.setNull(4, Types.INTEGER);
      } else
      {
        cstmt.setInt(4, XxcmnUtility.intValue(lotId));  // ���b�gID
      }
      
      // ************************************** //
      // * �������\���ւ̃o�C���h           * //
      // ************************************** //      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(5, Types.INTEGER);   // �������\��

      cstmt.setInt(6, XxcmnUtility.intValue(itemId)); // OPM�i��ID

      if (XxcmnUtility.isBlankOrNull(lotId))
      {
        cstmt.setNull(7, Types.INTEGER);
      } else
      {
        cstmt.setInt(7, XxcmnUtility.intValue(lotId));  // ���b�gID
      }
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      paramsRet.put("InTimeQty", cstmt.getObject(2));   // �L�����x�[�X�����\��
      paramsRet.put("TotalQty",  cstmt.getObject(5));   // �������\��

      return paramsRet;

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getReservedQuantity

  /*****************************************************************************
   * ����ԕi����(�A�h�I��)�Ƀf�[�^��ǉ����܂��B
   * @param trans �g�����U�N�V����
   * @param setParams �p�����[�^
   * @return HashMap    
   * @throws OAException OA��O
   ****************************************************************************/
  public static HashMap insertRcvAndRtnTxns(
    OADBTransaction trans,
    HashMap setParams
  ) throws OAException
  {
    String apiName      = "insertRcvAndRtnTxns";

    // IN�p�����[�^�擾
    // ���ы敪
    String txnsType              = (String)setParams.get("TxnsType");
    // ����ԕi�ԍ�
    String rcvRtnNumber          = (String)setParams.get("RcvRtnNumber");
    // �������ԍ�
    String sourceDocumentNumber  = (String)setParams.get("SourceDocumentNumber");
    // �����ID
    Number vendorId              = (Number)setParams.get("VendorId");
    // �����R�[�h
    String vendorCode            = (String)setParams.get("VendorCode");
    // ���o�ɐ�R�[�h
    String locationCode          = (String)setParams.get("LocationCode");
    // ���������הԍ�
    Number sourceDocumentLineNum = (Number)setParams.get("SourceDocumentLineNum");
    // ����ԕi���הԍ�
    Number rcvRtnLineNumber      = (Number)setParams.get("RcvRtnLineNumber");
    // �i��ID
    Number itemId                = (Number)setParams.get("ItemId");
    // �i�ڃR�[�h
    String itemCode              = (String)setParams.get("ItemCode");
    // ���b�gID
    Number lotId                 = (Number)setParams.get("LotId");
    // ���b�gNo
    String lotNumber             = (String)setParams.get("LotNumber");
    // �����
    Date txnsDate                = (Date)setParams.get("TxnsDate");
    // ����ԕi����
    String rcvRtnQuantity        = (String)setParams.get("RcvRtnQuantity");
    // ����ԕi�P��
    String rcvRtnUom             = (String)setParams.get("RcvRtnUom");
    // �P�ʃR�[�h
    String uom                   = (String)setParams.get("Uom");
    // ���דE�v
    String lineDescription       = (String)setParams.get("LineDescription");
    // ����
    String quantity              = (String)setParams.get("Quantity");
    // ���Z����
    String conversionFactor      = (String)setParams.get("ConversionFactor");
    // �����敪
    String dropshipCode          = (String)setParams.get("DropshipCode");
    // �P��
    Number unitPrice             = (Number)setParams.get("UnitPrice");
// 20080520 add yoshimoto Start
    // ���������R�[�h
    String departmentCode        = (String)setParams.get("DepartmentCode");
// 20080520 add yoshimoto End

    // OUT�p�����[�^�p
    HashMap retHashMap = new HashMap();
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" DECLARE "                                                       );
    sb.append("   lt_txns_id xxpo_rcv_and_rtn_txns.txns_id%TYPE; "              );
    sb.append(" BEGIN "                                                         );
    sb.append("   SELECT xxpo_rcv_and_rtn_txns_s1.NEXTVAL "                     );
    sb.append("   INTO   lt_txns_id "                                           );
    sb.append("   FROM   DUAL; "                                                );

    sb.append("   INSERT INTO xxpo_rcv_and_rtn_txns rart( "                     );
    sb.append("     rart.txns_id "                                              );  // ���ID
    sb.append("     ,rart.txns_type "                                           );  // ���ы敪        
    sb.append("     ,rart.rcv_rtn_number "                                      );  // ����ԕi�ԍ�    
    sb.append("     ,rart.source_document_number "                              );  // �������ԍ�      
    sb.append("     ,rart.vendor_id "                                           );  // �����ID        
    sb.append("     ,rart.vendor_code "                                         );  // �����R�[�h    
    sb.append("     ,rart.location_code "                                       );  // ���o�ɐ�R�[�h  
    sb.append("     ,rart.source_document_line_num "                            );  // ���������הԍ�  
    sb.append("     ,rart.rcv_rtn_line_number "                                 );  // ����ԕi���הԍ�
    sb.append("     ,rart.item_id "                                             );  // �i��ID          
    sb.append("     ,rart.item_code "                                           );  // �i�ڃR�[�h      
    sb.append("     ,rart.lot_id "                                              );  // ���b�gID        
    sb.append("     ,rart.lot_number "                                          );  // ���b�gNo        
    sb.append("     ,rart.txns_date "                                           );  // �����          
    sb.append("     ,rart.rcv_rtn_quantity "                                    );  // ����ԕi����    
    sb.append("     ,rart.rcv_rtn_uom "                                         );  // ����ԕi�P��    
    sb.append("     ,rart.quantity "                                            );  // ����            
    sb.append("     ,rart.uom "                                                 );  // �P�ʃR�[�h      
    sb.append("     ,rart.conversion_factor "                                   );  // ���Z����        
    sb.append("     ,rart.line_description "                                    );  // ���דE�v        
    sb.append("     ,rart.drop_ship_type "                                      );  // �����敪
    sb.append("     ,rart.unit_price "                                          );  // �P��
    sb.append("     ,rart.department_code "                                     );  // ���������R�[�h  //20080520 add yoshimoto
    sb.append("     ,rart.created_by "                                          );  // �쐬��          
    sb.append("     ,rart.creation_date "                                       );  // �쐬��          
    sb.append("     ,rart.last_updated_by "                                     );  // �ŏI�X�V��      
    sb.append("     ,rart.last_update_date "                                    );  // �ŏI�X�V��      
    sb.append("     ,rart.last_update_login) "                                  );  // �ŏI�X�V���O�C��

    sb.append("   VALUES( "                                                     );
    sb.append("     lt_txns_id "                                                );  // ���ID
    sb.append("     ,:1 "                                                       );  // ���ы敪        
    sb.append("     ,:2 "                                                       );  // ����ԕi�ԍ�    
    sb.append("     ,:3 "                                                       );  // �������ԍ�      
    sb.append("     ,:4 "                                                       );  // �����ID        
    sb.append("     ,:5 "                                                       );  // �����R�[�h    
    sb.append("     ,:6 "                                                       );  // ���o�ɐ�R�[�h  
    sb.append("     ,:7 "                                                       );  // ���������הԍ�  
    sb.append("     ,:8 "                                                       );  // ����ԕi���הԍ�
    sb.append("     ,:9 "                                                       );  // �i��ID          
    sb.append("     ,:10 "                                                       );  // �i�ڃR�[�h      
    sb.append("     ,:11 "                                                      );  // ���b�gID        
    sb.append("     ,:12 "                                                      );  // ���b�gNo        
    sb.append("     ,:13 "                                                      );  // �����          
    sb.append("     ,:14 "                                                      );  // ����ԕi����    
    sb.append("     ,:15 "                                                      );  // ����ԕi�P��    
    sb.append("     ,:16 "                                                      );  // ����            
    sb.append("     ,:17 "                                                      );  // �P�ʃR�[�h      
    sb.append("     ,:18 "                                                      );  // ���Z����        
    sb.append("     ,:19 "                                                      );  // ���דE�v        
    sb.append("     ,:20 "                                                      );  // �����敪        
    sb.append("     ,:21 "                                                      );  // �P��
    sb.append("     ,:22 "                                                      );  // ���������R�[�h  //20080520 add yoshimoto
    sb.append("     ,FND_GLOBAL.USER_ID "                                       );  // �쐬��          
    sb.append("     ,SYSDATE "                                                  );  // �쐬��          
    sb.append("     ,FND_GLOBAL.USER_ID "                                       );  // �ŏI�X�V��      
    sb.append("     ,SYSDATE "                                                  );  // �ŏI�X�V��      
    sb.append("     ,FND_GLOBAL.LOGIN_ID "                                      );  // �ŏI�X�V���O�C��
    sb.append("   ); "                                                          );

// 20080520 mod yoshimoto Start
//    sb.append("   :22 := '1'; "                                                 );
//    sb.append("   :23 := lt_txns_id; "                                          );
    sb.append("   :23 := '1'; "                                                 );
    sb.append("   :24 := lt_txns_id; "                                          );
// 20080520 mod yoshimoto End
    sb.append(" END; "                                                          );
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      
      cstmt.setString(1, txnsType);                                     // ���ы敪
      cstmt.setString(2, rcvRtnNumber);                                 // ����ԕi�ԍ�
      cstmt.setString(3, sourceDocumentNumber);                         // �������ԍ�
      cstmt.setInt(4, XxcmnUtility.intValue(vendorId));                 // �����ID
      cstmt.setString(5, vendorCode);                                   // �����R�[�h
      cstmt.setString(6, locationCode);                                 // ���o�ɐ�R�[�h
      cstmt.setInt(7, XxcmnUtility.intValue(sourceDocumentLineNum));    // ���������הԍ�
      cstmt.setInt(8, XxcmnUtility.intValue(rcvRtnLineNumber));         // ����ԕi���הԍ�
      cstmt.setInt(9, XxcmnUtility.intValue(itemId));                   // �i��ID
      cstmt.setString(10, itemCode);                                     // �i�ڃR�[�h 

      if (XxcmnUtility.isBlankOrNull(lotId))
      {
        cstmt.setNull(11, Types.INTEGER);                                // ���b�gID(NULL)
      } else
      {
        cstmt.setInt(11, XxcmnUtility.intValue(lotId));                   // ���b�gID
      }

      cstmt.setString(12, lotNumber);                                   // ���b�gNo
      cstmt.setDate(13, XxcmnUtility.dateValue(txnsDate));              // �����
      cstmt.setDouble(14, Double.parseDouble(rcvRtnQuantity));          // ����ԕi����
      cstmt.setString(15, rcvRtnUom);                                   // ����ԕi�P��
      cstmt.setDouble(16, Double.parseDouble(quantity));                // ����
      cstmt.setString(17, uom);                                         // �P�ʃR�[�h
      cstmt.setDouble(18, Double.parseDouble(conversionFactor));        // ���Z����
      cstmt.setString(19, lineDescription);                             // ���דE�v
      cstmt.setString(20, dropshipCode);                                // �����敪
      cstmt.setInt(21, XxcmnUtility.intValue(unitPrice));               // �P��
      cstmt.setString(22, departmentCode);                              // ���������R�[�h  // 20080520 add yoshimoto

      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
// 20080520 mod yoshimoto Start
//      cstmt.registerOutParameter(22, Types.VARCHAR);   // ���^�[���R�[�h
//      cstmt.registerOutParameter(23, Types.INTEGER);   // ���ID
      cstmt.registerOutParameter(23, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(24, Types.INTEGER);   // ���ID
// 20080520 mod yoshimoto End
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
// 20080520 mod yoshimoto Start
//      String retFlag = cstmt.getString(22);
      String retFlag = cstmt.getString(23);
// 20080520 mod yoshimoto End

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // ���^�[���R�[�h�F������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);
// 20080520 mod yoshimoto Start
//        retHashMap.put("TxnsId", new Number(cstmt.getObject(23)));
        retHashMap.put("TxnsId", new Number(cstmt.getObject(24)));
// 20080520 mod yoshimoto End
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {

      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //�g�[�N������
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_XXPO_RCV_AND_RTN_TXNS) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // insertXxpoVendorSupplyTxns

  /*****************************************************************************
   * ����w�b�_�I�[�v��IF�Ƀf�[�^��ǉ����܂��B
   * @param trans �g�����U�N�V����
   * @param params �p�����[�^
   * @return HashMap 
   * @throws OAException OA��O
   ****************************************************************************/
  public static HashMap insertRcvHeadersIf(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertRcvHeadersIf";

    // IN�p�����[�^�擾
    String headerNumber = (String)params.get("HeaderNumber"); // �����ԍ�
    Date deliveryDate   = (Date)params.get("DeliveryDate");   // �����w�b�_.�[����
    Number vendorId     = (Number)params.get("VendorId");     // �����w�b�_.�d����ID
    Number groupId      = (Number)params.get("GroupId");      // �O���[�vID

    // OUT�p�����[�^�p
    HashMap retHashMap = new HashMap();
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);    


    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);

    int count = 1;

    sb.append(" DECLARE "                                                           );
    sb.append("   lt_header_if_id rcv_headers_interface.header_interface_id%TYPE; " );
    sb.append("   lt_group_id_s   rcv_headers_interface.group_id%TYPE; "            );
    sb.append("   lt_group_id     rcv_headers_interface.group_id%TYPE; "            );

    sb.append(" BEGIN "                                                             );
    sb.append("   SELECT rcv_headers_interface_s.NEXTVAL "                          );
    sb.append("   INTO   lt_header_if_id "                                          );
    sb.append("   FROM   DUAL; "                                                    );

    if (XxcmnUtility.isBlankOrNull(groupId)) 
    {
    sb.append("   SELECT rcv_interface_groups_s.NEXTVAL "                           );
    sb.append("   INTO   lt_group_id_s "                                            );
    sb.append("   FROM   DUAL; "                                                    );

      // ���s���ꂽGROUP_ID�Ɣ����ԍ�������
      sb.append("   lt_group_id := lt_group_id_s; "                                  );   // RCV_INTERFACE_GROUPS_S
    }else
    {

      // ���s���ꂽGROUP_ID
      sb.append("   lt_group_id := :" + (count++) + "; "                             );   // �̔ԍς�RCV_INTERFACE_GROUPS_S

    }

    // ����w�b�_�I�[�v��IF�o�^
    sb.append("   INSERT INTO rcv_headers_interface rhi ( "                         );
    sb.append("      rhi.header_interface_id "                                      );
    sb.append("     ,rhi.group_id "                                                 );
    sb.append("     ,rhi.processing_status_code "                                   );
    sb.append("     ,rhi.receipt_source_code "                                      );
    sb.append("     ,rhi.transaction_type "                                         );
    sb.append("     ,rhi.last_update_date "                                         );
    sb.append("     ,rhi.last_updated_by "                                          );
    sb.append("     ,rhi.last_update_login "                                        );
    sb.append("     ,rhi.creation_date "                                            );
    sb.append("     ,rhi.created_by "                                               );
    sb.append("     ,rhi.vendor_id "                                                );
    sb.append("     ,rhi.expected_receipt_date "                                    );
    sb.append("     ,rhi.validation_flag) "                                         );
    sb.append("   VALUES( "                                                         );
    sb.append("      lt_header_if_id "                                              );
    sb.append("     ,lt_group_id "                                                  );  
    sb.append("     ,'PENDING' "                                                    );
    sb.append("     ,'VENDOR' "                                                     );
    sb.append("     ,'NEW' "                                                        );
    sb.append("     ,SYSDATE "                                                      );
    sb.append("     ,FND_GLOBAL.USER_ID "                                           );
    sb.append("     ,FND_GLOBAL.LOGIN_ID "                                          );
    sb.append("     ,SYSDATE "                                                      );
    sb.append("     ,FND_GLOBAL.USER_ID "                                           );
    sb.append("     ,:" + (count++) + " "                                           );  // �����w�b�_.�d����ID
    sb.append("     ,:" + (count++) + " "                                           );  // �����w�b�_.�[����
    sb.append("     ,'Y' "                                                          );
    sb.append("   ); "                                                              );
                 // OUT�p�����[�^
    sb.append("   :" + (count++) + " := '1'; "                                      );
    sb.append("   :" + (count++) + " := lt_header_if_id; "                          );
    sb.append("   :" + (count++) + " := lt_group_id; "                              );
    sb.append(" END; "                                                              );


    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      count = 1;

      // �p�����[�^�ݒ�(IN�p�����[�^)

      if (!XxcmnUtility.isBlankOrNull(groupId)) 
      {
        cstmt.setLong(count++, XxcmnUtility.longValue(groupId));      // �O���[�vID
      }

      cstmt.setInt(count++, XxcmnUtility.intValue(vendorId));         // �����w�b�_.�d����ID
      cstmt.setDate(count++, XxcmnUtility.dateValue(deliveryDate));   // �����w�b�_.�[����
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(count++, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(count++, Types.INTEGER);   // header_interface_id
      cstmt.registerOutParameter(count, Types.BIGINT);   // group_id

        
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      String retFlag = cstmt.getString(count-2); // ���^�[���R�[�h

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // ���^�[���R�[�h�F������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        retHashMap.put("RetFlag",           XxcmnConstants.RETURN_SUCCESS);
        retHashMap.put("HeaderInterfaceId", new Number(cstmt.getObject(count-1)));
        retHashMap.put("GroupId",           new Number(cstmt.getObject(count)));       
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //�g�[�N������
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_RCV_HEADERS_INTERFACE) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    
    return retHashMap;
  } // insertRcvHeadersIf

  /*****************************************************************************
   * ����g�����U�N�V�����I�[�v��IF�Ƀf�[�^��ǉ����܂��B
   * @param trans �g�����U�N�V����
   * @param params �p�����[�^
   * @return HashMap
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap insertRcvTransactionsIf(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertRcvTransactionsIf";

    // IN�p�����[�^�擾
    String locationCode       = (String)params.get("LocationCode");         // ��������.�[����R�[�h
    Number lineId             = (Number)params.get("LineId");               // ��������ID
    Number groupId            = (Number)params.get("GroupId");             // ����w�b�_OIF��GROUP_ID�Ɠ��l���w��
    Date txnsDate             = (Date)params.get("TxnsDate");               // �������RN.�[����
    String rcvRtnQuantity     = (String)params.get("RcvRtnQuantity");       // �������(���Z����)
    String unitMeasLookupCode = (String)params.get("UnitMeasLookupCode");   // ��������.�i�ڊ�P��
    Number plaItemId          = (Number)params.get("PlaItemId");            // ��������.�i��ID(ITEM_ID)
    Number headerId           = (Number)params.get("HeaderId");             // �����w�b�_.�����w�b�_ID
    Date deliveryDate         = (Date)params.get("DeliveryDate");           // �����w�b�_.�[����
    Number txnsId             = (Number)params.get("TxnsId");              // ����ԕi����(�A�h�I��)�̎��ID
    Number headerInterfaceId  = (Number)params.get("HeaderInterfaceId");   // ����w�b�_OIF��INTERFACE_TRANSACTION_ID


    // OUT�p�����[�^�p
    HashMap retHashMap = new HashMap();
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);    

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" DECLARE "                                                                               );
    sb.append("   lt_if_transaction_id      rcv_transactions_interface.interface_transaction_id%TYPE; " );
    sb.append("   lt_organization_id        mtl_item_locations.organization_id%TYPE; "                  );
    sb.append("   lt_subinventory_code      mtl_item_locations.subinventory_code%TYPE; "                );
    sb.append("   lt_inventory_location_id  mtl_item_locations.inventory_location_id%TYPE; "            );
    sb.append("   lt_line_location_id       po_line_locations_all.line_location_id%TYPE; "              );
// 2008-07-17 H.Itou Add Start
    sb.append("   lt_closed_code            po_line_locations_all.closed_code%TYPE; "                   );
// 2008-07-17 H.Itou Add End
    sb.append(" BEGIN "                                                                                 );
    // �V�[�P���X���擾
    sb.append("   SELECT rcv_transactions_interface_s.NEXTVAL "                 );
    sb.append("   INTO   lt_if_transaction_id "                                 );
    sb.append("   FROM   DUAL; "                                                );

    // OPM�ۊǏꏊ�����擾
    sb.append("   SELECT mil.organization_id "                                  );
    sb.append("         ,mil.subinventory_code "                                );
    sb.append("         ,mil.inventory_location_id "                            );
    sb.append("   INTO   lt_organization_id "                                   );
    sb.append("         ,lt_subinventory_code "                                 );
    sb.append("         ,lt_inventory_location_id "                             );
    sb.append("   FROM mtl_item_locations mil "                                 );
    sb.append("   WHERE mil.segment1 = :1; "                                    ); // ��������.�[����R�[�h
  
    // �����[������
    sb.append("   SELECT plla.line_location_id "                                );
// 2008-07-17 H.Itou Add Start
    sb.append("         ,plla.closed_code "                                     );
// 2008-07-17 H.Itou Add End
    sb.append("   INTO   lt_line_location_id "                                  );
// 2008-07-17 H.Itou Add Start
    sb.append("         ,lt_closed_code "                                       );
// 2008-07-17 H.Itou Add End
    sb.append("   FROM po_line_locations_all plla "                             );
    sb.append("   WHERE plla.po_line_id = :2; "                                 ); // ��������ID
// 2008-10-21 D.Nihei Del Start ������Q#384
//// 2008-07-17 H.Itou Add Start
//    // �����[������.closed_code��CLOSED FOR RECEIVING�̏ꍇ�AOPEN�ɕύX
//    sb.append("   IF (lt_closed_code = 'CLOSED FOR RECEIVING') THEN  "          );
//    sb.append("     UPDATE po_line_locations_all plla "                         ); // �����[������
//    sb.append("     SET    plla.closed_code               = 'OPEN' "            );
//    sb.append("           ,plla.closed_reason             = NULL "              );
//    sb.append("           ,plla.closed_date               = NULL "              );
//    sb.append("           ,plla.closed_by                 = NULL "              );
//    sb.append("           ,plla.shipment_closed_date      = NULL "              );
//    sb.append("           ,plla.closed_for_receiving_date = NULL "              );
//    sb.append("           ,plla.closed_for_invoice_date   = NULL "              );
//    sb.append("           ,plla.last_update_date          = SYSDATE "           );
//    sb.append("           ,plla.last_updated_by           = FND_GLOBAL.USER_ID "  );
//    sb.append("           ,plla.last_update_login         = FND_GLOBAL.LOGIN_ID " );
//    sb.append("     WHERE  plla.po_line_id  = :2;  "                            ); // ��������ID
//    sb.append("   END IF;  "                                                    );
//// 2008-07-17 H.Itou Add End
// 2008-10-21 D.Nihei Del End
    // ������b�g�g�����U�N�V�����I�[�v��IF�o�^
    sb.append("   INSERT INTO rcv_transactions_interface rti ( "                );
    sb.append("      rti.interface_transaction_id "                             );
    sb.append("     ,rti.group_id "                                             );
    sb.append("     ,rti.last_update_date "                                     );
    sb.append("     ,rti.last_updated_by "                                      );
    sb.append("     ,rti.creation_date "                                        );
    sb.append("     ,rti.created_by "                                           );
    sb.append("     ,rti.last_update_login "                                    );
    sb.append("     ,rti.transaction_type "                                     );
    sb.append("     ,rti.transaction_date "                                     );
    sb.append("     ,rti.processing_status_code "                               );
    sb.append("     ,rti.processing_mode_code "                                 );
    sb.append("     ,rti.transaction_status_code "                              );
    sb.append("     ,rti.quantity "                                             );
    sb.append("     ,rti.unit_of_measure "                                      );
    sb.append("     ,rti.item_id "                                              );
    sb.append("     ,rti.auto_transact_code "                                   );
    sb.append("     ,rti.receipt_source_code "                                  );
    sb.append("     ,rti.to_organization_id "                                   );
    sb.append("     ,rti.source_document_code "                                 );
    sb.append("     ,rti.po_header_id "                                         );
    sb.append("     ,rti.po_line_id "                                           );
    sb.append("     ,rti.po_line_location_id "                                  );
    sb.append("     ,rti.destination_type_code "                                );
    sb.append("     ,rti.subinventory "                                         );
    sb.append("     ,rti.locator_id "                                           );
    sb.append("     ,rti.expected_receipt_date "                                );
    sb.append("     ,rti.ship_line_attribute1 "                                 );
    sb.append("     ,rti.header_interface_id "                                  );
    sb.append("     ,rti.validation_flag) "                                     );
    sb.append("   VALUES( "                                                     );
    sb.append("      lt_if_transaction_id "                                     );
    sb.append("     ,:3 "                                                       ); // ����w�b�_OIF��GROUP_ID�Ɠ��l���w��
    sb.append("     ,SYSDATE "                                                  );
    sb.append("     ,FND_GLOBAL.USER_ID "                                       );
    sb.append("     ,SYSDATE "                                                  );
    sb.append("     ,FND_GLOBAL.USER_ID "                                       );
    sb.append("     ,FND_GLOBAL.LOGIN_ID "                                      );
    sb.append("     ,'RECEIVE' "                                                );
    sb.append("     ,:4 "                                                       ); // �������RN.�[����
    sb.append("     ,'PENDING' "                                                );
    sb.append("     ,'BATCH' "                                                  );
    sb.append("     ,'PENDING' "                                                );
    sb.append("     ,:5 "                                                       ); // �������(���Z����)
    sb.append("     ,:6 "                                                       ); // ��������.�i�ڊ�P��
    sb.append("     ,:7 "                                                       ); // ��������.�i��ID(ITEM_ID)
    sb.append("     ,'DELIVER' "                                                );
    sb.append("     ,'VENDOR' "                                                 );
    sb.append("     ,lt_organization_id "                                       );
    sb.append("     ,'PO' "                                                     );
    sb.append("     ,:8 "                                                       ); // �����w�b�_.�����w�b�_ID
    sb.append("     ,:9 "                                                       ); // ��������.��������ID
    sb.append("     ,lt_line_location_id "                                      );
    sb.append("     ,'INVENTORY' "                                              );
    sb.append("     ,lt_subinventory_code "                                     );
    sb.append("     ,lt_inventory_location_id "                                 );
    sb.append("     ,:10 "                                                      ); // �����w�b�_.�[����
    sb.append("     ,:11 "                                                      ); // ����ԕi����(�A�h�I��)�̎��ID
    sb.append("     ,:12 "                                                      ); // ����w�b�_OIF��INTERFACE_TRANSACTION_ID
    sb.append("     ,'Y' "                                                      );
    sb.append("   ); "                                                          );

    sb.append("   :13 := '1'; "                                                 );
    sb.append("   :14 := lt_if_transaction_id; "                                );
    sb.append(" END; "                                                          );

    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, locationCode);                                // ��������.�[����R�[�h
      cstmt.setInt(2,    XxcmnUtility.intValue(lineId));               // ��������ID
      cstmt.setLong(3,    XxcmnUtility.longValue(groupId));            // ����w�b�_OIF��GROUP_ID�Ɠ��l���w��
      cstmt.setDate(4,   XxcmnUtility.dateValue(txnsDate));            // �������RN.�[����
      cstmt.setDouble(5, Double.parseDouble(rcvRtnQuantity));          // �������(���Z����)
      cstmt.setString(6, unitMeasLookupCode);                          // ��������.�i�ڊ�P��
      cstmt.setInt(7,    XxcmnUtility.intValue(plaItemId));            // ��������.�i��ID(ITEM_ID)
      cstmt.setInt(8,    XxcmnUtility.intValue(headerId));             // �����w�b�_.�����w�b�_ID
      cstmt.setInt(9,    XxcmnUtility.intValue(lineId));               // ��������.��������ID
      cstmt.setDate(10,  XxcmnUtility.dateValue(deliveryDate));        // �����w�b�_.�[����
      cstmt.setInt(11,   XxcmnUtility.intValue(txnsId));               // ����ԕi����(�A�h�I��)�̎��ID
      cstmt.setInt(12,   XxcmnUtility.intValue(headerInterfaceId));    // ����w�b�_OIF��INTERFACE_TRANSACTION_ID


      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(13, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(14, Types.INTEGER);   // ���^�[���R�[�h
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      String retFlag = cstmt.getString(13); // ���^�[���R�[�h

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // ���^�[���R�[�h�F������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        retHashMap.put("RetFlag",                XxcmnConstants.RETURN_SUCCESS); // ���^�[���R�[�h
        retHashMap.put("InterfaceTransactionId", new Number(cstmt.getInt(14)));   // interface_transaction_id
        
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {

      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //�g�[�N������
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_RCV_TRANSACTIONS_INTERFACE) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // insertRcvTransactionsIf

  /*****************************************************************************
   * ����g�����U�N�V�����I�[�v��IF�ɒ����f�[�^��ǉ����܂��B
   * @param trans �g�����U�N�V����
   * @param params �p�����[�^
   * @return HashMap 
   * @throws OAException OA��O
   ****************************************************************************/
  public static HashMap correctRcvTransactionsIf(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {

    String apiName      = "correctRcvTransactionsIf";

    // IN�p�����[�^�擾
    String headerNum = (String)params.get("HeaderNumber");    // �����ԍ�
    Number headerId = (Number)params.get("HeaderId");         // �����w�b�_ID
    Number lineId   = (Number)params.get("LineId");           // ��������ID
    Number txnsId   = (Number)params.get("TxnsId");           // ���ID
    Number groupId  = (Number)params.get("GroupId");          // �O���[�vID
    String quantity = (String)params.get("RcvRtnQuantity");   // ��������
    Number lotCtl   = (Number)params.get("LotCtl");           // ���b�g�Ώ�(2)�A��Ώ�(1)�t���O
    String processCode = (String)params.get("ProcessCode");   // �������(0)�A��������(1)
// 2008-12-05 H.Itou Add Start �{�ԏ�Q#481�Ή�
    Date   txnsDate = (Date)params.get("TxnsDate"); // �����
// 2008-12-05 H.Itou Add End

    // OUT�p�����[�^�p
    HashMap retHashMap = new HashMap();
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);    

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);

    int count = 1;

    sb.append(" DECLARE ");
    sb.append("   l_category_id               rcv_transactions_interface.category_id%TYPE; ");              // �i�ڃJ�e�S��ID
    sb.append("   l_quantity                  rcv_transactions_interface.quantity%TYPE; ");                 // ����
    sb.append("   l_unit_of_measure           rcv_transactions_interface.unit_of_measure%TYPE; ");          // �P��
    sb.append("   l_item_id                   rcv_transactions_interface.item_id%TYPE; ");                  // �i��ID
    sb.append("   l_item_description          rcv_transactions_interface.item_description%TYPE; ");         // �i�ړE�v
    sb.append("   l_uom_code                  rcv_transactions_interface.uom_code%TYPE; ");                 // �P�ʃR�[�h
    sb.append("   l_employee_id               rcv_transactions_interface.employee_id%TYPE; ");              // �]�ƈ�ID
    sb.append("   l_shipment_header_id        rcv_transactions_interface.shipment_header_id%TYPE; ");       // ����w�b�_ID
    sb.append("   l_shipment_line_id          rcv_transactions_interface.shipment_line_id%TYPE; ");         // �������ID
    sb.append("   l_primary_quantity          rcv_transactions_interface.primary_quantity%TYPE; ");         // ����:�i�ڊ�P��
    sb.append("   l_primary_unit_of_measure   rcv_transactions_interface.primary_unit_of_measure%TYPE; ");  // �i�ڊ�P��
    sb.append("   l_vendor_id                 rcv_transactions_interface.vendor_id%TYPE; ");                // �d����ID
    sb.append("   l_vendor_site_id            rcv_transactions_interface.vendor_site_id%TYPE; ");           // �d����T�C�gID
    sb.append("   l_from_organization_id      rcv_transactions_interface.from_organization_id%TYPE; ");     // �������݌ɑg�DID
    sb.append("   l_from_subinventory         rcv_transactions_interface.from_subinventory%TYPE; ");        // �������ۊǒI�R�[�h
    sb.append("   l_to_organization_id        rcv_transactions_interface.to_organization_id%TYPE; ");       // ������݌ɑg�DID
    sb.append("   l_routing_header_id         rcv_transactions_interface.routing_header_id%TYPE; ");        // �����o�H�w�b�_ID
    sb.append("   l_parent_transaction_id     rcv_transactions_interface.parent_transaction_id%TYPE; ");    // �e���ID(������:���)
    sb.append("   l_po_header_id              rcv_transactions_interface.po_header_id%TYPE; ");             // �����w�b�_ID
    sb.append("   l_po_line_id                rcv_transactions_interface.po_line_id%TYPE; ");               // ��������ID
    sb.append("   l_po_line_location_id       rcv_transactions_interface.po_line_location_id%TYPE; ");      // �����[������ID
    sb.append("   l_po_unit_price             rcv_transactions_interface.po_unit_price%TYPE; ");            // �P���F����
    sb.append("   l_currency_code             rcv_transactions_interface.currency_code%TYPE; ");            // �ʉ݃R�[�h
    sb.append("   l_currency_conversion_rate  rcv_transactions_interface.currency_conversion_rate%TYPE; "); // �ʉݕϊ����[�g
    sb.append("   l_po_distribution_id        rcv_transactions_interface.po_distribution_id%TYPE; ");       // ������������ID
    sb.append("   l_use_mtl_lot               rcv_transactions_interface.use_mtl_lot%TYPE; ");              // ���b�g�g�p�t���O
    sb.append("   l_from_locator_id           rcv_transactions_interface.from_locator_id%TYPE; ");          // �������ۊǒIID
    sb.append("   lt_person_id                per_all_people_f.person_id%TYPE; ");                          // �]�ƈ�ID
    sb.append("   lt_rcv_transactions_if_id   rcv_transactions_interface.interface_transaction_id%TYPE; ");
    sb.append("   lt_group_id_s               rcv_transactions_interface.group_id%TYPE; ");
    sb.append("   lt_group_id                 rcv_transactions_interface.group_id%TYPE; ");

    sb.append(" BEGIN ");
  
    sb.append("   SELECT ");
    sb.append("      rsl.category_id ");
    sb.append("     ,rt.unit_of_measure ");
    sb.append("     ,rsl.item_id ");
    sb.append("     ,rsl.item_description ");
    sb.append("     ,rt.uom_code ");
    sb.append("     ,rsl.shipment_header_id ");
    sb.append("     ,rsl.shipment_line_id ");
    sb.append("     ,rt.primary_unit_of_measure ");
    sb.append("     ,rt.vendor_id ");
    sb.append("     ,rt.vendor_site_id ");
    sb.append("     ,rt.organization_id ");
    sb.append("     ,rt.subinventory ");
    sb.append("     ,rt.organization_id ");
    sb.append("     ,rsl.routing_header_id ");
    sb.append("     ,rt.transaction_id ");
    sb.append("     ,rsl.po_line_location_id ");
    sb.append("     ,rt.po_unit_price ");
    sb.append("     ,rt.currency_code ");
    sb.append("     ,rt.currency_conversion_rate ");
    sb.append("     ,rsl.po_distribution_id ");
    sb.append("     ,rt.locator_id ");
    sb.append("   INTO ");
    sb.append("      l_category_id ");
    sb.append("     ,l_unit_of_measure ");
    sb.append("     ,l_item_id ");
    sb.append("     ,l_item_description ");
    sb.append("     ,l_uom_code ");
    sb.append("     ,l_shipment_header_id ");
    sb.append("     ,l_shipment_line_id ");
    sb.append("     ,l_primary_unit_of_measure ");
    sb.append("     ,l_vendor_id ");
    sb.append("     ,l_vendor_site_id ");
    sb.append("     ,l_from_organization_id ");
    sb.append("     ,l_from_subinventory ");
    sb.append("     ,l_to_organization_id ");
    sb.append("     ,l_routing_header_id ");
    sb.append("     ,l_parent_transaction_id ");
    sb.append("     ,l_po_line_location_id ");
    sb.append("     ,l_po_unit_price ");
    sb.append("     ,l_currency_code ");
    sb.append("     ,l_currency_conversion_rate ");
    sb.append("     ,l_po_distribution_id ");
    sb.append("     ,l_from_locator_id ");
    sb.append("   FROM rcv_shipment_lines rsl ");
    sb.append("       ,rcv_transactions   rt ");

    // �������
    if ("0".equals(processCode)) 
    {  
      sb.append("   WHERE rt.parent_transaction_id = -1 ");
      sb.append("     AND rt.transaction_type      = 'RECEIVE' ");
      sb.append("     AND rt.destination_type_code = 'RECEIVING' ");
      sb.append("     AND rt.destination_context   = 'RECEIVING' ");
      sb.append("     AND rt.shipment_line_id      = rsl.shipment_line_id ");
      sb.append("     AND rt.po_header_id          = :" + (count++) +" ");                // �����w�b�_ID
      sb.append("     AND rt.po_line_id            = :" + (count++) + " ");               // ��������ID
      sb.append("     AND rsl.attribute1           = :" + (count++) + "; ");              // �������.���ID

    // ��������
    } else 
    {
      sb.append("   WHERE rt.parent_transaction_id in (SELECT transaction_id ");
      sb.append("                                      FROM rcv_transactions");
      sb.append("                                      WHERE po_header_id = :" + (count++) + " "); // �����w�b�_ID
      sb.append("                                        AND po_line_id   = :" + (count++) + " "); // ��������ID
      sb.append("                                        AND parent_transaction_id = -1) ");
      sb.append("     AND rt.transaction_type      ='DELIVER' "             );
      sb.append("     AND rt.destination_type_code = 'INVENTORY' "          );
      sb.append("     AND rt.destination_context   = 'INVENTORY' "          );
      sb.append("     AND rt.shipment_line_id      = rsl.shipment_line_id " );
      sb.append("     AND rsl.attribute1           = :" + (count++) + "; "  );              // �������.���ID

    }

    // �]�ƈ����
    sb.append("   SELECT papf.person_id ");
    sb.append("   INTO lt_person_id ");
    sb.append("   FROM fnd_user fu ");
    sb.append("       ,per_all_people_f papf ");
    sb.append("   WHERE  fu.employee_id               = papf.person_id ");             // �]�ƈ�ID
    sb.append("     AND    fu.start_date <= TRUNC(SYSDATE) "                          ); // �K�p�J�n��
    sb.append("     AND    ((fu.end_date IS NULL) OR (fu.end_date >= TRUNC(SYSDATE))) " ); // �K�p�I����
    sb.append("     AND    papf.effective_start_date <= TRUNC(SYSDATE) "              ); // �K�p�J�n��
    sb.append("     AND    papf.effective_end_date   >= TRUNC(SYSDATE) "              ); // �K�p�I����
    sb.append("     AND  fu.user_id = FND_GLOBAL.USER_ID; ");

    // �V�[�P���X�̎擾
    sb.append("   SELECT rcv_transactions_interface_s.NEXTVAL ");
    sb.append("   INTO   lt_rcv_transactions_if_id ");
    sb.append("   FROM   DUAL; ");

    // �O���[�vID��V�K�̔Ԃ���ꍇ
    if (XxcmnUtility.isBlankOrNull(groupId)) 
    {
      sb.append("   SELECT rcv_interface_groups_s.NEXTVAL ");
      sb.append("   INTO   lt_group_id_s ");
      sb.append("   FROM   DUAL; ");
  
      sb.append("   lt_group_id := lt_group_id_s; ");   // RCV_INTERFACE_GROUPS_S

    // �O���[�vID���̔ԍς݂̏ꍇ
    }else
    {
      sb.append("   lt_group_id := :" + (count++) + "; ");   // �̔ԍς�RCV_INTERFACE_GROUPS_S
    }

    // ������b�g�g�����U�N�V�����I�[�v��IF�o�^
    sb.append("   INSERT INTO rcv_transactions_interface rti ( ");
    sb.append("     rti.interface_transaction_id ");
    sb.append("     ,rti.group_id ");
    sb.append("     ,rti.last_update_date ");
    sb.append("     ,rti.last_updated_by ");
    sb.append("     ,rti.creation_date ");
    sb.append("     ,rti.created_by ");
    sb.append("     ,rti.last_update_login ");
    sb.append("     ,rti.transaction_type ");
    sb.append("     ,rti.transaction_date ");
    sb.append("     ,rti.processing_status_code ");
    sb.append("     ,rti.processing_mode_code ");
    sb.append("     ,rti.transaction_status_code ");
    sb.append("     ,rti.category_id ");
    sb.append("     ,rti.quantity ");
    sb.append("     ,rti.unit_of_measure ");
    sb.append("     ,rti.item_id ");
    sb.append("     ,rti.item_description ");
    sb.append("     ,rti.uom_code ");
    sb.append("     ,rti.employee_id ");
    sb.append("     ,rti.shipment_header_id ");
    sb.append("     ,rti.shipment_line_id ");
    sb.append("     ,rti.primary_quantity ");
    sb.append("     ,rti.primary_unit_of_measure ");
    sb.append("     ,rti.receipt_source_code ");
    sb.append("     ,rti.vendor_id ");
    sb.append("     ,rti.vendor_site_id ");
    sb.append("     ,rti.from_organization_id ");
    sb.append("     ,rti.from_subinventory ");
    sb.append("     ,rti.to_organization_id ");
    sb.append("     ,rti.routing_header_id ");
    sb.append("     ,rti.routing_step_id ");
    sb.append("     ,rti.source_document_code ");
    sb.append("     ,rti.parent_transaction_id ");
    sb.append("     ,rti.po_header_id ");
    sb.append("     ,rti.po_line_id ");
    sb.append("     ,rti.po_line_location_id ");
    sb.append("     ,rti.po_unit_price ");
    sb.append("     ,rti.currency_code ");
    sb.append("     ,rti.currency_conversion_rate ");
    sb.append("     ,rti.po_distribution_id ");
    sb.append("     ,rti.inspection_status_code ");
    sb.append("     ,rti.destination_type_code ");
    sb.append("     ,rti.locator_id ");
    sb.append("     ,rti.destination_context ");
    sb.append("     ,rti.use_mtl_lot ");
    sb.append("     ,rti.use_mtl_serial ");
    sb.append("     ,rti.from_locator_id) ");
    sb.append("   VALUES( ");
    sb.append("      lt_rcv_transactions_if_id ");
    sb.append("     ,lt_group_id ");
    sb.append("     ,SYSDATE ");
    sb.append("     ,FND_GLOBAL.USER_ID ");
    sb.append("     ,SYSDATE ");
    sb.append("     ,FND_GLOBAL.USER_ID ");
    sb.append("     ,FND_GLOBAL.LOGIN_ID ");
    sb.append("     ,'CORRECT' ");
// 2008-12-05 H.Itou Add Start �{�ԏ�Q#481�Ή�
//    sb.append("     ,SYSDATE ");
    sb.append("     ,:" + (count++) +" ");                                // ������Ftransaction_date
// 2008-12-05 H.Itou Add End
    sb.append("     ,'PENDING' ");
    sb.append("     ,'BATCH' ");
    sb.append("     ,'PENDING' ");
    sb.append("     ,l_category_id ");
    sb.append("     ,:" + (count++) +" ");                                // ��������
    sb.append("     ,l_unit_of_measure ");
    sb.append("     ,l_item_id ");
    sb.append("     ,l_item_description ");
    sb.append("     ,l_uom_code ");
    sb.append("     ,lt_person_id ");
    sb.append("     ,l_shipment_header_id ");
    sb.append("     ,l_shipment_line_id ");
    sb.append("     ,:" + (count++) +" ");                                // ��������
    sb.append("     ,l_primary_unit_of_measure ");
    sb.append("     ,'VENDOR' ");
    sb.append("     ,l_vendor_id ");
    sb.append("     ,l_vendor_site_id ");
    sb.append("     ,l_from_organization_id ");
    sb.append("     ,l_from_subinventory ");
    sb.append("     ,l_to_organization_id ");
    sb.append("     ,l_routing_header_id ");
    sb.append("     ,1 ");
    sb.append("     ,'PO' ");
    sb.append("     ,l_parent_transaction_id ");                          
    sb.append("     ,:" + (count++) +" ");                                // �����w�b�_ID
    sb.append("     ,:" + (count++) +" ");                                // ��������ID
    sb.append("     ,l_po_line_location_id ");
    sb.append("     ,l_po_unit_price ");
    sb.append("     ,l_currency_code ");
    sb.append("     ,l_currency_conversion_rate ");
    sb.append("     ,l_po_distribution_id ");
    sb.append("     ,'NOT INSPECTED' ");

    if ("0".equals(processCode)) 
    {
      sb.append("     ,'RECEIVING' ");    // �����������
    } else 
    {
      sb.append("     ,'INVENTORY' ");    // ������������
    }

    sb.append("     ,l_from_locator_id ");

    if ("0".equals(processCode)) 
    {
      sb.append("     ,'RECEIVING' ");    // �����������
    } else 
    {
      sb.append("     ,'INVENTORY' ");    // ������������
    }

    sb.append("     ,:" + (count++) +" ");                                // ���b�g�Ώ�(2)�A��Ώ�(1)
    sb.append("     ,1 ");
    sb.append("     ,l_from_locator_id ");
    sb.append("   ); ");
  
    sb.append("   :" + (count++) +" := '1'; ");
    sb.append("   :" + (count++) +" := lt_rcv_transactions_if_id; ");
    sb.append("   :" + (count++) +" := lt_group_id; ");
    sb.append(" END; ");
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {

      count = 1;

      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(count++, XxcmnUtility.intValue(headerId));     // �����w�b�_ID
      cstmt.setInt(count++, XxcmnUtility.intValue(lineId));       // ��������ID
      cstmt.setString(count++, XxcmnUtility.stringValue(txnsId)); // �������.���ID
      // �O���[�vID���̔ԍς݂̏ꍇ
      if (!XxcmnUtility.isBlankOrNull(groupId)) 
      {
        cstmt.setLong(count++, XxcmnUtility.longValue(groupId));  // groupId
      }
// 2008-12-05 H.Itou Add Start �{�ԏ�Q#481�Ή�
      cstmt.setDate(count++, XxcmnUtility.dateValue(txnsDate)); // �������.�����
// 2008-12-05 H.Itou Add End
      cstmt.setDouble(count++, Double.parseDouble(quantity));    // ��������
      cstmt.setDouble(count++, Double.parseDouble(quantity));    // ��������
      cstmt.setInt(count++, XxcmnUtility.intValue(headerId));    // �����w�b�_ID
      cstmt.setInt(count++, XxcmnUtility.intValue(lineId));      // ��������ID
      cstmt.setInt(count++, XxcmnUtility.intValue(lotCtl));      // ���b�g�Ώ�(2)�A��Ώ�(1)

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(count++, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(count++, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(count, Types.BIGINT);      // ���^�[���R�[�h
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      String retFlag = cstmt.getString(count-2); // ���^�[���R�[�h

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // ���^�[���R�[�h�F������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        retHashMap.put("RetFlag",                XxcmnConstants.RETURN_SUCCESS); // ���^�[���R�[�h
        retHashMap.put("InterfaceTransactionId", new Number(cstmt.getObject(count-1)));   // interface_transaction_id
        retHashMap.put("GroupId",                new Number(cstmt.getObject(count)));     // group_id
        
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {

      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //�g�[�N������
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_RCV_TRANSACTIONS_INTERFACE) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // correctRcvTransactionsIf 

  /*****************************************************************************
   * �i�ڃ��b�g�g�����U�N�V�����I�[�v��IF�Ƀf�[�^��ǉ����܂��B
   * @param trans �g�����U�N�V����
   * @param params �p�����[�^
   * @return String XxcmnConstants.RETURN_SUCCESS:1 ����
   *                XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException OA��O
   ****************************************************************************/
  public static String insertMtlTransactionLotsIf(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertMtlTransactionLotsIf";

    // IN�p�����[�^�擾
    String lotNo              = (String)params.get("LotNo");                // ��������.���b�gNo
    String rcvRtnQuantity     = (String)params.get("RcvRtnQuantity");       // �������(���Z����)
    Number interfaceTransactionId  = (Number)params.get("InterfaceTransactionId");    // ����g�����U�N�V����OIF��INTERFACE_TRANSACTION_ID
                                             
    // OUT�p�����[�^�p
    String retFlag = XxcmnConstants.RETURN_NOT_EXE;    

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append(" BEGIN "                                               );
    
    // �i�ڃ��b�g�g�����U�N�V�����I�[�v��IF�o�^
    sb.append("   INSERT INTO mtl_transaction_lots_interface mtli ( " );
    sb.append("      mtli.transaction_interface_id "                  );
    sb.append("     ,mtli.last_update_date "                          );
    sb.append("     ,mtli.last_updated_by "                           );
    sb.append("     ,mtli.creation_date "                             );
    sb.append("     ,mtli.created_by "                                );
    sb.append("     ,mtli.last_update_login "                         );
    sb.append("     ,mtli.lot_number "                                );
    sb.append("     ,mtli.transaction_quantity "                      );
    sb.append("     ,mtli.primary_quantity "                          );
    sb.append("     ,mtli.product_code "                              );
    sb.append("     ,mtli.product_transaction_id) "                   );
    sb.append("   VALUES( "                                           );
    sb.append("      mtl_material_transactions_s.NEXTVAL "            );
    sb.append("     ,SYSDATE "                                        );
    sb.append("     ,FND_GLOBAL.USER_ID "                             );
    sb.append("     ,SYSDATE "                                        );
    sb.append("     ,FND_GLOBAL.USER_ID "                             );
    sb.append("     ,FND_GLOBAL.LOGIN_ID "                            );
    sb.append("     ,:1 "                                             ); // ��������.���b�gNo
    sb.append("     ,ABS(:2) "                                        ); // �������(���Z����)�A��Βl
    sb.append("     ,ABS(:3) "                                        ); // �������(���Z����)�A��Βl
    sb.append("     ,'RCV' "                                          );
    sb.append("     ,:4 "                                             ); // ����g�����U�N�V����OIF��INTERFACE_TRANSACTION_ID
    sb.append("   ); "                                                );
    sb.append("   :5 := '1'; "                                        );
    sb.append(" END; "                                                );
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, lotNo);                                 // ��������.���b�gNo
      cstmt.setDouble(2, Double.parseDouble(rcvRtnQuantity));    // �������(���Z����)
      cstmt.setDouble(3, Double.parseDouble(rcvRtnQuantity));    // �������(���Z����)
      cstmt.setInt(4, XxcmnUtility.intValue(interfaceTransactionId)); // ����g�����U�N�V����OIF��INTERFACE_TRANSACTION_ID
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(5, Types.VARCHAR);   // ���^�[���R�[�h
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      retFlag = cstmt.getString(5); // ���^�[���R�[�h

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // ���^�[���R�[�h������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {

      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //�g�[�N������
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_MTL_TRANSACTION_LOTS_INTERFACE) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // insertMtlTransactionLotsIf 

  /*****************************************************************************
   * �i�ڃ��b�g�g�����U�N�V�����I�[�v��IF�ɒ����f�[�^��ǉ����܂��B
   * @param trans �g�����U�N�V����
   * @param params �p�����[�^
   * @return String ��������
   * @throws OAException OA��O
   ****************************************************************************/
  public static String correctMtlTransactionLotsIf(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {

    String apiName      = "correctMtlTransactionLotsIf";

    // IN�p�����[�^�擾
    String lotNo        = (String)params.get("LotNo");                              // ��������.���b�gNo
    String quantity     = (String)params.get("RcvRtnQuantity");                     // ��������
    Number interfaceTransactionId  = (Number)params.get("InterfaceTransactionId");  // INTERFACE_TRANSACTION_ID
// 20080611 yoshimoto add Start ST�s�#72
    Number opmItemId    = (Number)params.get("OpmItemId");                          // ��������.OPM�i��ID
// 20080611 yoshimoto add End ST�s�#72

    // OUT�p�����[�^�p
    String retFlag = XxcmnConstants.RETURN_NOT_EXE;    

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" DECLARE ");

    sb.append("   lt_expire_date ic_lots_mst.expire_date%TYPE; ");    // ������

    sb.append(" BEGIN ");

    sb.append("   SELECT ilm.expire_date ");
    sb.append("   INTO lt_expire_date ");
    sb.append("   FROM ic_lots_mst ilm ");
    sb.append("   WHERE ilm.lot_no = :1 ");     // ��������.���b�gNo
// 20080611 yoshimoto add Start
    sb.append("   AND   ilm.item_id = :2; ");   // ��������.OPM�i��ID
// 20080611 yoshimoto add End
  
    sb.append("   INSERT INTO mtl_transaction_lots_interface mtli ( ");
    sb.append("      mtli.transaction_interface_id ");
    sb.append("     ,mtli.source_code ");
    sb.append("     ,mtli.last_update_date ");
    sb.append("     ,mtli.last_updated_by ");
    sb.append("     ,mtli.creation_date ");
    sb.append("     ,mtli.created_by ");
    sb.append("     ,mtli.last_update_login ");
    sb.append("     ,mtli.lot_number ");
    sb.append("     ,mtli.lot_expiration_date ");
    sb.append("     ,mtli.transaction_quantity ");
    sb.append("     ,mtli.primary_quantity ");
    sb.append("     ,mtli.process_flag ");
    sb.append("     ,mtli.product_code ");
    sb.append("     ,mtli.product_transaction_id) ");
    sb.append("   VALUES( ");
    sb.append("      mtl_material_transactions_s.NEXTVAL ");
    sb.append("     ,'RCV' ");
    sb.append("     ,SYSDATE ");
    sb.append("     ,FND_GLOBAL.USER_ID ");
    sb.append("     ,SYSDATE ");
    sb.append("     ,FND_GLOBAL.USER_ID ");
    sb.append("     ,FND_GLOBAL.LOGIN_ID ");
// 20080611 yoshimoto mod Start ST�s�#72
/*
    sb.append("     ,:2 ");                                // ��������.���b�gNo
    sb.append("     ,lt_expire_date ");
    sb.append("     ,ABS(:3) ");                           // �������ʂ̐�Βl
    sb.append("     ,ABS(:4) ");                           // �������ʂ̐�Βl
    sb.append("     ,'1' ");
    sb.append("     ,'RCV' ");
    sb.append("     ,:5 ");                                // INTERFACE_TRANSACTION_ID
    sb.append("   ); ");
    sb.append("   :6 := '1'; ");
*/
    sb.append("     ,:3 ");                                // ��������.���b�gNo
    sb.append("     ,lt_expire_date ");
    sb.append("     ,ABS(:4) ");                           // �������ʂ̐�Βl
    sb.append("     ,ABS(:5) ");                           // �������ʂ̐�Βl
    sb.append("     ,'1' ");
    sb.append("     ,'RCV' ");
    sb.append("     ,:6 ");                                // INTERFACE_TRANSACTION_ID
    sb.append("   ); ");
    sb.append("   :7 := '1'; ");
// 20080611 yoshimoto mod End ST�s�#72
    sb.append(" END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, lotNo);   // ���b�gNo
// 20080611 yoshimoto mod Start ST�s�#72
/*
      cstmt.setString(2, lotNo);   // ���b�gNo
      cstmt.setDouble(3, Double.parseDouble(quantity));   // ��������
      cstmt.setDouble(4, Double.parseDouble(quantity));   // ��������
      cstmt.setInt(5, XxcmnUtility.intValue(interfaceTransactionId));  // INTERFACE_TRANSACTION_ID

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(6, Types.VARCHAR);   // ���^�[���R�[�h
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      retFlag = cstmt.getString(6); // ���^�[���R�[�h
*/
      cstmt.setInt(2, XxcmnUtility.intValue(opmItemId));      // ��������.OPM�i��ID
      cstmt.setString(3, lotNo);                              // ���b�gNo
      cstmt.setDouble(4, Double.parseDouble(quantity));       // ��������
      cstmt.setDouble(5, Double.parseDouble(quantity));       // ��������
      cstmt.setInt(6, XxcmnUtility.intValue(interfaceTransactionId));  // INTERFACE_TRANSACTION_ID

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(7, Types.VARCHAR);   // ���^�[���R�[�h

      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      retFlag = cstmt.getString(7); // ���^�[���R�[�h
// 20080611 yoshimoto mod End ST�s�#72

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // ���^�[���R�[�h�F������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {

      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //�g�[�N������
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_MTL_TRANSACTION_LOTS_INTERFACE) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // correctRcvLotsIf

  /*****************************************************************************
   * ������b�g�g�����U�N�V�����I�[�v��IF�ɒ����f�[�^��ǉ����܂��B
   * @param trans �g�����U�N�V����
   * @param params �p�����[�^
   * @return String �������� 
   * @throws OAException OA��O
   ****************************************************************************/
  public static String correctRcvLotsIf(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {

    String apiName      = "correctRcvLotsIf";

    // IN�p�����[�^�擾
    String lotNo        = (String)params.get("LotNo");                              // ��������.���b�gNo
    Number headerId     = (Number)params.get("HeaderId");                           // �����w�b�_ID
    Number lineId       = (Number)params.get("LineId");                             // ��������ID
    Number txnsId       = (Number)params.get("TxnsId");                             // ���ID
    String quantity     = (String)params.get("RcvRtnQuantity");                     // ��������
    Number interfaceTransactionId  = (Number)params.get("InterfaceTransactionId");  // INTERFACE_TRANSACTION_ID
// 20080611 yoshimoto add Start ST�s�#72
    Number opmItemId    = (Number)params.get("OpmItemId");                          // ��������.OPM�i��ID
// 20080611 yoshimoto add End ST�s�#72

    // OUT�p�����[�^�p
    String retFlag = XxcmnConstants.RETURN_NOT_EXE;    

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" DECLARE ");

    sb.append("   l_item_id          rcv_transactions_interface.item_id%TYPE; ");           // �i��ID
    sb.append("   l_shipment_line_id rcv_transactions_interface.shipment_line_id%TYPE; ");  // �������ID
    sb.append("   lt_expire_date     ic_lots_mst.expire_date%TYPE; ");                      // ������

    sb.append(" BEGIN ");

    sb.append("   SELECT ilm.expire_date ");
    sb.append("   INTO lt_expire_date ");
    sb.append("   FROM ic_lots_mst ilm ");
    sb.append("   WHERE ilm.lot_no = :1 ");      // ��������.���b�gNo
// 20080611 yoshimoto add Start ST�s�#72
    sb.append("   AND   ilm.item_id = :2; ");    // ��������.OPM�i��ID
// 20080611 yoshimoto add End ST�s�#72

    sb.append("   SELECT ");
    sb.append("      rsl.item_id ");
    sb.append("     ,rsl.shipment_line_id ");
    sb.append("   INTO ");
    sb.append("      l_item_id ");
    sb.append("     ,l_shipment_line_id ");
    sb.append("   FROM rcv_shipment_lines rsl ");
    sb.append("       ,rcv_transactions   rt ");
    sb.append("   WHERE rt.parent_transaction_id = -1 ");
    sb.append("     AND rt.transaction_type      = 'RECEIVE' ");
    sb.append("     AND rt.destination_type_code = 'RECEIVING' ");
    sb.append("     AND rt.destination_context   = 'RECEIVING' ");
    sb.append("     AND rt.shipment_line_id      = rsl.shipment_line_id ");
// 20080611 yoshimoto add Start ST�s�#72
/*
    sb.append("     AND rt.po_header_id          = :2 ");                      // �����w�b�_ID
    sb.append("     AND rt.po_line_id            = :3 ");                      // ��������ID
    sb.append("     AND rsl.attribute1           = :4; " );                    // �������.���ID

    sb.append("   INSERT INTO rcv_lots_interface rli ( ");
    sb.append("      rli.interface_transaction_id ");
    sb.append("     ,rli.last_update_date ");
    sb.append("     ,rli.last_updated_by ");
    sb.append("     ,rli.creation_date ");
    sb.append("     ,rli.created_by ");
    sb.append("     ,rli.last_update_login ");
    sb.append("     ,rli.lot_num ");
    sb.append("     ,rli.quantity ");
    sb.append("     ,rli.transaction_date ");
    sb.append("     ,rli.expiration_date ");
    sb.append("     ,rli.primary_quantity ");
    sb.append("     ,rli.item_id ");
    sb.append("     ,rli.shipment_line_id) ");
    sb.append("   VALUES( ");
    sb.append("     :5 ");                                 // INTERFACE_TRANSACTION_ID
    sb.append("     ,SYSDATE ");
    sb.append("     ,FND_GLOBAL.USER_ID ");
    sb.append("     ,SYSDATE ");
    sb.append("     ,FND_GLOBAL.USER_ID ");
    sb.append("     ,FND_GLOBAL.LOGIN_ID ");
    sb.append("     ,:6 ");                                // ��������.���b�gNo
    sb.append("     ,ABS(:7) ");                           // �������ʂ̐�Βl
    sb.append("     ,SYSDATE ");
    sb.append("     ,lt_expire_date ");
    sb.append("     ,ABS(:8) ");                           // �������ʂ̐�Βl
    sb.append("     ,l_item_id ");
    sb.append("     ,l_shipment_line_id ");
    sb.append("   ); ");

    sb.append("   :9 := '1'; ");
*/
    sb.append("     AND rt.po_header_id          = :3 ");                      // �����w�b�_ID
    sb.append("     AND rt.po_line_id            = :4 ");                      // ��������ID
    sb.append("     AND rsl.attribute1           = :5; " );                    // �������.���ID

    sb.append("   INSERT INTO rcv_lots_interface rli ( ");
    sb.append("      rli.interface_transaction_id ");
    sb.append("     ,rli.last_update_date ");
    sb.append("     ,rli.last_updated_by ");
    sb.append("     ,rli.creation_date ");
    sb.append("     ,rli.created_by ");
    sb.append("     ,rli.last_update_login ");
    sb.append("     ,rli.lot_num ");
    sb.append("     ,rli.quantity ");
    sb.append("     ,rli.transaction_date ");
    sb.append("     ,rli.expiration_date ");
    sb.append("     ,rli.primary_quantity ");
    sb.append("     ,rli.item_id ");
    sb.append("     ,rli.shipment_line_id) ");
    sb.append("   VALUES( ");
    sb.append("     :6 ");                                 // INTERFACE_TRANSACTION_ID
    sb.append("     ,SYSDATE ");
    sb.append("     ,FND_GLOBAL.USER_ID ");
    sb.append("     ,SYSDATE ");
    sb.append("     ,FND_GLOBAL.USER_ID ");
    sb.append("     ,FND_GLOBAL.LOGIN_ID ");
    sb.append("     ,:7 ");                                // ��������.���b�gNo
    sb.append("     ,ABS(:8) ");                           // �������ʂ̐�Βl
    sb.append("     ,SYSDATE ");
    sb.append("     ,lt_expire_date ");
    sb.append("     ,ABS(:9) ");                           // �������ʂ̐�Βl
    sb.append("     ,l_item_id ");
    sb.append("     ,l_shipment_line_id ");
    sb.append("   ); ");

    sb.append("   :10 := '1'; ");
// 20080611 yoshimoto add End ST�s�#72

    sb.append(" END; ");
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {

      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, lotNo);                                       // ���b�gNo
// 20080611 yoshimoto mod Start ST�s�#72
/*
      cstmt.setInt(2,    XxcmnUtility.intValue(headerId));             // �����w�b�_ID
      cstmt.setInt(3,    XxcmnUtility.intValue(lineId));               // ��������ID
      cstmt.setString(4, XxcmnUtility.stringValue(txnsId));            // �������.���ID
      cstmt.setInt(5, XxcmnUtility.intValue(interfaceTransactionId));  // INTERFACE_TRANSACTION_ID
      cstmt.setString(6, lotNo);                                       // ���b�gNo
      cstmt.setDouble(7, Double.parseDouble(quantity));                // ��������
      cstmt.setDouble(8, Double.parseDouble(quantity));                // ��������

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(9, Types.VARCHAR);   // ���^�[���R�[�h
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      retFlag = cstmt.getString(9); // ���^�[���R�[�h
*/
      cstmt.setInt(2,    XxcmnUtility.intValue(opmItemId));            // ��������.OPM�i��ID
      cstmt.setInt(3,    XxcmnUtility.intValue(headerId));             // �����w�b�_ID
      cstmt.setInt(4,    XxcmnUtility.intValue(lineId));               // ��������ID
      cstmt.setString(5, XxcmnUtility.stringValue(txnsId));            // �������.���ID
      cstmt.setInt(6, XxcmnUtility.intValue(interfaceTransactionId));  // INTERFACE_TRANSACTION_ID
      cstmt.setString(7, lotNo);                                       // ���b�gNo
      cstmt.setDouble(8, Double.parseDouble(quantity));                // ��������
      cstmt.setDouble(9, Double.parseDouble(quantity));                // ��������

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(10, Types.VARCHAR);   // ���^�[���R�[�h
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      retFlag = cstmt.getString(10);                  // ���^�[���R�[�h
// 20080611 yoshimoto mod End ST�s�#72

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // ���^�[���R�[�h�F������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {

      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //�g�[�N������
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_RCV_LOTS_INTERFACE) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // correctRcvLotsIf 

  /*****************************************************************************
   * �󒍖��ׂ̎������/���ʊm��t���O���X�V���܂��B
   * @param trans �g�����U�N�V����
   * @param poLineId ��������ID
   * @param receiptAmountTotal ���v�������
   * @throws OAException OA��O
   ****************************************************************************/
  public static void updateReceiptAmount(
    OADBTransaction trans,
    Number poLineId,
    double receiptAmountTotal
    ) throws OAException
  {
    String apiName = "updateReceiptAmount";

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" BEGIN "                                                         );
    sb.append("   UPDATE po_lines_all pla "                                     );
    sb.append("   SET pla.attribute7        = :1 "                              ); // �������(���v�l)
    sb.append("      ,pla.attribute13       = 'Y' "                             ); // ���ʊm��t���O
    sb.append("      ,pla.last_updated_by   = FND_GLOBAL.USER_ID "              ); // �ŏI�X�V��
    sb.append("      ,pla.last_update_date  = SYSDATE "                         ); // �ŏI�X�V��
    sb.append("      ,pla.last_update_login = FND_GLOBAL.LOGIN_ID "             ); // �ŏI�X�V���O�C��
    sb.append("   WHERE pla.po_line_id = :2; "                                  );
    sb.append(" END; "                                                          );
    
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setDouble(1, receiptAmountTotal);   // �������
      cstmt.setInt(2,    XxcmnUtility.intValue(poLineId));     // ��������ID
      
      //PL/SQL���s
      cstmt.execute();
    
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateReceiptAmount

  /*****************************************************************************
   * OPM���b�g�}�X�^Tbl�Ƀf�[�^���X�V���܂��B(���X�V�Ώۂ𓮓I�ɕύX�ł��܂�)
   * @param trans �g�����U�N�V����
   * @param params �p�����[�^�pHashMap
   * @return String XxcmnConstants.RETURN_SUCCESS:1 ����
   *                  XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException OA��O
   ****************************************************************************/
  public static String updateIcLotsMstTxns2(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
  
    String apiName      = "updateIcLotsMstTxns2";
    int bindCount = 1;
    
    // *********************** //
    // * �����������擾      * //
    // *********************** //
    // OPM�i��ID
    Number itemId            = (Number)params.get("ItemId");
    // ���b�gNo
    String lotNo             = (String)params.get("LotNo");
    // ������
    Date productionDate      = (Date)params.get("ProductionDate");
    // �ܖ�����
    Date useByDate           = (Date)params.get("UseByDate");
// 20080523 add yoshimoto Start
    // ����
    String itemAmount        = (String)params.get("ItemAmount");
    // ���דE�v
    String description       = (String)params.get("Description");
// 20080523 add yoshimoto End

    // *********************** //
    // * �X�V�f�[�^���擾    * //
    // *********************** //
    String firstTimeDeliveryDate = (String)params.get("FirstTimeDeliveryDate"); // �[����(����)
    String finalDeliveryDate     = (String)params.get("FinalDeliveryDate");     // �[����(�ŏI)

    // OUT�p�����[�^�p
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // �߂�l

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);

    sb.append("DECLARE "                                            );
    sb.append("  ln_api_version_number    CONSTANT NUMBER := 1.0; " );
    sb.append("  lv_ret_status            VARCHAR2(1); "            );
    sb.append("  ln_msg_cnt               NUMBER; "                 );
    sb.append("  lv_msg_data              VARCHAR2(5000); "         );
    sb.append("  lv_errbuf                VARCHAR2(5000); "         );
    sb.append("  lv_retcode               VARCHAR2(1); "            );
    sb.append("  lv_errmsg                VARCHAR2(5000); "         );
    sb.append("  lb_setup_return_sts      BOOLEAN; "                );

    // OPM���b�g�}�X�^�J�[�\��
    sb.append("  CURSOR p_lot_cur "                                 );
    sb.append("  IS "                                               );
    sb.append("    SELECT ilm.item_id "                             );
    sb.append("          ,ilm.lot_id "                              );
    sb.append("          ,ilm.lot_no "                              );
    sb.append("          ,ilm.sublot_no "                           );
    sb.append("          ,ilm.lot_desc "                            );
    sb.append("          ,ilm.qc_grade "                            );
    sb.append("          ,ilm.expaction_code "                      );
    sb.append("          ,ilm.expaction_date "                      );
    sb.append("          ,ilm.lot_created "                         );
    sb.append("          ,ilm.expire_date "                         );
    sb.append("          ,ilm.retest_date "                         );
    sb.append("          ,ilm.strength "                            );
    sb.append("          ,ilm.inactive_ind "                        );
    sb.append("          ,ilm.origination_type "                    );
    sb.append("          ,ilm.shipvend_id "                         );
    sb.append("          ,ilm.vendor_lot_no "                       );
    sb.append("          ,ilm.creation_date "                       );
    sb.append("          ,ilm.last_update_date "                    );
    sb.append("          ,ilm.created_by "                          );
    sb.append("          ,ilm.last_updated_by "                     );
    sb.append("          ,ilm.trans_cnt "                           );
    sb.append("          ,ilm.delete_mark "                         );
    sb.append("          ,ilm.text_code "                           );
    sb.append("          ,ilm.last_update_login "                   );
    sb.append("          ,ilm.program_application_id "              );
    sb.append("          ,ilm.program_id "                          );
    sb.append("          ,ilm.program_update_date "                 );
    sb.append("          ,ilm.request_id "                          );
    sb.append("          ,ilm.attribute1 "                          );  // �����N����
    sb.append("          ,ilm.attribute2 "                          );  // �ŗL�L��
    sb.append("          ,ilm.attribute3 "                          );  // �ܖ�����
    sb.append("          ,ilm.attribute4 "                          );  // �[�����i����j
    sb.append("          ,ilm.attribute5 "                          );  // �[�����i�ŏI�j
    sb.append("          ,ilm.attribute6 "                          );  // �݌ɓ���
    sb.append("          ,ilm.attribute7 "                          );  // �݌ɒP��
    sb.append("          ,ilm.attribute8 "                          );  // �����
    sb.append("          ,ilm.attribute9 "                          );  // �d���`��
    sb.append("          ,ilm.attribute10 "                         );  // �����敪
    sb.append("          ,ilm.attribute11 "                         );  // �N�x
    sb.append("          ,ilm.attribute12 "                         );  // �Y�n
    sb.append("          ,ilm.attribute13 "                         );  // �^�C�v
    sb.append("          ,ilm.attribute14 "                         );  // �����N�P
    sb.append("          ,ilm.attribute15 "                         );  // �����N�Q
    sb.append("          ,ilm.attribute16 "                         );  // ���Y�`�[�敪
    sb.append("          ,ilm.attribute17 "                         );  // ���C����
    sb.append("          ,ilm.attribute18 "                         );  // �E�v
    sb.append("          ,ilm.attribute19 "                         );  // �����N�R
    sb.append("          ,ilm.attribute20 "                         );  // ���������H��
    sb.append("          ,ilm.attribute22 "                         );  // �������������b�g�ԍ�
    sb.append("          ,ilm.attribute21 "                         );  // �����˗�No
    sb.append("          ,ilm.attribute23 "                         );  // ���b�g�X�e�[�^�X
    sb.append("          ,ilm.attribute24 "                         );  // �쐬�敪
    sb.append("          ,ilm.attribute25 "                         );  // DFF����25
    sb.append("          ,ilm.attribute26 "                         );  // DFF����26
    sb.append("          ,ilm.attribute27 "                         );  // DFF����27
    sb.append("          ,ilm.attribute28 "                         );  // DFF����28
    sb.append("          ,ilm.attribute29 "                         );  // DFF����29
    sb.append("          ,ilm.attribute30 "                         );  // DFF����30
    sb.append("          ,ilm.attribute_category "                  );  // DFF�J�e�S��
    sb.append("          ,ilm.odm_lot_number "                      );
    sb.append("    FROM ic_lots_mst ilm "                           );
    sb.append("    WHERE ilm.item_id = :" + (bindCount++)               );  // �i��ID
    sb.append("    AND   ilm.lot_no  = :" + (bindCount++) + "; "        );  // ���b�gNo
    sb.append("  p_lot_rec ic_lots_mst%ROWTYPE; "                   );
  
    sb.append("  CURSOR p_lot_cpg_cur( "                            );
    sb.append("    p_lot_id  ic_lots_cpg.lot_id%TYPE) "             );
    sb.append("  IS "                                               );
    sb.append("    SELECT ilc.item_id "                             );
    sb.append("          ,ilc.lot_id "                              );
    sb.append("          ,ilc.ic_matr_date "                        );
    sb.append("          ,ilc.ic_hold_date "                        );
    sb.append("          ,ilc.created_by "                          );
    sb.append("          ,ilc.creation_date "                       );
    sb.append("          ,ilc.last_update_date "                    );
    sb.append("          ,ilc.last_updated_by "                     );
    sb.append("          ,ilc.last_update_login "                   );
    sb.append("    FROM ic_lots_cpg ilc "                           );
    sb.append("    WHERE ilc.item_id = :"+ (bindCount++)                );  // �i��ID
    sb.append("    AND   ilc.lot_id  = p_lot_id; "                  );  // ���b�gID
    sb.append("  p_lot_cpg_rec ic_lots_cpg%ROWTYPE; "               );

    sb.append("BEGIN "                                              );
    // GMI�nAPI�O���[�o���萔�̐ݒ�
    sb.append("  lb_setup_return_sts  :=  GMIGUTL.Setup(FND_GLOBAL.USER_NAME); ");  
    
    // OPM���b�gMST�J�[�\�� OPEN
    sb.append("  OPEN p_lot_cur; "                                  );
    sb.append("  FETCH p_lot_cur INTO p_lot_rec; "                  );

    sb.append("  OPEN p_lot_cpg_cur(p_lot_rec.lot_id); "            );
    sb.append("  FETCH p_lot_cpg_cur INTO p_lot_cpg_rec; "          );

    // ******************************** //
    // * �X�V�f�[�^��ݒ�(���I) 6�`   * //
    // ******************************** //
    // �X�V����������ꍇ�A�X�V�f�[�^���i�[ [Start]
    if (!XxcmnUtility.isBlankOrNull(firstTimeDeliveryDate))
    {
      sb.append("  p_lot_rec.attribute4        := :" + (bindCount++) + "; " );  // �[�����i����j
    }
    if (!XxcmnUtility.isBlankOrNull(finalDeliveryDate))
    {
      sb.append("  p_lot_rec.attribute5        := :" + (bindCount++) + "; " );  // �[�����i�ŏI�j
    }
    if (!XxcmnUtility.isBlankOrNull(productionDate))
    {
      sb.append("  p_lot_rec.attribute1        := :" + (bindCount++) + "; " );  // �����N����
    }
    if (!XxcmnUtility.isBlankOrNull(useByDate))
    {
      sb.append("  p_lot_rec.attribute3        := :" + (bindCount++) + "; " );  // �ܖ�����
    }
// 20080523 add yoshimoto Start
    if (!XxcmnUtility.isBlankOrNull(itemAmount))
    {
      sb.append("  p_lot_rec.attribute6        := :" + (bindCount++) + "; " );  // ����
    }
    if (!XxcmnUtility.isBlankOrNull(description))
    {
      sb.append("  p_lot_rec.attribute18       := :" + (bindCount++) + "; " );  // �E�v
    }
// 20080523 add yoshimoto End
    // �X�V����������ꍇ�A�X�V�f�[�^���i�[ [End]
    
    sb.append("  p_lot_rec.last_updated_by   := FND_GLOBAL.USER_ID; " );  // �ŏI�X�V��
    sb.append("  p_lot_rec.last_update_date  := SYSDATE; "            );  // �ŏI�X�V��

    // ���b�g�X�VAPI�Ăяo��
    sb.append("  GMI_LotUpdate_PUB.Update_Lot( "                                       );
    sb.append("                     p_api_version      => ln_api_version_number "      );  // IN  API�̃o�[�W�����ԍ�
    sb.append("                    ,p_init_msg_list    => FND_API.G_FALSE "            );  // IN  ���b�Z�[�W�������t���O
    sb.append("                    ,p_commit           => FND_API.G_FALSE "            );  // IN  �����m��t���O
    sb.append("                    ,p_validation_level => FND_API.G_VALID_LEVEL_FULL " );  // IN  ���؃��x��
    sb.append("                    ,x_return_status    => lv_ret_status "              );  // OUT �I���X�e�[�^�X('S'-����I��,'E'-��O����,'U'-�V�X�e����O����)
    sb.append("                    ,x_msg_count        => ln_msg_cnt "                 );  // OUT ���b�Z�[�W�E�X�^�b�N��
    sb.append("                    ,x_msg_data         => lv_msg_data "                );  // OUT ���b�Z�[�W
    sb.append("                    ,p_lot_rec          => p_lot_rec "                  );  // IN  �X�V���郍�b�g�����w��
    sb.append("                    ,p_lot_cpg_rec      => p_lot_cpg_rec); "            );  // IN  �X�V���郍�b�g�����w��

    sb.append("  CLOSE p_lot_cur; "                );
    sb.append("  CLOSE p_lot_cpg_cur; "            );

    // �G���[���b�Z�[�W��FND_LOG_MESSAGES�ɏo��
    sb.append("  IF (ln_msg_cnt > 0) THEN "        );
    sb.append("    xxcmn_common_pkg.put_api_log( " );
    sb.append("       ov_errbuf  => lv_errbuf "    );
    sb.append("      ,ov_retcode => lv_retcode "   );
    sb.append("      ,ov_errmsg  => lv_errmsg ); " );
    sb.append("  END IF; "                         );

    // OUT�p�����[�^�o��
    sb.append("  :" + (bindCount++) + " := lv_ret_status; "            ); 
    sb.append("  :" + (bindCount++) + " := ln_msg_cnt; "               );
    sb.append("  :" + (bindCount++) + " := lv_msg_data; "              );

    sb.append("END; "                              );


    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {
      // ******************************* //
      // * �p�����[�^��ݒ�(�Œ�)      * //
      // ******************************* //
      // �p�����[�^�ݒ�(IN�p�����[�^)
      bindCount = 1;
      cstmt.setInt(bindCount++, XxcmnUtility.intValue(itemId)); // OPM�i��ID
      cstmt.setString(bindCount++, lotNo);                      // ���b�gNo
      cstmt.setInt(bindCount++, XxcmnUtility.intValue(itemId)); // OPM�i��ID

      // ****************************************** //
      // * �p�����[�^(�X�V�f�[�^)��ݒ�(���I)     * //
      // ****************************************** //
      // �擾�ł���ꍇ�͐ݒ�(IN�p�����[�^) Start
      // �[�����i����j
      if (!XxcmnUtility.isBlankOrNull(firstTimeDeliveryDate))
      {
        cstmt.setString(bindCount++, firstTimeDeliveryDate);
      }
      // �[�����i�ŏI�j
      if (!XxcmnUtility.isBlankOrNull(finalDeliveryDate))
      {
        cstmt.setString(bindCount++, finalDeliveryDate);
      }
      // �����N����
      if (!XxcmnUtility.isBlankOrNull(productionDate))
      {
// 20080521 yoshimoto mod Start
        //cstmt.setString(bindCount++, productionDate.toString());
        cstmt.setString(bindCount++, XxcmnUtility.stringValue(productionDate));
// 20080521 yoshimoto mod End
      }
      // �ܖ�����
      if (!XxcmnUtility.isBlankOrNull(useByDate))
      {
// 20080521 yoshimoto mod Start
        //cstmt.setString(bindCount++, useByDate.toString());
        cstmt.setString(bindCount++, XxcmnUtility.stringValue(useByDate));
// 20080521 yoshimoto mod End
      }
// 20080523 add yoshimoto Start
      // ����
      if (!XxcmnUtility.isBlankOrNull(itemAmount))
      {
        cstmt.setString(bindCount++, itemAmount);
      }
      // �E�v
      if (!XxcmnUtility.isBlankOrNull(description))
      {
        cstmt.setString(bindCount++, description);
      }
// 20080523 add yoshimoto End
      // �擾�ł���ꍇ�͐ݒ�(IN�p�����[�^) End


      // ******************************* //
      // * �p�����[�^��ݒ�(�Œ�)      * //
      // ******************************* //
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      int bindCount2 = bindCount; // OUT�p�����[�^�p�̃J�E���g(IN�p���̍ŏI�ԍ�+1)
      cstmt.registerOutParameter(bindCount2++, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(bindCount2++, Types.INTEGER);   // ���b�Z�[�W��
      cstmt.registerOutParameter(bindCount2++, Types.VARCHAR);   // ���b�Z�[�W

      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      bindCount2 = bindCount;     // OUT�p�����[�^�p�̃J�E���g���Đݒ�(IN�p���̍ŏI�ԍ�+1)
      String retStatus = cstmt.getString(bindCount2++); // ���^�[���R�[�h
      int msgCnt      = cstmt.getInt(bindCount2++);    // ���b�Z�[�W��
      String msgData   = cstmt.getString(bindCount2++); // ���b�Z�[�W


      // ����I���̏ꍇ�A�t���O��1:����ɁB
      if (XxcmnConstants.API_STATUS_SUCCESS.equals(retStatus)) 
      {
        // ���^�[���R�[�h������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;

      // ����I���łȂ��ꍇ�A�G���[  
      } else
      {

        // API�G���[���o�͂���B
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              msgData,
                              6);

        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);

      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {

      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }

    // ����ɏ������ꂽ�ꍇ�A"SUCCESS"(1)��ԋp
    return XxcmnConstants.RETURN_SUCCESS;    
  } // updateIcLotsMstTxns2
  
  /*****************************************************************************
   * �����w�b�_.�X�e�[�^�X�R�[�h���X�V���܂��B
   * @param trans �g�����U�N�V����
   * @param statusCode �X�e�[�^�X�R�[�h
   * @param headerId �����w�b�_ID
   * @return String XxcmnConstants.RETURN_SUCCESS:1 ����
   *                 XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String updateStatusCode(
    OADBTransaction trans,
    String statusCode,
    Number headerId
  ) throws OAException
  {
    String apiName = "updateStatusCode";
  
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                    );
    // �����w�b�_�X�V
    sb.append("  UPDATE po_headers_all pha "                              );
    sb.append("  SET    pha.attribute1            = :1 "                  ); // �X�e�[�^�X�R�[�h
    sb.append("        ,pha.last_updated_by       = FND_GLOBAL.USER_ID "  ); // �ŏI�X�V��
    sb.append("        ,pha.last_update_date      = SYSDATE "             ); // �ŏI�X�V��
    sb.append("        ,pha.last_update_login     = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C��
    sb.append("  WHERE  pha.po_header_id          = :2;  "                ); // �����w�b�_ID
    sb.append("END; "                                                     );

    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, statusCode);                      // �X�e�[�^�X�R�[�h
      cstmt.setInt(2, XxcmnUtility.intValue(headerId));    // �����w�b�_ID

      //PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return XxcmnConstants.RETURN_SUCCESS;
  } // updateStatusCode

  /***************************************************************************
   * �S�������ׂ̐��ʊm��ς��`�F�b�N���郁�\�b�h�ł��B
   * @param trans �g�����U�N�V����
   * @param headerId �����w�b�_ID
   * @return retCode Y�F�S�Đ��ʊm��ρAN�F���ʊm��ςłȂ��������חL��
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public static String chkAllFinDecisionAmountFlg(
    OADBTransaction trans,
    Number headerId
  )
  {
    String apiName = "chkAllFinDecisionAmountFlg";

    // �߂�l
    String retCode = null;
    
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);


    sb.append(" DECLARE "                           );
    sb.append("   ln_count1 NUMBER; "               );
    sb.append("   ln_count2 NUMBER; "               );
    sb.append(" BEGIN "                             );
    // �����w�b�_ID�ɕR�t���A�������ׂ̑������擾
    sb.append("   SELECT COUNT(pla.po_header_id) "  );
    sb.append("   INTO ln_count1 "                  );
    sb.append("   FROM po_lines_all pla "           );
    sb.append("   WHERE pla.po_header_id = :1 "     );
// 2008-12-18 v1.18 T.Yoshimoto Add Start �{��#788
    sb.append("   AND   pla.cancel_flag  = 'N' "    );
// 2008-12-18 v1.18 T.Yoshimoto Add End �{��#788
    sb.append("   ORDER BY pla.po_header_id; "      );

    // �����w�b�_ID�ɕR�t���A���ʊm��t���O(ATTRIBUTE13)��'Y'�ł���A
    // �������ׂ̑������擾
    sb.append("   SELECT COUNT(pla.po_header_id) "  );
    sb.append("   INTO ln_count2 "                  );
    sb.append("   FROM po_lines_all pla "           );
    sb.append("   WHERE pla.po_header_id = :1 "     );
    sb.append("   AND   pla.attribute13 = 'Y' "     );
// 2008-12-18 v1.18 T.Yoshimoto Add Start �{��#788
    sb.append("   AND   pla.cancel_flag  = 'N' "    );
// 2008-12-18 v1.18 T.Yoshimoto Add End �{��#788
    sb.append("   ORDER BY pla.po_header_id; "      );

    // �������ׂ̑����ƁA���ʊm��t���O(ATTRIBUTE13)��'Y'�ł��锭�����ׂ̑�����
    // �����̏ꍇ��'Y'
    sb.append("   IF (ln_count1 = ln_count2) THEN " );
    sb.append("    :2 := 'Y'; "                     );
    sb.append("   ELSE "                            );
    sb.append("    :2 := 'N'; "                     );
    sb.append("   END IF; "                         );
    sb.append(" END; "                              );


    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1, XxcmnUtility.intValue(headerId));  // �����w�b�_�A�h�I��ID
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(2, Types.VARCHAR);      // ���^�[���R�[�h
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      retCode = cstmt.getString(2); // ���^�[���R�[�h

    } catch (SQLException s) 
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally 
    {
      try 
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s) 
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
    return retCode;

  } // chkAllFinDecisionAmountFlg

  /*****************************************************************************
   * �݌ɐ���API���N�����܂��B
   * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @return HashMap
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap insertIcTranCmp(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertIcTranCmp"; // API��

    // IN�p�����[�^�擾
    String locationCode       = (String)params.get("LocationCode");       // �ۊǏꏊ
    String itemNo             = (String)params.get("ItemNo");             // �i��
    String unitMeasLookupCode = (String)params.get("UnitMeasLookupCode"); // �i�ڊ�P��
    String lotNo              = (String)params.get("LotNo");              // ���b�g
    String amount             = (String)params.get("Amount");             // ����
    Date txnsDate             = (Date)params.get("TxnsDate");             // �����
    String reasonCode         = (String)params.get("ReasonCode");         // ���R�R�[�h
    Number txnsId             = (Number)params.get("TxnsId");             // �����\�[�XID

    HashMap retHashMap = new HashMap(); // �߂�l
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append(" DECLARE "                                                        );
    sb.append("   lr_qty_in              GMIGAPI.qty_rec_typ; "                  );
    sb.append("   lr_qty_out             ic_jrnl_mst%ROWTYPE; "                  );
    sb.append("   lr_adjs_out1           ic_adjs_jnl%ROWTYPE; "                  );
    sb.append("   lr_adjs_out2           ic_adjs_jnl%ROWTYPE; "                  );
    sb.append("   ln_api_version_number  CONSTANT NUMBER := 3.0; "               );
    sb.append("   lb_setup_return_sts    BOOLEAN; "                              );
    sb.append("   lt_whse_code           ic_tran_cmp.whse_code%TYPE; "           );
    sb.append("   lt_co_code             ic_tran_cmp.co_code%TYPE; "             );
    sb.append("   lt_orgn_code           ic_tran_cmp.orgn_code%TYPE; "           );
    sb.append(" BEGIN "                                                          );
    // GMI�nAPI�O���[�o���萔�̐ݒ�
    sb.append("   lb_setup_return_sts  :=  GMIGUTL.Setup(FND_GLOBAL.USER_NAME); "); 
    
    // �q��,�g�D,��ЃR�[�h���擾
    sb.append("   SELECT xilv.whse_code "    );  // �q�ɃR�[�h
    sb.append("         ,iwm.orgn_code "     );  // �g�D�R�[�h
    sb.append("         ,somb.co_code "      );  // ��ЃR�[�h
    sb.append("   INTO   lt_whse_code "                    );
    sb.append("         ,lt_orgn_code "                    );
    sb.append("         ,lt_co_code "                      );
    sb.append("   FROM   xxcmn_item_locations_v  xilv "    );
    sb.append("         ,ic_whse_mst             iwm "     );
    sb.append("         ,sy_orgn_mst_b           somb "    );
    sb.append("   WHERE  xilv.whse_code = iwm.whse_code "  );
    sb.append("   AND    iwm.orgn_code  = somb.orgn_code " );
    sb.append("   AND    xilv.segment1  = :1; "            );
    
    
    // �p�����[�^�쐬
    sb.append("  lr_qty_in.trans_type          := 2; "                          ); // ����^�C�v(���2:��������)
    sb.append("  lr_qty_in.item_no             := :2; "                         ); // �i��
    sb.append("  lr_qty_in.from_whse_code      := lt_whse_code; "               ); // �q��
    sb.append("  lr_qty_in.item_um             := :3; "                         ); // �P��
    sb.append("  lr_qty_in.lot_no              := :4; "                         ); // ���b�g
    sb.append("  lr_qty_in.from_location       := :5; "                         ); // �ۊǏꏊ
    sb.append("  lr_qty_in.trans_qty           := :6; "                         ); // ����
    sb.append("  lr_qty_in.co_code             := lt_co_code; "                 ); // ���
    sb.append("  lr_qty_in.orgn_code           := lt_orgn_code; "               ); // �g�D
    sb.append("  lr_qty_in.trans_date          := :7; "                         ); // �����
    sb.append("  lr_qty_in.reason_code         := FND_PROFILE.VALUE(:8); "      ); // ���R�R�[�h
    sb.append("  lr_qty_in.user_name           := FND_GLOBAL.USER_NAME; "       ); // ���[�U��
    sb.append("  lr_qty_in.attribute1          := :9; "                         ); // �����\�[�XID

    // API:�݌ɐ���API���s
    sb.append("  GMIPAPI.INVENTORY_POSTING( "                                   );
    sb.append("     p_api_version      => ln_api_version_number "               ); // IN:API�̃o�[�W�����ԍ�
    sb.append("    ,p_init_msg_list    => FND_API.G_FALSE "                     ); // IN:���b�Z�[�W�������t���O
    sb.append("    ,p_commit           => FND_API.G_FALSE "                     ); // IN:�����m��t���O
    sb.append("    ,p_validation_level => FND_API.G_VALID_LEVEL_FULL "          ); // IN:���؃��x��
    sb.append("    ,p_qty_rec          => lr_qty_in "                           ); // IN:��������݌ɐ��ʏ����w��
    sb.append("    ,x_ic_jrnl_mst_row  => lr_qty_out "                          ); // OUT:�������ꂽ�݌ɐ��ʏ�񂪕ԋp
    sb.append("    ,x_ic_adjs_jnl_row1 => lr_adjs_out1 "                        ); // OUT:�������ꂽ�݌ɐ��ʏ�񂪕ԋp
    sb.append("    ,x_ic_adjs_jnl_row2 => lr_adjs_out2 "                        ); // OUT:-
    sb.append("    ,x_return_status    => :10 "                                 ); // OUT:�I���X�e�[�^�X( 'S'-����I��, 'E'-��O����, 'U'-�V�X�e����O����)
    sb.append("    ,x_msg_count        => :11 "                                 ); // OUT:���b�Z�[�W�E�X�^�b�N��
    sb.append("    ,x_msg_data         => :12); "                               ); // OUT:���b�Z�[�W   
    sb.append("END; "                                                           );
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, locationCode);                   // �ۊǏꏊ�R�[�h
      cstmt.setString(2, itemNo);                         // �i��
      cstmt.setString(3, unitMeasLookupCode);             // �P��
      cstmt.setString(4, lotNo);                          // ���b�g
      cstmt.setString(5, locationCode);                   // �ۊǏꏊ�R�[�h
      cstmt.setDouble(6, Double.parseDouble(amount));     // ����
      cstmt.setDate(7, XxcmnUtility.dateValue(txnsDate)); // �����
      cstmt.setString(8, reasonCode);                     // ���R�R�[�h
      cstmt.setInt(9, XxcmnUtility.intValue(txnsId));     // �����\�[�XID
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(10, Types.VARCHAR);  // ���^�[���X�e�[�^�X
      cstmt.registerOutParameter(11, Types.INTEGER); // ���b�Z�[�W�J�E���g
      cstmt.registerOutParameter(12, Types.VARCHAR); // ���b�Z�[�W

      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      String retStatus = cstmt.getString(10);  // ���^�[���X�e�[�^�X
      int msgCnt       = cstmt.getInt(11);    // ���b�Z�[�W�J�E���g
      String msgData   = cstmt.getString(12);  // ���b�Z�[�W

      // ����I���̏ꍇ
      if (XxcmnConstants.API_STATUS_SUCCESS.equals(retStatus)) 
      {
        // ���b�gID�A���^�[���R�[�h������Z�b�g
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);

      // ����I���łȂ��ꍇ�A�G���[  
      } else
      {
        // API�G���[���o�͂���B
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              msgData,
                              6);
        //�g�[�N������
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                   XxpoConstants.TAB_IC_LOTS_MST) };
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                               XxpoConstants.XXPO10007, 
                               tokens);
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
          XxcmnUtility.writeLog(trans,
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // insertIcTranCmp

  /*****************************************************************************
   * �R���J�����g�F�����������𔭍s���܂��B
   * @param trans �g�����U�N�V����
   * @param groupId �O���[�vID
   * @return HashMap ��������/�v��ID
   * @throws OAException OA��O
   ****************************************************************************/
  public static HashMap doRVCTP(
    OADBTransaction trans,
    String groupId
  ) throws OAException
  {
    String apiName      = "doRVCTP";

    // OUT�p�����[�^�p
    HashMap retHash = new HashMap();
    retHash.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE); // �߂�l

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "   );
    sb.append("  ln_request_id NUMBER; "                                       );
    sb.append("BEGIN "                                                         );
    // ����������(�R���J�����g)�Ăяo��
    sb.append("  ln_request_id := FND_REQUEST.SUBMIT_REQUEST( "                );
    sb.append("     application  => 'PO' "                                     ); // �A�v���P�[�V������
    sb.append("    ,program      => 'RVCTP' "                                  ); // �v���O�����Z�k��
    sb.append("    ,argument1    => 'BATCH' "                                  ); // ����������[�h
    sb.append("    ,argument2    => :1 ); "                                    ); // �O���[�vID
                 // �v��ID������ꍇ�A����
    sb.append("  IF ln_request_id > 0 THEN "                                   );
    sb.append("    :2 := '1'; "                                                ); // 1:����I��
    sb.append("    :3 := ln_request_id; "                                      ); // �v��ID
                 // �v��ID������ꍇ�A����
    sb.append("  ELSE "                                                        );
    sb.append("    :2 := '0'; "                                                ); // 0:�ُ�I��
    sb.append("    :3 := ln_request_id; "                                      ); // �v��ID
    sb.append("    ROLLBACK; "                                                 );
    sb.append("  END IF; "                                                     );
    sb.append("END; "                                                          );

    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, groupId);                    // �O���[�vID
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(2, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(3, Types.INTEGER);   // �v��ID

      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      String retFlag = cstmt.getString(2);    // ���^�[���R�[�h
      int requestId = cstmt.getInt(3); // �v��ID

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // ���^�[���R�[�h������Z�b�g
        retHash.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);
        retHash.put("RequestId", new Integer(requestId));
        
      // ����I���łȂ��ꍇ�A�G���[  
      } else
      {
        //�g�[�N������
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                   XxpoConstants.TOKEN_NAME_RVCTP) };
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                               XxpoConstants.XXPO10055, 
                               tokens);
      }
      
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }

    return retHash;
  } // doRVCTP. 

  /***************************************************************************
   * EBS�W��.���Tbl�o�^�σ`�F�b�N���s�����\�b�h�ł��B
   * @param trans - �g�����U�N�V����
   * @param txnsId - ���ID
   * @return String - XxcmnConstants.STRING_N�F���o�^
   *                  XxcmnConstants.STRING_Y�F�o�^��
   * @throws OAException OA��O
   ***************************************************************************
   */
  public static String chkRcvOifInput(
    OADBTransaction trans,
    Number txnsId
  )
  {
    String apiName = "chkRcvOifInput";
    CallableStatement cstmt = null;

    try
    {
      // PL/SQL�̍쐬���s���܂�
      StringBuffer sb = new StringBuffer(1000);
      sb.append(" BEGIN "                                          );
      sb.append("   SELECT COUNT(rsl.attribute1) cnt "             );
      sb.append("   INTO :1 "                                      );
      sb.append("   FROM rcv_shipment_lines rsl"                   );
      sb.append("   WHERE rsl.attribute1 = TO_CHAR(:2); "          );
      sb.append(" END; "                                           );

      // PL/SQL�̐ݒ���s���܂�
      cstmt = trans.createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);
      
      // PL/SQL�����s���܂�
      int i = 1;
      cstmt.registerOutParameter(i++, Types.INTEGER);
      cstmt.setInt(i++, XxcmnUtility.intValue(txnsId));

      // SQL���s
      cstmt.execute();

      int count = cstmt.getInt(1);

      // ����C���^�t�F�[�X�ɓo�^����Ă��Ȃ��ꍇ
      if (count == 0) 
      {
        return XxcmnConstants.STRING_N;
      }
      
    // PL/SQL���s����O�̏ꍇ   
    } catch (SQLException s) 
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally 
    {
      try 
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s) 
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }

    // ����C���^�t�F�[�X�ɓo�^�Ϗꍇ
    return XxcmnConstants.STRING_Y;

  } // chkRcvOifInput

  /*****************************************************************************
   * ����ԕi����(�A�h�I��)�Ƀf�[�^���X�V���܂��B
   * @param trans �g�����U�N�V����
   * @param params �p�����[�^
   * @return String ��������   
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String updateRcvAndRtnTxns(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "updateRcvAndRtnTxns";

    // IN�p�����[�^�擾
    // ���ID
    Number txnsId    = (Number)params.get("TxnsId");
    // ����
    String quantity  = (String)params.get("Quantity");
    // ����ԕi����
    String rcvRtnQuantity = (String)params.get("RcvRtnQuantity");
    // ���דE�v
    String lineDescription  = (String)params.get("LineDescription");

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" BEGIN "                                                         );
    sb.append("   UPDATE xxpo_rcv_and_rtn_txns rart "                           );
    sb.append("   SET rart.quantity          = :1 "                             );  // ����  
    sb.append("      ,rart.rcv_rtn_quantity  = :2 "                             );  // ����ԕi����
    sb.append("      ,rart.line_description  = :3 "                             );  // ���דE�v
// 2008-10-22 H.Itou Del Start �ύX�v����217
//    sb.append("      ,rart.created_by        = FND_GLOBAL.USER_ID "             );  // �쐬��          
//    sb.append("      ,rart.creation_date     = SYSDATE "                        );  // �쐬��          
// 2008-10-22 H.Itou Del End
    sb.append("      ,rart.last_updated_by   = FND_GLOBAL.USER_ID"              );  // �ŏI�X�V��      
    sb.append("      ,rart.last_update_date  = SYSDATE "                        );  // �ŏI�X�V��      
    sb.append("      ,rart.last_update_login = FND_GLOBAL.LOGIN_ID "            );  // �ŏI�X�V���O�C��
    sb.append("   WHERE rart.txns_id = :4; "                                    );  // ���ID
    sb.append(" END; "                                                          );
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setDouble(1, Double.parseDouble(quantity));         // ����
      cstmt.setDouble(2, Double.parseDouble(rcvRtnQuantity));   // ����ԕi����
      cstmt.setString(3, lineDescription);                      // ���דE�v
      cstmt.setInt(4, XxcmnUtility.intValue(txnsId));           // �����ID
      
      //PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {

      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
          XxcmnUtility.writeLog(trans,
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    
    return XxcmnConstants.RETURN_SUCCESS;
    
  } // updateRcvAndRtnTxns

  /*****************************************************************************
   * �󒍖��׃A�h�I���̖��׍s��_���폜���܂��B
   * @param trans        - �g�����U�N�V����
   * @param orderLineId  - �󒍖��׃A�h�I��ID
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void deleteOrderLine(
    OADBTransaction trans,
    Number orderLineId
    ) throws OAException
  {
    String apiName = "deleteOrderLine";
  
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    // ���׍s�̍폜�t���O���X�V���܂��B
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_lines_all xola   "); // �󒍖��׃A�h�I��
    sb.append("  SET    xola.delete_flag       = 'Y' ");                 // �폜�t���O
    sb.append("        ,xola.last_updated_by   = FND_GLOBAL.USER_ID ");  // �ŏI�X�V��
    sb.append("        ,xola.last_update_date  = SYSDATE ");             // �ŏI�X�V��
    sb.append("        ,xola.last_update_login = FND_GLOBAL.LOGIN_ID "); // �ŏI�X�V���O�C��
    sb.append("  WHERE  xola.order_Line_id   = :1;  ");                  // �������׃A�h�I��ID
    sb.append("END; ");
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1,  XxcmnUtility.intValue(orderLineId)); // �󒍖��׃A�h�I��ID
      //PL/SQL���s
      cstmt.execute();
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // deleteOrderLine

  /*****************************************************************************
   * �ғ������t�̎Z�o���s���܂��B
   * @param trans - �g�����U�N�V����
   * @param originalDate - ���
   * @param shipWhseCode - �ۊǑq�ɃR�[�h
   * @param shipToCode   - �z����R�[�h
   * @param leadTime     - ���[�h�^�C��
   * @return Date - �ғ������t
   * @throws OAException OA��O
   ****************************************************************************/
  public static Date getOprtnDay(
    OADBTransaction trans,
    Date originalDate,
    String shipWhseCode,
    String shipToCode,
    int leadTime
  ) throws OAException
  {
    String apiName   = "getOprtnDay";
    Date   oprtnDate = null;
    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  :1 := xxwsh_common_pkg.get_oprtn_day( ");
    sb.append("           :2 ");
    sb.append("          ,:3 ");
    sb.append("          ,:4 ");
    sb.append("          ,:5 ");
    sb.append("          ,FND_PROFILE.VALUE('XXCMN_ITEM_DIV_SECURITY') "); // ���i�敪
    sb.append("          ,:6); ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      int i = 1;
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(i++, Types.INTEGER); // �߂�l

      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setDate(i++, XxcmnUtility.dateValue(originalDate)); // ���ɓ�

      if (XxcmnUtility.isBlankOrNull(shipWhseCode)) 
      {
        cstmt.setNull(i++, Types.VARCHAR);
      } else 
      {
        cstmt.setString(i++, shipWhseCode); // �ۊǑq��
      }
      if (XxcmnUtility.isBlankOrNull(shipToCode)) 
      {
        cstmt.setNull(i++, Types.VARCHAR);
      } else 
      {
        cstmt.setString(i++, shipToCode); // �z����
      }
      cstmt.setInt(i++, leadTime); // ���[�h�^�C��
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(i++, Types.DATE);    // �ғ����t

      // PL/SQL���s
      cstmt.execute();
      if (cstmt.getInt(1) == 1) 
      {
        // ���[���o�b�N
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              "�߂�l���G���[�ŕԂ�܂����B",
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
      
      // �߂�l�擾
      oprtnDate = new Date(cstmt.getDate(6));

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return oprtnDate;
  } // getOprtnDay

  /*****************************************************************************
   * ��\�^����Ђ���^���Ǝ҂̎Z�o���s���܂��B
   * @param trans - �g�����U�N�V����
   * @param frequentMover - ��\�^�����
   * @param freightId     - �^���Ǝ�ID
   * @param freightCode   - �^���Ǝ҃R�[�h
   * @param freightName   - �^���ƎЖ�
   * @param originalDate  - ���(Null�̏ꍇSYSDATE)
   * @return HashMap - �߂�l�Q
   * @throws OAException OA��O
   ****************************************************************************/
  public static HashMap getfreightData(
    OADBTransaction trans,
    String frequentMover,
    Number freightId,
    String freightCode,
    String freightName,
    Date   originalDate
  ) throws OAException
  {
    String apiName   = "getfreightData";

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  SELECT xcv.party_id         party_id     "); // �^���Ǝ�ID(�p�[�e�B�[ID)
    sb.append("        ,xcv.party_number     party_number "); // �^���Ǝ҃R�[�h(�g�D�ԍ�)
    sb.append("        ,xcv.party_short_name party_name   "); // �^���ƎҖ�(����)
    sb.append("  INTO   :1 ");
    sb.append("        ,:2 ");
    sb.append("        ,:3 ");
    sb.append("  FROM   xxcmn_carriers2_v xcv "); // �^���Ǝҏ��VIEW
    sb.append("  WHERE  TRUNC(NVL(:4, SYSDATE)) BETWEEN xcv.start_date_active ");
    sb.append("                                 AND     xcv.end_date_active   ");
    sb.append("  AND    xcv.party_number = :5; ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      int i = 1;
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(i++, Types.INTEGER); // �^���Ǝ�ID
      cstmt.registerOutParameter(i++, Types.VARCHAR); // �^���Ǝ҃R�[�h
      cstmt.registerOutParameter(i++, Types.VARCHAR); // �^���ƎҖ�

      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setDate(i++, originalDate.dateValue());  // ���
      cstmt.setString(i++, frequentMover); // ��\�^�����

      // PL/SQL���s
      cstmt.execute();
      // �߂�l�擾
      Number retFreightId   = new Number(cstmt.getInt(1));
      String retFreightCode = cstmt.getString(2);
      String retFreightName = cstmt.getString(3);
      HashMap paramsRet = new HashMap();
      paramsRet.put("freightId",   retFreightId); 
      paramsRet.put("freightCode", retFreightCode);
      paramsRet.put("freightName", retFreightName);
      return paramsRet;
      
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���O�ɏo��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[�ɂ����߂�l�ɂ��ׂ�null���Z�b�g���Ė߂��B
      HashMap paramsRet = new HashMap();
      paramsRet.put("freightId",   null); 
      paramsRet.put("freightCode", null);
      paramsRet.put("freightName", null);
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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getfreightData

  /*****************************************************************************
   * �ő�z���敪�̎Z�o���s���܂��B
   * @param trans - �g�����U�N�V����
   * @param codeClass1 - �R�[�h�敪1
   * @param whseCode1  - ���o�ɏꏊ�R�[�h1
   * @param codeClass2 - �R�[�h�敪2
   * @param whseCode2  - ���o�ɏꏊ�R�[�h2
   * @param weightCapacityClass - �d�ʗe�ϋ敪
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
    String autoProcessType,
    Date   originalDate
  ) throws OAException
  {
    String apiName   = "getMaxShipMethod";

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lv_prod_class             VARCHAR2(1); ");
    sb.append("  ln_drink_deadweight       xxcmn_ship_methods.drink_deadweight%TYPE; ");
    sb.append("  ln_leaf_deadweight        xxcmn_ship_methods.leaf_deadweight%TYPE; ");
    sb.append("  ln_drink_loading_capacity xxcmn_ship_methods.drink_loading_capacity%TYPE; ");
    sb.append("  ln_leaf_loading_capacity  xxcmn_ship_methods.leaf_loading_capacity%TYPE; ");
    sb.append("  ln_palette_max_qty        xxcmn_ship_methods.palette_max_qty%TYPE; ");
    sb.append("  lv_weight_capacity_class  VARCHAR2(1); ");
    sb.append("  ln_deadweight             NUMBER; ");
    sb.append("  ln_loading_capacity       NUMBER; ");
    sb.append("BEGIN ");
    sb.append("  lv_prod_class := FND_PROFILE.VALUE('XXCMN_ITEM_DIV_SECURITY'); ");
    sb.append("  lv_weight_capacity_class := :1;   ");
    sb.append("  ln_deadweight            := null; ");
    sb.append("  ln_loading_capacity      := null; ");
    sb.append("  :2 := xxwsh_common_pkg.get_max_ship_method( ");
    sb.append("          :3    "); // �R�[�h�敪1
    sb.append("         ,:4    "); // ���o�ɏꏊ�R�[�h1
    sb.append("         ,:5    "); // �R�[�h�敪2
    sb.append("         ,:6    "); // ���o�ɏꏊ�R�[�h2
    sb.append("         ,lv_prod_class            "); // ���i�敪
    sb.append("         ,lv_weight_capacity_class "); // �d�ʗe�ϋ敪
    sb.append("         ,:7    "); // �����z�ԑΏۋ敪
    sb.append("         ,:8    "); // ���
    sb.append("         ,:9    "); // �ő�z���敪
    sb.append("         ,ln_drink_deadweight       "); // �h�����N�ύڏd��
    sb.append("         ,ln_leaf_deadweight        "); // ���[�t�ύڏd��
    sb.append("         ,ln_drink_loading_capacity "); // �h�����N�ύڗe��
    sb.append("         ,ln_leaf_loading_capacity  "); // ���[�t�ύڗe��
    sb.append("         ,ln_palette_max_qty); "); // �p���b�g�ő喇��
// 2008-07-29 D.Nihei MOD START
//    // ���[�t�E�d�ʂ̏ꍇ
//    sb.append("  IF (('1' = lv_prod_class) AND ('1' = lv_weight_capacity_class)) THEN ");
    // ���[�t�̏ꍇ
    sb.append("  IF ( '1' = lv_prod_class ) THEN ");
// 2008-07-29 D.Nihei MOD END
    sb.append("    ln_deadweight := ln_leaf_deadweight; ");
// 2008-07-29 D.Nihei DEL START
//    // ���[�t�E�e�ς̏ꍇ
//    sb.append("  ELSIF (('1' = lv_prod_class) AND ('2' = lv_weight_capacity_class)) THEN ");
// 2008-07-29 D.Nihei DEL END
    sb.append("    ln_loading_capacity := ln_leaf_loading_capacity; ");
// 2008-07-29 D.Nihei MOD START
//    // �h�����N�E�d�ʂ̏ꍇ
//    sb.append("  ELSIF (('2' = lv_prod_class) AND ('1' = lv_weight_capacity_class)) THEN ");
    // �h�����N�̏ꍇ
    sb.append("  ELSIF ('2' = lv_prod_class ) THEN ");
// 2008-07-29 D.Nihei MOD END
    sb.append("    ln_deadweight := ln_drink_deadweight; ");
// 2008-07-29 D.Nihei DEL START
//    // �h�����N�E�e�ς̏ꍇ
//    sb.append("  ELSIF (('2' = lv_prod_class) AND ('2' = lv_weight_capacity_class)) THEN ");
// 2008-07-29 D.Nihei DEL END
    sb.append("    ln_loading_capacity := ln_leaf_loading_capacity; ");
    // ����ȊO
    sb.append("  ELSE ");
    sb.append("    ln_deadweight       := null; ");
    sb.append("    ln_loading_capacity := null; ");
    sb.append("  END IF; ");
// 2008-07-29 D.Nihei MOD START
//    sb.append("  :10 := TO_CHAR(ln_palette_max_qty,  'FM9,999,990'); ");
//    sb.append("  :11 := TO_CHAR(ln_deadweight,       'FM9,999,990'); ");
//    sb.append("  :12 := TO_CHAR(ln_loading_capacity, 'FM9,999,990'); ");
    sb.append("  :10 := TO_CHAR(ln_palette_max_qty);  ");
    sb.append("  :11 := TO_CHAR(ln_deadweight);       ");
    sb.append("  :12 := TO_CHAR(ln_loading_capacity); ");
// 2008-07-29 D.Nihei MOD END
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      int i = 1;
      // �p�����[�^�ݒ�(IN�p�����[�^)
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
      if (cstmt.getInt(2) == 1) 
      {
        // ���O�ɏo��
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              "�߂�l���G���[�ŕԂ�܂����B",
                              6);
        // �G���[�ɂ����߂�l�ɂ��ׂ�null���Z�b�g���Ė߂��B
        HashMap paramsRet = new HashMap();
        paramsRet.put("maxShipMethods",  null); 
        paramsRet.put("paletteMaxQty",   null);
        paramsRet.put("deadweight",      null);
        paramsRet.put("loadingCapacity", null);
        return paramsRet;
      }

      // �߂�l�擾
      String retMaxShipMethods  = cstmt.getString(9);
      String retPaletteMaxQty   = cstmt.getString(10);
      String retDeadweight      = cstmt.getString(11);
      String retLoadingCapacity = cstmt.getString(12);

      HashMap paramsRet = new HashMap();
      paramsRet.put("maxShipMethods",  retMaxShipMethods);
      paramsRet.put("paletteMaxQty",   retPaletteMaxQty);
      paramsRet.put("deadweight",      retDeadweight);
      paramsRet.put("loadingCapacity", retLoadingCapacity);

      return paramsRet;
      
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���O�ɏo��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[�ɂ����߂�l�ɂ��ׂ�null���Z�b�g���Ė߂��B
      HashMap paramsRet = new HashMap();
      paramsRet.put("maxShipMethods",  null); 
      paramsRet.put("paletteMaxQty",   null);
      paramsRet.put("deadweight",      null);
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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getMaxShipMethod

  /*****************************************************************************
   * �����敪���甭�������쐬�敪���擾���܂��B
   * @param trans - �g�����U�N�V����
   * @param orderTypeId - �����敪
   * @return String - ���������쐬�敪
   * @throws OAException OA��O
   ****************************************************************************/
  public static String getAutoCreatePoClass(
    OADBTransaction trans,
    Number orderTypeId
  ) throws OAException
  {
    String apiName   = "getAutoCreatePoClass";

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  SELECT xottv.auto_create_po_class "); // ���������쐬�敪
    sb.append("  INTO   :1 ");
    sb.append("  FROM   xxwsh_oe_transaction_types_v xottv "); // �󒍃^�C�v���VIEW
    sb.append("  WHERE  xottv.transaction_type_id = :2; ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      int i = 1;
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(i++, Types.VARCHAR); // ���������쐬�敪

      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(i++, orderTypeId.intValue());  // �����敪

      // PL/SQL���s
      cstmt.execute();

      return cstmt.getString(1);
      
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�ɏo��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getAutoCreatePoClass

  /*****************************************************************************
   * �V�[�P���X����󒍃w�b�_�A�h�I��ID���擾���܂��B
   * @param trans - �g�����U�N�V����
   * @return Number - �󒍃w�b�_�A�h�I��ID
   * @throws OAException OA��O
   ****************************************************************************/
  public static Number getOrderHeaderId(
    OADBTransaction trans
    ) throws OAException
  {

    return XxcmnUtility.getSeq(trans, XxpoConstants.XXWSH_ORDER_HEADERS_ALL_S1);

  } // getOrderHeaderId

  /*****************************************************************************
   * �z�Ԋ֘A���𓱏o���܂��B
   * @param trans - �g�����U�N�V����
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   * @return HashMap - �߂�l�Q
   * @throws OAException OA��O
   ****************************************************************************/
  public static HashMap getCarriersData(
    OADBTransaction trans,
    Number orderHeaderId
  ) throws OAException
  {
    String apiName   = "getCarriersData";

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
// 2008/08/07 D.Nihei Mod Start
//// 2008-07-29 D.Nihei Mod Start
//    sb.append("  SELECT ROUND(SUM(CASE "); 
//    sb.append("  SELECT CEIL(SUM(CASE "); 
//// 2008-07-29 D.Nihei Mod End
    sb.append("  SELECT SUM(CASE "); 
// 2008/08/07 D.Nihei Mod End
    sb.append("               WHEN (ximv.num_of_deliver IS NOT NULL)      "); 
// 2008/08/07 D.Nihei Mod Start
//    sb.append("                 THEN xola.quantity / ximv.num_of_deliver  "); 
    sb.append("                 THEN CEIL(xola.quantity / ximv.num_of_deliver)  "); 
// 2008/08/07 D.Nihei Mod End
    sb.append("               WHEN (ximv.conv_unit IS NOT NULL)           "); 
// 2008/08/07 D.Nihei Mod Start
//    sb.append("                 THEN xola.quantity / ximv.num_of_cases    "); 
//    sb.append("                 ELSE xola.quantity  "); 
    sb.append("                 THEN CEIL(xola.quantity / ximv.num_of_cases)    "); 
    sb.append("                 ELSE CEIL(xola.quantity)  "); 
// 2008/08/07 D.Nihei Mod End
    sb.append("               END)    small_quantity ");   // ������
// 2008-07-29 D.Nihei Mod Start
//    sb.append("        ,TO_CHAR(SUM(xola.quantity),   'FM999,999,990.000') sum_quantity ");   // ���v����
//    sb.append("        ,TO_CHAR(SUM(NVL(xola.weight  , 0)), 'FM9,999,990') sum_weight   ");   // ���v�d��
//    sb.append("        ,TO_CHAR(SUM(NVL(xola.capacity, 0)), 'FM9,999,990') sum_capacity ");   // ���v�e��
    sb.append("        ,TO_CHAR(SUM(xola.quantity))         sum_quantity ");   // ���v����
    sb.append("        ,TO_CHAR(SUM(NVL(xola.weight  , 0))) sum_weight   ");   // ���v�d��
    sb.append("        ,TO_CHAR(SUM(NVL(xola.capacity, 0))) sum_capacity ");   // ���v�e��
// 2008-07-29 D.Nihei Mod End
    sb.append("  INTO   :1 "); 
    sb.append("        ,:2 "); 
    sb.append("        ,:3 "); 
    sb.append("        ,:4 "); 
    sb.append("  FROM   xxwsh_order_lines_all   xola ");  // �󒍖��׃A�h�I�� 
    sb.append("        ,xxcmn_item_mst_v        ximv ");  // OPM�i�ڏ��VIEW 
    sb.append("  WHERE xola.shipping_inventory_item_id = ximv.inventory_item_id "); 
    sb.append("  AND   xola.delete_flag                = 'N' "); 
    sb.append("  AND   xola.order_header_id            = :5  "); 
    sb.append("  GROUP BY xola.order_header_id; "); 
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      int i = 1;
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(i++, Types.NUMERIC); // ������
      cstmt.registerOutParameter(i++, Types.VARCHAR); // ���v����
      cstmt.registerOutParameter(i++, Types.VARCHAR); // ���v�d��
      cstmt.registerOutParameter(i++, Types.VARCHAR); // ���v�e��

      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId)); // �󒍖��׃A�h�I��ID

      // PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      Number smallQuantity = new Number(cstmt.getObject(1));
      String sumQuantity   = cstmt.getString(2);
      String sumWeight     = cstmt.getString(3);
      String sumCapacity   = cstmt.getString(4);

      HashMap paramsRet = new HashMap();
      paramsRet.put("smallQuantity", smallQuantity);
      paramsRet.put("labelQuantity", smallQuantity); // �������Ɠ��l���Z�b�g
      paramsRet.put("sumQuantity",   sumQuantity);
      paramsRet.put("sumWeight",     sumWeight);
      paramsRet.put("sumCapacity",   sumCapacity);

      return paramsRet;
      
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���O�ɏo��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[�ɂ����߂�l�ɂ��ׂ�null���Z�b�g���Ė߂��B
      HashMap paramsRet = new HashMap();
      paramsRet.put("smallQuantity", null);
      paramsRet.put("labelQuantity", null);
      paramsRet.put("sumQuantity",   null);
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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getCarriersData

  /*****************************************************************************
   * �S�����o�Ɏ��̓��o�Ɏ��т��쐬���܂��B
   * @param  trans - �g�����U�N�V����
   * @param  orderHeaderId - �󒍃w�b�_�A�h�I��ID
   * @param  recordTypeCode - ���R�[�h�^�C�v(20�F�o�Ɏ��сA30�F���Ɏ���) 
   * @param  actualDate - ���ѓ�(���ɓ��E�o�ɓ�)
   * @return �����t���O true�F�������s�Afalse�F���������s
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean updateOrderExecute(
    OADBTransaction trans,
    Number orderHeaderId,
    String recordTypeCode,
    Date   actualDate
  ) throws OAException

  {
    String apiName = "updateOrderExecute";
    boolean exeType = false;

    //PL/SQL�̍쐬���擾���s���܂�
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN ");
    sb.append("  :1 := xxpo_common2_pkg.update_order_data( ");
    sb.append("           in_order_header_id   => :2    "); // �󒍃w�b�_�A�h�I��ID
    sb.append("          ,iv_record_type_code  => :3    "); // ���R�[�h�^�C�v(20�F�o�Ɏ��сA30�F���Ɏ���) 
    sb.append("          ,id_actual_date       => :4    "); // ���ѓ�(���ɓ��E�o�ɓ�)
    sb.append("          ,in_created_by        => FND_GLOBAL.USER_ID "); // �쐬��
    sb.append("          ,id_creation_date     => SYSDATE "); // �쐬��
    sb.append("          ,in_last_updated_by   => FND_GLOBAL.USER_ID "); // �ŏI�X�V��
    sb.append("          ,id_last_update_date  => SYSDATE "); // �ŏI�X�V�� 
    sb.append("          ,in_last_update_login => FND_GLOBAL.LOGIN_ID "); // �ŏI�X�V���O�C�� 
    sb.append("        ); ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.registerOutParameter(i++, Types.INTEGER);
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));
      cstmt.setString(i++, recordTypeCode);
      cstmt.setDate(i++, XxcmnUtility.dateValue(actualDate));
      cstmt.execute();

      //�߂�l�̎擾
      int retCode = cstmt.getInt(1);
      if (retCode == 0) 
      { // ����I���̏ꍇ
        exeType = true;
      } else 
      { // �ُ�I���̏ꍇ
        // ���[���o�b�N
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              "�ُ�I��",
                              6);
        //�g�[�N������
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                   "�S������") };
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                               XxcmnConstants.XXCMN05002, 
                               tokens);
      }
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return exeType;
  } // updateOrderExecute

  /*****************************************************************************
   * ���i�\����P�����擾���܂��B
   * @param inventoryItemId - INV�i��ID
   * @param listIdVendor - �����ʉ��i�\ID
   * @param listIdRepresent - ��\���i�\ID
   * @param arrivalDate - �K�p��(���ɓ�)
   * @param itemNo - �i�ڃR�[�h
   * @return Number - �P�� �擾�ł��Ȃ��ꍇ��Null��ԋp
   * @throws OAException - OA��O
   ****************************************************************************/
  public static Number getUnitPrice(
    OADBTransaction trans,
    Number inventoryItemId,
    String listIdVendor,
    String listIdRepresent,
    Date arrivalDate,
    String itemNo
  ) throws OAException
  {
    String apiName = "getUnitPrice";  // API��
    Integer unitPrice;                // �P��

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  ln_unit_price NUMBER; ");
    sb.append("BEGIN ");
    sb.append("  ln_unit_price := xxpo_common2_pkg.get_unit_price( ");
    sb.append("                     :1, :2, :3, :4); ");
    sb.append("  :5 := ln_unit_price; ");
    sb.append("END; ");

    // PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try 
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1, XxcmnUtility.intValue(inventoryItemId));  // INV�i��ID
      cstmt.setString(2, listIdVendor);     // ����承�i�\ID
      cstmt.setString(3, listIdRepresent);  // ��\���i�\ID
      cstmt.setDate(4, XxcmnUtility.dateValue(arrivalDate));    // �K�p��(���ɓ�)

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(5, Types.NUMERIC);             // �P��

      // PL/SQL���s
      cstmt.execute();

      // �P���`�F�b�N
      if (XxcmnUtility.isBlankOrNull(cstmt.getObject(5))) 
      {
        return null;
      }

      // �P���ԋp
      return new Number(cstmt.getObject(5));

    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);

      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getUnitPrice

  /*****************************************************************************
   * ���i�\�̒P���Ŏ󒍖��׃A�h�I���̒P�����X�V���܂��B
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   * @param listIdVendor - �����ʉ��i�\ID
   * @param listIdRepresent - ��\���i�\ID
   * @param arrivalDate - �K�p��(���ɓ�)
   * @param returnFlag - �ԕi�t���O Y:�ԕi�ANull:�ԕi�ȊO
   * @param itemClassCode - �i�ڋ敪
   * @param itemNo - �i�ڃR�[�h
   * @return String - �G���[���b�Z�[�W(�i��No) ����I���̏ꍇ��Null
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String updateUnitPrice(
    OADBTransaction trans,
    Number orderHeaderId,
    String listIdVendor,
    String listIdRepresent,
    Date arrivalDate,
    String returnFlag,
    String itemClassCode,
    String itemNo
  ) throws  OAException
  {
    String apiName = "updateUnitPrice";

    // PL/SQL�̍쐬���s���܂��B
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  xxpo_common2_pkg.update_order_unit_price( ");
    sb.append("    in_order_header_id    => :1 ");
    sb.append("   ,iv_list_id_vendor     => :2 ");
    sb.append("   ,iv_list_id_represent  => :3 ");
    sb.append("   ,id_arrival_date       => :4 ");
    sb.append("   ,iv_return_flag        => :5 ");
    sb.append("   ,iv_item_class_code    => :6 ");
    sb.append("   ,iv_item_no            => :7 ");
    sb.append("   ,ov_retcode            => :8 ");
    sb.append("   ,ov_errmsg             => :9 ");
    sb.append("   ,ov_system_msg         => :10 ");
    sb.append("  ); ");
    sb.append("END; ");

    // PL/SQL�̐ݒ���s���܂��B
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1, XxcmnUtility.intValue(orderHeaderId));    // �󒍃w�b�_�A�h�I��ID
      cstmt.setString(2, listIdVendor);     // �����ʉ��i�\ID
      cstmt.setString(3, listIdRepresent);  // ��\���i�\ID
      cstmt.setDate(4, XxcmnUtility.dateValue(arrivalDate));    // �K�p��(���ɓ�)
      cstmt.setString(5, returnFlag);                           // �ԕi�t���O
      cstmt.setString(6, itemClassCode);                        // �i�ڋ敪
      cstmt.setString(7, itemNo);                               // �i�ڃR�[�h

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter( 8, Types.VARCHAR, 1);         // �X�e�[�^�X�R�[�h
      cstmt.registerOutParameter( 9, Types.VARCHAR, 5000);      // �G���[���b�Z�[�W
      cstmt.registerOutParameter(10, Types.VARCHAR, 5000);      // �V�X�e�����b�Z�[�W

      // PL/SQL���s
      cstmt.execute();

      // ���s���ʊi�[
      String retCode   = cstmt.getString(8);  //���^�[���R�[�h
      String errMsg    = cstmt.getString(9);   //�G���[���b�Z�[�W
      String systemMsg = cstmt.getString(10); //�V�X�e�����b�Z�[�W

      if (XxcmnConstants.API_RETURN_ERROR.equals(retCode))
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(10),
                              6);
        // �X�V���s�G���[���b�Z�[�W
        return errMsg;
      }

    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);

      }
    }
    return null;
  } // updateUnitPrice

  /*****************************************************************************
   * �ړ����b�g�ڍׂ̃��b�g�X�e�[�^�X�`�F�b�N���s���܂��B
   * @param requestNo - �˗�No
   * @throws OAException  - OA��O
   ****************************************************************************/
  public static boolean chkLotStatus(
    OADBTransaction trans,
    String requestNo
    ) throws OAException
  {
    String apiName = "chkLotStatus";
    boolean retFlag = false;

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "  );
    sb.append("  SELECT COUNT(1) ");
    sb.append("  INTO   :1 ");
    sb.append("  FROM   xxcmn_lot_status_v       xlsv "); // ���b�g�X�e�[�^�X����VIEW
    sb.append("        ,ic_lots_mst              ilm  "); // OPM���b�g�}�X�^
    sb.append("        ,xxwsh_order_headers_all  xoha "); // �󒍃w�b�_�A�h�I��
    sb.append("        ,xxwsh_order_lines_all    xola "); // �󒍖��׃A�h�I��
    sb.append("        ,xxinv_mov_lot_details    xmld "); // �ړ����b�g�ڍ�(�A�h�I��)
    sb.append("        ,xxcmn_item_categories5_v xicv "); // OPM�i�ڃJ�e�S�����VIEW5
    sb.append("  WHERE  xoha.request_no         = :2  ");
    sb.append("  AND    xola.order_header_id    = xoha.order_header_id ");
    sb.append("  AND    xmld.mov_line_id        = xola.order_line_id   ");
    sb.append("  AND    xicv.item_id            = xmld.item_id ");
    sb.append("  AND    xicv.item_class_code   IN ('1', '4', '5') "); // �����A�����i�A���i
    sb.append("  AND    xmld.document_type_code = '30'   "); // �x���w��
    sb.append("  AND    xmld.record_type_code   = '10'   "); // �w��
    sb.append("  AND    ilm.item_id             = xmld.item_id ");
    sb.append("  AND    ilm.lot_id              = xmld.lot_id ");
    sb.append("  AND    ilm.lot_no              = xmld.lot_no ");
    sb.append("  AND    xlsv.lot_status         = ilm.attribute23 ");
    sb.append("  AND    xlsv.prod_class_code    = xoha.prod_class ");
    sb.append("  AND    xlsv.pay_provision_rel  = 'N' ");
    sb.append("  AND    ROWNUM = 1;  ");
    sb.append("END; ");
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      //�o�C���h�ϐ��ɒl���Z�b�g
      cstmt.registerOutParameter(1,Types.INTEGER);
      cstmt.setString(2, requestNo); // �˗�No
      //PL/SQL���s
      cstmt.execute();
      // �p�����[�^�̎擾
      int cnt = cstmt.getInt(1);
      if(cnt == 0)
      {
        retFlag = true; 
      } 
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // chkLotStatus

  /*****************************************************************************
   * ���q�ɂ̃J�E���g���擾���܂��B
   * @param trans �g�����U�N�V����
   * @return int ���q�ɂ̃J�E���g
   * @throws OAException OA��O
   ****************************************************************************/
  public static int getWarehouseCount(
    OADBTransaction trans
  ) throws OAException
  {
    String apiName  = "getWarehouseCount"; // API��

    int warehouseCount = 0;  // �߂�l�p

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" BEGIN "                                                          );
    sb.append("   SELECT COUNT(1) "                                              ); // �ۊǑq�ɃR�[�h
    sb.append("   INTO   :1 "                                                    );
    sb.append("   FROM fnd_user      fu "                                        ); // ���[�U�}�X�^
    sb.append("       ,per_all_people_f papf "                                   );
    sb.append("       ,xxcmn_item_locations_v xilv "                             ); // OPM�ۊǏꏊ���VIEW
    sb.append("   WHERE fu.employee_id              = papf.person_id "            );
    sb.append("     AND fu.start_date <= TRUNC(SYSDATE) "                        ); // �K�p�J�n��
    sb.append("     AND ((fu.end_date IS NULL) OR (fu.end_date >= TRUNC(SYSDATE))) " ); // �K�p�I����
    sb.append("     AND papf.effective_start_date <= TRUNC(SYSDATE) "            ); // �K�p�J�n��
    sb.append("     AND papf.effective_end_date   >= TRUNC(SYSDATE) "            ); // �K�p�I����
    sb.append("     AND papf.ATTRIBUTE4 = xilv.PURCHASE_CODE "                   );
    sb.append("     AND fu.user_id                 = FND_GLOBAL.USER_ID; "       );
    sb.append(" END; "                                                           );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.INTEGER); // �J�E���g
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      warehouseCount = cstmt.getInt(1);

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {

      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return warehouseCount;
  } // getWarehouseCount

  /*****************************************************************************
   * ���q�ɏ����擾���܂��B
   * @param trans �g�����U�N�V����
   * @return HashMap ���q�ɏ��
   * @throws OAException OA��O
   ****************************************************************************/
  public static HashMap getWarehouse(
    OADBTransaction trans
  ) throws OAException
  {
    String apiName  = "getWarehouse"; // API��

    HashMap retHashMap = new HashMap();  // �߂�l�p

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" BEGIN "                                                          );
    sb.append("   SELECT xilv.segment1 "                                         ); // �ۊǑq�ɃR�[�h
    sb.append("         ,xilv.description "                                      ); // �ۊǑq�ɖ�
    sb.append("   INTO   :1 "                                                    );
    sb.append("         ,:2 "                                                    );
    sb.append("   FROM fnd_user      fu "                                        ); // ���[�U�}�X�^
    sb.append("       ,per_all_people_f papf "                                   );
    sb.append("       ,xxcmn_item_locations_v xilv "                             ); // OPM�ۊǏꏊ���VIEW
    sb.append("   WHERE fu.employee_id              = papf.person_id "            );   
    sb.append("     AND fu.start_date <= TRUNC(SYSDATE) "                        ); // �K�p�J�n��
    sb.append("     AND ((fu.end_date IS NULL) OR (fu.end_date >= TRUNC(SYSDATE))) " ); // �K�p�I����
    sb.append("     AND papf.effective_start_date <= TRUNC(SYSDATE) "            ); // �K�p�J�n��
    sb.append("     AND papf.effective_end_date   >= TRUNC(SYSDATE) "            ); // �K�p�I����  
    sb.append("     AND papf.attribute4 = xilv.purchase_code "                   );
    sb.append("     AND fu.user_id                 = FND_GLOBAL.USER_ID; "       );
    sb.append(" END; "                                                           );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR); // �ۊǑq�ɃR�[�h
      cstmt.registerOutParameter(2, Types.VARCHAR); // �ۊǑq�ɖ�
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      retHashMap.put("LocationCode", cstmt.getString(1));
      retHashMap.put("LocationName", cstmt.getString(2));


    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // getWarehouse

  /*****************************************************************************
   * �������(�A�h�I��)�ɑ΂���Y���������ԍ�/���������הԍ��̑��݃`�F�b�N���s���܂��B
   * @param trans �g�����U�N�V����
   * @param headerNumber �����ԍ�
   * @return String XxcmnConstants.STRING_N�F�f�[�^����
   *                 XxcmnConstants.STRING_Y�F�f�[�^�L��
   * @throws OAException OA��O
   ****************************************************************************/
  public static String chkRcvAndRtnTxnsInput(
    OADBTransaction trans,
    String headerNumber
  ) throws OAException
  {
    String apiName  = "chkRcvAndRtnTxnsInput"; // API��

    int rcvAndRtnTxnsCount = 0;  
    String checkFlag = XxcmnConstants.STRING_N; // �߂�l�p

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" BEGIN "                                     );
    sb.append("   SELECT COUNT(1) "                         );
    sb.append("   INTO   :1 "                               );
    sb.append("   FROM xxpo_rcv_and_rtn_txns rart "         );
    sb.append("   WHERE rart.source_document_number = :2; " );
    sb.append(" END; "                                      );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.INTEGER); // �J�E���g

      //�o�C���h�ϐ��ɒl���Z�b�g
      cstmt.setString(2, headerNumber);             // �����ԍ�

      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      rcvAndRtnTxnsCount = cstmt.getInt(1);

      if (rcvAndRtnTxnsCount > 0)
      {
        checkFlag = XxcmnConstants.STRING_Y;
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {

      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return checkFlag;
  } // chkRcvAndRtnTxnsInput

  /*****************************************************************************
   * �x���w������̔��������쐬�֐����Ăяo���܂��B
   * @param reqNo   - �˗�No/�ړ��ԍ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void provAutoPurchaseOrders(
    OADBTransaction trans,
    String reqNo
  ) throws OAException
  {
    String apiName = "provAutoPurchaseOrders";  // API��

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  xxpo_common925_pkg.auto_purchase_orders(:1, :2, :3, :4, :5); ");
    sb.append("END; ");

    // PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try 
    {

      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, reqNo);   // �˗�No/�ړ��ԍ�

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(2, Types.VARCHAR); // ���^�[���E�R�[�h
      cstmt.registerOutParameter(3, Types.NUMERIC); // �o�b�`ID
      cstmt.registerOutParameter(4, Types.VARCHAR); // �G���[�E���b�Z�[�W�E�R�[�h
      cstmt.registerOutParameter(5, Types.VARCHAR); // ���[�U�[�E�G���[�E���b�Z�[�W

      // PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      String retCode    = cstmt.getString(2);
      Object retBatchId = cstmt.getObject(3);
      
      // �߂�l�����������ȊO�̓��O�ɃG���[���b�Z�[�W���o��
      if (XxcmnConstants.API_RETURN_NORMAL.equals(retCode) 
      && !XxcmnUtility.isBlankOrNull(retBatchId)) 
      {
        Number batchId = new Number(retBatchId);
        // �R�~�b�g���s
        commit(trans);
        // �W�������C���|�[�g���Ăяo��
        provImportStandardPurchaseOrders(trans, batchId);

      } else
      {
        // ���[���o�b�N
        rollBack(trans);
        String errMsg = cstmt.getString(5);
        // ���O�o��
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              errMsg,
                              6);
        // �G���[���b�Z�[�W�o��
        XxcmnUtility.putErrorMessage("�x���w������̔��������쐬");

      }
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);

      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);

      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);

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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // provAutoPurchaseOrders

  /*****************************************************************************
   * �x���w���p�R���J�����g�F�W�������C���|�[�g�𔭍s���܂��B
   * @param trans - �g�����U�N�V����
   * @param batchId - �o�b�`ID
   * @return String - XxcmnConstants.RETURN_SUCCESS:1 ����
   *                  XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void provImportStandardPurchaseOrders(
    OADBTransaction trans,
    Number batchId
  ) throws OAException
  {
    String apiName = "provImportStandardPurchaseOrders";

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "   );
    sb.append("  ln_request_id NUMBER; "                                             );
    sb.append("BEGIN "                                                               );
                 // �W�������C���|�[�g(�R���J�����g)�Ăяo��
    sb.append("  ln_request_id := fnd_request.submit_request( "                      );
    sb.append("     application  => 'PO' "                                           ); // �A�v���P�[�V������
    sb.append("    ,program      => 'POXPOPDOI' "                                    ); // �v���O�����Z�k��
    sb.append("    ,argument1    => NULL "                                           ); // �w���S��ID
    sb.append("    ,argument2    => 'STANDARD' "                                     ); // �����^�C�v
    sb.append("    ,argument3    => NULL "                                           ); // �����T�u�^�C�v
    sb.append("    ,argument4    => 'N' "                                            ); // �i�ڂ̍쐬 N:�s��Ȃ�
    sb.append("    ,argument5    => NULL "                                           ); // �\�[�X�E���[���̍쐬
    sb.append("    ,argument6    => 'APPROVED' "                                     ); // ���F�X�e�[�^�X APPROVAL:���F
    sb.append("    ,argument7    => NULL "                                           ); // �����[�X�������@
    sb.append("    ,argument8    => TO_CHAR(:1) "                                    ); // �o�b�`ID
    sb.append("    ,argument9    => NULL "                                           ); // �c�ƒP��
    sb.append("    ,argument10   => NULL); "                                         ); // �O���[�o���_��
                 // �v��ID������ꍇ�A����
    sb.append("  IF ln_request_id > 0 THEN "                                         );
    sb.append("    :2 := '1'; "                                                      ); // 1:����I��
    sb.append("    :3 := ln_request_id; "                                            ); // �v��ID
    sb.append("    COMMIT; "                                                         );
                 // �v��ID���Ȃ��ꍇ�A�ُ�
    sb.append("  ELSE "                                                              );
    sb.append("    :2 := '0'; "                                                      ); // 0:�ُ�I��
    sb.append("    :3 := ln_request_id; "                                            ); // �v��ID
    sb.append("    ROLLBACK; "                                                       );
    sb.append("  END IF; "                                                           );
    sb.append("END; "                                                                );

    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setBigDecimal(1, XxcmnUtility.bigDecimalValue(batchId)); // �o�b�`ID
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(2, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(3, Types.INTEGER);   // �v��ID
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      String retFlag = cstmt.getString(2); // ���^�[���R�[�h
      int requestId  = cstmt.getInt(3); // �v��ID

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // ���^�[���R�[�h������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        
      // ����I���łȂ��ꍇ�A�G���[  
      } else
      {
        //�g�[�N������
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PRG_NAME,
                                                   "�W�������C���|�[�g") };
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10025, 
                              tokens);

      }
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
          XxcmnUtility.writeLog(trans,
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
  } // provImportStandardPurchaseOrders 

  /*****************************************************************************
   * �R���J�����g�F�d�����э쐬�����𔭍s���܂��B
   * @param trans �g�����U�N�V����
   * @param headerNumber �����ԍ�
   * @return String XxcmnConstants.RETURN_SUCCESS:1 ����
   *                   XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException OA��O
   ****************************************************************************/
  public static String doStockResultMake(
    OADBTransaction trans,
    String headerNumber
  ) throws OAException
  {
    String apiName      = "doStockResultMake";


    // OUT�p�����[�^�p
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // �߂�l

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "   );
    sb.append("  ln_request_id NUMBER; "                                       );
    sb.append("BEGIN "                                                         );
                 // �����d���E�o�׎��э쐬����(�R���J�����g)�Ăяo��
    sb.append("  ln_request_id := FND_REQUEST.SUBMIT_REQUEST( "                );
    sb.append("     application  => 'XXPO' "                                   ); // �A�v���P�[�V������
    sb.append("    ,program      => 'XXPO310001C' "                            ); // �v���O�����Z�k��
    sb.append("    ,argument1    => :1 ); "                                    ); // ����No.
                 // �v��ID������ꍇ�A����
    sb.append("  IF ln_request_id > 0 THEN "                                   );
    sb.append("    :2 := '1'; "                                                ); // 1:����I��
    sb.append("    :3 := ln_request_id; "                                      ); // �v��ID
                 // �v��ID���Ȃ��ꍇ�A�ُ�
    sb.append("  ELSE "                                                        );
    sb.append("    :2 := '0'; "                                                ); // 0:�ُ�I��
    sb.append("    :3 := ln_request_id; "                                      ); // �v��ID
    sb.append("    ROLLBACK; "                                                 );
    sb.append("  END IF; "                                                     );
    sb.append("END; "                                                          );

    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, headerNumber);               // �����ԍ�
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(2, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(3, Types.INTEGER);   // �v��ID

      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      retFlag = cstmt.getString(2); // ���^�[���R�[�h
      int requestId = cstmt.getInt(3); // �v��ID

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // ���^�[���R�[�h������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        
      // ����I���łȂ��ꍇ�A�G���[  
      } else
      {
        // ���^�[���R�[�h�ُ���Z�b�g
        retFlag = XxcmnConstants.RETURN_NOT_EXE;

      }
      
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }

    return retFlag;
  } // doStockResultMake.

  /*****************************************************************************
   * �󒍃w�b�_�ɕR�t�����ׂ��S�Ĉ����ς��`�F�b�N���s���܂��B
   * @param trans �g�����U�N�V����
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   * @return boolean - true�F�S�Ĉ����ρBfalse:�������L��
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean chkAllOrderReserved(
    OADBTransaction trans,
    Number orderHeaderId
  ) throws OAException
  {
    String apiName = "chkAllOrderReserved";
    boolean retFlag = false; // �߂�l
    
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("SELECT COUNT(1)  ");
    sb.append("INTO   :1 ");
    sb.append("FROM   xxwsh_order_lines_all  xola     "); // �󒍖��׃A�h�I��
    sb.append("WHERE  xola.order_header_id   = :2     ");
    sb.append("AND    xola.reserved_quantity IS NULL  ");
    sb.append("AND    xola.delete_flag       = 'N'    ");
    sb.append("AND    ROWNUM = 1;  ");
    sb.append("END; ");
     
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

     try
    {
      //�o�C���h�ϐ��ɒl���Z�b�g
      cstmt.registerOutParameter(1,Types.INTEGER);
      cstmt.setInt(2,XxcmnUtility.intValue(orderHeaderId));

      // PL/SQL���s
      cstmt.execute();

      // �p�����[�^�̎擾
      int cnt = cstmt.getInt(1);
      if(cnt == 0)
      {
        retFlag = true; 
      } 

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // chkAllOrderReserved

  /*****************************************************************************
   * ���v���ʁE���v�e�ς��Z�o���܂��B
   * @param itemNo   - �i�ڃR�[�h
   * @param quantity - ����
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
      String retCode   = cstmt.getString(3);  // ���^�[���R�[�h
      String errMsg    = cstmt.getString(4);  // �G���[���b�Z�[�W
      String systemMsg = cstmt.getString(5);  // �V�X�e�����b�Z�[�W
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
      retHashMap.put("sumWeight",       sumWeight);
      retHashMap.put("sumCapacity",     sumCapacity);
      retHashMap.put("sumPalletWeight", sumPalletWeight);

      // �G���[�̏ꍇ
      if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {
        // ���O�o��
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              errMsg + systemMsg,
                              6);
      }
      return retHashMap; 
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);

      }
    }
  } // calcTotalValue

  /*****************************************************************************
   * �󒍖��ׂ̓���/�K�p���X�V���܂��B
   * @param trans �g�����U�N�V����
   * @param params �p�����[�^
   * @throws OAException OA��O
   ****************************************************************************/
  public static void updateItemAmount(
    OADBTransaction trans,
    HashMap params
    ) throws OAException
  {
    String apiName = "updateItemAmount";

    String itemAmount  = (String)params.get("ItemAmount");
    String description = (String)params.get("Description");
    Number lineId      = (Number)params.get("LineId");
    
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" BEGIN "                                                         );
    sb.append("   UPDATE po_lines_all pla "                                     );
    sb.append("   SET pla.attribute4        = :1 "                              ); // �݌ɓ���
    sb.append("      ,pla.attribute15       = :2 "                              ); // �E�v
    sb.append("      ,pla.last_updated_by   = FND_GLOBAL.USER_ID "              ); // �ŏI�X�V��
    sb.append("      ,pla.last_update_date  = SYSDATE "                         ); // �ŏI�X�V��
    sb.append("      ,pla.last_update_login = FND_GLOBAL.LOGIN_ID "             ); // �ŏI�X�V���O�C��
    sb.append("   WHERE pla.po_line_id = :3; "                                  );
    sb.append(" END; "                                                          );
    
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, itemAmount);    // �݌ɓ���
      cstmt.setString(2, description);   // �E�v
      cstmt.setInt(3,    XxcmnUtility.intValue(lineId)); // ��������ID
      
      //PL/SQL���s
      cstmt.execute();
    
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }

  } // updateItemAmount
  /*****************************************************************************
   * �󒍖��׃A�h�I���̊e�퐔�ʁA�d�ʁA�e�ς��T�}���[���ĕԂ��܂��B
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   * @return HashMap  - �߂�l�Q
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap getSummaryDataOrderLine(
    OADBTransaction trans,
    Number orderHeaderId
  ) throws  OAException
  {
    String apiName = "getSummaryDataOrderLine";

    HashMap retHashMap = new HashMap(); // �߂�l

    // PL/SQL�̍쐬���s���܂��B
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  SELECT TO_CHAR(SUM(NVL(xola.quantity,0))) quantity"); // ����
    sb.append("        ,TO_CHAR(SUM(NVL(xola.shipped_quantity,0))) shipped_quantity"); // �o�׎��ѐ���
    sb.append("        ,TO_CHAR(SUM(NVL(xola.ship_to_quantity,0))) ship_to_quantity"); // ���Ɏ��ѐ���
    sb.append("        ,TO_CHAR(SUM(NVL(xola.based_request_quantity,0))) based_request_quantity"); // ���_�˗�����
    sb.append("        ,TO_CHAR(SUM(NVL(xola.weight,0))) weight"); // �d��
    sb.append("        ,TO_CHAR(SUM(NVL(xola.capacity,0))) capacity"); // �e��
    sb.append("        ,TO_CHAR(SUM(NVL(xola.pallet_quantity,0))) pallet_quantity"); // �p���b�g��
    sb.append("        ,TO_CHAR(SUM(NVL(xola.layer_quantity,0))) layer_quantity"); // �i��
    sb.append("        ,TO_CHAR(SUM(NVL(xola.case_quantity,0))) case_quantity");  // �P�[�X��
    sb.append("        ,TO_CHAR(SUM(NVL(xola.pallet_qty,0))) pallet_qty"); // �p���b�g����
    sb.append("        ,TO_CHAR(SUM(NVL(xola.pallet_weight,0))) pallet_weight"); // �p���b�g�d��
    sb.append("        ,TO_CHAR(SUM(NVL(xola.reserved_quantity,0))) reserved_quantity"); // ������
    sb.append("  INTO   :1 ");
    sb.append("        ,:2 ");
    sb.append("        ,:3 ");
    sb.append("        ,:4 ");
    sb.append("        ,:5 ");
    sb.append("        ,:6 ");
    sb.append("        ,:7 ");
    sb.append("        ,:8 ");
    sb.append("        ,:9 ");
    sb.append("        ,:10 ");
    sb.append("        ,:11 ");
    sb.append("        ,:12 ");
    sb.append("  FROM   xxwsh_order_lines_all xola ");
    sb.append("  WHERE  xola.order_header_id = :13 ");
    sb.append("  AND xola.delete_flag = 'N' ");                     // �폜�t���O(���폜)
    sb.append("  GROUP BY xola.request_no; ");
    sb.append("END; ");

    // PL/SQL�̐ݒ���s���܂��B
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try 
    {
      int i = 1;

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // ����
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // �o�׎��ѐ���
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // ���Ɏ��ѐ���
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // ���_�˗�����
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // �d��
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // �e��
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // �p���b�g��
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // �i��
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // �P�[�X��
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // �p���b�g����
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // �p���b�g�d��
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // ������
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));

      // PL/SQL���s
      cstmt.execute();
      // ���s���ʊi�[
      i = 1;
      String sumQuantity = cstmt.getString(i++);             // ����
      String sumShippedQuantity = cstmt.getString(i++);      // �o�׎��ѐ���
      String sumShipToQuantity = cstmt.getString(i++);       // ���Ɏ��ѐ���
      String sumBasedRequestQuantity = cstmt.getString(i++); // ���_�˗�����
      String sumWeight = cstmt.getString(i++);               // �d��
      String sumCapacity = cstmt.getString(i++);             // �e��
      String sumPalletQuantity = cstmt.getString(i++);       // �p���b�g��
      String sumLayerQuantity = cstmt.getString(i++);        // �i��
      String sumCaseQuantity = cstmt.getString(i++);         // �P�[�X��
      String sumPalletQty = cstmt.getString(i++);            // �p���b�g����
      String sumPalletWeight = cstmt.getString(i++);         // �p���b�g�d��
      String sumReservedQuantity = cstmt.getString(i++);     // ������

      // �߂�l�ݒ�
      retHashMap.put("sumQuantity",sumQuantity);
      retHashMap.put("sumShippedQuantity",sumShippedQuantity);
      retHashMap.put("sumShipToQuantity",sumShipToQuantity);
      retHashMap.put("sumBasedRequestQuantity",sumBasedRequestQuantity);
      retHashMap.put("sumWeight",sumWeight);
      retHashMap.put("sumCapacity",sumCapacity);
      retHashMap.put("sumPalletQuantity",sumPalletQuantity);
      retHashMap.put("sumLayerQuantity",sumLayerQuantity);
      retHashMap.put("sumCaseQuantity",sumCaseQuantity);
      retHashMap.put("sumPalletQty",sumPalletQty);
      retHashMap.put("sumPalletWeight",sumPalletWeight);
      retHashMap.put("sumReservedQuantity",sumReservedQuantity);

      return retHashMap;
      
    } catch (SQLException s) 
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
        
      }
    }
  } // getSummaryDataOrderLine

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
   * @param checkFlag     - �`�F�b�N���{�t���O true:���{�Afalse:�Z�o�̂�
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
    boolean checkFlag
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
    sb.append("   ,iv_prod_class                 => FND_PROFILE.VALUE('XXCMN_ITEM_DIV_SECURITY') "); // 8.���i�敪
    sb.append("   ,iv_auto_process_type          => null  "); // 9.�����z�ԑΏۋ敪
    sb.append("   ,id_standard_date              => :8  "); // 10.���(�K�p�����)
    sb.append("   ,ov_retcode                    => :9  "); // 11.���^�[���R�[�h
    sb.append("   ,ov_errmsg_code                => :10 "); // 12.�G���[���b�Z�[�W�R�[�h
    sb.append("   ,ov_errmsg                     => :11 "); // 13.�G���[���b�Z�[�W
    sb.append("   ,ov_loading_over_class         => :12 "); // 14.�ύڃI�[�o�[�敪
    sb.append("   ,ov_ship_methods               => :13 "); // 15.�o�ו��@
    sb.append("   ,on_load_efficiency_weight     => ln_load_efficiency_weight "); // 16.�d�ʐύڌ���
    sb.append("   ,on_load_efficiency_capacity   => ln_load_efficiency_capacity "); // 17.�e�ϐύڌ���
    sb.append("   ,ov_mixed_ship_method          => :14 "); // 18.���ڔz���敪
    sb.append("   ); ");
    sb.append("  :15 := TO_CHAR(ln_load_efficiency_weight);   ");
    sb.append("  :16 := TO_CHAR(ln_load_efficiency_capacity); ");
    sb.append("END; ");

    // PL/SQL�̐ݒ���s���܂��B
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      int i = 1;
      cstmt.setString(i++, XxcmnUtility.commaRemoval(sumWeight));    // ���v�d��
      cstmt.setString(i++, XxcmnUtility.commaRemoval(sumCapacity));  // ���v�e��
      cstmt.setString(i++, code1);        // �R�[�h�敪�P
      cstmt.setString(i++, whseCode1);    // ���o�ɏꏊ�R�[�h�P
      cstmt.setString(i++, code2);        // �R�[�h�敪�Q
      cstmt.setString(i++, whseCode2);    // ���o�ɏꏊ�R�[�h�Q
      cstmt.setString(i++, maxShipToCode); // ���v�e��
      cstmt.setDate(i++, XxcmnUtility.dateValue(originalDate)); // ���

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1);         // �X�e�[�^�X�R�[�h
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);      // �G���[���b�Z�[�W
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);      // �V�X�e�����b�Z�[�W
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);

      // PL/SQL���s
      cstmt.execute();

      // ���s���ʊi�[
      String retCode   = cstmt.getString(9);   // ���^�[���R�[�h
      String errMsg    = cstmt.getString(10);  // �G���[���b�Z�[�W
      String systemMsg = cstmt.getString(11);  // �V�X�e�����b�Z�[�W
      String loadingOverClass = cstmt.getString(12);  // �ύڃI�[�o�[�敪
      String shipMethod       = cstmt.getString(13);  // �z���敪
      String mixedShipMethod  = cstmt.getString(14);  // ���ڔz���敪
      String loadEfficiencyWeight    = cstmt.getString(15);  // �d�ʐύڌ���
      String loadEfficiencyCapacity  = cstmt.getString(16);  // �e�ϐύڌ���

      // �߂�l�擾
      retHashMap.put("loadingOverClass",       loadingOverClass);
      retHashMap.put("shipMethod",             shipMethod);
      retHashMap.put("mixedShipMethod",        mixedShipMethod);
      retHashMap.put("loadEfficiencyWeight",   loadEfficiencyWeight);
      retHashMap.put("loadEfficiencyCapacity", loadEfficiencyCapacity);

      // �G���[�̏ꍇ
      if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              errMsg + systemMsg,
                              6);
        // �G���[���b�Z�[�W�o��
        XxcmnUtility.putErrorMessage(XxpoConstants.TOKEN_NAME_CALC_LOAD_ERR);

      // �ύڃI�[�o�[�̏ꍇ
      } else if ("1".equals(loadingOverClass))
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              "�ύڃI�[�o�[�G���[",
                              6);
                
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10120);
      }
      return retHashMap; 
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);

      }
    }
  } // calcLoadEfficiency
  /*****************************************************************************
   * �󒍃w�b�_�A�h�I���̍��v���ʁA�ύڏd�ʍ��v�A�ύڗe�ύ��v���X�V���܂��B
   * @param trans        - �g�����U�N�V����
   * @param orderHeaderId  - �󒍃w�b�_�A�h�I��ID
   * @param sumQuantity - ���v����
   * @param smallQuantity - ������
   * @param labelQuantity - ���x������
   * @param sumWeight - �ύڏd�ʍ��v
   * @param sumCapacity - �ύڗe�ύ��v
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void updateSummaryInfo(
    OADBTransaction trans,
    Number orderHeaderId,
    String sumQuantity,
    Number smallQuantity,
    Number labelQuantity,
    String sumWeight,
    String sumCapacity
    ) throws OAException
  {
    String apiName = "updateSummaryInfo";
  
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_headers_all xoha   ");                 // �󒍃w�b�_�A�h�I��
    sb.append("  SET    xoha.sum_quantity      = TO_NUMBER(:1) ");         // ���v����
    sb.append("        ,xoha.small_quantity    = TO_NUMBER(:2) " );        // ������
    sb.append("        ,xoha.label_quantity    = TO_NUMBER(:3) " );        // ���x������
    sb.append("        ,xoha.sum_weight        = TO_NUMBER(:4) ");         // �ύڏd�ʍ��v
    sb.append("        ,xoha.sum_capacity      = TO_NUMBER(:5) ");         // �ύڗe�ύ��v
    sb.append("        ,xoha.last_updated_by   = FND_GLOBAL.USER_ID ");    // �ŏI�X�V��
    sb.append("        ,xoha.last_update_date  = SYSDATE ");               // �ŏI�X�V��
    sb.append("        ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID ");   // �ŏI�X�V���O�C��
    sb.append("  WHERE  xoha.order_header_id   = :6;  ");                  // �������׃A�h�I��ID
    sb.append("END; ");
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, XxcmnUtility.commaRemoval(sumQuantity)); // ���v����
      if (XxcmnUtility.isBlankOrNull(smallQuantity)) 
      {
        cstmt.setNull(2, Types.INTEGER);      // ������
      } else 
      {
        cstmt.setInt(2, XxcmnUtility.intValue(smallQuantity));      // ������
      }
      if (XxcmnUtility.isBlankOrNull(labelQuantity)) 
      {
        cstmt.setNull(3, Types.INTEGER);
      } else 
      {
        cstmt.setInt(3, XxcmnUtility.intValue(labelQuantity));      // ���x������
      }
      cstmt.setString(4, XxcmnUtility.commaRemoval(sumWeight));   // �ύڏd�ʍ��v
      cstmt.setString(5, XxcmnUtility.commaRemoval(sumCapacity)); // �ύڗe�ύ��v
      cstmt.setInt(6,  XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID
      //PL/SQL���s
      cstmt.execute();
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateSummaryInfo

  /*****************************************************************************
   * �o�Ɏ��т̑��݃`�F�b�N���s���܂��B
   * @param trans �g�����U�N�V����
   * @param headerNumber �����ԍ�
   * @return String XxcmnConstants.STRING_N�F�f�[�^����
   *                 XxcmnConstants.STRING_Y�F�f�[�^�L��
   * @throws OAException OA��O
   ****************************************************************************/
  public static String chkDeliveryResults(
    OADBTransaction trans,
    String headerNumber
  ) throws OAException
  {
    String apiName  = "chkDeliveryResults"; // API��

    int rcvAndRtnTxnsCount = 0;  
    String checkFlag = XxcmnConstants.STRING_N; // �߂�l�p

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" BEGIN "                                        );
    sb.append("   SELECT COUNT(1) "                            );
    sb.append("   INTO   :1 "                                  );
    sb.append("   FROM po_headers_all pha "                    );   // �����w�b�_
    sb.append("       ,po_lines_all   pla "                    );   // ��������
    sb.append("   WHERE pha.po_header_id  = pla.po_header_id " );
    sb.append("     AND pla.attribute6 IS NOT NULL "           );   // �d����o�א���
    sb.append("     AND pha.segment1      = :2; "              );
    sb.append(" END; "                                         );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.INTEGER); // �J�E���g

      //�o�C���h�ϐ��ɒl���Z�b�g
      cstmt.setString(2, headerNumber);             // �����ԍ�

      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      rcvAndRtnTxnsCount = cstmt.getInt(1);

      if (rcvAndRtnTxnsCount > 0)
      {
        checkFlag = XxcmnConstants.STRING_Y;
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {

      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return checkFlag;
  } // chkDeliveryResults

  /*****************************************************************************
   * �������׋��z�m��t���O���擾���܂��B
   * @param trans �g�����U�N�V����
   * @param headerNumber �����ԍ�
   * @return String XxcmnConstants.STRING_N�F�f�[�^����
   *                 XxcmnConstants.STRING_Y�F�f�[�^�L��
   * @throws OAException OA��O
   ****************************************************************************/
  public static String getMoneyDecisionFlag(
    OADBTransaction trans,
    String headerNumber
  ) throws OAException
  {
    String apiName  = "getMoneyDecisionFlag"; // API��

    int moneyDecisionFlagCount = 0;  
    String checkFlag = XxcmnConstants.STRING_N; // �߂�l�p

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" BEGIN "                                        );
    sb.append("   SELECT COUNT(1) "                            );
    sb.append("   INTO   :1 "                                  );
    sb.append("   FROM po_headers_all pha "                    );   // �����w�b�_
    sb.append("       ,po_lines_all   pla "                    );   // ��������
    sb.append("   WHERE pha.po_header_id  = pla.po_header_id " );
    sb.append("     AND pla.attribute14   = 'Y' "              );   // ����.���z�m��t���O
    sb.append("     AND pha.segment1      = :2; "              );
    sb.append(" END; "                                         );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.INTEGER); // ��������.���z�m��σJ�E���g

      //�o�C���h�ϐ��ɒl���Z�b�g
      cstmt.setString(2, headerNumber);             // �����ԍ�

      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      moneyDecisionFlagCount = cstmt.getInt(1);

      if (moneyDecisionFlagCount > 0)
      {
        checkFlag = XxcmnConstants.STRING_Y;
      }
      
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {

      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    
    return checkFlag;
    
  } // getMoneyDecisionFlag

  /*****************************************************************************
   * ���[�U�[�����擾���܂��B(�x���p)
   * @param trans    - �g�����U�N�V����
   * @return HashMap - ���[�U���
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap getProvUserData(
    OADBTransaction trans
    ) throws OAException
  {
    String apiName  = "getProvUserData"; // API��

    HashMap retHashMap = new HashMap();  // �߂�l�p

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  SELECT papf.attribute3        people_code   "); // �]�ƈ��敪
    sb.append("        ,papf.attribute4        vendor_code   "); // �d����R�[�h
    sb.append("        ,xvv.vendor_id          vendor_id     "); // �d����ID
    sb.append("        ,xvv.vendor_short_name  vendor_name   "); // �d���於
    sb.append("        ,xcav.party_id          customer_id   "); // �ڋqID(�p�[�e�B�[ID)
    sb.append("        ,xcav.party_number      customer_code "); // �ڋq�R�[�h(�g�D�ԍ�)
    sb.append("        ,xvv.spare2             price_list    "); // ����承�i�\ID
    sb.append("  INTO   :1 ");
    sb.append("        ,:2 ");
    sb.append("        ,:3 ");
    sb.append("        ,:4 ");
    sb.append("        ,:5 ");
    sb.append("        ,:6 ");
    sb.append("        ,:7 ");
    sb.append("  FROM   fnd_user              fu   ");  // ���[�U�[�}�X�^
    sb.append("        ,per_all_people_f      papf ");  // �]�ƈ��}�X�^
    sb.append("        ,xxcmn_vendors_v       xvv  ");  // �d������V
    sb.append("        ,xxcmn_cust_accounts_v xcav ");  // �ڋq���VIEW
    sb.append("  WHERE  fu.employee_id             = papf.person_id      ");  // �]�ƈ�ID
    sb.append("  AND    papf.attribute4            = xvv.segment1        ");  // �d����R�[�h
    sb.append("  AND    xvv.customer_num           = xcav.account_number ");  // �g�D�ԍ�
    sb.append("  AND    fu.user_id                 = FND_GLOBAL.USER_ID  ");  // ���[�U�[ID
    sb.append("  AND    papf.effective_start_date <= TRUNC(SYSDATE)      ");
    sb.append("  AND    papf.effective_end_date   >= TRUNC(SYSDATE)      ");
    sb.append("  AND    fu.start_date             <= TRUNC(SYSDATE)      ");
    sb.append("  AND    ((fu.end_date IS NULL) OR (fu.end_date >= TRUNC(SYSDATE)));");
    sb.append("EXCEPTION ");
    sb.append("  WHEN NO_DATA_FOUND THEN ");
    sb.append("    null; ");
    sb.append("END; ");

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      int i = 1;
      cstmt.registerOutParameter(i++, Types.VARCHAR); // �]�ƈ��敪
      cstmt.registerOutParameter(i++, Types.VARCHAR); // �d����R�[�h
      cstmt.registerOutParameter(i++, Types.INTEGER); // �d����ID
      cstmt.registerOutParameter(i++, Types.VARCHAR); // �d���於
      cstmt.registerOutParameter(i++, Types.INTEGER); // �ڋqID
      cstmt.registerOutParameter(i++, Types.VARCHAR); // �ڋq�R�[�h
      cstmt.registerOutParameter(i++, Types.VARCHAR); // ����承�i�\ID
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      retHashMap.put("PeopleCode",   cstmt.getObject(1)); // �]�ƈ��敪
      retHashMap.put("VendorCode",   cstmt.getObject(2)); // �d����R�[�h
      retHashMap.put("VendorId",     cstmt.getObject(3)); // �d����ID
      retHashMap.put("VendorName",   cstmt.getObject(4)); // �d���於
      retHashMap.put("CustomerId",   cstmt.getObject(5)); // �ڋqID
      retHashMap.put("CustomerCode", cstmt.getObject(6)); // �ڋq�R�[�h
      retHashMap.put("PriceList",    cstmt.getObject(7)); // ����承�i�\ID

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // getProvUserData

// 2008-06-18 H.Itou ADD START
  /*****************************************************************************
   * ���󍇌v���擾���܂��B
   * @param trans            - �g�����U�N�V����
   * @param params           - �p�����[�^
   * @return String          - ���󍇌v
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String getTotalAmount(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName    = "getTotalAmount"; // API��
    String totalAmount = "";    // ���󍇌v

    // �p�����[�^�l�擾
    String unitPriceCalcCode = (String)params.get("UnitPriceCalcCode");// �d���P�����o���^�C�v
    Number itemId            = (Number)params.get("ItemId");           // �i��ID
    Number vendorId          = (Number)params.get("VendorId");         // �����ID
    Number factoryId         = (Number)params.get("FactoryId");        // �H��ID
    Date   manufacturedDate  = (Date)params.get("ManufacturedDate");   // ���Y��
    Date   productedDate     = (Date)params.get("ProductedDate");      // ������

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                                 );
    sb.append("  lt_total_amount  xxpo_price_headers.total_amount%TYPE; ");
    sb.append("BEGIN "                                                   );
    sb.append("  SELECT xph.total_amount    total_amount "               ); // ���󍇌v
    sb.append("  INTO   lt_total_amount "                                );
    sb.append("  FROM   xxpo_price_headers  xph "                        ); // �d����W���P���w�b�_
    sb.append("  WHERE  xph.item_id             = :1 "                   ); // �i��ID
    sb.append("  AND    xph.vendor_id           = :2 "                   ); // �����ID
    sb.append("  AND    xph.factory_id          = :3 "                   ); // �H��ID
    sb.append("  AND    xph.futai_code          = '0' "                  ); // �t�уR�[�h
    sb.append("  AND    xph.price_type          = '1' "                  ); // �}�X�^�敪1:�d��
// 20080702 yoshimoto add Start
    sb.append("  AND    xph.supply_to_code IS NULL "                     ); // �x����R�[�h IS NULL
// 20080702 yoshimoto add End
    sb.append("  AND    (((:4                   = '1') "                 ); // �d���P���������^�C�v��1:�������̏ꍇ�A������������
    sb.append("    AND  (xph.start_date_active <= :5) "                  ); // �K�p�J�n�� <= ������
    sb.append("    AND  (xph.end_date_active   >= :5)) "                 ); // �K�p�I���� >= ������
    sb.append("  OR     ((:4                    = '2') "                 ); // �d���P���������^�C�v��2:�[�����̏ꍇ�A���������Y��
    sb.append("    AND  (xph.start_date_active <= :6) "                  ); // �K�p�J�n�� <= ���Y��
    sb.append("    AND  (xph.end_date_active   >= :6))); "               ); // �K�p�I���� >= ���Y��
    sb.append("  :7 := TO_CHAR(lt_total_amount); "                       );
    sb.append("EXCEPTION "                                               );
    sb.append("  WHEN OTHERS THEN "                                      ); // �f�[�^���Ȃ��ꍇ��0
    sb.append("    :7 := '0'; "                                          );
    sb.append("END; "                                                    );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1, XxcmnUtility.intValue(itemId));            // �i��ID
      cstmt.setInt(2, XxcmnUtility.intValue(vendorId));          // �����ID
      cstmt.setInt(3, XxcmnUtility.intValue(factoryId));         // �H��ID
      cstmt.setString(4, unitPriceCalcCode);                     // �d���P�������^�C�v
      cstmt.setDate(5, XxcmnUtility.dateValue(productedDate));   // ������
      cstmt.setDate(6, XxcmnUtility.dateValue(manufacturedDate));// ���Y��
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(7, Types.VARCHAR); // ���󍇌v
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      return cstmt.getString(7);

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getTotalAmount
// 2008-06-18 H.Itou ADD END

// 2008-10-22 T.Yoshimoto ADD START
  /***************************************************************************
   * �󒍃w�b�_.�L�����z�m��ς݂��m�F���܂�
   * @param trans - �g�����U�N�V����
   * @param requestNo - �˗�No
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public static boolean chkAmountFixClass(
    OADBTransaction trans, 
    String requestNo
    ) throws OAException
  {
    String apiName = "chkAmountFixClass";
    String plSqlRet;

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                               );
    sb.append("   SELECT xoha.amount_fix_class "                     ); // �L�����z�m��敪(1:�m��,2:���m��)
    sb.append("   INTO   :1 "                                        ); 
    sb.append("   FROM   po_headers_all pha "                        ); // �����w�b�_
    sb.append("         ,xxwsh_order_headers_all xoha "              ); // �󒍃w�b�_�A�h�I��
    sb.append("   WHERE  pha.attribute9 = xoha.request_no "          ); // �˗�No
    sb.append("   AND    xoha.latest_external_flag = 'Y' "           ); // �ŐV�t���O
    sb.append("   AND    xoha.request_no = :2; "                     ); // �˗�No
    sb.append("END; "                                                );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(2, requestNo);  // �˗�No

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR); // ���b�g�J�E���g��
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      plSqlRet = cstmt.getString(1);

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        // �������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        XxpoUtility.rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    
    // PL/SQL�߂�l��0�̏ꍇ false
    if ("1".equals(plSqlRet))
    {
      return true;
    
    // PL/SQL�߂�l��0�ȊO�̏ꍇ true
    } else
    {
      return false;
    }
  } // chkAmountFixClass 
// 2008-10-22 T.Yoshimoto ADD END

// 2009-01-16 v1.21 T.Yoshimoto Add Start
  /*****************************************************************************
   * �R���J�����g�F�v���Z�b�g�Ŏ����������𔭍s���܂��B
   * @param trans �g�����U�N�V����
   * @param groupId �O���[�vID
   * @return HashMap ��������/�v��ID
   * @throws OAException OA��O
   ****************************************************************************/
  public static HashMap doRVCTP2(
    OADBTransaction trans,
    String[] groupId
  ) throws OAException
  {
    String apiName      = "doRVCTP2";

    // OUT�p�����[�^�p
    HashMap retHash = new HashMap();
    retHash.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE); // �߂�l

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    
    sb.append("DECLARE "                                                        );
    // ���[�J���ϐ�
    sb.append("  ln_req_id                NUMBER; "                             );
    sb.append("  lv_rcv_stage    CONSTANT VARCHAR2(50) := 'STAGE10'; "          );
    sb.append("  lv_rcv_stage2   CONSTANT VARCHAR2(50) := 'STAGE20'; "          );
    sb.append("  lv_errbuf                VARCHAR2(5000); "                     );  // �G���[�E���b�Z�[�W
    sb.append("  lv_retcode               VARCHAR2(1); "                        );  // ���^�[���E�R�[�h
    sb.append("  lv_errmsg                VARCHAR2(5000); "                     );  // ���[�U�[�E�G���[�E���b�Z�[�W
    sb.append("  lb_ret                   BOOLEAN; "                            );
    // ���������ʗ�O
    sb.append("  process_expt             EXCEPTION; "                          );
    sb.append("BEGIN "                                                          );
    // �v���Z�b�g�̏���
    sb.append("  lb_ret := FND_SUBMIT.SET_REQUEST_SET('XXPO', 'XXPO320001Q'); " );

    sb.append("  IF (NOT lb_ret) THEN "                                         );
    sb.append("    RAISE process_expt; "                                        );
    sb.append("  END IF; "                                                      );

    // �����������N��(�v���Z�b�g�p����1)
    sb.append("  lb_ret := FND_SUBMIT.SUBMIT_PROGRAM('PO', "                    );
    sb.append("                                      'RVCTP', "                 );
    sb.append("                                      'STAGE10', "               );
    sb.append("                                      'BATCH', "                 );
    sb.append("                                      :1); "                     );

    sb.append("  IF (NOT lb_ret) THEN "                                         );
    sb.append("    RAISE process_expt; "                                        );
    sb.append("  END IF; "                                                      );

    // �����������N��(�v���Z�b�g�p����2)
    sb.append("  lb_ret := FND_SUBMIT.SUBMIT_PROGRAM('PO', "                    );
    sb.append("                                      'RVCTP', "                 );
    sb.append("                                      'STAGE20', "               );
    sb.append("                                      'BATCH', "                 );
    sb.append("                                      :2); "                     );

    sb.append("  IF (NOT lb_ret) THEN "                                         );
    sb.append("    RAISE process_expt; "                                        );
    sb.append("  END IF; "                                                      );

    // �v���Z�b�g�̔��s
    sb.append("  ln_req_id := FND_SUBMIT.SUBMIT_SET(null,FALSE); "              );

    // �������s
    sb.append("  IF (ln_req_id > 0) THEN "                                      );
    sb.append("    :3 := '1'; "                                                 );
    sb.append("  ELSE "                                                         );
    sb.append("    RAISE process_expt; "                                        );
    sb.append("  END IF; "                                                      );

    sb.append("EXCEPTION "                                                      );
    sb.append("  WHEN OTHERS THEN "                                             );
    sb.append("    :3 := '0'; "                                                 );
    sb.append("    ROLLBACK; "                                                  );
    sb.append("END; "                                                           );

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {
    
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, groupId[0]);                    // �O���[�vID
      cstmt.setString(2, groupId[1]);                    // �O���[�vID

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(3, Types.VARCHAR);   // ���^�[���R�[�h

      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      String retFlag = cstmt.getString(3);    // ���^�[���R�[�h

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // ���^�[���R�[�h������Z�b�g
        retHash.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);
        
      // ����I���łȂ��ꍇ�A�G���[  
      } else
      {
        //�g�[�N������
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                   XxpoConstants.TOKEN_NAME_RVCTP) };
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                               XxpoConstants.XXPO10055, 
                               tokens);
      }
      
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }

    return retHash;
  } // doRVCTP2.
// 2009-01-16 v1.21 T.Yoshimoto Add End

// 2009-01-20 v1.22 T.Yoshimoto Add Start
  /***************************************************************************
   * �󒍃w�b�_�A�h�I��.���Ɏ��ѓ����m�F���܂�
   * @param trans - �g�����U�N�V����
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public static Date chkArrivalDate(
    OADBTransaction trans, 
    Number orderHeaderId
    ) throws OAException
  {
    String apiName = "chkArrivalDate";
    Date plSqlRet;

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                               );
    sb.append("   SELECT xoha.arrival_date "                         ); // ���Ɏ��ѓ�
    sb.append("   INTO   :1 "                                        ); 
    sb.append("   FROM   xxwsh_order_headers_all xoha "              ); // �󒍃w�b�_�A�h�I��
    sb.append("   WHERE  xoha.latest_external_flag = 'Y' "           ); // �ŐV�t���O
    sb.append("   AND    xoha.order_header_id = :2; "                ); // �󒍃w�b�_�A�h�I��ID
    sb.append("END; "                                                );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(orderHeaderId));  // �󒍃w�b�_�A�h�I��ID

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.DATE); // ���b�g�J�E���g��
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      if (XxcmnUtility.isBlankOrNull(cstmt.getDate(1))) 
      {
        return null;
      }
      
      plSqlRet = new Date(cstmt.getDate(1));

      return plSqlRet;

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        // �������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        XxpoUtility.rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // chkArrivalDate 

  /*****************************************************************************
   * �󒍃w�b�_�A�h�I���̓��Ɏ��ѓ����X�V���܂��B
   * @param trans         - �g�����U�N�V����
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   * @param arrivalDate - ���Ɏ��ѓ�
   * @throws OAException  - OA��O
   ****************************************************************************/
  public static void updArrivalDate(
    OADBTransaction trans,
    Number orderHeaderId,
    Date arrivalDate
    ) throws OAException
  {
    String apiName = "updArrivalDate";
  
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                );
    sb.append("  UPDATE xxwsh_order_headers_all xoha "                );  // �󒍃w�b�_�A�h�I��
    sb.append("  SET    xoha.arrival_date = :1 "                      );  // ���Ɏ��ѓ�
    sb.append("        ,xoha.last_updated_by   = FND_GLOBAL.USER_ID  ");  // �ŏI�X�V��
    sb.append("        ,xoha.last_update_date  = SYSDATE             ");  // �ŏI�X�V��
    sb.append("        ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID ");  // �ŏI�X�V���O�C��
    sb.append("  WHERE  xoha.order_header_id   = :2; "                );  // �󒍃w�b�_�A�h�I��ID
    sb.append("END; ");
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setDate(1, XxcmnUtility.dateValue(arrivalDate));  // ���Ɏ��ѓ�
      cstmt.setInt(2,  XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID

      //PL/SQL���s
      cstmt.execute();
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updArrivalDate 
// 2009-01-20 v1.22 T.Yoshimoto Add End
// 2011-06-01 v1.28 K.Kubo Add Start
  /*****************************************************************************
   * �d�����я����`�F�b�N���܂��B
   * @param OADBTransaction  - �g�����U�N�V����
   * @param Number           - �����w�b�_ID
   * @return String          - �`�F�b�N����
   * @throws OAException     - OA��O
   ****************************************************************************/
  public static String chkStockResult(
    OADBTransaction trans,   // �g�����U�N�V����
    Number poHeaderId        // �����w�b�_ID
  ) throws OAException
  {
    String apiName  = "chkStockResult"; // API��
    String retCode;   // ���^�[���R�[�h
    
    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                       );
    sb.append("  :1 := xxpo_common3_pkg.check_result( "      ); // (OUT)�`�F�b�N����
    sb.append("          in_po_header_id  => TO_NUMBER(:2) " ); // (IN) �����w�b�_ID
    sb.append("        );  "                                 );
    sb.append("END; "                                        );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(poHeaderId)); // �����w�b�_ID
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR);        // �߂�l
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      retCode  = cstmt.getString(1); // ���^�[���R�[�h
      
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //�g�[�N������
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                 XxpoConstants.TOKEN_NAME_CHK_STOCK_RESULT_MANE) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                             XxcmnConstants.XXCMN05002, 
                             tokens);
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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retCode;
  } // chkStockResult

  /*****************************************************************************
   * �d�����я���o�^���܂��B
   * @param OADBTransaction  - �g�����U�N�V����
   * @param Number           - �����w�b�_ID
   * @param String           - �����ԍ�
   * @throws OAException     - OA��O
   ****************************************************************************/
  public static String insStockResult(
    OADBTransaction trans    // �g�����U�N�V����
   ,Number headerId          // �����w�b�_ID
   ,String headerNumber      // �����ԍ�
  ) throws OAException
  {
    String apiName  = "insStockResult"; // API��
    String retCode;   // ���^�[���R�[�h
    
    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                 );
    sb.append("  :1 := xxpo_common3_pkg.insert_result( "               ); // (OUT)�`�F�b�N����
    sb.append("          in_po_header_id      => TO_NUMBER(:2) "       ); // (IN) �����w�b�_ID
    sb.append("         ,iv_po_header_number  => TO_CHAR(:3) "         ); // (IN) �����ԍ�
    sb.append("         ,in_created_by        => FND_GLOBAL.USER_ID "  ); // (IN) �쐬��
    sb.append("         ,id_creation_date     => SYSDATE "             ); // (IN) �쐬��
    sb.append("         ,in_last_updated_by   => FND_GLOBAL.USER_ID "  ); // (IN) �ŏI�X�V��
    sb.append("         ,id_last_update_date  => SYSDATE "             ); // (IN) �ŏI�X�V��
    sb.append("         ,in_last_update_login => FND_GLOBAL.LOGIN_ID " ); // (IN) �ŏI�X�V���O�C��
    sb.append("        );  "                                     );
    sb.append("END; "                                            );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(headerId));             // �����w�b�_ID
      cstmt.setString(3, headerNumber);                             // �����ԍ�
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR);        // �߂�l
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      retCode  = cstmt.getString(1); // ���^�[���R�[�h
      
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //�g�[�N������
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                 XxpoConstants.TOKEN_NAME_STOCK_RESULT_MANEGEMENT) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                             XxcmnConstants.XXCMN05002, 
                             tokens);
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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retCode;
  } // insStockResult

// 2011-06-01 v1.28 K.Kubo Add End
// v1.34 E_�{�ғ�_14267 Add Start
  /*****************************************************************************
   * �ғ����t�Z�o�ɔz��LT���g�p���邩���肵�܂��B
   * @param  trans       - �g�����U�N�V����
   * @param  OrderTypeId - �����敪(�󒍃^�C�vID�j
   * @return boolean     - �o�ɓ��Z�o�Ƀ��[�h�^�C�����g�p����ꍇ   true
   *                       �o�ɓ��Z�o�Ƀ��[�h�^�C�����g�p���Ȃ��ꍇ false
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean chkOprtnDayUseReadTime(
    OADBTransaction trans,
    Number OrderTypeId      // �����敪(�󒍃^�C�vID�j
  ) throws OAException
  {
    String apiName = "chkOprtnDayUseReadTime"; // API��
    String plSqlRet;                           // PL/SQL�߂�l
    
    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                              );
    sb.append("  SELECT flvv.attribute1 attribute1"                                 );
    sb.append("  INTO   :1 "                                                        );
    sb.append("  FROM   xxwsh_oe_transaction_types_v xottv "                        );  //�󒍃^�C�v���VIEW
    sb.append("        ,fnd_lookup_values_vl         flvv "                         );  //�Q�ƃ^�C�v XXPO�F�����敪�i�����j
    sb.append("  WHERE  xottv.transaction_type_id   = :2 "                          );
    sb.append("  AND    xottv.transaction_type_name = flvv.meaning "                );
    sb.append("  AND    flvv.lookup_type            = 'XXPO_INTERNAL_TRANS_TYPE'; " );
    sb.append("END; "                                                               );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(OrderTypeId)); // �����敪(�󒍃^�C�vID�j
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR); // �߂�l
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      plSqlRet = cstmt.getString(1);

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN,
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
      }
    }
    // PL/SQL�߂�l��Y�F�o�ɓ��Z�o�Ƀ��[�h�^�C�����g�p����ꍇtrue
    if ("Y".equals(plSqlRet))
    {
      return true;
    
    // PL/SQL�߂�l��N�F�o�ɓ��Z�o�Ƀ��[�h�^�C�����g�p���Ȃ��ꍇfalse
    } else
    {
      return false;
    }    
  } // chkOprtnDayUseReadTime

  /*****************************************************************************
   * �z��LT���擾���܂��B
   * @param  trans       - �g�����U�N�V����
   * @param  params      - �p�����[�^
   * @return int         - �z��LT
   * @throws OAException - OA��O
   ****************************************************************************/
  public static int getLeadTime(
    OADBTransaction trans,
    HashMap         params  //�p�����[�^
  ) throws OAException
  {
    String apiName = "getLeadTime"; // API��
    int    plSqlRet;                // PL/SQL�߂�l

    // �p�����[�^�l�擾
    String shipWhseCode = (String)params.get("ShipWhseCode"); // �o�ɑq��
    String shipToCode   = (String)params.get("ShipToCode");   // �z����
    Number orderTypeId  = (Number)params.get("OrderTypeId");  // �����敪(�󒍃^�C�vID)
    Date   arrivalDate  = (Date)params.get("ArrivalDate");    // ���ɓ�

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                  );
    sb.append("  lv_retcode                    VARCHAR2(1); "                                        );
    sb.append("  lv_errmsg_code                VARCHAR2(5000); "                                     );
    sb.append("  lv_errmsg                     VARCHAR2(5000); "                                     );
    sb.append("  ln_lead_time                  NUMBER; "                                             );
    sb.append("BEGIN "                                                                               );
// v1.38 Y.Sasaki Modified START
//    sb.append("  xxwsh_common910_pkg_pt.calc_lead_time( "                                            );
    sb.append("  xxwsh_common910_pkg.calc_lead_time( "                                            );
// v1.38 Y.Sasaki Modified END
    sb.append("    iv_code_class1                => '4' "                                            ); // 4(�q��)
    sb.append("   ,iv_entering_despatching_code1 => :1 "                                             ); // �o�ɑq��
    sb.append("   ,iv_code_class2                => '11' "                                           ); // 11(�x����)
    sb.append("   ,iv_entering_despatching_code2 => :2 "                                             ); // �z����
    sb.append("   ,iv_prod_class                 => FND_PROFILE.VALUE('XXCMN_ITEM_DIV_SECURITY') "   ); // ���i�敪
    sb.append("   ,in_transaction_type_id        => :3 "                                             ); // �����敪
    sb.append("   ,id_standard_date              => :4 "                                             ); // ���ɓ�
    sb.append("   ,ov_retcode                    => lv_retcode "                                     ); // ���^�[���R�[�h
    sb.append("   ,ov_errmsg_code                => lv_errmsg_code "                                 ); // �G���[���b�Z�[�W�R�[�h
    sb.append("   ,ov_errmsg                     => lv_errmsg "                                      ); // �G���[���b�Z�[�W
    sb.append("   ,on_lead_time                  => ln_lead_time "                                   ); // ���Y����LT�^����ύXLT
    sb.append("   ,on_delivery_lt                => :5 ); "                                          ); // �z��LT
    sb.append("  IF (:5 IS NULL ) THEN "                                                             );
    sb.append("    :5 := -99; "                                                                      ); // �擾�ł��Ȃ��ꍇ�A�ݒ�s�̒l��Ԃ�
    sb.append("  END IF; "                                                                           );
    sb.append("END; "                                                                                );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, shipWhseCode);                       // �o�ɑq��
      cstmt.setString(2, shipToCode);                         // �z����
      cstmt.setInt(3, XxcmnUtility.intValue(orderTypeId));    // �����敪(�󒍃^�C�vID)
      cstmt.setDate(4, XxcmnUtility.dateValue(arrivalDate));  // ���Ɏ��ѓ�

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(5, Types.INTEGER); // �߂�l(�z��LT)

      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      plSqlRet = cstmt.getInt(5);

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN,
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
      }
    }

    // �z��LT��Ԃ�
    return plSqlRet;

  } // getLeadTime

// v1.34 E_�{�ғ�_14267 Add End
// S.Yamashita Ver.1.35 Add Start
  /*****************************************************************************
   * �X�V�Ώ�(�������)���݃`�F�b�N
   * @param trans            - �g�����U�N�V����
   * @param createdPoNum     - �����ԍ�(�쐬��)
   * @return String          - 1 �Ώۂ���
   *                           2 �ΏۂȂ�
   *                           3 �������쐬�G���[
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String getPoTarget(
    OADBTransaction trans,
    String createdPoNum
  ) throws OAException
  {
    String apiName = "getPoTarget"; // API��
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // �߂�l
    
    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append(" DECLARE                                                         ");
    sb.append("   lt_po_status     po_headers_all.attribute1%TYPE;              "); // �����X�e�[�^�X
    sb.append("   lt_cancel_flag   po_lines_all.cancel_flag%TYPE;               "); // ����t���O
    sb.append(" BEGIN                                                           ");
                  // �������݃`�F�b�N
    sb.append("   SELECT pha.attribute1  AS po_status                           ");
    sb.append("         ,pla.cancel_flag AS cancel_flag                         ");
    sb.append("   INTO   lt_po_status                                           ");
    sb.append("         ,lt_cancel_flag                                         ");
    sb.append("   FROM   po_headers_all pha                                     "); // �����w�b�_
    sb.append("         ,po_lines_all   pla                                     "); // ��������
    sb.append("   WHERE  pha.segment1     = :1                                  "); // 1:�����ԍ�(�쐬��)
    sb.append("     AND  pha.po_header_id = pla.po_header_id                    ");
    sb.append("     AND  pla.line_num     = 1                                   ");
    sb.append("   ;                                                             ");
                  // �X�e�[�^�X�`�F�b�N
    sb.append("   IF ( (lt_po_status = '20') AND (lt_cancel_flag = 'N' ) ) THEN "); // �����쐬�ς��A���ׂ��������Ă��Ȃ��ꍇ
    sb.append("     :2 := '1';                                                  ");
    sb.append("   ELSE                                                          ");
    sb.append("     :2 := '2';                                                  ");
    sb.append("   END IF;                                                       ");
    sb.append(" EXCEPTION                                                       ");
    sb.append("   WHEN NO_DATA_FOUND THEN                                       "); // ���������݂��Ȃ��ꍇ�̓G���[
    sb.append("     :2 := '3';                                                  ");
    sb.append(" END;                                                            ");
    
    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
    
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, createdPoNum); // �����ԍ�(�쐬��)
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(2, Types.VARCHAR); // ���^�[���R�[�h
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      retFlag = cstmt.getString(2); // ���^�[���R�[�h
      
      // �������݃G���[�̏ꍇ
      if ("3".equals(retFlag))
      {
        // �߂�l�ɃG���[��ݒ�
        retFlag = XxcmnConstants.RETURN_NOT_EXE;
        // ���[���o�b�N
        rollBack(trans);
        // �������쐬�G���[
        throw new OAException(XxcmnConstants.APPL_XXPO,
                               XxpoConstants.XXPO40043);
      }
      
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN,
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // getPoTarget

  /*****************************************************************************
   * ��������(�����l)���擾���܂��B
   * @param trans            - �g�����U�N�V����
   * @param txnsId           - ����ID
   * @return String          - ��������(�����l)
   * @throws OAException - OA��O
   ****************************************************************************/
// V1.36 Added START
//  public static String getCorrectedQuantityDef(
  public static HashMap getCorrectedQuantityDef(
// V1.36 Added END
    OADBTransaction trans,
    Number txnsId
  ) throws OAException
  {
    String apiName = "getCorrectedQuantityDef"; // API��
// V1.36 Mod START
//    String returnQty;   // �߂�l
    HashMap retHash = new HashMap();  // �߂�l
// V1.36 Mod END
    
    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append(" BEGIN                                   ");
    sb.append("   SELECT REPLACE(TO_CHAR(NVL(xvst.corrected_quantity, xvst.producted_quantity),'999999990.000'),' ') AS corrected_qty " ); // ��������(�����l)
// V1.36 Add START
    sb.append("         ,REPLACE(TO_CHAR(xvst.corrected_quantity,'999999990.000'),' ') AS corrected_qty_org "                           ); // ��������(�I���W�i�������l)
// V1.36 Add END
    sb.append("   INTO   :1                             ");
// V1.36 Add START
    sb.append("         ,:2                             ");
// V1.36 Add END
    sb.append("   FROM   xxpo_vendor_supply_txns xvst   "); // �O���o��������
// V1.36 Mod END
//    sb.append("   WHERE  xvst.txns_id = :2              ");
    sb.append("   WHERE  xvst.txns_id = :3              ");
// V1.36 Mod END
    sb.append("   ;                                     ");
    sb.append(" END;                                    ");
    
    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
    
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
// V1.36 Mod START
//      cstmt.setInt(2, XxcmnUtility.intValue(txnsId)); // ����ID
      cstmt.setInt(3, XxcmnUtility.intValue(txnsId)); // ����ID
// V1.36 Mod END
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR);   // ��������(�����l)
// V1.36 Add START
      cstmt.registerOutParameter(2, Types.VARCHAR);   // ��������(�I���W�i�������l)
// V1.36 Add END
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
// V1.36 Mod START
//      returnQty    = cstmt.getString(1); // ��������(�����l)
      retHash.put("CorrectedQuantityDef", cstmt.getString(1)); // ��������(�����l)
      retHash.put("CorrectedQuantityOrg", cstmt.getString(2)); // ��������(�I���W�i�������l)
// V1.36 Mod END
      
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN,
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
      }
    }
// V1.36 Mod START
//    return returnQty;
    return retHash;
// V1.36 Mod END
  } // getCorrectedQuantityDef

  /*****************************************************************************
   * �o�������ѕύX�����Ƀf�[�^��ǉ����܂��B
   * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @return String - XxcmnConstants.RETURN_SUCCESS:1 ����
   *                  XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String insertTxnsUpdateHistory(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertTxnsUpdateHistory";

    // IN�p�����[�^�擾
    Number txns_id              = (Number)params.get("TxnsId");                 // ����ID
    String CreatedPoNum         = (String)params.get("CreatedPoNum");           // �����ԍ�(�쐬��)
    String programName          = (String)XxpoConstants.SAVE_POINT_XXPO340001J; // �@�\��
    String correctedQuantity    = (String)params.get("CorrectedQuantity");      // ��������
    String correctedQuantityDef = (String)params.get("CorrectedQuantityDef");   // ��������(�����l)
// V1.36 Added START
    String productedQuantity    = (String)params.get("ProductedQuantity");      // �o��������
// V1.36 Added END
    
    // OUT�p�����[�^�p
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // �߂�l
    
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE                                                      ");
    sb.append("  lt_txns_id xxpo_txns_update_history.txns_history_id%TYPE;  ");
    sb.append("BEGIN                                                        ");
                 // �V�[�P���X�擾
    sb.append("  SELECT xxpo_txns_update_history_s1.NEXTVAL AS next_val     ");
    sb.append("  INTO   lt_txns_id                                          ");
    sb.append("  FROM   DUAL;                                               ");
                 // �o�������эX�V����o�^
    sb.append("  INSERT INTO xxpo_txns_update_history xtuh(                 ");
    sb.append("     xtuh.txns_history_id                                    "); // �X�V����ID
    sb.append("    ,xtuh.txns_id                                            "); // 1:����ID
    sb.append("    ,xtuh.po_number                                          "); // 2:�����ԍ�
    sb.append("    ,xtuh.program_name                                       "); // 3:�X�V�@�\��
    sb.append("    ,xtuh.before_qty                                         "); // 4:�X�V�O_����
    sb.append("    ,xtuh.after_qty                                          "); // 5:�X�V��_����
    sb.append("    ,xtuh.before_lot                                         "); // �X�V�O_�ܖ�����
    sb.append("    ,xtuh.after_lot                                          "); // �X�V��_�ܖ�����
    sb.append("    ,xtuh.created_by                                         "); // �쐬��
    sb.append("    ,xtuh.creation_date                                      "); // �쐬��
    sb.append("    ,xtuh.last_updated_by                                    "); // �ŏI�X�V��
    sb.append("    ,xtuh.last_update_date                                   "); // �ŏI�X�V��
    sb.append("    ,xtuh.last_update_login)                                 "); // �ŏI�X�V���O�C��
    sb.append("  VALUES(                                                    ");
    sb.append("     lt_txns_id                                              "); // �X�V����ID
    sb.append("    ,:1                                                      "); // 1:����ID
    sb.append("    ,:2                                                      "); // 2:�����ԍ�
    sb.append("    ,:3                                                      "); // 3:�X�V�@�\��
    sb.append("    ,TO_NUMBER(:4)                                           "); // 4:�X�V�O_����
    sb.append("    ,TO_NUMBER(:5)                                           "); // 5:�X�V��_����
    sb.append("    ,NULL                                                    "); // �X�V�O_�ܖ�����
    sb.append("    ,NULL                                                    "); // �X�V��_�ܖ�����
    sb.append("    ,FND_GLOBAL.USER_ID                                      "); // �쐬��
    sb.append("    ,SYSDATE                                                 "); // �쐬��
    sb.append("    ,FND_GLOBAL.USER_ID                                      "); // �ŏI�X�V��
    sb.append("    ,SYSDATE                                                 "); // �ŏI�X�V��
    sb.append("    ,FND_GLOBAL.LOGIN_ID);                                   "); // �ŏI�X�V���O�C��
                 // OUT�p�����[�^
    sb.append("  :6 := '1';                                                 "); // 1:����I��
    sb.append("END;                                                         ");
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1,    XxcmnUtility.intValue(txns_id)); // ����ID
      cstmt.setString(2, CreatedPoNum);                   // �����ԍ�(�쐬��)
      cstmt.setString(3, programName);                    // �X�V�@�\��
      cstmt.setString(4, correctedQuantityDef);           // �X�V�O_����
// V1.36 Added START
      if ( !XxcmnUtility.isBlankOrNull(correctedQuantity) )
      {
// V1.36 Added END
        cstmt.setString(5, correctedQuantity);            // �X�V��_����
// V1.36 Added START
      }
      else
      {
        cstmt.setString(5, productedQuantity);            // �X�V��_����(�������ʂ�NULL�̏ꍇ�͏o�������ʂƂ���)
      }
// V1.36 Added END
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(6, Types.VARCHAR);   // ���^�[���R�[�h
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      retFlag = cstmt.getString(6);

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag))
      {
        // ���^�[���R�[�h�F������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //�g�[�N������
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_XXPO_TXNS_UPDATE_HISTORY) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXPO,
                             XxpoConstants.XXPO10007,
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN,
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // insertTxnsUpdateHistory

  /*****************************************************************************
   * ���������X�V���܂��B
   * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @return String - 0 �ُ� (XxcmnConstants.RETURN_NOT_EXE)
   *                  1 ���� (XxcmnConstants.RETURN_SUCCESS)
   *                  2 ���b�N�G���[
   *                  3 �������׍X�V�G���[
   *                  4 �����[�����׍X�V�G���[
   *                  5 ����API�G���[
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String refPoChange(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "refPoChange";

    // IN�p�����[�^�擾
    String CreatedPoNum      = (String)params.get("CreatedPoNum");      // �����ԍ�(�쐬��)
    Number conversionFactor  = (Number)params.get("ConversionFactor");  // ���Z����
    String correctedQuantity = (String)params.get("CorrectedQuantity"); // ��������
    String lastUpdateDate    = (String)params.get("LastUpdateDate");    // �ŏI�X�V��
// V1.36 Added START
    String productedQuantity = (String)params.get("ProductedQuantity"); // �o��������
// V1.36 Added END

    // OUT�p�����[�^�p
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // �߂�l

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append(" DECLARE                                                                        ");
    sb.append("   lt_po_header_id       po_headers_all.po_header_id%TYPE;                      "); // �����w�b�_ID
    sb.append("   lt_po_line_id         po_lines_all.po_line_id%TYPE;                          "); // ��������ID
    sb.append("   ln_kobikigo_tanka     NUMBER;                                                "); // ������P��
    sb.append("   ln_kousen_kingaku     NUMBER;                                                "); // �a����K���z
    sb.append("   ln_huka_kingaku       NUMBER;                                                "); // ���ۋ��z
    sb.append("   lt_revision_num       po_headers_all.revision_num%TYPE;                      "); // �����ԍ�
    sb.append("   ln_corrected_quantity NUMBER := TO_NUMBER(:1);                               "); // ��������
    sb.append("   ln_case_in_qty        NUMBER := :2;                                          "); // ����
    sb.append("   ln_return_status      NUMBER;                                                "); // �����w�b�_ID
    sb.append("   lock_expt             EXCEPTION;                                             "); // ���b�N�G���[
    sb.append("   upd_pla_expt          EXCEPTION;                                             "); // �������׍X�V�G���[
    sb.append("   upd_plla_expt         EXCEPTION;                                             "); // �����[�����׍X�V�G���[
    sb.append("   PRAGMA EXCEPTION_INIT(lock_expt, -54);                                       ");
    sb.append(" BEGIN                                                                          ");
                  // �������̎擾�E���b�N
    sb.append("   SELECT pha.po_header_id                     AS po_header_id                  "); // �����w�b�_ID
    sb.append("         ,pla.po_line_id                       AS po_line_id                    "); // ��������ID
    sb.append("         ,TO_NUMBER(NVL(plla.attribute2, '0')) AS kobikigo_tanka                "); // ������P��
    sb.append("         ,TO_NUMBER(NVL(plla.attribute5, '0')) AS kousen_kingaku                "); // �a����K���z
    sb.append("         ,TO_NUMBER(NVL(plla.attribute8, '0')) AS huka_kingaku                  "); // ���ۋ��z
    sb.append("         ,pha.revision_num                     AS revision_num                  "); // �����ԍ�
    sb.append("   INTO   lt_po_header_id                                                       ");
    sb.append("         ,lt_po_line_id                                                         ");
    sb.append("         ,ln_kobikigo_tanka                                                     ");
    sb.append("         ,ln_kousen_kingaku                                                     ");
    sb.append("         ,ln_huka_kingaku                                                       ");
    sb.append("         ,lt_revision_num                                                       ");
    sb.append("   FROM   po_headers_all        pha                                             "); // �����w�b�_
    sb.append("         ,po_lines_all          pla                                             "); // ��������
    sb.append("         ,po_line_locations_all plla                                            "); // �����[������
    sb.append("   WHERE  pha.segment1      = :3                                                "); // �����ԍ�
    sb.append("   AND    pha.po_header_id  = pla.po_header_id                                  ");
    sb.append("   AND    plla.po_header_id = pha.po_header_id                                  ");
    sb.append("   AND    plla.po_line_id   = pla.po_line_id                                    ");
    sb.append("   AND    pla.line_num      = 1                                                 ");
    sb.append("   FOR UPDATE NOWAIT                                                            ");
    sb.append("   ;                                                                            ");
                  // �������׍X�V(DFF)
    sb.append("   BEGIN                                                                        ");
    sb.append("     UPDATE po_lines_all pla                                                    ");
    sb.append("     SET    pla.attribute11          = TO_CHAR(ln_corrected_quantity)           "); // ��������
    sb.append("           ,pla.last_updated_by      = FND_GLOBAL.USER_ID                       "); // �ŏI�X�V��
    sb.append("           ,pla.last_update_date     = SYSDATE                                  "); // �ŏI�X�V��
    sb.append("           ,pla.last_update_login    = FND_GLOBAL.USER_ID                       "); // �ŏI�X�V���O�C��
    sb.append("     WHERE  pla.po_header_id = lt_po_header_id                                  ");
    sb.append("     AND    pla.po_line_id   = lt_po_line_id                                    ");
    sb.append("     ;                                                                          ");
    sb.append("   EXCEPTION                                                                    ");
    sb.append("     WHEN OTHERS THEN                                                           ");
    sb.append("       RAISE upd_pla_expt;                                                      ");
    sb.append("   END;                                                                         ");
                  // �����[�����׍X�V(DFF)
    sb.append("   BEGIN                                                                        ");
    sb.append("     UPDATE po_line_locations_all plla                                          ");
    sb.append("     SET   plla.attribute2           = TO_CHAR(ln_kobikigo_tanka)               "); // ������P��
    sb.append("          ,plla.attribute5           = TO_CHAR(ln_kousen_kingaku)               "); // �a����K���z
    sb.append("          ,plla.attribute8           = TO_CHAR(ln_huka_kingaku)                 "); // ���ۋ��z
    sb.append("          ,plla.attribute9           = TO_CHAR(ln_corrected_quantity * ln_case_in_qty * ln_kobikigo_tanka ) "); // ��������z(��������*����*������P��)
    sb.append("          ,plla.last_updated_by      = FND_GLOBAL.LOGIN_ID                      "); // �ŏI�X�V��
    sb.append("          ,plla.last_update_date     = SYSDATE                                  "); // �ŏI�X�V��
    sb.append("          ,plla.last_update_login    = FND_GLOBAL.LOGIN_ID                      "); // �ŏI�X�V���O�C��
    sb.append("     WHERE plla.po_header_id = lt_po_header_id                                  ");
    sb.append("     AND   plla.po_line_id   = lt_po_line_id                                    ");
    sb.append("     ;                                                                          ");
    sb.append("   EXCEPTION                                                                    ");
    sb.append("     WHEN OTHERS THEN                                                           ");
    sb.append("       RAISE upd_plla_expt;                                                     ");
    sb.append("   END;                                                                         ");
                  // �����X�VAPI
    sb.append("   ln_return_status :=                                                          ");
    sb.append("     xxpo_common_pkg.update_po(                                                 ");
    sb.append("       :3                                                                       "); // IN �����ԍ�
    sb.append("      ,NULL                                                                     "); // IN �����[�X�ԍ�
    sb.append("      ,lt_revision_num                                                          "); // IN �����ԍ�
    sb.append("      ,1                                                                        "); // IN ���הԍ�
    sb.append("      ,NULL                                                                     "); // IN �o�הԍ�
    sb.append("      ,ln_corrected_quantity * ln_case_in_qty                                   "); // IN ����(�X�V��)
    sb.append("      ,NULL                                                                     "); // IN �P��(�X�V��)
    sb.append("      ,NULL                                                                     "); // IN �o�ד�(�X�V��)
    sb.append("      ,'Y'                                                                      "); // IN ���F�t���O
    sb.append("      ,NULL                                                                     "); // IN �X�V�\�[�X
    sb.append("      ,'1.0'                                                                    "); // IN �o�[�W����
    sb.append("      ,NULL                                                                     "); // IN ������
    sb.append("      ,NULL                                                                     "); // IN �w����
    sb.append("      ,'xxpo340001j'                                                            "); // IN �ďo�����W���[�����i���O�o�͗p�j
    sb.append("      ,'XxpoUtility'                                                            "); // IN �ďo���p�b�P�[�W���i���O�o�͗p�j
    sb.append("     );                                                                         ");
    sb.append("   :4 := '1';                                                                   "); // ����
    sb.append("   IF (ln_return_status <> 1) THEN                                              "); // �����X�VAPI�G���[
    sb.append("     :4 := '5';                                                                 ");
    sb.append("   END IF;                                                                      ");
    sb.append(" EXCEPTION                                                                      ");
    sb.append("   WHEN lock_expt THEN                                                          "); // ���b�N�G���[
    sb.append("       :4 := '2';                                                               ");
    sb.append("   WHEN upd_pla_expt THEN                                                       "); // �������׍X�V�G���[
    sb.append("       :4 := '3';                                                               ");
    sb.append("   WHEN upd_plla_expt THEN                                                      "); // �����[�����׍X�V�G���[
    sb.append("       :4 := '4';                                                               ");
    sb.append(" END;                                                                           ");
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
// V1.36 Added START
      if ( !XxcmnUtility.isBlankOrNull(correctedQuantity) )
      {
// V1.36 Added END
        cstmt.setString(1, correctedQuantity);                  // ��������
// V1.36 Added START
      }
      else
      {
        cstmt.setString(1, productedQuantity);                  // �o��������(�������ʂ�NULL�̏ꍇ�͏o�������ʂƂ���)
      }
// V1.36 Added END
      cstmt.setInt(2, XxcmnUtility.intValue(conversionFactor)); // ���Z����
      cstmt.setString(3, CreatedPoNum);                         // �����ԍ�(�쐬��)
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(4, Types.VARCHAR);   // ���^�[���R�[�h
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      retFlag = cstmt.getString(4); // ���^�[���R�[�h

      // ����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag))
      {
        // ���^�[���R�[�h�F������Z�b�g
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        
      // ���b�N�G���[�̏ꍇ
      } else if ("2".equals(retFlag))
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���b�N�G���[
        throw new OAException(XxcmnConstants.APPL_XXPO,
                               XxpoConstants.XXPO10138);

      // �������׍X�V�G���[�̏ꍇ
      } else if ("3".equals(retFlag))
      {
        // ���[���o�b�N
        rollBack(trans);
        
        //�g�[�N������
        MessageToken[] tokens = new MessageToken[3];
        tokens[0] = new MessageToken(XxpoConstants.TOKEN_INFO_NAME, XxpoConstants.TOKEN_NAME_UPD_PO_LINES);
        tokens[1] = new MessageToken(XxpoConstants.TOKEN_PARAMETER, XxpoConstants.TOKEN_NAME_PO_NUMBER);
        tokens[2] = new MessageToken(XxpoConstants.TOKEN_VALUE    , CreatedPoNum);
        
        // �������s�G���[
        throw new OAException(XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO40042,
                              tokens);
       
      // �����[�����׍X�V�G���[�̏ꍇ
      } else if ("4".equals(retFlag))
      {
        // ���[���o�b�N
        rollBack(trans);
        
        //�g�[�N������
        MessageToken[] tokens = new MessageToken[3];
        tokens[0] = new MessageToken(XxpoConstants.TOKEN_INFO_NAME, XxpoConstants.TOKEN_NAME_UPD_PO_LINES_LOC);
        tokens[1] = new MessageToken(XxpoConstants.TOKEN_PARAMETER, XxpoConstants.TOKEN_NAME_PO_NUMBER);
        tokens[2] = new MessageToken(XxpoConstants.TOKEN_VALUE    , CreatedPoNum);
        
        // �������s�G���[
        throw new OAException(XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO40042,
                              tokens);
      
      // ����API�G���[�̏ꍇ
      } else if ("5".equals(retFlag))
      {
        // ���[���o�b�N
        rollBack(trans);
        
        //�g�[�N������
        MessageToken[] tokens = new MessageToken[3];
        tokens[0] = new MessageToken(XxpoConstants.TOKEN_INFO_NAME, XxpoConstants.TOKEN_NAME_UPD_PO_API);
        tokens[1] = new MessageToken(XxpoConstants.TOKEN_PARAMETER, XxpoConstants.TOKEN_NAME_PO_NUMBER);
        tokens[2] = new MessageToken(XxpoConstants.TOKEN_VALUE    , CreatedPoNum);
        
        // �������s�G���[
        throw new OAException(XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO40042,
                              tokens);
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);

      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN,
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
          XxcmnUtility.writeLog(trans,
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN,
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // refPoChange
// S.Yamashita Ver.1.35 Add End
}