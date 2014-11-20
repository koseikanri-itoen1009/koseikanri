/*============================================================================
* �t�@�C���� : XxinvUtility
* �T�v����   : �ړ����ʊ֐�
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-14 1.0  �勴 �F�Y    �V�K�쐬
* 2008-07-10 1.1  �ɓ��ЂƂ�   isMovHdrUpdForOwnConc,isMovLineUpdForOwnConc�ǉ�
*============================================================================
*/
package itoen.oracle.apps.xxinv.util;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxinv.util.XxinvConstants;
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.common.MessageToken;

import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

/***************************************************************************
 * �ړ����ʊ֐��N���X�ł��B
 * @author  ORACLE �勴�F�Y
 * @version 1.1
 ***************************************************************************
 */
public class XxinvUtility 
{
  public XxinvUtility()
  {
  }
  /*****************************************************************************
   * ���[�U�[�����擾���܂��B
   * @param trans            - �g�����U�N�V����
   * @return HashMap         - �߂�l�Q
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap getUserData(
    OADBTransaction trans
  ) throws OAException
  {
    String apiName  = "getUserData"; // API��

    HashMap paramsRet = new HashMap();

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                             );
    sb.append("  SELECT papf.attribute3          people_code "                     ); // �]�ƈ��敪
    sb.append("        ,xinvisv.segment1         locations_code "                  ); // �ۊǑq�ɃR�[�h
    sb.append("        ,xinvisv.description      locations_name "                  ); // �ۊǑq�ɖ�
    sb.append("        ,xinvisv.inventory_location_id inventory_location_id "      ); // �q��ID
    sb.append("  INTO   :1 "                                                       );
    sb.append("        ,:2 "                                                       );
    sb.append("        ,:3 "                                                       );
    sb.append("        ,:4 "                                                       );
    sb.append("  FROM   fnd_user              fu "                                 ); // ���[�U�[�}�X�^
    sb.append("        ,per_all_people_f      papf "                               ); // �]�ƈ��}�X�^
    sb.append("        ,xxinv_info_sec_v      xinvisv "                            ); // ���Z�L�����e�B�}�X�^
    sb.append("  WHERE  fu.employee_id              = papf.person_id "             ); // �]�ƈ�ID
    sb.append("  AND    fu.start_date <= TRUNC(SYSDATE) "                          ); // �K�p�J�n��
    sb.append("  AND    ((fu.end_date IS NULL) OR (fu.end_date >= TRUNC(SYSDATE))) " ); // �K�p�I����
    sb.append("  AND    papf.effective_start_date <= TRUNC(SYSDATE) "              ); // �K�p�J�n��
    sb.append("  AND    papf.effective_end_date   >= TRUNC(SYSDATE) "              ); // �K�p�I����
    sb.append("  AND    fu.user_id                  = FND_GLOBAL.USER_ID "         ); // ���[�U�[ID
    sb.append("  AND    xinvisv.user_id = DECODE(papf.attribute3,'1',-1,FND_GLOBAL.USER_ID) " ); // ���[�U�[ID
    sb.append("  AND    ROWNUM                      = 1 "                          ); 
    sb.append("  ORDER BY TO_NUMBER(xinvisv.segment1); "                           ); 
    sb.append("END; "                                                              );

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      int i = 1;
       // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(i++, Types.VARCHAR); // �]�ƈ��敪
      cstmt.registerOutParameter(i++, Types.VARCHAR); // �ۊǑq�ɃR�[�h
      cstmt.registerOutParameter(i++, Types.VARCHAR); // �ۊǑq�ɖ�
      cstmt.registerOutParameter(i++, Types.INTEGER); // �q��ID
      
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      paramsRet.put("retpeopleCode", cstmt.getString(1));          // �]�ƈ��敪
      paramsRet.put("locationsCode", cstmt.getString(2));          // �ۊǑq�ɃR�[�h
      paramsRet.put("locationsName", cstmt.getString(3));          // �ۊǑq�ɖ�
      paramsRet.put("locationId",    new Number(cstmt.getInt(4))); // �q��ID


    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    return paramsRet;
  } // getUserData

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
    // ���[�t�E�d�ʂ̏ꍇ
    sb.append("  IF (('1' = lv_prod_class) AND ('1' = lv_weight_capacity_class)) THEN ");
    sb.append("    ln_deadweight := ln_leaf_deadweight; ");
    // ���[�t�E�e�ς̏ꍇ
    sb.append("  ELSIF (('1' = lv_prod_class) AND ('2' = lv_weight_capacity_class)) THEN ");
    sb.append("    ln_loading_capacity := ln_leaf_loading_capacity; ");
    // �h�����N�E�d�ʂ̏ꍇ
    sb.append("  ELSIF (('2' = lv_prod_class) AND ('1' = lv_weight_capacity_class)) THEN ");
    sb.append("    ln_deadweight := ln_drink_deadweight; ");
    // �h�����N�E�e�ς̏ꍇ
    sb.append("  ELSIF (('2' = lv_prod_class) AND ('2' = lv_weight_capacity_class)) THEN ");
    sb.append("    ln_loading_capacity := ln_leaf_loading_capacity; ");
    // ����ȊO
    sb.append("  ELSE ");
    sb.append("    ln_deadweight := null; ");
    sb.append("    ln_loading_capacity := null; ");
    sb.append("  END IF; ");
    sb.append("  :10 := TO_CHAR(ln_palette_max_qty,  'FM9,999,990'); ");
    sb.append("  :11 := TO_CHAR(ln_deadweight,       'FM9,999,990'); ");
    sb.append("  :12 := TO_CHAR(ln_loading_capacity, 'FM9,999,990'); ");
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
      if (XxcmnUtility.isBlankOrNull(originalDate)) 
      {
         cstmt.setNull(i++, Types.DATE);
      } else 
      {
        
        cstmt.setDate(i++, originalDate.dateValue()); // ���

      }
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
                              XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getMaxShipMethod

  /*****************************************************************************
   * �V�[�P���X����ړ��w�b�_ID���擾���܂��B
   * @param trans - �g�����U�N�V����
   * @return Number - �ړ��w�b�_ID
   * @throws OAException OA��O
   ****************************************************************************/
  public static Number getMovHdrId(
    OADBTransaction trans
    ) throws OAException
  {

    return XxcmnUtility.getSeq(trans, XxinvConstants.XXINV_MOV_HDR_S1);


  } // getMovHdrId

  /*****************************************************************************
   * �ړ��˗�/�w���w�b�_(�A�h�I��)Tbl�Ƀf�[�^���X�V���܂��B
   * @param trans �g�����U�N�V����
   * @param params �p�����[�^�pHashMap
   * @return String XxcmnConstants.RETURN_SUCCESS:1 ����
   *                 XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException OA��O
   ****************************************************************************/
  public static String updateMovReqInsrtHdr(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    //
    String apiName      = "updateMovReqInsrtHdr";

    // IN�p�����[�^�擾
    Number movHdrId          = (Number)params.get("MovHdrId");         // �ړ��w�b�_ID
    
    Date   actualShipDate    = (Date)params.get("ActualShipDate");     // �o�Ɏ��ѓ�
    
    Date   actualArrivalDate = (Date)params.get("ActualArrivalDate");  // ���Ɏ��ѓ�
    
    Number outPalletQty      = (Number)params.get("OutPalletQty");     // �p���b�g����(�o)
    
    Number inPalletQty       = (Number)params.get("InPalletQty");      // �p���b�g����(��)

    Number dctualCareerId    = (Number)params.get("ActualCareerId");   // �^���Ǝ�ID_����

    String actualFreightCarrierCode = (String)params.get("ActualFreightCarrierCode"); // �^���Ǝ�_����

    String actualShippingMethodCode = (String)params.get("ActualShippingMethodCode"); // �z���敪_����

    String arrivalTimeFrom   = (String)params.get("ArrivalTimeFrom");  // ���׎���FROM

    String arrivalTimeTo     = (String)params.get("ArrivalTimeTo");    // ���׎���TO
    
    String correctActualFlg  = (String)params.get("CorrectActualFlg"); // ���ђ����t���O
    
    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);

