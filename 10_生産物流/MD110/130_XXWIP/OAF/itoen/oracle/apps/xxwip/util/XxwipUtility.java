/*============================================================================
* ファイル名 : XxwipUtility
* 概要説明   : 生産共通関数
* バージョン : 1.2
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2007-11-09 1.0  二瓶大輔     新規作成
* 2008-06-27 1.1  二瓶大輔     addメソッド追加
* 2008-10-31 1.2  二瓶大輔     在庫会計クローズ関数追加
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
 * 生産共通関数クラスです。
 * @author  ORACLE 二瓶 大輔
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
   * 賞味期限日の算出を行います。
	 * @param trans - トランザクション
   * @param itemId - 品目ID
   * @param MakerDate - 生産日
   * @return Date 賞味期限日
   ****************************************************************************/
  public static Date getExpirationDate(
    OADBTransaction trans,
    Number itemId,
    Date MakerDate
  ) throws OAException
  {
    String apiName      = "getExpirationDate";
    Date expirationDate = null;
    // 品目ID、生産日がNullの場合は処理を行わない。
    if (XxcmnUtility.isBlankOrNull(itemId) 
      || XxcmnUtility.isBlankOrNull(MakerDate)) 
    {
      return null;
    }
    // PL/SQLの作成を取得を行います
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN ");
    sb.append("	 SELECT :1 + NVL(ximv.expiration_day, 0) ");
    sb.append("	 INTO   :2 ");
    sb.append("	 FROM   xxcmn_item_mst2_v ximv       ");
    sb.append("	 WHERE  ximv.item_id           = :3  ");
    sb.append("	 AND    ximv.start_date_active<= :4  ");
    sb.append("	 AND    ximv.end_date_active  >= :5; ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      //PL/SQLを実行します
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
      // ロールバック
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
        //処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
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
   * 原料を追加します。
	 * @param trans - トランザクション
   * @param row - 行クラス
   * @param params - パラメータ
   * @param tabType - タブタイプ　0：投入、1：打込、2：副産物
   * @return 処理フラグ true：処理実行、false：処理未実行
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

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lr_material_detail_in   gme_material_details%ROWTYPE; ");
    sb.append("  lr_material_detail_out  gme_material_details%ROWTYPE; ");
    sb.append("BEGIN ");
    sb.append("  lr_material_detail_in.batch_id   := :1;  ");// バッチID   
    sb.append("  lr_material_detail_in.item_id    := :2;  ");// 品目ID    
    sb.append("  lr_material_detail_in.item_um    := :3;  ");// 単位      
    sb.append("  lr_material_detail_in.line_type  := :4;  ");// ラインタイプ
    sb.append("  lr_material_detail_in.attribute5 := :5;  ");// 打込区分   
    sb.append("  lr_material_detail_in.attribute8 := :6;  ");// 投入口     
    sb.append("  lr_material_detail_in.attribute6 := :7;  ");// 在庫入数     
    sb.append("  lr_material_detail_in.attribute1 := :8;  ");// タイプ     
    sb.append("  lr_material_detail_in.attribute2 := :9;  ");// ランク１     
    sb.append("  lr_material_detail_in.attribute3 := :10; ");// ランク２    
    sb.append("  lr_material_detail_in.attribute10:= TO_CHAR(:11,'YYYY/MM/DD'); "); // 賞味期限日
    sb.append("  lr_material_detail_in.attribute11:= TO_CHAR(:12,'YYYY/MM/DD'); "); // 生産日
    sb.append("  lr_material_detail_in.attribute17:= TO_CHAR(:13,'YYYY/MM/DD'); "); // 製造日
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
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      //PL/SQLを実行します
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
      // 副産物の場合
      if (XxwipConstants.LINE_TYPE_CO_PROD.equals(lineType.stringValue())) 
      {
        cstmt.setDate(i++, XxcmnUtility.dateValue(expirationDate));
        cstmt.setDate(i++, XxcmnUtility.dateValue(productDate));
        cstmt.setDate(i++, XxcmnUtility.dateValue(makerDate));
      // 投入品の場合
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
        // ロールバック
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        // APIエラーを出力する。
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(14) + cstmt.getString(16),
                              6);
        //トークンを生成します。
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "原料追加関数") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                               XxwipConstants.XXWIP10049, 
                               tokens);
      }
    } catch(SQLException s)
    {
      // ロールバック
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
        //処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
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
   * 原料を更新します。
	 * @param trans - トランザクション
   * @param params - パラメータ
   * @return 処理フラグ true：処理実行、false：処理未実行
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

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lr_material_detail gme_material_details%ROWTYPE; ");
    sb.append("BEGIN ");
    sb.append("  lr_material_detail.material_detail_id := :1;  "); // 生産原料詳細
    sb.append("  lr_material_detail.line_type          := :2;  "); // ラインタイプ
    sb.append("  lr_material_detail.attribute1         := :3;  "); // タイプ
    sb.append("  lr_material_detail.attribute2         := :4;  "); // ランク１
    sb.append("  lr_material_detail.attribute3         := :5;  "); // ランク２
    sb.append("  lr_material_detail.attribute6         := :6;  "); // 在庫入数
    sb.append("  lr_material_detail.attribute4         := :7;  "); // 摘要
    sb.append("  lr_material_detail.attribute9         := :8;  "); // 委託加工単価
    sb.append("  lr_material_detail.attribute10        := TO_CHAR(:9,'YYYY/MM/DD');  "); // 賞味期限日
    sb.append("  lr_material_detail.attribute11        := TO_CHAR(:10,'YYYY/MM/DD'); "); // 生産日
    sb.append("  lr_material_detail.attribute14        := :11; "); // 委託計算区分
    sb.append("  lr_material_detail.attribute16        := :12; "); // その他金額
    sb.append("  lr_material_detail.attribute17        := TO_CHAR(:13,'YYYY/MM/DD'); "); // 製造日
    sb.append("  xxwip_common_pkg.update_material_line(  ");
    sb.append("    lr_material_detail ");
    sb.append("   ,:14  ");
    sb.append("   ,:15  ");
    sb.append("   ,:16  ");
    sb.append("  ); ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      //PL/SQLを実行します
      int i = 1;
      cstmt.setInt(i++, XxcmnUtility.intValue(mtlDtlId));
      cstmt.setInt(i++, XxcmnUtility.intValue(lineType));
      cstmt.setString(i++, type);
      cstmt.setString(i++, rank1);
      cstmt.setString(i++, rank2);
      cstmt.setString(i++, entityInner);
      // 完成品の場合
      if (XxwipConstants.LINE_TYPE_PROD.equals(lineType.stringValue())) 
      {
        cstmt.setString(i++, mtlDesc);
        cstmt.setString(i++, trustProcUnitPrice);
        cstmt.setDate(i++, XxcmnUtility.dateValue(expirationDate));
        cstmt.setDate(i++, XxcmnUtility.dateValue(productDate));
        cstmt.setString(i++, trustCalcType);
        cstmt.setString(i++, othersCost);
        cstmt.setDate(i++, XxcmnUtility.dateValue(makerDate));
      // 副産物の場合
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
        // ロールバック
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        // APIエラーを出力する。
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(14) + cstmt.getString(16),
                              6);
        //トークンを生成します。
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "原料更新関数") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                              XxwipConstants.XXWIP10049, 
                              tokens);
      }
    } catch(SQLException s)
    {

      // ロールバック
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
        //処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
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
   * 割当の追加を行います。
	 * @param trans - トランザクション
   * @param params - パラメータ
   * @param lineType - ラインタイプ　1：完成品、2：副産物
   * @return 処理フラグ true：処理実行、false：処理未実行
   * @throws OAException - OA例外
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
    
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lr_tran_row_in  gme_inventory_txns_gtmp%ROWTYPE; ");
    sb.append("BEGIN ");
    sb.append("  lr_tran_row_in.doc_id             := :1; ");    // バッチID
    sb.append("  lr_tran_row_in.lot_id             := :2; ");    // ロットID
    sb.append("  lr_tran_row_in.trans_qty          := :3; ");    // 処理数量
    sb.append("  lr_tran_row_in.trans_date         := :4; ");    // 処理日付
    sb.append("  lr_tran_row_in.location           := :5; ");    // 保管倉庫
    sb.append("  lr_tran_row_in.completed_ind      := :6; ");    // 完了フラグ
    sb.append("  lr_tran_row_in.material_detail_id := :7; ");    // 生産原料詳細ID
    sb.append("  lr_tran_row_in.whse_code          := :8; ");    // 倉庫コード
    sb.append("  xxwip_common_pkg.insert_line_allocation ( ");
    sb.append("    ir_tran_row_in  => lr_tran_row_in ");
    sb.append("   ,ov_errbuf       => :9  ");
    sb.append("   ,ov_retcode      => :10  ");
    sb.append("   ,ov_errmsg       => :11 ");
    sb.append("  ); ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {

      //PL/SQLを実行します
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
        // ロールバック
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(9) + cstmt.getString(11),
                              6);
        // エラーをスロー
        //トークンを生成します。
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "割当追加関数") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                              XxwipConstants.XXWIP10049, 
                              tokens);
      }
    } catch (SQLException s) 
    {
      // ロールバック
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
        // ロールバック
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
   * 割当の更新を行います。
	 * @param trans - トランザクション
   * @param params - パラメータ
   * @param lineType - ラインタイプ　1：完成品、2：副産物、-1：投入品
   * @return 処理フラグ true：処理実行、false：処理未実行
   * @throws OAException - OA例外
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

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lr_tran_row_in  gme_inventory_txns_gtmp%ROWTYPE; ");
    sb.append("BEGIN ");
    sb.append("  lr_tran_row_in.trans_id      := :1; ");    // 処理ID
    sb.append("  lr_tran_row_in.lot_id        := :2; ");    // ロットID
    sb.append("  lr_tran_row_in.trans_qty     := :3; ");    // 処理数量
    sb.append("  lr_tran_row_in.trans_date    := :4; ");    // 処理日付
    sb.append("  lr_tran_row_in.doc_id        := :5; ");    // バッチID
    sb.append("  lr_tran_row_in.completed_ind := :6; ");    // 完了フラグ
    sb.append("  xxwip_common_pkg.update_line_allocation (  ");
    sb.append("    ir_tran_row_in  => lr_tran_row_in ");
    sb.append("   ,ov_errbuf       => :7 ");
    sb.append("   ,ov_retcode      => :8 ");
    sb.append("   ,ov_errmsg       => :9 ");
    sb.append("  ); ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {

      //PL/SQLを実行します
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
        // ロールバック
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(7) + cstmt.getString(9),
                              6);
        //トークンを生成します。
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "割当更新関数") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                              XxwipConstants.XXWIP10049, 
                              tokens);
      }
    } catch (SQLException s) 
    {
      // ロールバック
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
        // ロールバック
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
   * 割当の削除を行います。
	 * @param trans - トランザクション
   * @param params - パラメータ
   * @param lineType - ラインタイプ　1：完成品、2：副産物
   * @return 処理フラグ true：処理実行、false：処理未実行
   * @throws OAException - OA例外
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

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lr_tran_row_in  gme_inventory_txns_gtmp%ROWTYPE; ");
    sb.append("BEGIN ");
    sb.append("  lr_tran_row_in.trans_id := :1; ");    // 処理ID
    sb.append("  lr_tran_row_in.doc_id   := :2; ");    // バッチID
    sb.append("  xxwip_common_pkg.delete_line_allocation (  ");
    sb.append("    ir_tran_row_in  => lr_tran_row_in ");
    sb.append("   ,ov_errbuf       => :3 ");
    sb.append("   ,ov_retcode      => :4 ");
    sb.append("   ,ov_errmsg       => :5 ");
    sb.append("  ); ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {

      //PL/SQLを実行します
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
        // ロールバック
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(3) + cstmt.getString(5),
                              6);
        //トークンを生成します。
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "割当削除関数") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                              XxwipConstants.XXWIP10049, 
                              tokens);
      }
        
    } catch (SQLException s) 
    {
      // ロールバック
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
        // ロールバック
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
   * ステータスの更新を行います。
	 * @param trans - トランザクション
   * @param batchId - バッチID
   * @param dutyStatus - 更新ステータス
   * @return 処理フラグ true：処理実行、false：処理未実行
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean updateStatus(
    OADBTransaction trans,
    Number batchId,
    String dutyStatus
  ) throws OAException 
  {
    String apiName  = "updateStatus";
    boolean exeFlag = false;
    //PL/SQLの作成を行います
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
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      //PL/SQLを実行します
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
        // ロールバック
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(3) + cstmt.getString(5),
                              6);
        //トークンを生成します。
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "業務ステータス更新関数") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                               XxwipConstants.XXWIP10049, 
                               tokens);
      }
    } catch (SQLException s) 
    {
      // ロールバック
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
        // ロールバック
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
   * 原料の削除を行います。
	 * @param trans - トランザクション
   * @param params - パラメータ
   * @return 処理フラグ true：処理実行、false：処理未実行
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean deleteMaterialLine(
    OADBTransaction trans,
    HashMap params
  ) throws OAException 
  {
    String  apiName = "deleteMaterialLine";
    boolean exeFlag = false;
    //PL/SQLの作成を行います
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
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      Number batchId  = new Number(params.get("batchId"));
      Number mtlDtlId = new Number(params.get("mtlDtlId"));
      //PL/SQLを実行します
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
        // ロールバック
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(3) + cstmt.getString(5),
                              6);
        //トークンを生成します。
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "原料削除関数") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                               XxwipConstants.XXWIP10049, 
                               tokens);
      }
    } catch (SQLException s) 
    {
      // ロールバック
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
        // ロールバック
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
   * 生産バッチのセーブを行います。
	 * @param trans - トランザクション
   * @param batchId - バッチID
   * @return 処理フラグ true：処理実行、false：処理未実行
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean saveBatch(
    OADBTransaction trans,
    String batchId
  ) throws OAException 
  {
    String  apiName = "saveBatch";
    boolean exeFlag = false;
    //PL/SQLの作成を行います
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
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      //PL/SQLを実行します
      int i = 1;
      cstmt.setInt(i++, Integer.parseInt(batchId));
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1); 

      cstmt.execute();

      if (XxcmnConstants.API_STATUS_SUCCESS.equals(cstmt.getString(2))) 
      {
        exeFlag = true;
      } else 
      {
        // ロールバック
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              "",
                              6);
        //トークンを生成します。
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "バッチセーブ関数") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                              XxwipConstants.XXWIP10049, 
                              tokens);
      }
        
    } catch (SQLException s) 
    {
      // ロールバック
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
        // ロールバック
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
   * ロットの登録・更新を行います。
	 * @param trans - トランザクション
   * @param lotNoProd - 副産物ロットNo
   * @param row - OARowオブジェクト
   * @param lineType - ラインタイプ　1：完成品、2：副産物
   * @param params - パラメータ
   * @return 処理フラグ true：処理実行、false：処理未実行
   * @throws OAException - OA例外
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

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lr_ic_lots_mst_in        ic_lots_mst%ROWTYPE; ");
    sb.append("  lr_ic_lots_mst_out       ic_lots_mst%ROWTYPE; ");
    sb.append("BEGIN ");
    sb.append("  lr_ic_lots_mst_in.item_id     := :1;   "); // 品目コード
    sb.append("  lr_ic_lots_mst_in.lot_id      := :2;   "); // ロットID
    sb.append("  lr_ic_lots_mst_in.attribute1  := :3;   "); // 製造年月日
    sb.append("  lr_ic_lots_mst_in.attribute2  := :4;   "); // 固有記号
    sb.append("  lr_ic_lots_mst_in.attribute3  := :5;   "); // 賞味期限
    sb.append("  lr_ic_lots_mst_in.attribute6  := :6;   "); // 在庫入数
    sb.append("  lr_ic_lots_mst_in.attribute13 := :7;   "); // タイプ
    sb.append("  lr_ic_lots_mst_in.attribute14 := :8;   "); // ランク１
    sb.append("  lr_ic_lots_mst_in.attribute15 := :9;   "); // タンク２
    sb.append("  lr_ic_lots_mst_in.attribute16 := :10;  "); // 生産伝票区分
    sb.append("  lr_ic_lots_mst_in.attribute17 := :11;  "); // ラインNo
    if (XxwipConstants.LINE_TYPE_PROD.equals(lineType)) 
    {
      sb.append("lr_ic_lots_mst_in.attribute18 := :12;  "); // 摘要
    } else 
    {
      sb.append("lr_ic_lots_mst_in.lot_no      := :12;  "); // ロットNo
    }
    sb.append("  lr_ic_lots_mst_in.attribute23 := :13;  "); // ロットステータス
    sb.append("  xxwip_common_pkg.lot_execute ( ");
    sb.append("    ir_lot_mst         => lr_ic_lots_mst_in  "); // OPMロットマスタテーブル変数
    sb.append("   ,it_item_no         => :14                "); // 品目コード
    sb.append("   ,it_line_type       => :15                "); // ラインタイプ
    sb.append("   ,it_item_class_code => :16                "); // 品目区分
    sb.append("   ,it_lot_no_prod     => :17                "); // 完成品ロットNo
    sb.append("   ,or_lot_mst         => lr_ic_lots_mst_out "); // OPMロットマスタテーブル変数
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

    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      //PL/SQLを実行します
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
        cstmt.setString(i++, XxwipConstants.QT_STATUS_NON_JUDG); // 未判定
      } else 
      {
        cstmt.setString(i++, XxwipConstants.QT_STATUS_PASS); // 合格
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

      // 正常終了の場合
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
      // 異常終了の場合
      } else
      {
        // ロールバック
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(18) + cstmt.getString(20),
                              6);
        //トークンを生成します。
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "ロット追加・更新関数") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                               XxwipConstants.XXWIP10049, 
                               tokens);
      }
    } catch (SQLException s) 
    {
      // ロールバック
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
        // ロールバック
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
   * 在庫単価の更新を行います。
	 * @param trans - トランザクション
   * @param batchId - バッチID
   * @return boolean 処理フラグ true：処理実行、false：処理未実行
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean updateInvPrice(
    OADBTransaction trans,
    String batchId
  ) throws OAException 
  {
    String apiName  = "updateInvPrice";
    boolean exeFlag = false;
    //PL/SQLの作成を行います
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

    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      //PL/SQLを実行します
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
        // ロールバック
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(2) + cstmt.getString(4),
                              6);
        //トークンを生成します。
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "在庫単価更新関数") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                               XxwipConstants.XXWIP10049, 
                               tokens);
      }
    } catch (SQLException s) 
    {
      // ロールバック
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
        // ロールバック
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
   * 委託加工費の更新を行います。
	 * @param trans - トランザクション
   * @param batchId - バッチID
   * @return boolean 処理フラグ true：処理実行、false：処理未実行
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean updateTrustPrice(
    OADBTransaction trans,
    String batchId
  ) throws OAException 
  {
    String apiName  = "updateTrustPrice";
    boolean exeFlag = false;
    //PL/SQLの作成を行います
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

    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      //PL/SQLを実行します
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
        // ロールバック
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(2) + cstmt.getString(4),
                              6);
        //トークンを生成します。
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "委託加工費更新関数") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                               XxwipConstants.XXWIP10049, 
                               tokens);
      }
    } catch (SQLException s) 
    {
      // ロールバック
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
        // ロールバック
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
   * 入出庫換算単位を取得します。
	 * @param trans - トランザクション
   * @param convType - 変換方法
   * @param itemId - 品目ID
   * @param baseTransQty - 換算前処理数量
   * @return String 換算後処理数量
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
    //PL/SQLの作成を取得を行います
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN ");
    sb.append("	 :1 := TO_CHAR(xxcmn_common_pkg.rcv_ship_conv_qty(:2, :3, TO_NUMBER(:4)), 'FM999999990.000'); ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      //PL/SQLを実行します
      int i = 1;
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.setString(i++, convType);
      cstmt.setInt(i++, XxcmnUtility.intValue(itemId));
      cstmt.setString(i++, baseTransQty);
      cstmt.execute();
      transQty = cstmt.getString(1);

    } catch(SQLException s)
    {
      // ロールバック
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
        //処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
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
   * 品質検査依頼情報を作成します。
	 * @param trans - トランザクション
   * @param disposalDiv - 処理区分　1：挿入、2：更新
   * @param lotId - ロットID
   * @param itemId - 品目ID
   * @param batchId - バッチID
   * @param qtNumber - 検査依頼No
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
    //PL/SQLの作成を取得を行います
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN ");
    sb.append("  xxwip_common_pkg.make_qt_inspection( ");
    sb.append("    it_division          => 1     "); // 区分：生産(固定)
    sb.append("   ,iv_disposal_div      => :1    "); // 処理区分
    sb.append("   ,it_lot_id            => :2    "); // ロットID
    sb.append("   ,it_item_id           => :3    "); // 品目ID
    sb.append("   ,iv_qt_object         => null  ");
    sb.append("   ,it_batch_id          => :4    "); // バッチID
    sb.append("   ,it_batch_po_id       => null  ");
    sb.append("   ,it_qty               => null  ");
    sb.append("   ,it_prod_dely_date    => null  ");
    sb.append("   ,it_vendor_line       => null  ");
    sb.append("   ,it_qt_inspect_req_no => :5    "); // 検査依頼No
    sb.append("   ,ot_qt_inspect_req_no => :6    "); // 検査依頼No
    sb.append("   ,ov_errbuf            => :7    ");
    sb.append("   ,ov_retcode           => :8    ");
    sb.append("   ,ov_errmsg            => :9    ");
    sb.append("  ); ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      //PL/SQLを実行します
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
      // 異常終了の場合
      } else if (XxcmnConstants.API_RETURN_ERROR.equals(retCode)) 
      {
        // ロールバック
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(7) + cstmt.getString(9),
                              6);
        //トークンを生成します。
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "品質検査依頼情報作成") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                               XxwipConstants.XXWIP10049, 
                               tokens);
      }
    } catch(SQLException s)
    {
      // ロールバック
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
        //処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
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
   * ロールバック処理を行うメソッドです。
	 * @param trans - トランザクション
	 * @param savePointName - セーブポイント名
   ***************************************************************************
   */
  public static void rollBack(
    OADBTransaction trans,
    String savePointName)
  {
    // セーブポイントまでロールバック
    trans.executeCommand("ROLLBACK TO " + savePointName);
    // コミット
    trans.commit();
  } // doRollBack

  /***************************************************************************
   * 値１から値２を減算するメソッドです。
	 * @param value1 - 値１
	 * @param value2 - 値２
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
   * 移動ロット詳細への書込み処理を行います。
	 * @param trans - トランザクション
   * @param params - パラメータ
   * @return 処理フラグ true：処理実行、false：処理未実行
   * @throws OAException - OA例外
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

    // ロット詳細IDがNullの場合
    if (XxcmnUtility.isBlankOrNull(movLotDtlId)) 
    {
      // 挿入処理
      //PL/SQLの作成を行います
      StringBuffer insSb = new StringBuffer(1000);
      insSb.append("BEGIN ");
      insSb.append("  INSERT INTO xxinv_mov_lot_details( ");// 移動ロット詳細
      insSb.append("    mov_lot_dtl_id            ");      // ロット詳細ID
      insSb.append("   ,mov_line_id               ");      // 明細ID
      insSb.append("   ,document_type_code        ");      // 文書タイプ
      insSb.append("   ,record_type_code          ");      // レコードタイプ
      insSb.append("   ,item_id                   ");      // 品目ID
      insSb.append("   ,item_code                 ");      // 品目コード
      insSb.append("   ,lot_id                    ");      // ロットID
      insSb.append("   ,lot_no                    ");      // ロットNo
      insSb.append("   ,actual_date               ");      // 実績日
      insSb.append("   ,actual_quantity           ");      // 実績数量
      insSb.append("   ,created_by                ");      // 作成者
      insSb.append("   ,creation_date             ");      // 作成日
      insSb.append("   ,last_updated_by           ");      // 最終更新者
      insSb.append("   ,last_update_date          ");      // 最終更新日
      insSb.append("   ,last_update_login         ");      // 最終更新ログイン
      insSb.append("   ,request_id                ");      // 要求ID
      insSb.append("   ,program_application_id    ");      // コンカレント・プログラム・アプリケーションID
      insSb.append("   ,program_id                ");      // コンカレント・プログラムID
      insSb.append("   ,program_update_date       ");      // プログラム更新日
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

      //PL/SQLの設定を行います
      CallableStatement cstmt = trans.createCallableStatement(
                                  insSb.toString(),
                                  OADBTransaction.DEFAULT);
      try
      {

        //PL/SQLを実行します
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
        // ロールバック
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
          // ロールバック
          rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
          XxcmnUtility.writeLog(trans,
                                XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
        } 
      }        
    // ロット詳細IDがNull以外の場合
    } else
    {
      // 更新処理
      // PL/SQLの作成を行います
      StringBuffer updSb = new StringBuffer(1000);
      updSb.append("BEGIN ");
      updSb.append("  UPDATE xxinv_mov_lot_details xmld ");// 移動ロット詳細
      updSb.append("  SET    xmld.actual_date       = :1                  "); // 実績日
      updSb.append("        ,xmld.actual_quantity   = :2                  "); // 実績数量
      updSb.append("        ,xmld.last_updated_by   = fnd_global.user_id  "); // 最終更新者
      updSb.append("        ,xmld.last_update_date  = SYSDATE             "); // 最終更新日
      updSb.append("        ,xmld.last_update_login = fnd_global.login_id "); // 最終更新ログイン
      updSb.append("  WHERE  xmld.mov_lot_dtl_id    = :3   ");      // ロット詳細ID
      updSb.append("  ;   ");
      updSb.append("END; ");

      //PL/SQLの設定を行います
      CallableStatement cstmt = trans.createCallableStatement(
                                  updSb.toString(),
                                  OADBTransaction.DEFAULT);
      try
      {

        //PL/SQLを実行します
        int i = 1;
        cstmt.setDate(i++, XxcmnUtility.dateValue(productDate));
        cstmt.setString(i++, actualQty);
        cstmt.setInt(i++, XxcmnUtility.intValue(movLotDtlId));

        cstmt.execute();
      } catch (SQLException s) 
      {
        // ロールバック
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
          // ロールバック
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
   * 引当可能数量チェックを行います。
   * @param trans         - トランザクション
   * @param itemId        - 品目ID
   * @param lotId         - ロットID
   * @param whseId        - OPM保管倉庫ID
   * @param actualDate    - 実績日
   * @param actualQty     - 実績数量
   * @param baseActualQty - 元実績数量
   * @return String - 戻り値：0 正常、1 警告
   * @throws OAException - OA例外
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
 
    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  ln_enc_qty NUMBER; "); // 引当可能数
    sb.append("BEGIN ");
    sb.append("  ln_enc_qty := xxcmn_common_pkg.get_can_enc_qty( ");
    sb.append("                  in_whse_id     => :1   "); // OPM保管倉庫ID
    sb.append("                 ,in_item_id     => :2   "); // OPM品目ID
    sb.append("                 ,in_lot_id      => :3   "); // ロットID
    sb.append("                 ,in_active_date => :4 );"); // 有効日
    sb.append("  IF (:5 - :6 > ln_enc_qty) THEN ");
    sb.append("    :7 := '1'; "); // 警告
    sb.append("  ELSE ");
    sb.append("    :7 := '0'; "); // 正常
    sb.append("  END IF; ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      int i = 1;
      cstmt.setInt(i++,  XxcmnUtility.intValue(whseId));      // OPM保管倉庫ID
      cstmt.setInt(i++,  XxcmnUtility.intValue(itemId));      // OPM品目ID
      cstmt.setInt(i++,  XxcmnUtility.intValue(lotId));       // ロットID
      cstmt.setDate(i++, XxcmnUtility.dateValue(actualDate)); // 実績日
      cstmt.setString(i++, getRcvShipQty(trans, "1", itemId, baseActualQty)); // 元実績数量
      cstmt.setString(i++, getRcvShipQty(trans, "1", itemId, actualQty));     // 実績数量
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 処理結果
      
      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      return cstmt.getString(7); // 処理結果

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
      XxcmnUtility.writeLog(trans,
                            XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        //処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // chkReservedQuantity

  /*****************************************************************************
   * OPMロットマスタの妥当性チェックを行うメソッドです。
   * @param trans     - トランザクション
   * @param lotId     - ロットID
   * @return boolean  - true:ロット使用可
   *                    false:ロット使用不可
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean checkLotStatus(
    OADBTransaction trans,
    Number lotId
    ) throws OAException
  {
    String apiName   = "checkLotStatus";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(500);
    sb.append("BEGIN "  );
    sb.append("  SELECT COUNT(1) ");
    sb.append("  INTO   :1 ");
    sb.append("  FROM   xxcmn_lot_status_v       xlsv "); // ロットステータス共通VIEW
    sb.append("        ,ic_lots_mst              ilm  "); // OPMロットマスタ
    sb.append("        ,xxcmn_item_categories4_v xicv "); // OPM品目カテゴリ情報VIEW4
    sb.append("  WHERE  xicv.item_id            = ilm.item_id          ");
    sb.append("  AND    xlsv.lot_status         = ilm.attribute23      ");
    sb.append("  AND    xlsv.prod_class_code    = xicv.prod_class_code ");
    sb.append("  AND    xlsv.raw_mate_turn_rel  = 'Y' "); // 生産原料投入(実績)
    sb.append("  AND    ilm.lot_id              = :2  ");
    sb.append("  AND    ROWNUM                  = 1;  ");
    sb.append("END; ");
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.INTEGER);
      // パラメータ設定(パラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(lotId)); // ロットID

      //PL/SQL実行
      cstmt.execute();
      // パラメータの取得
      if(cstmt.getInt(1) == 0)
      {
        return false; 
      } else
      {
        return true; 
      }
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
        // ロールバック
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        //処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // checkLotStatus

  /*****************************************************************************
   * 委託先情報を取得します。
   * @param trans    - トランザクション
   * @param itemId   - 品目ID
   * @param orgnCode - 取引先
   * @param tranDate - 基準日
   * @return HashMap  - 委託先情報
   * @throws OAException - OA例外
   ****************************************************************************/
  public static HashMap getStockValue(
    OADBTransaction trans,
    Number itemId,
    String orgnCode,
    Date   originalDate
    ) throws OAException
  {
    String apiName    = "getStockValue"; // API名
    HashMap retHashMap = new HashMap();  // 戻り値用

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lt_total_amount    xxpo_price_headers.total_amount%TYPE;   ");
    sb.append("  lt_calculate_type  xxpo_price_headers.calculate_type%TYPE; ");
    sb.append("  lt_orgn_name       sy_orgn_mst_vl.orgn_name%TYPE;          ");
    sb.append("BEGIN ");
    sb.append("  SELECT xph.total_amount   "); // 委託加工単価
    sb.append("        ,xph.calculate_type "); // 委託計算区分
    sb.append("        ,somv.orgn_name     "); // 取引先名
    sb.append("  INTO   lt_total_amount    ");
    sb.append("        ,lt_calculate_type  ");
    sb.append("        ,lt_orgn_name  ");
    sb.append("  FROM   sy_orgn_mst_vl     somv ");  // OPMプラントマスタビュー
    sb.append("        ,xxpo_price_headers xph  ");  // 仕入・標準単価ヘッダ(アドオン)
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
    sb.append("  WHEN NO_DATA_FOUND THEN "); // データがない場合は0
    sb.append("    :4 := '0';  ");
    sb.append("    :5 := '1';  ");
    sb.append("    :6 := null; ");
    sb.append("END; ");

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      int i = 1;
      cstmt.setInt(i++, XxcmnUtility.intValue(itemId));         // 品目ID
      cstmt.setString(i++, orgnCode);                           // プラントコード
      cstmt.setDate(i++, XxcmnUtility.dateValue(originalDate)); // 生産日
          
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 在庫単価
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 委託計算区分
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 取引先名
          
      //PL/SQL実行
      cstmt.execute();
          
      // 戻り値取得
      retHashMap.put("totalAmount", cstmt.getString(4));
      retHashMap.put("calcType"   , cstmt.getString(5));
      retHashMap.put("orgnName"   , cstmt.getString(6));

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
      XxcmnUtility.writeLog(trans,
                            XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        //処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(trans,
                              XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // getStockValue

// 2008-10-31 v.1.2 D.Nihei Add Start 統合障害#405
  /*****************************************************************************
   * 在庫クローズチェックを行います。
   * @param trans   - トランザクション
   * @param chkDate - 比較日付
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void chkStockClose(
    OADBTransaction trans,
    Date chkDate
  ) throws OAException
  {
    String apiName = "chkStockClose"; // API名
    
    // PL/SQL作成
    StringBuffer sb = new StringBuffer(100);
    sb.append("DECLARE ");
    sb.append("  lv_close_date VARCHAR2(6); "); // クローズ日付
    sb.append("BEGIN ");
    sb.append("  lv_close_date := xxcmn_common_pkg.get_opminv_close_period; "); // OPM在庫会計期間CLOSE年月取得
    sb.append("  IF ( lv_close_date >= TO_CHAR(:1, 'YYYYMM') ) THEN "); 
    sb.append("    :2 := 'N'; ");
    sb.append("  ELSE ");
    sb.append("    :2 := 'Y'; ");
    sb.append("  END IF; "); 
    sb.append("END; ");

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setDate(1, XxcmnUtility.dateValue(chkDate)); // 日付
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(2, Types.VARCHAR); // 戻り値
      
      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      String plSqlRet  = cstmt.getString(2);

      // クローズしている場合
      if (XxcmnConstants.STRING_N.equals(plSqlRet))
      {
        // 在庫会計期間チェックエラー
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10601);  
      }
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
        // ロールバック
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        //処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans, XxwipConstants.SAVE_POINT_XXWIP200001J);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwipConstants.CLASS_XXWIP_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    } 
  } // chkStockClose
// 2008-10-31 D.Nihei Add End
}