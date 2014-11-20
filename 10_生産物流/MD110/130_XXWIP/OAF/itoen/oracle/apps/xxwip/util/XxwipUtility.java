/*============================================================================
* �t�@�C���� : XxwipUtility
* �T�v����   : ���Y���ʊ֐�
* �o�[�W���� : 1.2
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2007-11-09 1.0  ��r���     �V�K�쐬
* 2008-06-27 1.1  ��r���     add���\�b�h�ǉ�
* 2008-10-31 1.2  ��r���     �݌ɉ�v�N���[�Y�֐��ǉ�
*============================================================================
*/
package itoen.oracle.apps.xxwip.util;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxwip.util.XxwipConstants;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
/***************************************************************************
 * ���Y���ʊ֐��N���X�ł��B
 * @author  ORACLE ��r ���
 * @version 1.2
 ***************************************************************************
 */
public class XxwipUtility 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwipUtility()
  {
  }

  /*****************************************************************************
   * �ܖ��������̎Z�o���s���܂��B
	 * @param trans - �g�����U�N�V����
   * @param itemId - �i��ID
   * @param MakerDate - ���Y��
   * @return Date �ܖ�������
   ****************************************************************************/
  public static Date getExpirationDate(
    OADBTransaction trans,
    Number itemId,
    Date MakerDate
  ) throws OAException
  {
    String apiName      = "getExpirationDate";
    Date expirationDate = null;
    // �i��ID�A���Y����Null�̏ꍇ�͏������s��Ȃ��B
    if (XxcmnUtility.isBlankOrNull(itemId) 
      || XxcmnUtility.isBlankOrNull(MakerDate)) 
    {
      return null;
    }
    // PL/SQL�̍쐬���擾���s���܂�
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN ");
    sb.append("	 SELECT :1 + NVL(ximv.expiration_day, 0) ");
    sb.append("	 INTO   :2 ");
    sb.append("	 FROM   xxcmn_item_mst2_v ximv       ");
    sb.append("	 WHERE  ximv.item_id           = :3  ");
    sb.append("	 AND    ximv.start_date_active<= :4  ");
    sb.append("	 AND    ximv.end_date_active  >= :5; ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setDate(i++, XxcmnUtility.dateValue(MakerDate));
      cstmt.registerOutParameter(i++, Types.DATE);
      cstmt.setInt(i++, XxcmnUtility.intValue(itemId));
      cstmt.setDate(i++, XxcmnUtility.dateValue(MakerDate));
      cstmt.setDate(i++, XxcmnUtility.dateValue(MakerDate));
      cstmt.execute();
      expirationDate = new Date(cstmt.getDate(2));

    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
      XxcmnUtility.writeLog(trans,
                            XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return expirationDate;
	} // getExpirationDate

  /*****************************************************************************
   * ������ǉ����܂��B
	 * @param trans - �g�����U�N�V����
   * @param row - �s�N���X
   * @param params - �p�����[�^
   * @param tabType - �^�u�^�C�v�@0�F�����A1�F�ō��A2�F���Y��
   * @return �����t���O true�F�������s�Afalse�F���������s
   ****************************************************************************/
  public static boolean insertMaterialLine(
    OADBTransaction trans,
    OARow row,
    HashMap params,
    String tabType
  ) throws OAException
  {
    String apiName      = "insertMaterialLine";
    boolean insertFlag  = false;
    Number  batchId     = (Number)params.get("batchId");
    String  itemUm      = (String)params.get("itemUm");
    Number  itemId      = (Number)params.get("itemId");
    Number  lineType    = (Number)params.get("lineType");
    String  entityInner = (String)params.get("entityInner");
    String  type        = (String)params.get("type");
    String  rank1       = (String)params.get("rank1");
    String  rank2       = (String)params.get("rank2");
    String  slit        = (String)params.get("slit");
    String  utkType     = (String)params.get("utkType");
    Number  mtlDtlId    = null; 
    Date    productDate    = (Date)params.get("productDate");
    Date    makerDate      = (Date)params.get("makerDate");
    Date    expirationDate = (Date)params.get("expirationDate");

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lr_material_detail_in   gme_material_details%ROWTYPE; ");
    sb.append("  lr_material_detail_out  gme_material_details%ROWTYPE; ");
    sb.append("BEGIN ");
    sb.append("  lr_material_detail_in.batch_id   := :1;  ");// �o�b�`ID   
    sb.append("  lr_material_detail_in.item_id    := :2;  ");// �i��ID    
    sb.append("  lr_material_detail_in.item_um    := :3;  ");// �P��      
    sb.append("  lr_material_detail_in.line_type  := :4;  ");// ���C���^�C�v
    sb.append("  lr_material_detail_in.attribute5 := :5;  ");// �ō��敪   
    sb.append("  lr_material_detail_in.attribute8 := :6;  ");// ������     
    sb.append("  lr_material_detail_in.attribute6 := :7;  ");// �݌ɓ���     
    sb.append("  lr_material_detail_in.attribute1 := :8;  ");// �^�C�v     
    sb.append("  lr_material_detail_in.attribute2 := :9;  ");// �����N�P     
    sb.append("  lr_material_detail_in.attribute3 := :10; ");// �����N�Q    
    sb.append("  lr_material_detail_in.attribute10:= TO_CHAR(:11,'YYYY/MM/DD'); "); // �ܖ�������
    sb.append("  lr_material_detail_in.attribute11:= TO_CHAR(:12,'YYYY/MM/DD'); "); // ���Y��
    sb.append("  lr_material_detail_in.attribute17:= TO_CHAR(:13,'YYYY/MM/DD'); "); // ������
    sb.append("  xxwip_common_pkg.insert_material_line (  ");
    sb.append("    lr_material_detail_in  ");
    sb.append("   ,lr_material_detail_out ");
    sb.append("   ,:14  ");
    sb.append("   ,:15  ");
    sb.append("   ,:16  ");
    sb.append("  ); ");
    sb.append("  :17 := lr_material_detail_out.attribute6; ");
    sb.append("  :18 := lr_material_detail_out.material_detail_id; ");
    sb.append("  :19 := lr_material_detail_out.attribute1; ");
    sb.append("  :20 := lr_material_detail_out.attribute2; ");
    sb.append("  :21 := lr_material_detail_out.attribute3; ");
    sb.append("END; ");
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setInt(i++, XxcmnUtility.intValue(batchId));
      cstmt.setInt(i++, XxcmnUtility.intValue(itemId));
      cstmt.setString(i++, itemUm);
      cstmt.setInt(i++, XxcmnUtility.intValue(lineType));
      cstmt.setString(i++, utkType);
      cstmt.setString(i++, slit);
      cstmt.setString(i++, entityInner);
      cstmt.setString(i++, type);
      cstmt.setString(i++, rank1);
      cstmt.setString(i++, rank2);
      // ���Y���̏ꍇ
      if (XxwipConstants.LINE_TYPE_CO_PROD.equals(lineType.stringValue())) 
      {
        cstmt.setDate(i++, XxcmnUtility.dateValue(expirationDate));
        cstmt.setDate(i++, XxcmnUtility.dateValue(productDate));
        cstmt.setDate(i++, XxcmnUtility.dateValue(makerDate));
      // �����i�̏ꍇ
      } else 
      {
        cstmt.setNull(i++, Types.DATE);
        cstmt.setNull(i++, Types.DATE);
        cstmt.setNull(i++, Types.DATE);
      }      
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000); 
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1); 
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000); 
      cstmt.registerOutParameter(i++, Types.VARCHAR); 
      cstmt.registerOutParameter(i++, Types.INTEGER); 
      cstmt.registerOutParameter(i++, Types.VARCHAR); 
      cstmt.registerOutParameter(i++, Types.VARCHAR); 
      cstmt.registerOutParameter(i++, Types.VARCHAR); 

      cstmt.execute();

      if (XxcmnConstants.API_RETURN_NORMAL.equals(cstmt.getString(15))) 
      {
        insertFlag = true;
        if (XxwipConstants.TAB_TYPE_CO_PROD.equals(tabType)) 
        {
          entityInner = cstmt.getString(17);
          mtlDtlId    = new Number(cstmt.getInt(18));
          type  = cstmt.getString(19);
          rank1 = cstmt.getString(20);
          rank2 = cstmt.getString(21);
          row.setAttribute("EntityInner", entityInner);  
          row.setAttribute("MaterialDetailId", mtlDtlId);  
          row.setAttribute("Type",  type);  
          row.setAttribute("Rank1", rank1);  
          row.setAttribute("Rank2", rank2);  
        }
      } else
      {
        // ���[���o�b�N
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        // API�G���[���o�͂���B
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(14) + cstmt.getString(16),
                              6);
        //�g�[�N���𐶐����܂��B
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "�����ǉ��֐�") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                               XxwipConstants.XXWIP10049, 
                               tokens);
      }
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
      XxcmnUtility.writeLog(trans,
                            XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return insertFlag;
	} // insertMaterialLine

  /*****************************************************************************
   * �������X�V���܂��B
	 * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @return �����t���O true�F�������s�Afalse�F���������s
   ****************************************************************************/
  public static boolean updateMaterialLine(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName         = "updateMaterialLine";
    boolean exeFlag        = false;
    Number  mtlDtlId       = (Number)params.get("mtlDtlId");
    Number  lineType       = (Number)params.get("lineType");
    String  type           = (String)params.get("type");
    String  rank1          = (String)params.get("rank1");
    String  rank2          = (String)params.get("rank2");
    String  mtlDesc        = (String)params.get("mtlDesc");
    String  entityInner    = (String)params.get("entityInner");
    Date    productDate    = (Date)params.get("productDate");
    Date    makerDate      = (Date)params.get("makerDate");
    Date    expirationDate = (Date)params.get("expirationDate");
    String  trustCalcType  = (String)params.get("trustCalcType");
    String  othersCost     = (String)params.get("othersCost");
    String  trustProcUnitPrice = (String)params.get("trustProcUnitPrice");

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lr_material_detail gme_material_details%ROWTYPE; ");
    sb.append("BEGIN ");
    sb.append("  lr_material_detail.material_detail_id := :1;  "); // ���Y�����ڍ�
    sb.append("  lr_material_detail.line_type          := :2;  "); // ���C���^�C�v
    sb.append("  lr_material_detail.attribute1         := :3;  "); // �^�C�v
    sb.append("  lr_material_detail.attribute2         := :4;  "); // �����N�P
    sb.append("  lr_material_detail.attribute3         := :5;  "); // �����N�Q
    sb.append("  lr_material_detail.attribute6         := :6;  "); // �݌ɓ���
    sb.append("  lr_material_detail.attribute4         := :7;  "); // �E�v
    sb.append("  lr_material_detail.attribute9         := :8;  "); // �ϑ����H�P��
    sb.append("  lr_material_detail.attribute10        := TO_CHAR(:9,'YYYY/MM/DD');  "); // �ܖ�������
    sb.append("  lr_material_detail.attribute11        := TO_CHAR(:10,'YYYY/MM/DD'); "); // ���Y��
    sb.append("  lr_material_detail.attribute14        := :11; "); // �ϑ��v�Z�敪
    sb.append("  lr_material_detail.attribute16        := :12; "); // ���̑����z
    sb.append("  lr_material_detail.attribute17        := TO_CHAR(:13,'YYYY/MM/DD'); "); // ������
    sb.append("  xxwip_common_pkg.update_material_line(  ");
    sb.append("    lr_material_detail ");
    sb.append("   ,:14  ");
    sb.append("   ,:15  ");
    sb.append("   ,:16  ");
    sb.append("  ); ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setInt(i++, XxcmnUtility.intValue(mtlDtlId));
      cstmt.setInt(i++, XxcmnUtility.intValue(lineType));
      cstmt.setString(i++, type);
      cstmt.setString(i++, rank1);
      cstmt.setString(i++, rank2);
      cstmt.setString(i++, entityInner);
      // �����i�̏ꍇ
      if (XxwipConstants.LINE_TYPE_PROD.equals(lineType.stringValue())) 
      {
        cstmt.setString(i++, mtlDesc);
        cstmt.setString(i++, trustProcUnitPrice);
        cstmt.setDate(i++, XxcmnUtility.dateValue(expirationDate));
        cstmt.setDate(i++, XxcmnUtility.dateValue(productDate));
        cstmt.setString(i++, trustCalcType);
        cstmt.setString(i++, othersCost);
        cstmt.setDate(i++, XxcmnUtility.dateValue(makerDate));
      // ���Y���̏ꍇ
      } else 
      {
        cstmt.setNull(i++, Types.VARCHAR);
        cstmt.setNull(i++, Types.VARCHAR);
        cstmt.setNull(i++, Types.DATE);
        cstmt.setNull(i++, Types.DATE);
        cstmt.setNull(i++, Types.VARCHAR);
        cstmt.setNull(i++, Types.INTEGER);
        cstmt.setNull(i++, Types.DATE);
      }      
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000); 
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1); 
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000); 

      cstmt.execute();

      if (XxcmnConstants.API_RETURN_NORMAL.equals(cstmt.getString(15))) 
      {
        exeFlag = true;
      } else
      {
        // ���[���o�b�N
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        // API�G���[���o�͂���B
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(14) + cstmt.getString(16),
                              6);
        //�g�[�N���𐶐����܂��B
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "�����X�V�֐�") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                              XxwipConstants.XXWIP10049, 
                              tokens);
      }
    } catch(SQLException s)
    {

      // ���[���o�b�N
      rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
      XxcmnUtility.writeLog(trans,
                            XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return exeFlag;
	} // updateMaterialLine

  /*****************************************************************************
   * �����̒ǉ����s���܂��B
	 * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @param lineType - ���C���^�C�v�@1�F�����i�A2�F���Y��
   * @return �����t���O true�F�������s�Afalse�F���������s
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean insertLineAllocation(
    OADBTransaction trans,
    HashMap params,
    String lineType
  ) throws OAException 
  {
    String apiName      = "insertLineAllocation";
    boolean executeFlag = false;
    Number batchId      = (Number)params.get("batchId");
    Number mtlDtlId     = (Number)params.get("mtlDtlId");
    Number lotId        = (Number)params.get("lotId");
    String actualQty    = (String)params.get("actualQty");
    Date   productDate  = (Date)params.get("productDate");
    String location     = (String)params.get("location");
    String whseCode     = (String)params.get("whseCode");
    
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lr_tran_row_in  gme_inventory_txns_gtmp%ROWTYPE; ");
    sb.append("BEGIN ");
    sb.append("  lr_tran_row_in.doc_id             := :1; ");    // �o�b�`ID
    sb.append("  lr_tran_row_in.lot_id             := :2; ");    // ���b�gID
    sb.append("  lr_tran_row_in.trans_qty          := :3; ");    // ��������
    sb.append("  lr_tran_row_in.trans_date         := :4; ");    // �������t
    sb.append("  lr_tran_row_in.location           := :5; ");    // �ۊǑq��
    sb.append("  lr_tran_row_in.completed_ind      := :6; ");    // �����t���O
    sb.append("  lr_tran_row_in.material_detail_id := :7; ");    // ���Y�����ڍ�ID
    sb.append("  lr_tran_row_in.whse_code          := :8; ");    // �q�ɃR�[�h
    sb.append("  xxwip_common_pkg.insert_line_allocation ( ");
    sb.append("    ir_tran_row_in  => lr_tran_row_in ");
    sb.append("   ,ov_errbuf       => :9  ");
    sb.append("   ,ov_retcode      => :10  ");
    sb.append("   ,ov_errmsg       => :11 ");
    sb.append("  ); ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {

      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setInt(i++, XxcmnUtility.intValue(batchId));
      cstmt.setInt(i++, XxcmnUtility.intValue(lotId));
      cstmt.setString(i++, actualQty);
      cstmt.setDate(i++, XxcmnUtility.dateValue(productDate));
      cstmt.setString(i++, location);
      cstmt.setInt(i++, 1);
      cstmt.setInt(i++, XxcmnUtility.intValue(mtlDtlId));
      cstmt.setString(i++, whseCode);
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000); 
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1); 
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000); 

      cstmt.execute();

      if (XxcmnConstants.API_RETURN_NORMAL.equals(cstmt.getString(10))) 
      {
        executeFlag = true;
      } else
      {
        // ���[���o�b�N
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(9) + cstmt.getString(11),
                              6);
        // �G���[���X���[
        //�g�[�N���𐶐����܂��B
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "�����ǉ��֐�") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                              XxwipConstants.XXWIP10049, 
                              tokens);
      }
    } catch (SQLException s) 
    {
      // ���[���o�b�N
      rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
      XxcmnUtility.writeLog(trans,
                            XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
    return executeFlag;
  } // insertLineAllocation
  
  /*****************************************************************************
   * �����̍X�V���s���܂��B
	 * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @param lineType - ���C���^�C�v�@1�F�����i�A2�F���Y���A-1�F�����i
   * @return �����t���O true�F�������s�Afalse�F���������s
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean updateLineAllocation(
    OADBTransaction trans,
    HashMap params,
    String lineType
  ) throws OAException 
  {
    String apiName      = "updateLineAllocation";
    boolean executeFlag = false;
    Number batchId      = (Number)params.get("batchId");
    Number transId      = (Number)params.get("transId");
    Number lotId        = (Number)params.get("lotId");
    String actualQty    = (String)params.get("actualQty");
    Date   productDate  = (Date)params.get("productDate");
    String completedInd = (String)params.get("completedInd");

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lr_tran_row_in  gme_inventory_txns_gtmp%ROWTYPE; ");
    sb.append("BEGIN ");
    sb.append("  lr_tran_row_in.trans_id      := :1; ");    // ����ID
    sb.append("  lr_tran_row_in.lot_id        := :2; ");    // ���b�gID
    sb.append("  lr_tran_row_in.trans_qty     := :3; ");    // ��������
    sb.append("  lr_tran_row_in.trans_date    := :4; ");    // �������t
    sb.append("  lr_tran_row_in.doc_id        := :5; ");    // �o�b�`ID
    sb.append("  lr_tran_row_in.completed_ind := :6; ");    // �����t���O
    sb.append("  xxwip_common_pkg.update_line_allocation (  ");
    sb.append("    ir_tran_row_in  => lr_tran_row_in ");
    sb.append("   ,ov_errbuf       => :7 ");
    sb.append("   ,ov_retcode      => :8 ");
    sb.append("   ,ov_errmsg       => :9 ");
    sb.append("  ); ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {

      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setInt(i++, XxcmnUtility.intValue(transId));
      cstmt.setInt(i++, XxcmnUtility.intValue(lotId));
      cstmt.setString(i++, actualQty);
      cstmt.setDate(i++, XxcmnUtility.dateValue(productDate));
      cstmt.setInt(i++, XxcmnUtility.intValue(batchId));
      if (XxcmnConstants.STRING_ZERO.equals(completedInd)) 
      {
        cstmt.setInt(i++, 0);
      } else 
      {
        cstmt.setInt(i++, 1);
      }
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1); 
      
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);
      
      cstmt.execute();

      if (XxcmnConstants.API_RETURN_NORMAL.equals(cstmt.getString(8))) 
      {
        executeFlag = true;
      } else
      {
        // ���[���o�b�N
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(7) + cstmt.getString(9),
                              6);
        //�g�[�N���𐶐����܂��B
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "�����X�V�֐�") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                              XxwipConstants.XXWIP10049, 
                              tokens);
      }
    } catch (SQLException s) 
    {
      // ���[���o�b�N
      rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
      XxcmnUtility.writeLog(trans,
                            XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }        
    return executeFlag;
  } // updateLineAllocation

  /*****************************************************************************
   * �����̍폜���s���܂��B
	 * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @param lineType - ���C���^�C�v�@1�F�����i�A2�F���Y��
   * @return �����t���O true�F�������s�Afalse�F���������s
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean deleteLineAllocation(
    OADBTransaction trans,
    HashMap params,
    String lineType
  ) throws OAException 
  {
    String  apiName     = "deleteLineAllocation";
    boolean executeFlag = false;
    Number  batchId     = (Number)params.get("batchId");
    Number  transId     = (Number)params.get("transId");

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lr_tran_row_in  gme_inventory_txns_gtmp%ROWTYPE; ");
    sb.append("BEGIN ");
    sb.append("  lr_tran_row_in.trans_id := :1; ");    // ����ID
    sb.append("  lr_tran_row_in.doc_id   := :2; ");    // �o�b�`ID
    sb.append("  xxwip_common_pkg.delete_line_allocation (  ");
    sb.append("    ir_tran_row_in  => lr_tran_row_in ");
    sb.append("   ,ov_errbuf       => :3 ");
    sb.append("   ,ov_retcode      => :4 ");
    sb.append("   ,ov_errmsg       => :5 ");
    sb.append("  ); ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {

      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setInt(i++, XxcmnUtility.intValue(transId));
      cstmt.setInt(i++, XxcmnUtility.intValue(batchId));
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1); 
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);
      
      cstmt.execute();

      if (XxcmnConstants.API_RETURN_NORMAL.equals(cstmt.getString(4))) 
      {
        executeFlag = true;
      } else
      {
        // ���[���o�b�N
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(3) + cstmt.getString(5),
                              6);
        //�g�[�N���𐶐����܂��B
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "�����폜�֐�") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                              XxwipConstants.XXWIP10049, 
                              tokens);
      }
        
    } catch (SQLException s) 
    {
      // ���[���o�b�N
      rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
      XxcmnUtility.writeLog(trans,
                            XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }        
    return executeFlag;
  } // deleteLineAllocation

  /*****************************************************************************
   * �X�e�[�^�X�̍X�V���s���܂��B
	 * @param trans - �g�����U�N�V����
   * @param batchId - �o�b�`ID
   * @param dutyStatus - �X�V�X�e�[�^�X
   * @return �����t���O true�F�������s�Afalse�F���������s
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean updateStatus(
    OADBTransaction trans,
    Number batchId,
    String dutyStatus
  ) throws OAException 
  {
    String apiName  = "updateStatus";
    boolean exeFlag = false;
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  xxwip_common_pkg.update_duty_status( ");
    sb.append("    in_batch_id    => :1 ");
    sb.append("   ,iv_duty_status => :2 ");
    sb.append("   ,ov_errbuf      => :3 ");
    sb.append("   ,ov_retcode     => :4 ");
    sb.append("   ,ov_errmsg      => :5 ");
    sb.append("  ); ");
    sb.append("END; ");
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setInt(i++, XxcmnUtility.intValue(batchId));
      cstmt.setString(i++, dutyStatus);
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1); 
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);

      cstmt.execute();

      if (XxcmnConstants.API_RETURN_NORMAL.equals(cstmt.getString(4))) 
      {
        exeFlag = true;
        
      } else 
      {
        // ���[���o�b�N
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(3) + cstmt.getString(5),
                              6);
        //�g�[�N���𐶐����܂��B
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "�Ɩ��X�e�[�^�X�X�V�֐�") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                               XxwipConstants.XXWIP10049, 
                               tokens);
      }
    } catch (SQLException s) 
    {
      // ���[���o�b�N
      rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
      XxcmnUtility.writeLog(trans,
                            XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
    return exeFlag;
  } // updateStatus

  /*****************************************************************************
   * �����̍폜���s���܂��B
	 * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @return �����t���O true�F�������s�Afalse�F���������s
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean deleteMaterialLine(
    OADBTransaction trans,
    HashMap params
  ) throws OAException 
  {
    String  apiName = "deleteMaterialLine";
    boolean exeFlag = false;
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  xxwip_common_pkg.delete_material_line( ");
    sb.append("    in_batch_id   => :1 ");
    sb.append("   ,in_mtl_dtl_id => :2 ");
    sb.append("   ,ov_errbuf     => :3 ");
    sb.append("   ,ov_retcode    => :4 ");
    sb.append("   ,ov_errmsg     => :5 ");
    sb.append("  ); ");
    sb.append("END; ");
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      Number batchId  = new Number(params.get("batchId"));
      Number mtlDtlId = new Number(params.get("mtlDtlId"));
      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setInt(i++, XxcmnUtility.intValue(batchId));
      cstmt.setInt(i++, XxcmnUtility.intValue(mtlDtlId));
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1); 
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);

      cstmt.execute();

      if (XxcmnConstants.API_RETURN_NORMAL.equals(cstmt.getString(4))) 
      {
        exeFlag = true;
      } else 
      {
        // ���[���o�b�N
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(3) + cstmt.getString(5),
                              6);
        //�g�[�N���𐶐����܂��B
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "�����폜�֐�") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                               XxwipConstants.XXWIP10049, 
                               tokens);
      }
    } catch (SQLException s) 
    {
      // ���[���o�b�N
      rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
      XxcmnUtility.writeLog(trans,
                            XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
    return exeFlag;
  } // deleteMaterialLine

  /*****************************************************************************
   * ���Y�o�b�`�̃Z�[�u���s���܂��B
	 * @param trans - �g�����U�N�V����
   * @param batchId - �o�b�`ID
   * @return �����t���O true�F�������s�Afalse�F���������s
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean saveBatch(
    OADBTransaction trans,
    String batchId
  ) throws OAException 
  {
    String  apiName = "saveBatch";
    boolean exeFlag = false;
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lr_batch_save gme_batch_header%ROWTYPE; ");
    sb.append("BEGIN ");
    sb.append("  lr_batch_save.batch_id := :1;    ");
    sb.append("  GME_API_PUB.SAVE_BATCH( ");
    sb.append("    p_batch_header  => lr_batch_save    ");
    sb.append("   ,x_return_status => :2 ");
    sb.append("  ); ");
    sb.append("END; ");
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setInt(i++, Integer.parseInt(batchId));
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1); 

      cstmt.execute();

      if (XxcmnConstants.API_STATUS_SUCCESS.equals(cstmt.getString(2))) 
      {
        exeFlag = true;
      } else 
      {
        // ���[���o�b�N
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              "",
                              6);
        //�g�[�N���𐶐����܂��B
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "�o�b�`�Z�[�u�֐�") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                              XxwipConstants.XXWIP10049, 
                              tokens);
      }
        
    } catch (SQLException s) 
    {
      // ���[���o�b�N
      rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
      XxcmnUtility.writeLog(trans,
                            XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
    return exeFlag;
  } // saveBatch

  /*****************************************************************************
   * ���b�g�̓o�^�E�X�V���s���܂��B
	 * @param trans - �g�����U�N�V����
   * @param lotNoProd - ���Y�����b�gNo
   * @param row - OARow�I�u�W�F�N�g
   * @param lineType - ���C���^�C�v�@1�F�����i�A2�F���Y��
   * @param params - �p�����[�^
   * @return �����t���O true�F�������s�Afalse�F���������s
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean lotExecute(
    OADBTransaction trans,
    String  lotNoProd,
    OARow   row,
    String  lineType,
    HashMap params
  ) throws OAException 
  {
    String  apiName       = "lotExecute";
    boolean exeFlag       = false;
    String  itemNo        = (String)params.get("itemNo");
    String  qtType        = (String)params.get("qtType");
    String  type          = (String)params.get("type");
    String  rank1         = (String)params.get("rank1");
    String  rank2         = (String)params.get("rank2");
    String  materialDesc  = (String)params.get("materialDesc");
    String  lotNo         = (String)params.get("lotNo");    
    String  uniqueSign    = (String)params.get("uniqueSign");    
    String routingNo      = (String)params.get("routingNo");    
    String slipType       = (String)params.get("slipType");    
    String entityInner    = (String)params.get("entityInner");
    Number itemId         = (Number)params.get("itemId");
    Number lotId          = (Number)params.get("lotId");    
    Date makerDate        = (Date)params.get("makerDate");    
    Date expirationDate   = (Date)params.get("expirationDate");    
    String itemClassCode  = (String)params.get("itemClassCode");    

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lr_ic_lots_mst_in        ic_lots_mst%ROWTYPE; ");
    sb.append("  lr_ic_lots_mst_out       ic_lots_mst%ROWTYPE; ");
    sb.append("BEGIN ");
    sb.append("  lr_ic_lots_mst_in.item_id     := :1;   "); // �i�ڃR�[�h
    sb.append("  lr_ic_lots_mst_in.lot_id      := :2;   "); // ���b�gID
    sb.append("  lr_ic_lots_mst_in.attribute1  := :3;   "); // �����N����
    sb.append("  lr_ic_lots_mst_in.attribute2  := :4;   "); // �ŗL�L��
    sb.append("  lr_ic_lots_mst_in.attribute3  := :5;   "); // �ܖ�����
    sb.append("  lr_ic_lots_mst_in.attribute6  := :6;   "); // �݌ɓ���
    sb.append("  lr_ic_lots_mst_in.attribute13 := :7;   "); // �^�C�v
    sb.append("  lr_ic_lots_mst_in.attribute14 := :8;   "); // �����N�P
    sb.append("  lr_ic_lots_mst_in.attribute15 := :9;   "); // �^���N�Q
    sb.append("  lr_ic_lots_mst_in.attribute16 := :10;  "); // ���Y�`�[�敪
    sb.append("  lr_ic_lots_mst_in.attribute17 := :11;  "); // ���C��No
    if (XxwipConstants.LINE_TYPE_PROD.equals(lineType)) 
    {
      sb.append("lr_ic_lots_mst_in.attribute18 := :12;  "); // �E�v
    } else 
    {
      sb.append("lr_ic_lots_mst_in.lot_no      := :12;  "); // ���b�gNo
    }
    sb.append("  lr_ic_lots_mst_in.attribute23 := :13;  "); // ���b�g�X�e�[�^�X
    sb.append("  xxwip_common_pkg.lot_execute ( ");
    sb.append("    ir_lot_mst         => lr_ic_lots_mst_in  "); // OPM���b�g�}�X�^�e�[�u���ϐ�
    sb.append("   ,it_item_no         => :14                "); // �i�ڃR�[�h
    sb.append("   ,it_line_type       => :15                "); // ���C���^�C�v
    sb.append("   ,it_item_class_code => :16                "); // �i�ڋ敪
    sb.append("   ,it_lot_no_prod     => :17                "); // �����i���b�gNo
    sb.append("   ,or_lot_mst         => lr_ic_lots_mst_out "); // OPM���b�g�}�X�^�e�[�u���ϐ�
    sb.append("   ,ov_errbuf          => :18                ");
    sb.append("   ,ov_retcode         => :19                ");
    sb.append("   ,ov_errmsg          => :20                ");
    sb.append("  ); ");
    sb.append("  :21 := lr_ic_lots_mst_out.lot_no;      ");
    sb.append("  :22 := lr_ic_lots_mst_out.lot_id;      ");
    sb.append("  :23 := lr_ic_lots_mst_out.attribute13; ");
    sb.append("  :24 := lr_ic_lots_mst_out.attribute14; ");
    sb.append("  :25 := lr_ic_lots_mst_out.attribute15; ");
    sb.append("  :26 := lr_ic_lots_mst_out.attribute18; ");
    sb.append("END;    ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setInt(i++, XxcmnUtility.intValue(itemId));
      if (XxcmnUtility.isBlankOrNull(lotId)) 
      {
        cstmt.setNull(i++, Types.INTEGER);
      } else 
      {
        cstmt.setInt(i++, XxcmnUtility.intValue(lotId));
      }
      cstmt.setDate(i++, XxcmnUtility.dateValue(makerDate));
      cstmt.setString(i++, uniqueSign);
      cstmt.setDate(i++, XxcmnUtility.dateValue(expirationDate));
      cstmt.setString(i++, entityInner);
      cstmt.setString(i++, type);
      cstmt.setString(i++, rank1);
      cstmt.setString(i++, rank2);
      cstmt.setString(i++, slipType);
      cstmt.setString(i++, routingNo);
      if (XxwipConstants.LINE_TYPE_PROD.equals(lineType)) 
      {
        cstmt.setString(i++, materialDesc);
      } else
      {
        cstmt.setString(i++, lotNo);      
      }
      if (XxwipConstants.QT_TYPE_ON.equals(qtType)) 
      {
        cstmt.setString(i++, XxwipConstants.QT_STATUS_NON_JUDG); // ������
      } else 
      {
        cstmt.setString(i++, XxwipConstants.QT_STATUS_PASS); // ���i
      }
      cstmt.setString(i++, itemNo);
      cstmt.setInt(i++, Integer.parseInt(lineType)); 
      cstmt.setString(i++, itemClassCode); 
      cstmt.setString(i++, lotNoProd);
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000); 
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1); 
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000); 
      cstmt.registerOutParameter(i++, Types.VARCHAR, 10); 
      cstmt.registerOutParameter(i++, Types.INTEGER, 10); 
      cstmt.registerOutParameter(i++, Types.VARCHAR); 
      cstmt.registerOutParameter(i++, Types.VARCHAR); 
      cstmt.registerOutParameter(i++, Types.VARCHAR); 
      cstmt.registerOutParameter(i++, Types.VARCHAR); 
      cstmt.execute();

      // ����I���̏ꍇ
      if (XxcmnConstants.API_RETURN_NORMAL.equals(cstmt.getString(19))) 
      {
        exeFlag = true;
        lotNo        = cstmt.getString(21);
        lotId        = new Number(cstmt.getInt(22));
        type         = cstmt.getString(23);
        rank1        = cstmt.getString(24);
        rank2        = cstmt.getString(25);
        materialDesc = cstmt.getString(26);
        row.setAttribute("LotId", lotId);
        row.setAttribute("LotNo", lotNo);
        row.setAttribute("Type",  type);
        row.setAttribute("Rank1", rank1);
        row.setAttribute("Rank2", rank2);
        if (XxwipConstants.LINE_TYPE_PROD.equals(lineType)) 
        {
          row.setAttribute("MaterialDesc", materialDesc);
        }        
      // �ُ�I���̏ꍇ
      } else
      {
        // ���[���o�b�N
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(18) + cstmt.getString(20),
                              6);
        //�g�[�N���𐶐����܂��B
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "���b�g�ǉ��E�X�V�֐�") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                               XxwipConstants.XXWIP10049, 
                               tokens);
      }
    } catch (SQLException s) 
    {
      // ���[���o�b�N
      rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
      XxcmnUtility.writeLog(trans,
                            XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
    return exeFlag;
  } // lotExecute

  /*****************************************************************************
   * �݌ɒP���̍X�V���s���܂��B
	 * @param trans - �g�����U�N�V����
   * @param batchId - �o�b�`ID
   * @return boolean �����t���O true�F�������s�Afalse�F���������s
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean updateInvPrice(
    OADBTransaction trans,
    String batchId
  ) throws OAException 
  {
    String apiName  = "updateInvPrice";
    boolean exeFlag = false;
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lt_batch_id gme_batch_header.batch_id%TYPE; ");
    sb.append("BEGIN ");
    sb.append("  lt_batch_id := :1;    ");
    sb.append("  xxwip_common_pkg.update_inv_price ( ");
    sb.append("    it_batch_id        => lt_batch_id ");
    sb.append("   ,ov_errbuf          => :2          ");
    sb.append("   ,ov_retcode         => :3          ");
    sb.append("   ,ov_errmsg          => :4          ");
    sb.append("  ); ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setInt(i++, Integer.parseInt(batchId));
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1); 
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);

      cstmt.execute();

      if (XxcmnConstants.API_RETURN_NORMAL.equals(cstmt.getString(3))) 
      {
        exeFlag = true;
      } else 
      {
        // ���[���o�b�N
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(2) + cstmt.getString(4),
                              6);
        //�g�[�N���𐶐����܂��B
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "�݌ɒP���X�V�֐�") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                               XxwipConstants.XXWIP10049, 
                               tokens);
      }
    } catch (SQLException s) 
    {
      // ���[���o�b�N
      rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
      XxcmnUtility.writeLog(trans,
                            XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
    return exeFlag;
  } // updateInvPrice

  /*****************************************************************************
   * �ϑ����H��̍X�V���s���܂��B
	 * @param trans - �g�����U�N�V����
   * @param batchId - �o�b�`ID
   * @return boolean �����t���O true�F�������s�Afalse�F���������s
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean updateTrustPrice(
    OADBTransaction trans,
    String batchId
  ) throws OAException 
  {
    String apiName  = "updateTrustPrice";
    boolean exeFlag = false;
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lt_batch_id gme_batch_header.batch_id%TYPE; ");
    sb.append("BEGIN ");
    sb.append("  lt_batch_id := :1;    ");
    sb.append("  xxwip_common_pkg.update_trust_price ( ");
    sb.append("    it_batch_id        => lt_batch_id ");
    sb.append("   ,ov_errbuf          => :2          ");
    sb.append("   ,ov_retcode         => :3          ");
    sb.append("   ,ov_errmsg          => :4          ");
    sb.append("  ); ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setInt(i++, Integer.parseInt(batchId));
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1); 
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);

      cstmt.execute();

      if (XxcmnConstants.API_RETURN_NORMAL.equals(cstmt.getString(3))) 
      {
        exeFlag = true;
      } else 
      {
        // ���[���o�b�N
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(2) + cstmt.getString(4),
                              6);
        //�g�[�N���𐶐����܂��B
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "�ϑ����H��X�V�֐�") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                               XxwipConstants.XXWIP10049, 
                               tokens);
      }
    } catch (SQLException s) 
    {
      // ���[���o�b�N
      rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
      XxcmnUtility.writeLog(trans,
                            XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
    return exeFlag;
  } // updateTrustPrice

  /*****************************************************************************
   * ���o�Ɋ��Z�P�ʂ��擾���܂��B
	 * @param trans - �g�����U�N�V����
   * @param convType - �ϊ����@
   * @param itemId - �i��ID
   * @param baseTransQty - ���Z�O��������
   * @return String ���Z�㏈������
   ****************************************************************************/
  public static String getRcvShipQty(
    OADBTransaction trans,
    String convType,
    Number itemId,
    String baseTransQty
  ) throws OAException
  {
    String apiName  = "getRcvShipQty";
    String transQty = null;
    //PL/SQL�̍쐬���擾���s���܂�
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN ");
    sb.append("	 :1 := TO_CHAR(xxcmn_common_pkg.rcv_ship_conv_qty(:2, :3, TO_NUMBER(:4)), 'FM999999990.000'); ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.setString(i++, convType);
      cstmt.setInt(i++, XxcmnUtility.intValue(itemId));
      cstmt.setString(i++, baseTransQty);
      cstmt.execute();
      transQty = cstmt.getString(1);

    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
      XxcmnUtility.writeLog(trans,
                            XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return transQty;
	} // getRcvShipQty

  /*****************************************************************************
   * �i�������˗������쐬���܂��B
	 * @param trans - �g�����U�N�V����
   * @param disposalDiv - �����敪�@1�F�}���A2�F�X�V
   * @param lotId - ���b�gID
   * @param itemId - �i��ID
   * @param batchId - �o�b�`ID
   * @param qtNumber - �����˗�No
   ****************************************************************************/
  public static String doQtInspection(
    OADBTransaction trans,
    String disposalDiv,
    Number lotId,
    Number itemId,
    Number batchId,
    String qtNumber
  ) throws OAException
  {
    String apiName = "doQtInspection";
    String exeType = XxcmnConstants.RETURN_NOT_EXE;
    //PL/SQL�̍쐬���擾���s���܂�
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN ");
    sb.append("  xxwip_common_pkg.make_qt_inspection( ");
    sb.append("    it_division          => 1     "); // �敪�F���Y(�Œ�)
    sb.append("   ,iv_disposal_div      => :1    "); // �����敪
    sb.append("   ,it_lot_id            => :2    "); // ���b�gID
    sb.append("   ,it_item_id           => :3    "); // �i��ID
    sb.append("   ,iv_qt_object         => null  ");
    sb.append("   ,it_batch_id          => :4    "); // �o�b�`ID
    sb.append("   ,it_batch_po_id       => null  ");
    sb.append("   ,it_qty               => null  ");
    sb.append("   ,it_prod_dely_date    => null  ");
    sb.append("   ,it_vendor_line       => null  ");
    sb.append("   ,it_qt_inspect_req_no => :5    "); // �����˗�No
    sb.append("   ,ot_qt_inspect_req_no => :6    "); // �����˗�No
    sb.append("   ,ov_errbuf            => :7    ");
    sb.append("   ,ov_retcode           => :8    ");
    sb.append("   ,ov_errmsg            => :9    ");
    sb.append("  ); ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setString(i++, disposalDiv);
      cstmt.setInt(i++, XxcmnUtility.intValue(lotId));
      cstmt.setInt(i++, XxcmnUtility.intValue(itemId));
      cstmt.setInt(i++, XxcmnUtility.intValue(batchId));
      cstmt.setString(i++, qtNumber);
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000); 
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1); 
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000); 
      cstmt.execute();

      String retCode = cstmt.getString(8);
      if (XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {
        exeType = XxcmnConstants.RETURN_SUCCESS;
      } else if (XxcmnConstants.API_RETURN_WARN.equals(retCode))
      {
        exeType = XxcmnConstants.RETURN_WARN;
      // �ُ�I���̏ꍇ
      } else if (XxcmnConstants.API_RETURN_ERROR.equals(retCode)) 
      {
        // ���[���o�b�N
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(7) + cstmt.getString(9),
                              6);
        //�g�[�N���𐶐����܂��B
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "�i�������˗����쐬") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                               XxwipConstants.XXWIP10049, 
                               tokens);
      }
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
      XxcmnUtility.writeLog(trans,
                            XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return exeType;
	} // doQtInspection

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
    // �Z�[�u�|�C���g�܂Ń��[���o�b�N
    trans.executeCommand("ROLLBACK TO " + savePointName);
    // �R�~�b�g
    trans.commit();
  } // doRollBack

  /***************************************************************************
   * �l�P����l�Q�����Z���郁�\�b�h�ł��B
	 * @param value1 - �l�P
	 * @param value2 - �l�Q
   ***************************************************************************
   */
  public static String subtract(
    OADBTransaction trans,
    Object value1,
    Object value2)
  {
    String apiName = "subtract";
    try 
    {
      if (XxcmnUtility.isBlankOrNull(value1)) 
      {
        value1 = XxcmnConstants.STRING_ZERO;
      }
      if (XxcmnUtility.isBlankOrNull(value2)) 
      {
        value2 = XxcmnConstants.STRING_ZERO;
      }
      Number numA = new Number(value1);
      Number numB = new Number(value2);
      String subtractNum = numA.subtract(numB).toString();
      return subtractNum;
    } catch (SQLException s) 
    {
      XxcmnUtility.writeLog(trans,
                            XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      return XxcmnConstants.STRING_ZERO;
    }
  } // subtract

  /*****************************************************************************
   * �ړ����b�g�ڍׂւ̏����ݏ������s���܂��B
	 * @param trans - �g�����U�N�V����
   * @param params - �p�����[�^
   * @return �����t���O true�F�������s�Afalse�F���������s
   * @throws OAException - OA��O
   ****************************************************************************/
  public static void movLotExecute(
    OADBTransaction trans,
    HashMap params
  ) throws OAException 
  {
    String  apiName       = "movLotExecute";
    boolean executeFlag   = false;
    Number  mtlDtlId      = (Number)params.get("mtlDtlId");
    Number  movLotDtlId   = (Number)params.get("movLotDtlId");
    String  xmldActualQty = (String)params.get("xmldActualQty");
    String  actualQty     = (String)params.get("actualQty");
    String  itemNo        = (String)params.get("itemNo");
    String  lotNo         = (String)params.get("lotNo");    
    Number  itemId        = (Number)params.get("itemId");
    Number  lotId         = (Number)params.get("lotId");    
    Date    productDate   = (Date)params.get("productDate");    

    // ���b�g�ڍ�ID��Null�̏ꍇ
    if (XxcmnUtility.isBlankOrNull(movLotDtlId)) 
    {
      // �}������
      //PL/SQL�̍쐬���s���܂�
      StringBuffer insSb = new StringBuffer(1000);
      insSb.append("BEGIN ");
      insSb.append("  INSERT INTO xxinv_mov_lot_details( ");// �ړ����b�g�ڍ�
      insSb.append("    mov_lot_dtl_id            ");      // ���b�g�ڍ�ID
      insSb.append("   ,mov_line_id               ");      // ����ID
      insSb.append("   ,document_type_code        ");      // �����^�C�v
      insSb.append("   ,record_type_code          ");      // ���R�[�h�^�C�v
      insSb.append("   ,item_id                   ");      // �i��ID
      insSb.append("   ,item_code                 ");      // �i�ڃR�[�h
      insSb.append("   ,lot_id                    ");      // ���b�gID
      insSb.append("   ,lot_no                    ");      // ���b�gNo
      insSb.append("   ,actual_date               ");      // ���ѓ�
      insSb.append("   ,actual_quantity           ");      // ���ѐ���
      insSb.append("   ,created_by                ");      // �쐬��
      insSb.append("   ,creation_date             ");      // �쐬��
      insSb.append("   ,last_updated_by           ");      // �ŏI�X�V��
      insSb.append("   ,last_update_date          ");      // �ŏI�X�V��
      insSb.append("   ,last_update_login         ");      // �ŏI�X�V���O�C��
      insSb.append("   ,request_id                ");      // �v��ID
      insSb.append("   ,program_application_id    ");      // �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      insSb.append("   ,program_id                ");      // �R���J�����g�E�v���O����ID
      insSb.append("   ,program_update_date       ");      // �v���O�����X�V��
      insSb.append("  ) VALUES( ");
      insSb.append("    xxinv_mov_lot_s1.NEXTVAL ");
      insSb.append("   ,:1                   ");
      insSb.append("   ,'40'                 ");
      insSb.append("   ,'40'                 ");
      insSb.append("   ,:2                   ");
      insSb.append("   ,:3                   ");
      insSb.append("   ,:4                   ");
      insSb.append("   ,:5                   ");
      insSb.append("   ,:6                   ");
      insSb.append("   ,TO_NUMBER(:7)        ");
      insSb.append("   ,fnd_global.user_id   ");
      insSb.append("   ,SYSDATE              ");
      insSb.append("   ,fnd_global.user_id   ");
      insSb.append("   ,SYSDATE              ");
      insSb.append("   ,fnd_global.login_id  ");
      insSb.append("   ,NULL                 ");
      insSb.append("   ,NULL                 ");
      insSb.append("   ,NULL                 ");
      insSb.append("   ,NULL                 ");
      insSb.append("  );   ");
      insSb.append("END; ");

      //PL/SQL�̐ݒ���s���܂�
      CallableStatement cstmt = trans.createCallableStatement(
                                  insSb.toString(),
                                  OADBTransaction.DEFAULT);
      try
      {

        //PL/SQL�����s���܂�
        int i = 1;
        cstmt.setInt(i++, XxcmnUtility.intValue(mtlDtlId));
        cstmt.setInt(i++, XxcmnUtility.intValue(itemId));
        cstmt.setString(i++, itemNo);
        cstmt.setInt(i++, XxcmnUtility.intValue(lotId));
        cstmt.setString(i++, lotNo);
        cstmt.setDate(i++, XxcmnUtility.dateValue(productDate));
        cstmt.setString(i++, actualQty);

        cstmt.execute();
      } catch (SQLException s) 
      {
        // ���[���o�b�N
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
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
          rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
          XxcmnUtility.writeLog(trans,
                                XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
        } 
      }        
    // ���b�g�ڍ�ID��Null�ȊO�̏ꍇ
    } else
    {
      // �X�V����
      // PL/SQL�̍쐬���s���܂�
      StringBuffer updSb = new StringBuffer(1000);
      updSb.append("BEGIN ");
      updSb.append("  UPDATE xxinv_mov_lot_details xmld ");// �ړ����b�g�ڍ�
      updSb.append("  SET    xmld.actual_date       = :1                  "); // ���ѓ�
      updSb.append("        ,xmld.actual_quantity   = :2                  "); // ���ѐ���
      updSb.append("        ,xmld.last_updated_by   = fnd_global.user_id  "); // �ŏI�X�V��
      updSb.append("        ,xmld.last_update_date  = SYSDATE             "); // �ŏI�X�V��
      updSb.append("        ,xmld.last_update_login = fnd_global.login_id "); // �ŏI�X�V���O�C��
      updSb.append("  WHERE  xmld.mov_lot_dtl_id    = :3   ");      // ���b�g�ڍ�ID
      updSb.append("  ;   ");
      updSb.append("END; ");

      //PL/SQL�̐ݒ���s���܂�
      CallableStatement cstmt = trans.createCallableStatement(
                                  updSb.toString(),
                                  OADBTransaction.DEFAULT);
      try
      {

        //PL/SQL�����s���܂�
        int i = 1;
        cstmt.setDate(i++, XxcmnUtility.dateValue(productDate));
        cstmt.setString(i++, actualQty);
        cstmt.setInt(i++, XxcmnUtility.intValue(movLotDtlId));

        cstmt.execute();
      } catch (SQLException s) 
      {
        // ���[���o�b�N
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
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
          rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
          XxcmnUtility.writeLog(trans,
                                XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
        } 
      }        
    }
  } // movLotExecute

  /*****************************************************************************
   * �����\���ʃ`�F�b�N���s���܂��B
   * @param trans         - �g�����U�N�V����
   * @param itemId        - �i��ID
   * @param lotId         - ���b�gID
   * @param whseId        - OPM�ۊǑq��ID
   * @param actualDate    - ���ѓ�
   * @param actualQty     - ���ѐ���
   * @param baseActualQty - �����ѐ���
   * @return String - �߂�l�F0 ����A1 �x��
   * @throws OAException - OA��O
   ****************************************************************************/
  public static String chkReservedQuantity(
    OADBTransaction trans,
    Number itemId,
    Number lotId,
    Number whseId,
    Date actualDate,
    String actualQty,
    String baseActualQty
  ) throws OAException
  {
    String apiName      = "chkReservedQuantity";
 
    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  ln_enc_qty NUMBER; "); // �����\��
    sb.append("BEGIN ");
    sb.append("  ln_enc_qty := xxcmn_common_pkg.get_can_enc_qty( ");
    sb.append("                  in_whse_id     => :1   "); // OPM�ۊǑq��ID
    sb.append("                 ,in_item_id     => :2   "); // OPM�i��ID
    sb.append("                 ,in_lot_id      => :3   "); // ���b�gID
    sb.append("                 ,in_active_date => :4 );"); // �L����
    sb.append("  IF (:5 - :6 > ln_enc_qty) THEN ");
    sb.append("    :7 := '1'; "); // �x��
    sb.append("  ELSE ");
    sb.append("    :7 := '0'; "); // ����
    sb.append("  END IF; ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      int i = 1;
      cstmt.setInt(i++,  XxcmnUtility.intValue(whseId));      // OPM�ۊǑq��ID
      cstmt.setInt(i++,  XxcmnUtility.intValue(itemId));      // OPM�i��ID
      cstmt.setInt(i++,  XxcmnUtility.intValue(lotId));       // ���b�gID
      cstmt.setDate(i++, XxcmnUtility.dateValue(actualDate)); // ���ѓ�
      cstmt.setString(i++, getRcvShipQty(trans, "1", itemId, baseActualQty)); // �����ѐ���
      cstmt.setString(i++, getRcvShipQty(trans, "1", itemId, actualQty));     // ���ѐ���
      
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(i++, Types.VARCHAR); // ��������
      
      //PL/SQL���s
      cstmt.execute();
      
      // �߂�l�擾
      return cstmt.getString(7); // ��������

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
      XxcmnUtility.writeLog(trans,
                            XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // chkReservedQuantity

  /*****************************************************************************
   * OPM���b�g�}�X�^�̑Ó����`�F�b�N���s�����\�b�h�ł��B
   * @param trans     - �g�����U�N�V����
   * @param lotId     - ���b�gID
   * @return boolean  - true:���b�g�g�p��
   *                    false:���b�g�g�p�s��
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean checkLotStatus(
    OADBTransaction trans,
    Number lotId
    ) throws OAException
  {
    String apiName   = "checkLotStatus";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(500);
    sb.append("BEGIN "  );
    sb.append("  SELECT COUNT(1) ");
    sb.append("  INTO   :1 ");
    sb.append("  FROM   xxcmn_lot_status_v       xlsv "); // ���b�g�X�e�[�^�X����VIEW
    sb.append("        ,ic_lots_mst              ilm  "); // OPM���b�g�}�X�^
    sb.append("        ,xxcmn_item_categories4_v xicv "); // OPM�i�ڃJ�e�S�����VIEW4
    sb.append("  WHERE  xicv.item_id            = ilm.item_id          ");
    sb.append("  AND    xlsv.lot_status         = ilm.attribute23      ");
    sb.append("  AND    xlsv.prod_class_code    = xicv.prod_class_code ");
    sb.append("  AND    xlsv.raw_mate_turn_rel  = 'Y' "); // ���Y��������(����)
    sb.append("  AND    ilm.lot_id              = :2  ");
    sb.append("  AND    ROWNUM                  = 1;  ");
    sb.append("END; ");
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {

      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(1, Types.INTEGER);
      // �p�����[�^�ݒ�(�p�����[�^)
      cstmt.setInt(2, XxcmnUtility.intValue(lotId)); // ���b�gID

      //PL/SQL���s
      cstmt.execute();
      // �p�����[�^�̎擾
      if(cstmt.getInt(1) == 0)
      {
        return false; 
      } else
      {
        return true; 
      }
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
        // ���[���o�b�N
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // checkLotStatus

  /*****************************************************************************
   * �ϑ�������擾���܂��B
   * @param trans    - �g�����U�N�V����
   * @param itemId   - �i��ID
   * @param orgnCode - �����
   * @param tranDate - ���
   * @return HashMap  - �ϑ�����
   * @throws OAException - OA��O
   ****************************************************************************/
  public static HashMap getStockValue(
    OADBTransaction trans,
    Number itemId,
    String orgnCode,
    Date   originalDate
    ) throws OAException
  {
    String apiName    = "getStockValue"; // API��
    HashMap retHashMap = new HashMap();  // �߂�l�p

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lt_total_amount    xxpo_price_headers.total_amount%TYPE;   ");
    sb.append("  lt_calculate_type  xxpo_price_headers.calculate_type%TYPE; ");
    sb.append("  lt_orgn_name       sy_orgn_mst_vl.orgn_name%TYPE;          ");
    sb.append("BEGIN ");
    sb.append("  SELECT xph.total_amount   "); // �ϑ����H�P��
    sb.append("        ,xph.calculate_type "); // �ϑ��v�Z�敪
    sb.append("        ,somv.orgn_name     "); // ����於
    sb.append("  INTO   lt_total_amount    ");
    sb.append("        ,lt_calculate_type  ");
    sb.append("        ,lt_orgn_name  ");
    sb.append("  FROM   sy_orgn_mst_vl     somv ");  // OPM�v�����g�}�X�^�r���[
    sb.append("        ,xxpo_price_headers xph  ");  // �d���E�W���P���w�b�_(�A�h�I��)
    sb.append("  WHERE  somv.attribute1   = xph.vendor_code(+) ");
    sb.append("  AND    somv.attribute1       = xph.factory_code(+)");
    sb.append("  AND    xph.supply_to_code(+) IS NULL              ");
    sb.append("  AND    xph.item_id(+)    = :1                 ");
    sb.append("  AND    somv.orgn_code    = :2                 ");
    sb.append("  AND    xph.futai_code(+) = '9'                ");
    sb.append("  AND    :3  BETWEEN xph.start_date_active(+)   ");
    sb.append("             AND     xph.end_date_active(+);    ");
    sb.append("  :4 := TO_CHAR(NVL(lt_total_amount, 0), 'FM9999990.00'); ");
    sb.append("  :5 := NVL(lt_calculate_type, 1);                        ");
    sb.append("  :6 := lt_orgn_name;                             ");
    sb.append("EXCEPTION ");
    sb.append("  WHEN NO_DATA_FOUND THEN "); // �f�[�^���Ȃ��ꍇ��0
    sb.append("    :4 := '0';  ");
    sb.append("    :5 := '1';  ");
    sb.append("    :6 := null; ");
    sb.append("END; ");

    //PL/SQL�ݒ�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      int i = 1;
      cstmt.setInt(i++, XxcmnUtility.intValue(itemId));         // �i��ID
      cstmt.setString(i++, orgnCode);                           // �v�����g�R�[�h
      cstmt.setDate(i++, XxcmnUtility.dateValue(originalDate)); // ���Y��
          
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(i++, Types.VARCHAR); // �݌ɒP��
      cstmt.registerOutParameter(i++, Types.VARCHAR); // �ϑ��v�Z�敪
      cstmt.registerOutParameter(i++, Types.VARCHAR); // ����於
          
      //PL/SQL���s
      cstmt.execute();
          
      // �߂�l�擾
      retHashMap.put("totalAmount", cstmt.getString(4));
      retHashMap.put("calcType"   , cstmt.getString(5));
      retHashMap.put("orgnName"   , cstmt.getString(6));

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
      XxcmnUtility.writeLog(trans,
                            XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // getStockValue

// 2008-10-31 v.1.2 D.Nihei Add Start ������Q#405
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
    sb.append("DECLARE ");
    sb.append("  lv_close_date VARCHAR2(6); "); // �N���[�Y���t
    sb.append("BEGIN ");
    sb.append("  lv_close_date := xxcmn_common_pkg.get_opminv_close_period; "); // OPM�݌ɉ�v����CLOSE�N���擾
    sb.append("  IF ( lv_close_date >= TO_CHAR(:1, 'YYYYMM') ) THEN "); 
    sb.append("    :2 := 'N'; ");
    sb.append("  ELSE ");
    sb.append("    :2 := 'Y'; ");
    sb.append("  END IF; "); 
    sb.append("END; ");

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
      String plSqlRet  = cstmt.getString(2);

      // �N���[�Y���Ă���ꍇ
      if (XxcmnConstants.STRING_N.equals(plSqlRet))
      {
        // �݌ɉ�v���ԃ`�F�b�N�G���[
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10601);  
      }
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
        // ���[���o�b�N
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        // ���O�o��
        XxcmnUtility.writeLog(
          trans,
          XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    } 
  } // chkStockClose
// 2008-10-31 D.Nihei Add End
}