    sb.append("BEGIN ");
    sb.append("  UPDATE xxinv_mov_req_instr_headers ximrih      ");   // �ړ��˗�/�w���w�b�_(�A�h�I��)
    sb.append("  SET    ximrih.actual_ship_date    = :1         ");   // �o�Ɏ��ѓ�
    sb.append("        ,ximrih.actual_arrival_date = :2         ");   // ���Ɏ��ѓ�
    sb.append("        ,ximrih.out_pallet_qty      = :3         ");   // �p���b�g����(�o)
    sb.append("        ,ximrih.in_pallet_qty       = :4         ");   // �p���b�g����(��)
    sb.append("        ,ximrih.actual_career_id    = :5         ");   // �^���Ǝ�ID_����
    sb.append("        ,ximrih.actual_freight_carrier_code = :6 ");   // �^���Ǝ�_����
    sb.append("        ,ximrih.actual_shipping_method_code = :7 ");   // �z���敪_����
    sb.append("        ,ximrih.arrival_time_from   = :8         ");   // ���׎���FROM
    sb.append("        ,ximrih.arrival_time_to     = :9         ");   // ���׎���TO
    sb.append("        ,ximrih.correct_actual_flg  = :10        ");   // ���ђ����t���O
    sb.append("        ,ximrih.last_updated_by   = FND_GLOBAL.USER_ID "); // �ŏI�X�V��
    sb.append("        ,ximrih.last_update_date  = SYSDATE            "); // �ŏI�X�V��
    sb.append("        ,ximrih.last_update_login = FND_GLOBAL.LOGIN_ID"); // �ŏI�X�V���O�C��
    sb.append("  WHERE  ximrih.mov_hdr_id = :11;  ");   // �w�b�_�[ID
    sb.append("END; ");

    // PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {
      // IN�p�����[�^�ݒ�
      cstmt.setDate(1, XxcmnUtility.dateValue(actualShipDate));          // �o�Ɏ��ѓ�
      cstmt.setDate(2, XxcmnUtility.dateValue(actualArrivalDate));       // ���Ɏ��ѓ�
      if (XxcmnUtility.isBlankOrNull(outPalletQty))
      {
        cstmt.setNull(3, Types.INTEGER);                                 // �p���b�g����(�o)
      } else
      {
        cstmt.setInt(3, XxcmnUtility.intValue(outPalletQty));            // �p���b�g����(�o)
      }
      if (XxcmnUtility.isBlankOrNull(inPalletQty))
      {
        cstmt.setNull(4, Types.INTEGER);                                 // �p���b�g����(��)
      } else
      {
        cstmt.setInt(4, XxcmnUtility.intValue(inPalletQty));             // �p���b�g����(��)
      }
      if (XxcmnUtility.isBlankOrNull(dctualCareerId))
      {
        cstmt.setNull(5, Types.INTEGER);                                 // �^���Ǝ�ID_����
      } else
      {
        cstmt.setInt(5, XxcmnUtility.intValue(dctualCareerId));          // �^���Ǝ�ID_����
      }
      if (XxcmnUtility.isBlankOrNull(actualFreightCarrierCode))
      {
        cstmt.setNull(6, Types.INTEGER);                                 // �^���Ǝ�_����
      } else
      {
        cstmt.setString(6, actualFreightCarrierCode);                    // �^���Ǝ�_����
      }
      if (XxcmnUtility.isBlankOrNull(actualShippingMethodCode))
      {
        cstmt.setNull(7, Types.INTEGER);                                 // �z���敪_����
      } else
      {
        cstmt.setString(7, actualShippingMethodCode);                    // �z���敪_����
      }
      if (XxcmnUtility.isBlankOrNull(arrivalTimeFrom))
      {
        cstmt.setNull(8, Types.INTEGER);                                 // ���׎���FROM
      } else
      {
        cstmt.setString(8, arrivalTimeFrom);                             // ���׎���FROM
      }
      if (XxcmnUtility.isBlankOrNull(arrivalTimeTo))
      {
        cstmt.setNull(9, Types.INTEGER);                                 // ���׎���TO
      } else
      {
        cstmt.setString(9, arrivalTimeTo);                               // ���׎���TO
      }
      cstmt.setString(10, correctActualFlg);                             // ���ђ����t���O
      cstmt.setInt(11, XxcmnUtility.intValue(movHdrId));                 // �ړ��w�b�_ID

      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      rollBack(trans);
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_AM_XXINV510001J + XxcmnConstants.DOT + apiName,
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
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }

    // ����ɏ������ꂽ�ꍇ�A"SUCCESS"(1)��ԋp
    return XxcmnConstants.RETURN_SUCCESS;
    
  } // updateMovReqInsrtHdr

 /*****************************************************************************
  * �ړ��˗�/�w���w�b�_�A�h�I�����b�N���擾���܂��B
  * @param trans �g�����U�N�V����
  * @param headerId - �ړ��w�b�_ID
  * @return boolean - true ���b�N����  false ���b�N���s
  * @throws OAException - OA��O
  ****************************************************************************/
  public static boolean getMovReqInstrHdrLock(
   OADBTransaction trans,
   Number headerId
  ) throws OAException
  {
    String apiName = "getMovReqInstrHdrLock";
    boolean retFlag = true; // �߂�l

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  CURSOR xmrih_cur ");
    sb.append("  IS ");
    sb.append("    SELECT xmrih.mov_hdr_id ");
    sb.append("    FROM   xxinv_mov_req_instr_headers xmrih   "); // �ړ��˗�/�w���w�b�_�A�h�I��
    sb.append("    WHERE  xmrih.mov_hdr_id = TO_NUMBER(:1) ");
    sb.append("    FOR UPDATE OF xmrih.mov_hdr_id NOWAIT; ");
    sb.append("BEGIN ");
    sb.append("  OPEN  xmrih_cur; ");
    sb.append("  CLOSE xmrih_cur; ");
    sb.append("END; ");
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                               sb.toString(),
                               OADBTransaction.DEFAULT);
   try
   {
     //PL/SQL�����s���܂�
     int i = 1;
     cstmt.setString(i++, XxcmnUtility.stringValue(headerId));

     cstmt.execute();
       
   } catch (SQLException s) 
   {
     // ���[���o�b�N
     rollBack(trans);
     // ���O�o��
     XxcmnUtility.writeLog(
       trans,
       XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
       XxcmnUtility.writeLog(
         trans,
         XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
         s.toString(),
         6);
       // �G���[���b�Z�[�W�o��
       throw new OAException(
         XxcmnConstants.APPL_XXCMN,
         XxcmnConstants.XXCMN10123);
     }
   }
   return retFlag;
  } // getMovReqInstrHdrLock

  /***************************************************************************
  * �ړ��˗�/�w���w�b�_�A�h�I���̔r������`�F�b�N���s�����\�b�h�ł��B
  * @param trans �g�����U�N�V����
  * @param headerId - �ړ��w�b�_ID
  * @param lastUpdateDate - �ړ��˗�/�w���w�b�_�ŏI�X�V��
  * @return boolean       - true �r���G���[�Ȃ�  false �r���G���[����
  * @throws OAException - OA��O
  ***************************************************************************
  */
  public static boolean chkExclusiveMovReqInstrHdr(
   OADBTransaction trans,
   Number headerId,
   String lastUpdateDate
  ) throws OAException
  {
    String apiName  = "chkExclusiveMovReqInstrHdr";
    CallableStatement cstmt = null;
    boolean retFlag = true; // �߂�l

    try
    {
      // PL/SQL�̍쐬���s���܂�
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT TO_CHAR(xmrih.last_update_date, 'YYYY/MM/DD HH24:MI:SS') ");
      sb.append("  INTO   :1 ");
      sb.append("  FROM   xxinv_mov_req_instr_headers xmrih "); // �ړ��˗�/�w���w�b�_�A�h�I��
      sb.append("  WHERE  xmrih.mov_hdr_id = TO_NUMBER(:2) ");
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
      cstmt.setString(i++, XxcmnUtility.stringValue(headerId));
      // SQL���s
      cstmt.execute();

      String dbLastUpdateDate = cstmt.getString(1);
       
      // �r���G���[�̏ꍇ
      if (!XxcmnUtility.isEquals(lastUpdateDate, dbLastUpdateDate))
      {
        retFlag = false;
      }
    } catch (SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      throw new OAException(
        XxcmnConstants.APPL_XXCMN, 
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
       XxcmnUtility.writeLog(
         trans,
         XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
         s.toString(),
         6);
       throw new OAException(
         XxcmnConstants.APPL_XXCMN, 
         XxcmnConstants.XXCMN10123);
     }
    }
    return retFlag;
  } // chkExclusiveMovReqInstrHdr

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
     XxcmnUtility.writeLog(
       trans,
       XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
       XxcmnUtility.writeLog(
         trans,
         XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
         s.toString(),
         6);
       // �G���[���b�Z�[�W�o��
       throw new OAException(
         XxcmnConstants.APPL_XXCMN, 
         XxcmnConstants.XXCMN10123);
     }
   }
   return sysdate;
  } // getSysdate

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
     XxcmnUtility.writeLog(
       trans,
       XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
         XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
         s.toString(),
         6);
       // �G���[���b�Z�[�W�o��
       throw new OAException(
         XxcmnConstants.APPL_XXCMN, 
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
     oprtnDate = new Date(cstmt.getDate(6));
     if (cstmt.getInt(1) == 1) 
     {
       // ���[���o�b�N
       rollBack(trans);
       XxcmnUtility.writeLog(
         trans,
         XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
         "�߂�l���G���[�ŕԂ�܂����B",
         6);
       // �G���[���b�Z�[�W�o��
       throw new OAException(
         XxcmnConstants.APPL_XXCMN, 
         XxcmnConstants.XXCMN10123);
     }
     
     if(!oprtnDate.equals(originalDate))
     {
       oprtnDate = null;
     } else
     {
       oprtnDate = originalDate;
     }

   // PL/SQL���s����O�̏ꍇ
   } catch(SQLException s)
   {
     // ���[���o�b�N
     rollBack(trans);
     XxcmnUtility.writeLog(
       trans,
       XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
       XxcmnUtility.writeLog(
         trans,
         XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
         s.toString(),
         6);
       // �G���[���b�Z�[�W�o��
       throw new OAException(
         XxcmnConstants.APPL_XXCMN, 
         XxcmnConstants.XXCMN10123);
     }
   }
   return oprtnDate;
  } // getOprtnDay

  /****************************************************************************
  * �R���J�����g�F�ړ����o�Ɏ��ѓo�^�����𔭍s���܂��B
  * @param trans �g�����U�N�V����
  * @param params �p�����[�^�pHashMap
  * @return HashMap ��������
  * @throws OAException OA��O
  ****************************************************************************/
  public static HashMap doMovShipActualMake(
   OADBTransaction trans,
   HashMap params
  ) throws OAException
  {
    String apiName      = "doMovShipActualMake";

    // IN�p�����[�^�擾
    String movNum    = (String)params.get("MovNum");  // �ړ��ԍ�

    // OUT�p�����[�^�pHashMap����
    HashMap outParams = new HashMap();
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // �߂�l

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "   );
    sb.append("  ln_request_id NUMBER; "                                       );
    sb.append("BEGIN "                                                         );
                // �ړ����o�Ɏ��ѓo�^����(�R���J�����g)�Ăяo��
    sb.append("  ln_request_id := FND_REQUEST.SUBMIT_REQUEST( "                );
    sb.append("     application  => 'XXINV' "                                  ); // �A�v���P�[�V������
    sb.append("    ,program      => 'XXINV570001C' "                           ); // �v���O�����Z�k��
    sb.append("    ,argument1    => :1 ); "                                    ); // �ړ��ԍ�
                // �v��ID������ꍇ�A����
    sb.append("  IF ln_request_id > 0 THEN "                                   );
    sb.append("    :2 := '1'; "                                                ); // 1:����I��
    sb.append("    :3 := ln_request_id; "                                      ); // �v��ID
    sb.append("    COMMIT; "                                                   );
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
     cstmt.setString(1, movNum);                     // �ړ��ԍ�
      
     // �p�����[�^�ݒ�(OUT�p�����[�^)
     cstmt.registerOutParameter(2, Types.VARCHAR);   // ���^�[���R�[�h
     cstmt.registerOutParameter(3, Types.INTEGER); // �v��ID

     //PL/SQL���s
     cstmt.execute();

     // �߂�l�擾
     retFlag = cstmt.getString(2); // ���^�[���R�[�h
     int requestId = cstmt.getInt(3); // �v��ID
     outParams.put("retFlag", retFlag);
     outParams.put("requestId", new Integer(requestId));

     // ����I���̏ꍇ
     if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
     {
       // ���^�[���R�[�h������Z�b�g
       retFlag = XxcmnConstants.RETURN_SUCCESS;
       outParams.put("retFlag", retFlag);
        
     // ����I���łȂ��ꍇ�A�G���[  
     } else
     {
       //�g�[�N������
       MessageToken[] tokens = { new MessageToken(XxinvConstants.TOKEN_PROGRAM,
                                                  XxinvConstants.TOKEN_NAME_MOV_ACTUAL_MAKE) };
       // �G���[���b�Z�[�W�o��
       throw new OAException(
         XxcmnConstants.APPL_XXINV, 
         XxinvConstants.XXINV10005, 
         tokens);
     }
      
   // PL/SQL���s����O�̏ꍇ
   } catch(SQLException s)
   {
     // ���[���o�b�N
     rollBack(trans);
     XxcmnUtility.writeLog(
       trans,
       XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
       XxcmnUtility.writeLog(
         trans,
         XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
         s.toString(),
         6);
       // �G���[���b�Z�[�W�o��
       throw new OAException(
         XxcmnConstants.APPL_XXCMN, 
         XxcmnConstants.XXCMN10123);
     }
   }

   return outParams;
  } // doMovShipActualMake
   
  /*****************************************************************************
   * �ړ����b�g�ڍׂ̑��݃`�F�b�N���s���܂��B
   * @param trans      - �g�����U�N�V����
   * @param movHdrId   - �ړ��w�b�_ID
   * @param recordType - ���R�[�h�^�C�v
   * @return boolean   - ���݂���ꍇ   true
   *                    - ���݂��Ȃ��ꍇ false
   * @throws OAException  - OA��O
   ****************************************************************************/
  public static boolean chkLotDetails(
    OADBTransaction trans,
    Number movHdrId,
    String recordType
    ) throws OAException
  {
    String apiName = "chkLotDetails";
    boolean retFlag = false;

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "  );
    sb.append("  SELECT COUNT(xmld.mov_lot_dtl_id) ");
    sb.append("  INTO   :1 ");
    sb.append("  FROM   xxinv_mov_req_instr_lines ximril "  ); // �ړ��˗�/�w������(�A�h�I��)
    sb.append("        ,xxinv_mov_lot_details     xmld "    ); // �ړ����b�g�ڍ�(�A�h�I��)
    sb.append("  WHERE  ximril.mov_hdr_id         = :2  "      ); // �ړ��w�b�_ID
    sb.append("  AND    xmld.mov_line_id = ximril.mov_line_id "); // �ړ�����ID
    sb.append("  AND    xmld.item_id = ximril.item_id "        ); // OPM�i��ID
    sb.append("  AND    xmld.record_type_code     = :3; "      ); // ���R�[�h�^�C�v
    sb.append("END; ");
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      //�o�C���h�ϐ��ɒl���Z�b�g
      cstmt.registerOutParameter(1,Types.INTEGER);
      cstmt.setInt(2, XxcmnUtility.intValue(movHdrId)); // �ړ��w�b�_ID
      cstmt.setString(3, recordType);                   // ���R�[�h�^�C�v
      //PL/SQL���s
      cstmt.execute();
      // �p�����[�^�̎擾
      int cnt = cstmt.getInt(1);
      if(cnt > 0)
      {
        retFlag = true; 
      }
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // chkLotDetails 

  /*****************************************************************************
   * �ړ����b�g�ڍׂ̎��ѓ��f�[�^���X�V���܂��B
   * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @return String - XxcmnConstants.RETURN_SUCCESS:1 ����
   *                   XxcmnConstants.RETURN_NOT_EXE:0 �ُ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String updateMovLotDetails(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "updateMovLotDetails";

    // IN�p�����[�^�擾
    Number movHdrId          = (Number)params.get("MovHdrId");        // �ړ��w�b�_ID
    String recordType        = (String)params.get("RecordType");      // ���R�[�h�^�C�v
    Date   actualShipDate    = (Date)params.get("ActualShipDate");    // �o�ɓ�(����)
    Date   actualArrivalDate = (Date)params.get("ActualArrivalDate"); // ����(����)

    // OUT�p�����[�^�p
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // �߂�l

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                                             );
    sb.append("  lt_mov_hdr_id   xxinv_mov_req_instr_headers.mov_hdr_id%TYPE := :1; "); // �ړ��w�b�_ID
    sb.append("  lt_record_type  xxinv_mov_lot_details.record_type_code%TYPE := :2; "); // ���R�[�h�^�C�v
    sb.append("  lt_hdr_id       xxinv_mov_req_instr_headers.mov_hdr_id%TYPE; "      );
                 // ���[�U�[��`�G���[
    sb.append("  lock_expt             EXCEPTION; "                                  ); // ���b�N�G���[
    sb.append("  PRAGMA EXCEPTION_INIT(lock_expt, -54); "                            ); 
    sb.append("BEGIN "                                                );
                 // ���b�N�擾
    sb.append("  SELECT xmrih.mov_hdr_id "                            );
    sb.append("  INTO   lt_hdr_id "                                   );
    sb.append("  FROM   xxinv_mov_req_instr_headers xmrih "           );
    sb.append("        ,xxinv_mov_req_instr_lines   ximril "          );
    sb.append("        ,xxinv_mov_lot_details       ximld "           );
    sb.append("  WHERE  xmrih.mov_hdr_id = lt_mov_hdr_id "            );
    sb.append("  AND    xmrih.mov_hdr_id = ximril.mov_hdr_id "        );
    sb.append("  AND    ximril.mov_line_id = ximld.mov_line_id "      );
    sb.append("  AND    ximld.record_type_code = lt_record_type "     );
    sb.append("  FOR UPDATE OF xmrih.mov_hdr_id "                     );
    sb.append("               ,ximril.mov_hdr_id "                    );
    sb.append("               ,ximld.mov_line_id NOWAIT; "            );
                 // �ړ����b�g�ڍ�(�A�h�I��)�X�V
    sb.append("  UPDATE xxinv_mov_lot_details ximld"          );
    // ���R�[�h�^�C�v��:20(�o�Ɏ���)�̏ꍇ
    if (recordType.equals(XxinvConstants.RECORD_TYPE_20))
    {
      sb.append("  SET    actual_date = :3"                   );
    // ���R�[�h�^�C�v��:30(���Ɏ���)�̏ꍇ
    } else if (recordType.equals(XxinvConstants.RECORD_TYPE_30))
    {
      sb.append("  SET    actual_date = :3"                   );
    }
    sb.append("  WHERE ximld.mov_line_id IN(SELECT ximril.mov_line_id ");
    sb.append("                             FROM   xxinv_mov_req_instr_headers xmrih ");
    sb.append("                                   ,xxinv_mov_req_instr_lines ximril ");
    sb.append("                             WHERE xmrih.mov_hdr_id = lt_mov_hdr_id ");
    sb.append("                             AND   xmrih.mov_hdr_id = ximril.mov_hdr_id) ");
    sb.append("  AND   ximld.record_type_code = lt_record_type; ");
    sb.append("  COMMIT; "                                                               ); // �R�~�b�g
                 // OUT�p�����[�^
    sb.append("  :4 := '1'; "                                                            ); // 1:����I��
    sb.append("EXCEPTION "                                                               );
    sb.append("  WHEN lock_expt THEN "                                                   );
    sb.append("    ROLLBACK; "                                                           ); // ���[���o�b�N
    sb.append("    :4 := '2'; "                                                          ); // 2:���b�N�G���[
    sb.append("    :5 := SQLERRM; "                                                      ); // SQLERR���b�Z�[�W 
    sb.append("END; "                                                                    );

    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1, XxcmnUtility.intValue(movHdrId));            // �ړ��w�b�_ID
      cstmt.setString(2, recordType);                              // ���R�[�h�^�C�v
      // ���R�[�h�^�C�v��:20(�o�Ɏ���)�̏ꍇ
      if (recordType.equals(XxinvConstants.RECORD_TYPE_20))
      {
        cstmt.setDate(3, XxcmnUtility.dateValue(actualShipDate));    // �o�ɓ�(����)
      // ���R�[�h�^�C�v��:30(���Ɏ���)�̏ꍇ
      } else if (recordType.equals(XxinvConstants.RECORD_TYPE_30))
      {
        cstmt.setDate(3, XxcmnUtility.dateValue(actualArrivalDate)); // ���ɓ�(����)
      }
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(4, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(5, Types.VARCHAR);   // �G���[���b�Z�[�W
      
      //PL/SQL���s
      cstmt.execute();

      // �߂�l�擾
      retFlag = cstmt.getString(4); // ���^�[���R�[�h
      String sqlErrMsg = cstmt.getString(5); // �G���[���b�Z�[�W

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
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          sqlErrMsg,
          6);
        // ���b�N�G���[
        throw new OAException(
          XxcmnConstants.APPL_XXINV, 
          XxinvConstants.XXINV10159);
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_AM_XXINV510001J + XxcmnConstants.DOT + apiName,
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
          XxcmnUtility.writeLog(
            trans,
            XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
            s.toString(),
            6);
          // �G���[���b�Z�[�W�o��
          throw new OAException(
            XxcmnConstants.APPL_XXCMN, 
            XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // updateMovLotDetails

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
   * �ړ����b�g�ڍ�ID�V�[�P���X���A�V�KID���擾���郁�\�b�h�ł��B
   * @param trans   - �g�����U�N�V����
   * @throws OAException - OA��O
   ****************************************************************************/
  public static Number getMovLotDtlId(
    OADBTransaction trans
  ) throws OAException
  {
    String apiName   = "getMovLotDtlId";
    Number movLotDtlId = null;
    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                              );
    sb.append("  SELECT xxinv_mov_lot_s1.NEXTVAL  " ); // 1:�ړ����b�g�ڍ׃A�h�I��ID
    sb.append("  INTO   :1 "                        );
    sb.append("  FROM   DUAL; "                     );
    sb.append("END; "                               );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.INTEGER);
      
      // PL/SQL���s
      cstmt.execute();

      // OUT�p�����[�^�擾
      movLotDtlId = new Number(cstmt.getObject(1)); // �ړ����b�g�ڍ׃A�h�I��ID

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    return movLotDtlId;
  } // getMovLotDtlId

  /*****************************************************************************
   * OPM���b�g�}�X�^�̑Ó����`�F�b�N���s�����\�b�h�ł��B
   * @param trans             - �g�����U�N�V����
   * @param lotNo             - ���b�gNo
   * @param manufacturedDate  - �����N����
   * @param useByDate         - �ܖ�����
   * @param koyuCode          - �ŗL�L��
   * @param itemId            - �i��ID
   * @param productFlg        - ���i���ʋ敪 1:���i 2:���i�ȊO
   * @return HashMap          - ���b�g�}�X�^���
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap seachOpmLotMst(
    OADBTransaction trans,
    String lotNo,
    Date   manufacturedDate,
    Date   useByDate,
    String koyuCode,
    Number itemId,
    String productFlg
  ) throws OAException
  {
    String apiName   = "seachOpmLotMst";

    HashMap ret = new HashMap();
    
    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                                            );
    sb.append("  SELECT ilm.lot_no                     lot_no                  "                  ); // 1:���b�gNo
    sb.append("        ,FND_DATE.STRING_TO_DATE(ilm.attribute1,'YYYY/MM/DD')  manufactured_date " ); // 2:�����N����
    sb.append("        ,FND_DATE.STRING_TO_DATE(ilm.attribute3,'YYYY/MM/DD')  use_by_date       " ); // 3:�ܖ�����
    sb.append("        ,ilm.attribute2                 koyu_code               "                  ); // 4:�ŗL�L��
    sb.append("        ,ilm.lot_id                     lot_id                  "                  ); // 5:���b�gID
    sb.append("        ,xlsv.move_inst_rel             move_inst_rel           "                  ); // 6:�ړ��w��(����)
    sb.append("        ,xlsv.status_desc               status_desc             "                  ); // 7:���b�g�X�e�[�^�X����
    sb.append("        ,REPLACE(TO_CHAR(ilm.attribute6,'99990.000'),' ')      stock_quantity    " ); // 8:�݌ɓ���
    sb.append("  INTO   :1 "                                                                      );
    sb.append("        ,:2 "                                                                      );
    sb.append("        ,:3 "                                                                      );
    sb.append("        ,:4 "                                                                      );
    sb.append("        ,:5 "                                                                      );
    sb.append("        ,:6 "                                                                      );
    sb.append("        ,:7 "                                                                      );
    sb.append("        ,:8 "                                                                      );
    sb.append("  FROM   ic_lots_mst            ilm "                                              ); // OPM���b�g�}�X�^
    sb.append("        ,xxcmn_lot_status_v     xlsv "                                             ); // ���b�g�X�e�[�^�X���VIEW
    sb.append("  WHERE  ilm.attribute23 = xlsv.lot_status "                                       );
    sb.append("  AND    ilm.item_id = :9 "                                                        ); // �i��ID
    sb.append("  AND    xlsv.prod_class_code = FND_PROFILE.VALUE('XXCMN_ITEM_DIV_SECURITY') "     ); // ���i�敪
    // ���i���ʋ敪��1:���i�łȂ��ꍇ
    sb.append("  AND  (((:10 <> '1') "                                                             );
    sb.append("  AND    (:11 IS NULL OR ilm.lot_no = :11)) "                                      ); // ���b�gNo      
    // ���i���ʋ敪��1:���i�̏ꍇ
    sb.append("  OR    ((:10 = '1') "                                                              );
    sb.append("  AND    (:12 IS NULL OR ilm.attribute1 = TO_CHAR(:12, 'YYYY/MM/DD')) "            ); // �����N����
    sb.append("  AND    (:13 IS NULL OR ilm.attribute3 = TO_CHAR(:13, 'YYYY/MM/DD')) "            ); // �ܖ�����
    sb.append("  AND    (:14 IS NULL OR ilm.attribute2 = :14))); "                                ); // �ŗL�L��      
    sb.append("  :15 := '1'; "                                                                    );
    sb.append("EXCEPTION "                                                                        );
    sb.append("  WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN "                                       );
    sb.append("    :15 := '0'; "                                                                  );
    sb.append("END; "                                                                             );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt   (9, XxcmnUtility.intValue(itemId));            // �i��ID
      cstmt.setString(10, productFlg);                               // ���i���ʋ敪
      cstmt.setString(11, lotNo);                                   // ���b�gNo
      cstmt.setDate  (12, XxcmnUtility.dateValue(manufacturedDate)); // �����N����
      cstmt.setDate  (13, XxcmnUtility.dateValue(useByDate));       // �ܖ�����
      cstmt.setString(14, koyuCode);                                // �ŗL�L��

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1,  Types.VARCHAR);
      cstmt.registerOutParameter(2,  Types.DATE);
      cstmt.registerOutParameter(3,  Types.DATE);
      cstmt.registerOutParameter(4,  Types.VARCHAR);
      cstmt.registerOutParameter(5,  Types.INTEGER);
      cstmt.registerOutParameter(6,  Types.VARCHAR);
      cstmt.registerOutParameter(7,  Types.VARCHAR);
      cstmt.registerOutParameter(8,  Types.VARCHAR);
      cstmt.registerOutParameter(15, Types.VARCHAR);

      // PL/SQL���s
      cstmt.execute();

      // OUT�p�����[�^�擾
      ret.put("lotNo"               , cstmt.getString(1));          // ���b�gNo
      ret.put("manufacturedDate"    , cstmt.getObject(2));          // �����N����
      ret.put("useByDate"           , cstmt.getObject(3));          // �ܖ�����
      ret.put("koyuCode"            , cstmt.getString(4));          // �ŗL�L��
      ret.put("lotId"               , new Number(cstmt.getInt(5))); // ���b�gID
      ret.put("movInstRel"          , cstmt.getString(6));          // �ړ��w��(����)
      ret.put("statusDesc"          , cstmt.getString(7));          // �X�e�[�^�X�R�[�h����
      ret.put("stock_quantity"      , cstmt.getString(8));          // �݌ɓ���
      ret.put("retCode"             , cstmt.getString(15));         // �߂�l

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    return ret;
  } // seachOpmLotMst

  /*****************************************************************************
   * ���b�g�t�]�h�~�`�F�b�NAPI�����s���܂��B
   * @param trans        - �g�����U�N�V����
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
    sb.append("    iv_lot_biz_class    => '6',           ");   //  .���b�g�t�]������� 6:�ړ�����
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

      String retCode      = cstmt.getString(5);              // ���^�[���R�[�h
      String errmsgCode   = cstmt.getString(6);              // �G���[���b�Z�[�W�R�[�h
      String errmsg       = cstmt.getString(7);              // �G���[���b�Z�[�W

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
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
      cstmt.setInt   (2, XxcmnUtility.intValue(whseId)); // �ۊǑq��ID
      cstmt.setInt   (3, XxcmnUtility.intValue(itemId)); // �i��ID
      // ���b�g�Ǘ��O�i�̏ꍇ�A���b�gID��NULL
      if (XxinvConstants.LOT_CTL_N.equals(lotCtl))
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
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
      if (XxinvConstants.LOT_CTL_N.equals(lotCtl))
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
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
   * @return boolean         - true:���� false:�Ȃ�
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
      cstmt.setString(3, recordTypeCode);                // ���R�[�h�^�C�v
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
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
   * �ړ����b�g�ڍ׃A�h�I�����b�N���擾���܂��B
   * @param trans            - �g�����U�N�V����
   * @param movLineId        - �ړ�����ID
   * @param documentTypeCode - �����^�C�v(10:�o�׈˗��A30:�x���w��)
   * @param recordTypeCode   - ���R�[�h�^�C�v(10�F�w���A20�F�o�Ɏ���  30�F���Ɏ���)
   * @return boolean         - true ���b�N���� false ���b�N���s
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean getMovLotDetailsLock(
    OADBTransaction trans,
    Number movLineId,
    String documentTypeCode,
    String recordTypeCode
  ) throws OAException
  {
    String apiName = "getMovLotDetailsLock";
    
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                     );
    sb.append("  lock_expt             EXCEPTION; "          ); 
    sb.append("  PRAGMA EXCEPTION_INIT(lock_expt, -54); "    );
    sb.append("CURSOR lock_cur IS "                          );
    sb.append("  SELECT 1 "                                  );
    sb.append("  FROM   xxinv_mov_lot_details xmld "         );
    sb.append("  WHERE  xmld.mov_line_id        = :1 "       ); // 1.�ړ�����ID
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
      cstmt.setInt   (1, XxcmnUtility.intValue(movLineId)); // �ړ�����ID
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
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          cstmt.getString(5),
          6);

        return false;

      // ����I���̏ꍇ
      } else
      {
        return true;
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getMovLotDetailsLock

   /*****************************************************************************
   * �ړ��˗�/�w�����׃��b�N���擾���܂��B
   * @param trans �g�����U�N�V����
   * @param lineId - �ړ�����ID
   * @return boolean - true ���b�N����  false ���b�N���s
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean getMovReqInstrLineLock(
   OADBTransaction trans,
   Number lineId
  ) throws OAException
  {
    String apiName = "getMovReqInstrLineLock";
    boolean retFlag = true; // �߂�l

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                      );
    sb.append("  lock_expt             EXCEPTION; "           ); 
    sb.append("  PRAGMA EXCEPTION_INIT(lock_expt, -54); "     );
    sb.append("  CURSOR xmril_cur IS "                        );
    sb.append("    SELECT xmril.mov_line_id "                 );
    sb.append("    FROM   xxinv_mov_req_instr_lines xmril "   ); // �ړ��˗�/�w�����׃A�h�I��
    sb.append("    WHERE  xmril.mov_line_id = :1 "            );
    sb.append("    FOR UPDATE OF xmril.mov_line_id NOWAIT; "  );
    sb.append("BEGIN "                                        );
    sb.append("  OPEN  xmril_cur; "                           );
    sb.append("  CLOSE xmril_cur; "                           );
    sb.append("EXCEPTION "                                    );
    sb.append("  WHEN lock_expt THEN "                        );
    sb.append("    IF (xmril_cur%ISOPEN) THEN "               );
    sb.append("      CLOSE xmril_cur; "                       );
    sb.append("    END IF; "                                  );
    sb.append("    :2 := '1'; "                               );
    sb.append("    :3 := SQLERRM; "                           );
    sb.append("END; "                                         );

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                               sb.toString(),
                               OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1, XxcmnUtility.intValue(lineId)); // �ړ�����ID
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(2, Types.VARCHAR);   // ���^�[���R�[�h
      cstmt.registerOutParameter(3, Types.VARCHAR);   // �G���[���b�Z�[�W
      // PL/SQL���s
      cstmt.execute();

      // ���b�N�G���[�I���̏ꍇ  
      if ("1".equals(cstmt.getString(2)))
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          cstmt.getString(3),
          6);

        return false;

      // ����I���̏ꍇ
      } else
      {
        return true;
      }
    
    // PL/SQL���s����O�̏ꍇ
    } catch (SQLException s) 
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
                     XxcmnConstants.APPL_XXCMN,
                     XxcmnConstants.XXCMN10123);
      }
    }
  } // getMovReqInstrLineLock
  /***************************************************************************
  * �ړ��˗�/�w�����׃A�h�I���̔r������`�F�b�N���s�����\�b�h�ł��B
  * @param trans          - �g�����U�N�V����
  * @param lineId         - �ړ�����ID
  * @param lastUpdateDate - �ړ��˗�/�w�����׍ŏI�X�V��
  * @return boolean       - true �r���G���[�Ȃ�  false �r���G���[����
  * @throws OAException   - OA��O
  ***************************************************************************
  */
  public static boolean chkExclusiveMovReqInstrLine(
   OADBTransaction trans,
   Number lineId,
   String lastUpdateDate
  ) throws OAException
  {
    String apiName  = "chkExclusiveMovReqInstrLine";
    CallableStatement cstmt = null;
    boolean retFlag = true; // �߂�l

    try
    {
      // PL/SQL�̍쐬���s���܂�
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN "                                                            );
      sb.append("  SELECT TO_CHAR(xmril.last_update_date, 'YYYY/MM/DD HH24:MI:SS') ");
      sb.append("  INTO   :1 "                                                      );
      sb.append("  FROM   xxinv_mov_req_instr_lines xmril "                         ); // �ړ��˗�/�w�����׃A�h�I��
      sb.append("  WHERE  xmril.mov_line_id = TO_NUMBER(:2) "                       );
      sb.append("  AND    ROWNUM               = 1  "                               );
      sb.append("  ;  "                                                             );
      sb.append("END; "                                                             );

      // PL/SQL�̐ݒ���s���܂�
      cstmt = trans.createCallableStatement(
                                 sb.toString(),
                                 OADBTransaction.DEFAULT);

      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(2, XxcmnUtility.stringValue(lineId));

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR);
      
      // SQL���s
      cstmt.execute();

      String dbLastUpdateDate = cstmt.getString(1);
       
      // �r���G���[�̏ꍇ
      if (!XxcmnUtility.isEquals(lastUpdateDate, dbLastUpdateDate))
      {
        retFlag = false;
      }
    } catch (SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�o��
      XxcmnUtility.writeLog(trans,
                           XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
       XxcmnUtility.writeLog(trans,
                             XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
                             s.toString(),
                             6);
       throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
     }
    }
    return retFlag;
  } // chkExclusiveMovReqInstrLine

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
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
   * �ړ����b�g�ڍ׃A�h�I���ɒǉ��������s�����\�b�h�ł��B
   * @param trans   - �g�����U�N�V����
   * @param params  - �p�����[�^
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void insertMovLotDetails(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "insertMovLotDetails";

    Number movLineId        = (Number)params.get("movLineId");        // ����ID
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
      cstmt.setInt   (1, XxcmnUtility.intValue(movLineId));   // ����ID
      cstmt.setString(2, documentTypeCode);                   // �����^�C�v
      cstmt.setString(3, recordTypeCode);                     // ���R�[�h�^�C�v
      cstmt.setInt   (4, XxcmnUtility.intValue(itemId));      // OPM�i��ID
      cstmt.setString(5, itemCode);                           // �i��
      cstmt.setInt   (6, XxcmnUtility.intValue(lotId));       // ���b�gID
      cstmt.setString(7, lotNo);                              // ���b�gNo
      cstmt.setDate  (8, XxcmnUtility.dateValue(actualDate)); // ���ѓ�
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
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // insertMovLotDetails

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
    Number movLineId        = (Number)params.get("movLineId");        // ����ID
    String documentTypeCode = (String)params.get("documentTypeCode"); // �����^�C�v
    String recordTypeCode   = (String)params.get("recordTypeCode");   // ���R�[�h�^�C�v
    Number lotId            = (Number)params.get("lotId");            // ���b�gID
    String actualQuantity   = (String)params.get("actualQuantity");   // ���ѐ���

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                 );
    sb.append("  UPDATE xxinv_mov_lot_details xmld "                   ); // �ړ����b�g���׃A�h�I��
    sb.append("  SET    xmld.actual_quantity   = TO_NUMBER(:1) "       ); // 1.���ѐ���
    sb.append("        ,xmld.last_updated_by   = FND_GLOBAL.USER_ID "  ); // �ŏI�X�V��
    sb.append("        ,xmld.last_update_date  = SYSDATE "             ); // �ŏI�X�V��
    sb.append("        ,xmld.last_update_login = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C��
    sb.append("  WHERE  xmld.mov_line_id        = :2 "                 ); // 2.����ID
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
      cstmt.setString(1, actualQuantity);                     // ���ѐ���
      cstmt.setInt   (2, XxcmnUtility.intValue(movLineId));   // ����ID
      cstmt.setString(3, documentTypeCode);                   // �����^�C�v
      cstmt.setString(4, recordTypeCode);                     // ���R�[�h�^�C�v
      cstmt.setInt   (5, XxcmnUtility.intValue(lotId));       // ���b�gID

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
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
   * �ړ����b�g�ڍ׃A�h�I��������ѐ��ʂ̍��v�l���擾���郁�\�b�h�ł��B
   * @param trans            - �g�����U�N�V����
   * @param movLineId        - �ړ�����ID
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
    sb.append("  WHERE  xmld.mov_line_id        = :2 "          ); // 2.�ړ�����ID
    sb.append("  AND    xmld.document_type_code = :3 "          ); // 3.�����^�C�v
    sb.append("  AND    xmld.record_type_code   = :4; "         ); // 4.���R�[�h�^�C�v
    sb.append("END; "                                           );

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    { 
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(movLineId)); // �ړ�����ID
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
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
   * �ړ��˗�/�w�����׃A�h�I���̏o�Ɏ��ѐ��ʂ��X�V���郁�\�b�h�ł��B
   * @param trans        - �g�����U�N�V����
   * @param movLineId  - �ړ��˗�/�w�����׃A�h�I��ID
   * @param shippedQty   - �o�Ɏ��ѐ���
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void updateShippedQuantity(
    OADBTransaction trans,
     Number movLineId,
     String shippedQty
  ) throws OAException
  {
    String apiName   = "updateShippedQuantity";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                  );
    sb.append("  UPDATE xxinv_mov_req_instr_lines xmril "               ); // �ړ��˗�/�w�����׃A�h�I��
    sb.append("  SET    xmril.shipped_quantity  = TO_NUMBER(:1) "       ); // 1.�o�Ɏ��ѐ���
    sb.append("        ,xmril.last_updated_by   = FND_GLOBAL.USER_ID "  ); // �ŏI�X�V��
    sb.append("        ,xmril.last_update_date  = SYSDATE "             ); // �ŏI�X�V��
    sb.append("        ,xmril.last_update_login = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C��
    sb.append("  WHERE xmril.mov_line_id = :2; "                        ); // 2.�ړ�����ID
    sb.append("END; "                                                   );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, shippedQty);                       // �o�Ɏ��ѐ���
      cstmt.setInt   (2, XxcmnUtility.intValue(movLineId)); // �ړ�����ID

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
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
   * �ړ��˗�/�w�����׃A�h�I���̓��Ɏ��ѐ��ʂ��X�V���郁�\�b�h�ł��B
   * @param trans        - �g�����U�N�V����
   * @param movLineId    - �ړ��˗�/�w�����׃A�h�I��ID
   * @param shipToQty    - ���Ɏ��ѐ���
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void updateShipToQuantity(
    OADBTransaction trans,
     Number movLineId,
     String shipToQty
  ) throws OAException
  {
    String apiName   = "updateShipToQuantity";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                  );
    sb.append("  UPDATE xxinv_mov_req_instr_lines xmril "               ); // �ړ��˗�/�w�����׃A�h�I��
    sb.append("  SET    xmril.ship_to_quantity  = TO_NUMBER(:1) "       ); // 1.���Ɏ��ѐ���
    sb.append("        ,xmril.last_updated_by   = FND_GLOBAL.USER_ID "  ); // �ŏI�X�V��
    sb.append("        ,xmril.last_update_date  = SYSDATE "             ); // �ŏI�X�V��
    sb.append("        ,xmril.last_update_login = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C��
    sb.append("  WHERE xmril.mov_line_id = :2; "                        ); // 2.�ړ�����ID
    sb.append("END; "                                                   );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, shipToQty);                        // ���Ɏ��ѐ���
      cstmt.setInt   (2, XxcmnUtility.intValue(movLineId)); // �ړ�����ID

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
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        // PLSQL�N���[�Y
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
   * �o�Ɏ��ѐ��ʂ܂��͓��Ɏ��ѐ��ʂ����ׂēo�^����Ă��邩�ǂ����𔻒肷�郁�\�b�h�ł��B
   * @param trans         - �g�����U�N�V����
   * @param movHeaderId   - �ړ��w�b�_ID
   * @param mode          - 1:�o�Ɏ��ѐ��ʂ��`�F�b�N  2:���Ɏ��ѐ��ʂ��`�F�b�N
   * @return boolean      - true:���ׂēo�^��  false:���o�^����
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean isQuantityAllEntry(
    OADBTransaction trans,
     Number movHeaderId,
     String mode
  ) throws OAException
  {
    String apiName   = "isQuantityAllEntry";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                      );
    sb.append("  SELECT COUNT(1) "                          );
    sb.append("  INTO   :1 "                                ); // 1.���ѐ����o�^�J�E���g
    sb.append("  FROM   xxinv_mov_req_instr_lines xmril "   ); // �ړ��˗�/�w������
    sb.append("  WHERE xmril.mov_hdr_id = :2 "              ); // 2.�ړ��w�b�_ID
    // mode��1�̏ꍇ�A�o�Ɏ��ѐ��ʂ��`�F�b�N
    if ("1".equals(mode))
    {
      sb.append("  AND   xmril.shipped_quantity IS NULL "   ); // �o�Ɏ��ѐ���      

    // mode��2�̏ꍇ�A���Ɏ��ѐ��ʂ��`�F�b�N
    } else
    {
      sb.append("  AND   xmril.ship_to_quantity IS NULL "  ); // ���Ɏ��ѐ���      
    }
    sb.append("  AND   ROWNUM = 1; "                        );
    sb.append("END; "                                       );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt   (2, XxcmnUtility.intValue(movHeaderId)); // �ړ��w�b�_ID

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
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // isQuantityAllEntry

  /*****************************************************************************
   * �ړ��˗�/�w���w�b�_�̃X�e�[�^�X���X�V���郁�\�b�h�ł��B
   * @param trans          - �g�����U�N�V����
   * @param movHeaderId    - �ړ��w�b�_ID
   * @param status      - �X�e�[�^�X
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void updateStatus(
    OADBTransaction trans,
     Number movHeaderId,
     String status
  ) throws OAException
  {
    String apiName   = "updateStatus";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                  );
    sb.append("  UPDATE xxinv_mov_req_instr_headers xmrih "             ); // �ړ��˗�/�w���w�b�_
    sb.append("  SET    xmrih.status        = :1 "                      ); // 1.�X�e�[�^�X
    sb.append("        ,xmrih.last_updated_by   = FND_GLOBAL.USER_ID "  ); // �ŏI�X�V��
    sb.append("        ,xmrih.last_update_date  = SYSDATE "             ); // �ŏI�X�V��
    sb.append("        ,xmrih.last_update_login = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C��
    sb.append("  WHERE xmrih.mov_hdr_id         = :2; "                 ); // 2.�ړ��w�b�_ID
    sb.append("END; "                                                   );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, status);                             // �X�e�[�^�X
      cstmt.setInt   (2, XxcmnUtility.intValue(movHeaderId)); // �ړ��w�b�_ID

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
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updateStatus

  /*****************************************************************************
   * �ړ��˗�/�w���w�b�_�̎��ђ����t���O��Y�ɍX�V���郁�\�b�h�ł��B
   * @param trans          - �g�����U�N�V����
   * @param movHeaderId    - �ړ��w�b�_ID
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void updateCorrectActualFlg(
    OADBTransaction trans,
     Number movHeaderId
  ) throws OAException
  {
    String apiName   = "updateCorrectActualFlg";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                  );
    sb.append("  UPDATE xxinv_mov_req_instr_headers xmrih "             ); // �ړ��˗�/�w���w�b�_
    sb.append("  SET    xmrih.correct_actual_flg = 'Y' "                ); // ���ђ����t���O
    sb.append("        ,xmrih.last_updated_by    = FND_GLOBAL.USER_ID "  ); // �ŏI�X�V��
    sb.append("        ,xmrih.last_update_date   = SYSDATE "             ); // �ŏI�X�V��
    sb.append("        ,xmrih.last_update_login  = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C��
    sb.append("  WHERE xmrih.mov_hdr_id          = :1; "                 ); // 1.�ړ��w�b�_ID
    sb.append("END; "                                                   );
  
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1, XxcmnUtility.intValue(movHeaderId)); // �ړ��w�b�_ID

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
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        // PLSQL�N���[�Y
        cstmt.close();
      
      //CLOSE�������ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updateCorrectActualFlg

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
      cstmt.setInt(2, XxcmnUtility.intValue(movLineId)); // �󒍖��׃A�h�I��ID
      cstmt.setString(3, documentTypeCode);              // �����^�C�v
      cstmt.setString(4, recordTypeCode);                // ���R�[�h�^�C�v
      cstmt.setInt(5, XxcmnUtility.intValue(lotId));     // ���b�gID
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.INTEGER);
      
      // PL/SQL���s
      cstmt.execute();

      return new Number(cstmt.getInt(1));  // ���ѐ��ʂ�Ԃ��B

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getActualQuantity
// 2008-07-10 H.Itou ADD START

 /*****************************************************************************
   * �ړ��˗�/�w���w�b�_�A�h�I�����������g�̃R���J�����g�N���ɂ��X�V���ꂽ���ǂ����`�F�b�N���郁�\�b�h�ł��B
   * @param trans          - �g�����U�N�V����
   * @param movHeaderId    - �w�b�_ID
   * @param concName       - �R���J�����g��
   * @return boolean  - true:�������N�������R���J�����g���X�V����Ă���
   *                   - false:�������N�������R���J�����g���X�V����Ă��Ȃ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean isMovHdrUpdForOwnConc(
    OADBTransaction trans,
    Number movHeaderId,
    String concName
  ) throws OAException
  {
    String apiName     = "isMovHdrUpdForOwnConc";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);

    sb.append("BEGIN                                                                        ");
    sb.append("  SELECT TO_CHAR(COUNT(1))                                                   ");
    sb.append("  INTO   :1                                                                  "); // 1:����
    sb.append("  FROM   xxinv_mov_req_instr_headers xmrih                                   "); // �ړ��˗�/�w���w�b�_�A�h�I��
    sb.append("  WHERE  xmrih.mov_hdr_id  = :2                                              "); // 2:�w�b�_ID
    sb.append("  AND    xmrih.last_updated_by  = FND_GLOBAL.USER_ID                         "); // ���[�U�[ID
    sb.append("  AND    xmrih.last_update_date = xmrih.program_update_date                  "); // �ŏI�X�V���ƃv���O�����X�V��������
    sb.append("  AND    EXISTS (                                                            "); // �w�肵���R���J�����g�ōX�V���ꂽ���R�[�h
    sb.append("           SELECT 1                                                          ");
    sb.append("           FROM   fnd_concurrent_programs     fcp                            "); // �R���J�����g�v���O�����e�[�u��
    sb.append("           WHERE  fcp.concurrent_program_name = :3                           "); // 3:�R���J�����g��
    sb.append("           AND    fcp.concurrent_program_id   = xmrih.program_id             "); // �R���J�����g�v���O����ID
    sb.append("           AND    fcp.application_id          = xmrih.program_application_id "); // �A�v���P�[�V����ID
    sb.append("           )                                                                 ");
    sb.append("  AND    ROWNUM = 1;                                                         ");
    sb.append("END;                                                                         ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    { 
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR);
      
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(movHeaderId));   // �w�b�_ID
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
        XxinvUtility.rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        XxinvUtility.rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // isMovHdrUpdForOwnConc

 /*****************************************************************************
   * �ړ��˗�/�w�����׃A�h�I�����������g�̃R���J�����g�N���ɂ��X�V���ꂽ���ǂ����`�F�b�N���郁�\�b�h�ł��B
   * @param trans          - �g�����U�N�V����
   * @param movLineId      - ����ID
   * @param concName       - �R���J�����g��
   * @return boolean   - true:�������N�������R���J�����g���X�V����Ă���
   *                   - false:�������N�������R���J�����g���X�V����Ă��Ȃ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean isMovLineUpdForOwnConc(
    OADBTransaction trans,
    Number movLineId,
    String concName
  ) throws OAException
  {
    String apiName     = "isMovLineUpdForOwnConc";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);

    sb.append("BEGIN                                                                        ");
    sb.append("  SELECT TO_CHAR(COUNT(1))                                                   ");
    sb.append("  INTO   :1                                                                  "); // 1:����
    sb.append("  FROM   xxinv_mov_req_instr_lines xmril                                     "); // �ړ��˗�/�w�����׃A�h�I��
    sb.append("  WHERE  xmril.mov_line_id  = :2                                             "); // 2:����ID
    sb.append("  AND    xmril.last_updated_by  = FND_GLOBAL.USER_ID                         "); // ���[�U�[ID
    sb.append("  AND    xmril.last_update_date = xmril.program_update_date                  "); // �ŏI�X�V���ƃv���O�����X�V��������
    sb.append("  AND    EXISTS (                                                            "); // �w�肵���R���J�����g�ōX�V���ꂽ���R�[�h
    sb.append("           SELECT 1                                                          ");
    sb.append("           FROM   fnd_concurrent_programs     fcp                            "); // �R���J�����g�v���O�����e�[�u��
    sb.append("           WHERE  fcp.concurrent_program_name = :3                           "); // 3:�R���J�����g��
    sb.append("           AND    fcp.concurrent_program_id   = xmril.program_id             "); // �R���J�����g�v���O����ID
    sb.append("           AND    fcp.application_id          = xmril.program_application_id "); // �A�v���P�[�V����ID
    sb.append("           )                                                                 ");
    sb.append("  AND    ROWNUM = 1;                                                         ");
    sb.append("END;                                                                         ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    { 
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.VARCHAR);
      
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(movLineId));     // ����ID
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
        XxinvUtility.rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        XxinvUtility.rollBack(trans);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // isMovLineUpdForOwnConc
// 2008-07-10 H.Itou ADD END
}