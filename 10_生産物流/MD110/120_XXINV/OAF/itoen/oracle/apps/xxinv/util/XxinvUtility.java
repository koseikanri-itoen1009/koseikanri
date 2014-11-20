/*============================================================================
* ファイル名 : XxinvUtility
* 概要説明   : 移動共通関数
* バージョン : 1.5
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-14 1.0  大橋 孝郎    新規作成
* 2008-07-10 1.1  伊藤ひとみ   isMovHdrUpdForOwnConc,isMovLineUpdForOwnConc追加
* 2008-10-21 1.2  伊藤ひとみ   updateMovLotDetailsロック取得を変更
* 2008-12-05 1.3  伊藤ひとみ   本番障害#452対応
* 2008-12-06 1.4  伊藤ひとみ   本番障害#508対応
* 2010-02-18 1.5  伊藤ひとみ   E_本稼動_01612
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
 * 移動共通関数クラスです。
 * @author  ORACLE 大橋孝郎
 * @version 1.5
 ***************************************************************************
 */
public class XxinvUtility 
{
  public XxinvUtility()
  {
  }
  /*****************************************************************************
   * ユーザー情報を取得します。
   * @param trans            - トランザクション
   * @return HashMap         - 戻り値群
   * @throws OAException - OA例外
   ****************************************************************************/
  public static HashMap getUserData(
    OADBTransaction trans
  ) throws OAException
  {
    String apiName  = "getUserData"; // API名

    HashMap paramsRet = new HashMap();

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                             );
    sb.append("  SELECT papf.attribute3          people_code "                     ); // 従業員区分
    sb.append("        ,xinvisv.segment1         locations_code "                  ); // 保管倉庫コード
    sb.append("        ,xinvisv.description      locations_name "                  ); // 保管倉庫名
    sb.append("        ,xinvisv.inventory_location_id inventory_location_id "      ); // 倉庫ID
    sb.append("  INTO   :1 "                                                       );
    sb.append("        ,:2 "                                                       );
    sb.append("        ,:3 "                                                       );
    sb.append("        ,:4 "                                                       );
    sb.append("  FROM   fnd_user              fu "                                 ); // ユーザーマスタ
    sb.append("        ,per_all_people_f      papf "                               ); // 従業員マスタ
    sb.append("        ,xxinv_info_sec_v      xinvisv "                            ); // 情報セキュリティマスタ
    sb.append("  WHERE  fu.employee_id              = papf.person_id "             ); // 従業員ID
    sb.append("  AND    fu.start_date <= TRUNC(SYSDATE) "                          ); // 適用開始日
    sb.append("  AND    ((fu.end_date IS NULL) OR (fu.end_date >= TRUNC(SYSDATE))) " ); // 適用終了日
    sb.append("  AND    papf.effective_start_date <= TRUNC(SYSDATE) "              ); // 適用開始日
    sb.append("  AND    papf.effective_end_date   >= TRUNC(SYSDATE) "              ); // 適用終了日
    sb.append("  AND    fu.user_id                  = FND_GLOBAL.USER_ID "         ); // ユーザーID
    sb.append("  AND    xinvisv.user_id = DECODE(papf.attribute3,'1',-1,FND_GLOBAL.USER_ID) " ); // ユーザーID
    sb.append("  AND    ROWNUM                      = 1 "                          ); 
    sb.append("  ORDER BY TO_NUMBER(xinvisv.segment1); "                           ); 
    sb.append("END; "                                                              );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      int i = 1;
       // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 従業員区分
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 保管倉庫コード
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 保管倉庫名
      cstmt.registerOutParameter(i++, Types.INTEGER); // 倉庫ID
      
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      paramsRet.put("retpeopleCode", cstmt.getString(1));          // 従業員区分
      paramsRet.put("locationsCode", cstmt.getString(2));          // 保管倉庫コード
      paramsRet.put("locationsName", cstmt.getString(3));          // 保管倉庫名
      paramsRet.put("locationId",    new Number(cstmt.getInt(4))); // 倉庫ID


    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    return paramsRet;
  } // getUserData

  /*****************************************************************************
   * 最大配送区分の算出を行います。
   * @param trans - トランザクション
   * @param codeClass1 - コード区分1
   * @param whseCode1  - 入出庫場所コード1
   * @param codeClass2 - コード区分2
   * @param whseCode2  - 入出庫場所コード2
   * @param weightCapacityClass - 重量容積区分
   * @param autoProcessType - 自動配車対象区分
   * @param originalDate    - 基準日(Nullの場合SYSDATE)
   * @return HashMap - 戻り値群
   * @throws OAException OA例外
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

    // PL/SQLの作成を行います
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
    sb.append("          :3    "); // コード区分1
    sb.append("         ,:4    "); // 入出庫場所コード1
    sb.append("         ,:5    "); // コード区分2
    sb.append("         ,:6    "); // 入出庫場所コード2
    sb.append("         ,lv_prod_class            "); // 商品区分
    sb.append("         ,lv_weight_capacity_class "); // 重量容積区分
    sb.append("         ,:7    "); // 自動配車対象区分
    sb.append("         ,:8    "); // 基準日
    sb.append("         ,:9    "); // 最大配送区分
    sb.append("         ,ln_drink_deadweight       "); // ドリンク積載重量
    sb.append("         ,ln_leaf_deadweight        "); // リーフ積載重量
    sb.append("         ,ln_drink_loading_capacity "); // ドリンク積載容積
    sb.append("         ,ln_leaf_loading_capacity  "); // リーフ積載容積
    sb.append("         ,ln_palette_max_qty); "); // パレット最大枚数
    // リーフ・重量の場合
    sb.append("  IF (('1' = lv_prod_class) AND ('1' = lv_weight_capacity_class)) THEN ");
    sb.append("    ln_deadweight := ln_leaf_deadweight; ");
    // リーフ・容積の場合
    sb.append("  ELSIF (('1' = lv_prod_class) AND ('2' = lv_weight_capacity_class)) THEN ");
    sb.append("    ln_loading_capacity := ln_leaf_loading_capacity; ");
    // ドリンク・重量の場合
    sb.append("  ELSIF (('2' = lv_prod_class) AND ('1' = lv_weight_capacity_class)) THEN ");
    sb.append("    ln_deadweight := ln_drink_deadweight; ");
    // ドリンク・容積の場合
    sb.append("  ELSIF (('2' = lv_prod_class) AND ('2' = lv_weight_capacity_class)) THEN ");
    sb.append("    ln_loading_capacity := ln_leaf_loading_capacity; ");
    // それ以外
    sb.append("  ELSE ");
    sb.append("    ln_deadweight := null; ");
    sb.append("    ln_loading_capacity := null; ");
    sb.append("  END IF; ");
    sb.append("  :10 := TO_CHAR(ln_palette_max_qty,  'FM9,999,990'); ");
    sb.append("  :11 := TO_CHAR(ln_deadweight,       'FM9,999,990'); ");
    sb.append("  :12 := TO_CHAR(ln_loading_capacity, 'FM9,999,990'); ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      int i = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setString(i++, weightCapacityClass);    // 重量容積区分

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(i++, Types.INTEGER); // 戻り値

      // パラメータ設定(INパラメータ)
      cstmt.setString(i++, codeClass1);   // コード区分1
      cstmt.setString(i++, whseCode1);    // 入出庫場所コード1
      cstmt.setString(i++, codeClass2);   // コード区分2
      cstmt.setString(i++, whseCode2);    // 入出庫場所コード2
      cstmt.setString(i++, autoProcessType);        // 自動配車対象区分
      if (XxcmnUtility.isBlankOrNull(originalDate)) 
      {
         cstmt.setNull(i++, Types.DATE);
      } else 
      {
        
        cstmt.setDate(i++, originalDate.dateValue()); // 基準日

      }
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 最大配送区分
      cstmt.registerOutParameter(i++, Types.VARCHAR); // パレット最大枚数
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 積載重量
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 積載容積

      // PL/SQL実行
      cstmt.execute();
      if (cstmt.getInt(2) == 1) 
      {
        // ログに出力
        XxcmnUtility.writeLog(trans,
                              XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
                              "戻り値がエラーで返りました。",
                              6);
        // エラーにせず戻り値にすべてnullをセットして戻す。
        HashMap paramsRet = new HashMap();
        paramsRet.put("maxShipMethods",  null); 
        paramsRet.put("paletteMaxQty",   null);
        paramsRet.put("deadweight",      null);
        paramsRet.put("loadingCapacity", null);
        return paramsRet;
      }

      // 戻り値取得
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
      
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ログに出力
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
        s.toString(),
        6);
      // エラーにせず戻り値にすべてnullをセットして戻す。
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
        //処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getMaxShipMethod

  /*****************************************************************************
   * シーケンスから移動ヘッダIDを取得します。
   * @param trans - トランザクション
   * @return Number - 移動ヘッダID
   * @throws OAException OA例外
   ****************************************************************************/
  public static Number getMovHdrId(
    OADBTransaction trans
    ) throws OAException
  {

    return XxcmnUtility.getSeq(trans, XxinvConstants.XXINV_MOV_HDR_S1);


  } // getMovHdrId

  /*****************************************************************************
   * 移動依頼/指示ヘッダ(アドオン)Tblにデータを更新します。
   * @param trans トランザクション
   * @param params パラメータ用HashMap
   * @return String XxcmnConstants.RETURN_SUCCESS:1 正常
   *                 XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException OA例外
   ****************************************************************************/
  public static String updateMovReqInsrtHdr(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    //
    String apiName      = "updateMovReqInsrtHdr";

    // INパラメータ取得
    Number movHdrId          = (Number)params.get("MovHdrId");         // 移動ヘッダID
    
    Date   actualShipDate    = (Date)params.get("ActualShipDate");     // 出庫実績日
    
    Date   actualArrivalDate = (Date)params.get("ActualArrivalDate");  // 入庫実績日
    
    Number outPalletQty      = (Number)params.get("OutPalletQty");     // パレット枚数(出)
    
    Number inPalletQty       = (Number)params.get("InPalletQty");      // パレット枚数(入)

    Number dctualCareerId    = (Number)params.get("ActualCareerId");   // 運送業者ID_実績

    String actualFreightCarrierCode = (String)params.get("ActualFreightCarrierCode"); // 運送業者_実績

    String actualShippingMethodCode = (String)params.get("ActualShippingMethodCode"); // 配送区分_実績

    String arrivalTimeFrom   = (String)params.get("ArrivalTimeFrom");  // 着荷時間FROM

    String arrivalTimeTo     = (String)params.get("ArrivalTimeTo");    // 着荷時間TO
    
    String correctActualFlg  = (String)params.get("CorrectActualFlg"); // 実績訂正フラグ
    
    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);

    sb.append("BEGIN ");
    sb.append("  UPDATE xxinv_mov_req_instr_headers ximrih      ");   // 移動依頼/指示ヘッダ(アドオン)
    sb.append("  SET    ximrih.actual_ship_date    = :1         ");   // 出庫実績日
    sb.append("        ,ximrih.actual_arrival_date = :2         ");   // 入庫実績日
    sb.append("        ,ximrih.out_pallet_qty      = :3         ");   // パレット枚数(出)
    sb.append("        ,ximrih.in_pallet_qty       = :4         ");   // パレット枚数(入)
    sb.append("        ,ximrih.actual_career_id    = :5         ");   // 運送業者ID_実績
    sb.append("        ,ximrih.actual_freight_carrier_code = :6 ");   // 運送業者_実績
    sb.append("        ,ximrih.actual_shipping_method_code = :7 ");   // 配送区分_実績
    sb.append("        ,ximrih.arrival_time_from   = :8         ");   // 着荷時間FROM
    sb.append("        ,ximrih.arrival_time_to     = :9         ");   // 着荷時間TO
    sb.append("        ,ximrih.correct_actual_flg  = :10        ");   // 実績訂正フラグ
    sb.append("        ,ximrih.last_updated_by   = FND_GLOBAL.USER_ID "); // 最終更新者
    sb.append("        ,ximrih.last_update_date  = SYSDATE            "); // 最終更新日
    sb.append("        ,ximrih.last_update_login = FND_GLOBAL.LOGIN_ID"); // 最終更新ログイン
    sb.append("  WHERE  ximrih.mov_hdr_id = :11;  ");   // ヘッダーID
    sb.append("END; ");

    // PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {
      // INパラメータ設定
      cstmt.setDate(1, XxcmnUtility.dateValue(actualShipDate));          // 出庫実績日
      cstmt.setDate(2, XxcmnUtility.dateValue(actualArrivalDate));       // 入庫実績日
      if (XxcmnUtility.isBlankOrNull(outPalletQty))
      {
        cstmt.setNull(3, Types.INTEGER);                                 // パレット枚数(出)
      } else
      {
        cstmt.setInt(3, XxcmnUtility.intValue(outPalletQty));            // パレット枚数(出)
      }
      if (XxcmnUtility.isBlankOrNull(inPalletQty))
      {
        cstmt.setNull(4, Types.INTEGER);                                 // パレット枚数(入)
      } else
      {
        cstmt.setInt(4, XxcmnUtility.intValue(inPalletQty));             // パレット枚数(入)
      }
      if (XxcmnUtility.isBlankOrNull(dctualCareerId))
      {
        cstmt.setNull(5, Types.INTEGER);                                 // 運送業者ID_実績
      } else
      {
        cstmt.setInt(5, XxcmnUtility.intValue(dctualCareerId));          // 運送業者ID_実績
      }
      if (XxcmnUtility.isBlankOrNull(actualFreightCarrierCode))
      {
        cstmt.setNull(6, Types.INTEGER);                                 // 運送業者_実績
      } else
      {
        cstmt.setString(6, actualFreightCarrierCode);                    // 運送業者_実績
      }
      if (XxcmnUtility.isBlankOrNull(actualShippingMethodCode))
      {
        cstmt.setNull(7, Types.INTEGER);                                 // 配送区分_実績
      } else
      {
        cstmt.setString(7, actualShippingMethodCode);                    // 配送区分_実績
      }
      if (XxcmnUtility.isBlankOrNull(arrivalTimeFrom))
      {
        cstmt.setNull(8, Types.INTEGER);                                 // 着荷時間FROM
      } else
      {
        cstmt.setString(8, arrivalTimeFrom);                             // 着荷時間FROM
      }
      if (XxcmnUtility.isBlankOrNull(arrivalTimeTo))
      {
        cstmt.setNull(9, Types.INTEGER);                                 // 着荷時間TO
      } else
      {
        cstmt.setString(9, arrivalTimeTo);                               // 着荷時間TO
      }
      cstmt.setString(10, correctActualFlg);                             // 実績訂正フラグ
      cstmt.setInt(11, XxcmnUtility.intValue(movHdrId));                 // 移動ヘッダID

      // PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      rollBack(trans);
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_AM_XXINV510001J + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }

    // 正常に処理された場合、"SUCCESS"(1)を返却
    return XxcmnConstants.RETURN_SUCCESS;
    
  } // updateMovReqInsrtHdr

 /*****************************************************************************
  * 移動依頼/指示ヘッダアドオンロックを取得します。
  * @param trans トランザクション
  * @param headerId - 移動ヘッダID
  * @return boolean - true ロック成功  false ロック失敗
  * @throws OAException - OA例外
  ****************************************************************************/
  public static boolean getMovReqInstrHdrLock(
   OADBTransaction trans,
   Number headerId
  ) throws OAException
  {
    String apiName = "getMovReqInstrHdrLock";
    boolean retFlag = true; // 戻り値

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  CURSOR xmrih_cur ");
    sb.append("  IS ");
    sb.append("    SELECT xmrih.mov_hdr_id ");
    sb.append("    FROM   xxinv_mov_req_instr_headers xmrih   "); // 移動依頼/指示ヘッダアドオン
    sb.append("    WHERE  xmrih.mov_hdr_id = TO_NUMBER(:1) ");
    sb.append("    FOR UPDATE OF xmrih.mov_hdr_id NOWAIT; ");
    sb.append("BEGIN ");
    sb.append("  OPEN  xmrih_cur; ");
    sb.append("  CLOSE xmrih_cur; ");
    sb.append("END; ");
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                               sb.toString(),
                               OADBTransaction.DEFAULT);
   try
   {
     //PL/SQLを実行します
     int i = 1;
     cstmt.setString(i++, XxcmnUtility.stringValue(headerId));

     cstmt.execute();
       
   } catch (SQLException s) 
   {
     // ロールバック
     rollBack(trans);
     // ログ出力
     XxcmnUtility.writeLog(
       trans,
       XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
       s.toString(),
       6);
     // ロックエラー
     retFlag = false;
   } finally
   {
     try
     {
       // PL/SQLクローズ
       cstmt.close();

     // close中に例外が発生した場合
     } catch(SQLException s)
     {
       // ロールバック
       rollBack(trans);
       // ログ出力
       XxcmnUtility.writeLog(
         trans,
         XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
         s.toString(),
         6);
       // エラーメッセージ出力
       throw new OAException(
         XxcmnConstants.APPL_XXCMN,
         XxcmnConstants.XXCMN10123);
     }
   }
   return retFlag;
  } // getMovReqInstrHdrLock

  /***************************************************************************
  * 移動依頼/指示ヘッダアドオンの排他制御チェックを行うメソッドです。
  * @param trans トランザクション
  * @param headerId - 移動ヘッダID
  * @param lastUpdateDate - 移動依頼/指示ヘッダ最終更新日
  * @return boolean       - true 排他エラーなし  false 排他エラーあり
  * @throws OAException - OA例外
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
    boolean retFlag = true; // 戻り値

    try
    {
      // PL/SQLの作成を行います
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT TO_CHAR(xmrih.last_update_date, 'YYYY/MM/DD HH24:MI:SS') ");
      sb.append("  INTO   :1 ");
      sb.append("  FROM   xxinv_mov_req_instr_headers xmrih "); // 移動依頼/指示ヘッダアドオン
      sb.append("  WHERE  xmrih.mov_hdr_id = TO_NUMBER(:2) ");
      sb.append("  AND    ROWNUM               = 1  ");
      sb.append("  ;  ");
      sb.append("END; ");

      // PL/SQLの設定を行います
      cstmt = trans.createCallableStatement(
                                 sb.toString(),
                                 OADBTransaction.DEFAULT);
      // PL/SQLを実行します
      int i = 1;
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.setString(i++, XxcmnUtility.stringValue(headerId));
      // SQL実行
      cstmt.execute();

      String dbLastUpdateDate = cstmt.getString(1);
       
      // 排他エラーの場合
      if (!XxcmnUtility.isEquals(lastUpdateDate, dbLastUpdateDate))
      {
        retFlag = false;
      }
    } catch (SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
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
       // ロールバック
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
  * SYSDATEを取得します。
  * @param trans - トランザクション
  * @return Date SYSDATE
  * @throws OAException - OA例外
  ****************************************************************************/
  public static Date getSysdate(
   OADBTransaction trans
  ) throws OAException
  {
    String apiName   = "getSysdate";
    Date   sysdate = null;

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                  );
    sb.append("   SELECT SYSDATE "      ); // SYSDATE
    sb.append("   INTO   :1 "           );
    sb.append("   FROM   DUAL; "        );
    sb.append("END; "                   );

    //PL/SQLの設定を行います
    CallableStatement cstmt
     = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
   try
   {
     // パラメータ設定(OUTパラメータ)
     cstmt.registerOutParameter(1, Types.DATE); // SYSDATE

     // PL/SQL実行
     cstmt.execute();
      
     // 戻り値取得
     sysdate = new Date(cstmt.getDate(1));

   // PL/SQL実行時例外の場合
   } catch(SQLException s)
   {
     // ロールバック
     rollBack(trans);
     XxcmnUtility.writeLog(
       trans,
       XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
       rollBack(trans);
       XxcmnUtility.writeLog(
         trans,
         XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
         s.toString(),
         6);
       // エラーメッセージ出力
       throw new OAException(
         XxcmnConstants.APPL_XXCMN, 
         XxcmnConstants.XXCMN10123);
     }
   }
   return sysdate;
  } // getSysdate

  /*****************************************************************************
  * 在庫クローズチェックを行います。
  * @param trans   - トランザクション
  * @param chkDate - 比較日付
  * @return boolean  - クローズの場合 true
  *                   - クローズ前の場合 false
  * @throws OAException - OA例外
  ****************************************************************************/
  public static boolean chkStockClose(
   OADBTransaction trans,
   Date chkDate
  ) throws OAException
  {
    String apiName = "chkStockClose"; // API名
    String plSqlRet;                  // PL/SQL戻り値
    
    // PL/SQL作成
    StringBuffer sb = new StringBuffer(100);
    sb.append("DECLARE "                                                      );
    sb.append("  lv_close_date VARCHAR2(30); "                                ); // クローズ日付
    sb.append("BEGIN "                                                        );
                // OPM在庫会計期間CLOSE年月取得
    sb.append("   lv_close_date := xxcmn_common_pkg.get_opminv_close_period; ");
                // 比較日付がクローズ日付以前の場合、Y：クローズをセット
    sb.append("   IF (lv_close_date >= TO_CHAR(:1, 'YYYYMM')) THEN "          ); 
    sb.append("     :2 := 'Y'; "                                              );
                // 比較日付がクローズ日付以降の場合、N：クローズ前をセット
    sb.append("   ELSE "                                                      );
    sb.append("     :2 := 'N'; "                                              );
    sb.append("   END IF; "                                                   ); 
    sb.append("END; "                                                         );

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
     plSqlRet = cstmt.getString(2);

   // PL/SQL実行時例外の場合
   } catch(SQLException s)
   {
     // ロールバック
     rollBack(trans);
     // ログ出力
     XxcmnUtility.writeLog(
       trans,
       XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
       rollBack(trans);
       // ログ出力
       XxcmnUtility.writeLog(
         trans,
         XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
         s.toString(),
         6);
       // エラーメッセージ出力
       throw new OAException(
         XxcmnConstants.APPL_XXCMN, 
         XxcmnConstants.XXCMN10123);
     }
   }
   // PL/SQL戻り値がY：クローズの場合true
   if ("Y".equals(plSqlRet))
   {
     return true;
    
   // PL/SQL戻り値がN：クローズ前の場合false
   } else
   {
     return false;
   }    
  } // chkStockClose

  /*****************************************************************************
  * 稼働日日付の算出を行います。
  * @param trans - トランザクション
  * @param originalDate - 基準日
  * @param shipWhseCode - 保管倉庫コード
  * @param shipToCode   - 配送先コード
  * @param leadTime     - リードタイム
  * @return Date - 稼働日日付
  * @throws OAException OA例外
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
    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  :1 := xxwsh_common_pkg.get_oprtn_day( ");
    sb.append("           :2 ");
    sb.append("          ,:3 ");
    sb.append("          ,:4 ");
    sb.append("          ,:5 ");
    sb.append("          ,FND_PROFILE.VALUE('XXCMN_ITEM_DIV_SECURITY') "); // 商品区分
    sb.append("          ,:6); ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt
     = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
   try
   {
     int i = 1;
     // パラメータ設定(OUTパラメータ)
     cstmt.registerOutParameter(i++, Types.INTEGER); // 戻り値

     // パラメータ設定(INパラメータ)
     cstmt.setDate(i++, XxcmnUtility.dateValue(originalDate)); // 入庫日

     if (XxcmnUtility.isBlankOrNull(shipWhseCode)) 
     {
       cstmt.setNull(i++, Types.VARCHAR);
     } else 
     {
       cstmt.setString(i++, shipWhseCode); // 保管倉庫
     }
     if (XxcmnUtility.isBlankOrNull(shipToCode)) 
     {
       cstmt.setNull(i++, Types.VARCHAR);
     } else 
     {
       cstmt.setString(i++, shipToCode); // 配送先
     }
     cstmt.setInt(i++, leadTime); // リードタイム
      
     // パラメータ設定(OUTパラメータ)
     cstmt.registerOutParameter(i++, Types.DATE);    // 稼動日付

     // PL/SQL実行
     cstmt.execute();
     oprtnDate = new Date(cstmt.getDate(6));
     if (cstmt.getInt(1) == 1) 
     {
       // ロールバック
       rollBack(trans);
       XxcmnUtility.writeLog(
         trans,
         XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
         "戻り値がエラーで返りました。",
         6);
       // エラーメッセージ出力
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

   // PL/SQL実行時例外の場合
   } catch(SQLException s)
   {
     // ロールバック
     rollBack(trans);
     XxcmnUtility.writeLog(
       trans,
       XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
       rollBack(trans);
       XxcmnUtility.writeLog(
         trans,
         XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
         s.toString(),
         6);
       // エラーメッセージ出力
       throw new OAException(
         XxcmnConstants.APPL_XXCMN, 
         XxcmnConstants.XXCMN10123);
     }
   }
   return oprtnDate;
  } // getOprtnDay

  /****************************************************************************
  * コンカレント：移動入出庫実績登録処理を発行します。
  * @param trans トランザクション
  * @param params パラメータ用HashMap
  * @return HashMap 処理結果
  * @throws OAException OA例外
  ****************************************************************************/
  public static HashMap doMovShipActualMake(
   OADBTransaction trans,
   HashMap params
  ) throws OAException
  {
    String apiName      = "doMovShipActualMake";

    // INパラメータ取得
    String movNum    = (String)params.get("MovNum");  // 移動番号

    // OUTパラメータ用HashMap生成
    HashMap outParams = new HashMap();
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // 戻り値

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "   );
    sb.append("  ln_request_id NUMBER; "                                       );
    sb.append("BEGIN "                                                         );
                // 移動入出庫実績登録処理(コンカレント)呼び出し
    sb.append("  ln_request_id := FND_REQUEST.SUBMIT_REQUEST( "                );
    sb.append("     application  => 'XXINV' "                                  ); // アプリケーション名
    sb.append("    ,program      => 'XXINV570001C' "                           ); // プログラム短縮名
    sb.append("    ,argument1    => :1 ); "                                    ); // 移動番号
                // 要求IDがある場合、正常
    sb.append("  IF ln_request_id > 0 THEN "                                   );
    sb.append("    :2 := '1'; "                                                ); // 1:正常終了
    sb.append("    :3 := ln_request_id; "                                      ); // 要求ID
    sb.append("    COMMIT; "                                                   );
                // 要求IDがある場合、正常
    sb.append("  ELSE "                                                        );
    sb.append("    :2 := '0'; "                                                ); // 0:異常終了
    sb.append("    :3 := ln_request_id; "                                      ); // 要求ID
    sb.append("    ROLLBACK; "                                                 );
    sb.append("  END IF; "                                                     );
    sb.append("END; "                                                          );

    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                               sb.toString(),
                               OADBTransaction.DEFAULT);
   try
   {
     // パラメータ設定(INパラメータ)
     cstmt.setString(1, movNum);                     // 移動番号
      
     // パラメータ設定(OUTパラメータ)
     cstmt.registerOutParameter(2, Types.VARCHAR);   // リターンコード
     cstmt.registerOutParameter(3, Types.INTEGER); // 要求ID

     //PL/SQL実行
     cstmt.execute();

     // 戻り値取得
     retFlag = cstmt.getString(2); // リターンコード
     int requestId = cstmt.getInt(3); // 要求ID
     outParams.put("retFlag", retFlag);
     outParams.put("requestId", new Integer(requestId));

     // 正常終了の場合
     if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
     {
       // リターンコード正常をセット
       retFlag = XxcmnConstants.RETURN_SUCCESS;
       outParams.put("retFlag", retFlag);
        
     // 正常終了でない場合、エラー  
     } else
     {
       //トークン生成
       MessageToken[] tokens = { new MessageToken(XxinvConstants.TOKEN_PROGRAM,
                                                  XxinvConstants.TOKEN_NAME_MOV_ACTUAL_MAKE) };
       // エラーメッセージ出力
       throw new OAException(
         XxcmnConstants.APPL_XXINV, 
         XxinvConstants.XXINV10005, 
         tokens);
     }
      
   // PL/SQL実行時例外の場合
   } catch(SQLException s)
   {
     // ロールバック
     rollBack(trans);
     XxcmnUtility.writeLog(
       trans,
       XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
       rollBack(trans);
       XxcmnUtility.writeLog(
         trans,
         XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
         s.toString(),
         6);
       // エラーメッセージ出力
       throw new OAException(
         XxcmnConstants.APPL_XXCMN, 
         XxcmnConstants.XXCMN10123);
     }
   }

   return outParams;
  } // doMovShipActualMake
   
  /*****************************************************************************
   * 移動ロット詳細の存在チェックを行います。
   * @param trans      - トランザクション
   * @param movHdrId   - 移動ヘッダID
   * @param recordType - レコードタイプ
   * @return boolean   - 存在する場合   true
   *                    - 存在しない場合 false
   * @throws OAException  - OA例外
   ****************************************************************************/
  public static boolean chkLotDetails(
    OADBTransaction trans,
    Number movHdrId,
    String recordType
    ) throws OAException
  {
    String apiName = "chkLotDetails";
    boolean retFlag = false;

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "  );
    sb.append("  SELECT COUNT(xmld.mov_lot_dtl_id) ");
    sb.append("  INTO   :1 ");
    sb.append("  FROM   xxinv_mov_req_instr_lines ximril "  ); // 移動依頼/指示明細(アドオン)
    sb.append("        ,xxinv_mov_lot_details     xmld "    ); // 移動ロット詳細(アドオン)
    sb.append("  WHERE  ximril.mov_hdr_id         = :2  "      ); // 移動ヘッダID
    sb.append("  AND    xmld.mov_line_id = ximril.mov_line_id "); // 移動明細ID
    sb.append("  AND    xmld.item_id = ximril.item_id "        ); // OPM品目ID
    sb.append("  AND    xmld.record_type_code     = :3; "      ); // レコードタイプ
    sb.append("END; ");
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      //バインド変数に値をセット
      cstmt.registerOutParameter(1,Types.INTEGER);
      cstmt.setInt(2, XxcmnUtility.intValue(movHdrId)); // 移動ヘッダID
      cstmt.setString(3, recordType);                   // レコードタイプ
      //PL/SQL実行
      cstmt.execute();
      // パラメータの取得
      int cnt = cstmt.getInt(1);
      if(cnt > 0)
      {
        retFlag = true; 
      }
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        // PL/SQLクローズ
        cstmt.close();
      // close中に例外が発生した場合 
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // chkLotDetails 

  /*****************************************************************************
   * 移動ロット詳細の実績日データを更新します。
   * @param trans - トランザクション
   * @param params - パラメータ
   * @return String - XxcmnConstants.RETURN_SUCCESS:1 正常
   *                   XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String updateMovLotDetails(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "updateMovLotDetails";

    // INパラメータ取得
    Number movHdrId          = (Number)params.get("MovHdrId");        // 移動ヘッダID
    String recordType        = (String)params.get("RecordType");      // レコードタイプ
    Date   actualShipDate    = (Date)params.get("ActualShipDate");    // 出庫日(実績)
    Date   actualArrivalDate = (Date)params.get("ActualArrivalDate"); // 着日(実績)

    // OUTパラメータ用
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // 戻り値

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                                             );
    sb.append("  lt_mov_hdr_id   xxinv_mov_req_instr_headers.mov_hdr_id%TYPE := :1; "); // 移動ヘッダID
    sb.append("  lt_record_type  xxinv_mov_lot_details.record_type_code%TYPE := :2; "); // レコードタイプ
    sb.append("  lt_hdr_id       xxinv_mov_req_instr_headers.mov_hdr_id%TYPE; "      );
                 // ユーザー定義エラー
    sb.append("  lock_expt             EXCEPTION; "                                  ); // ロックエラー
    sb.append("  PRAGMA EXCEPTION_INIT(lock_expt, -54); "                            ); 
// 2008-10-21 H.Itou Add Start
    sb.append("  CURSOR lock_cur IS "                                 );
    sb.append("  SELECT xmrih.mov_hdr_id "                            );
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
// 2008-10-21 H.Itou Add End
    sb.append("BEGIN "                                                );
                 // ロック取得
// 2008-10-21 Mod Start
//    sb.append("  SELECT xmrih.mov_hdr_id "                            );
//    sb.append("  INTO   lt_hdr_id "                                   );
//    sb.append("  FROM   xxinv_mov_req_instr_headers xmrih "           );
//    sb.append("        ,xxinv_mov_req_instr_lines   ximril "          );
//    sb.append("        ,xxinv_mov_lot_details       ximld "           );
//    sb.append("  WHERE  xmrih.mov_hdr_id = lt_mov_hdr_id "            );
//    sb.append("  AND    xmrih.mov_hdr_id = ximril.mov_hdr_id "        );
//    sb.append("  AND    ximril.mov_line_id = ximld.mov_line_id "      );
//    sb.append("  AND    ximld.record_type_code = lt_record_type "     );
//    sb.append("  FOR UPDATE OF xmrih.mov_hdr_id "                     );
//    sb.append("               ,ximril.mov_hdr_id "                    );
//    sb.append("               ,ximld.mov_line_id NOWAIT; "            );
    sb.append("  OPEN lock_cur; "                                                                        );
    sb.append("  FETCH lock_cur INTO lt_hdr_id; "                                                         );
    sb.append("  CLOSE lock_cur; "                                                                       );
// 2008-10-21 Mod End
                 // 移動ロット詳細(アドオン)更新
    sb.append("  UPDATE xxinv_mov_lot_details ximld"          );
    // レコードタイプが:20(出庫実績)の場合
    if (recordType.equals(XxinvConstants.RECORD_TYPE_20))
    {
      sb.append("  SET    actual_date = :3"                   );
    // レコードタイプが:30(入庫実績)の場合
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
    sb.append("  COMMIT; "                                                               ); // コミット
                 // OUTパラメータ
    sb.append("  :4 := '1'; "                                                            ); // 1:正常終了
    sb.append("EXCEPTION "                                                               );
    sb.append("  WHEN lock_expt THEN "                                                   );
    sb.append("    ROLLBACK; "                                                           ); // ロールバック
    sb.append("    :4 := '2'; "                                                          ); // 2:ロックエラー
    sb.append("    :5 := SQLERRM; "                                                      ); // SQLERRメッセージ 
    sb.append("END; "                                                                    );

    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1, XxcmnUtility.intValue(movHdrId));            // 移動ヘッダID
      cstmt.setString(2, recordType);                              // レコードタイプ
      // レコードタイプが:20(出庫実績)の場合
      if (recordType.equals(XxinvConstants.RECORD_TYPE_20))
      {
        cstmt.setDate(3, XxcmnUtility.dateValue(actualShipDate));    // 出庫日(実績)
      // レコードタイプが:30(入庫実績)の場合
      } else if (recordType.equals(XxinvConstants.RECORD_TYPE_30))
      {
        cstmt.setDate(3, XxcmnUtility.dateValue(actualArrivalDate)); // 入庫日(実績)
      }
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(4, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(5, Types.VARCHAR);   // エラーメッセージ
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      retFlag = cstmt.getString(4); // リターンコード
      String sqlErrMsg = cstmt.getString(5); // エラーメッセージ

      // 正常終了の場合
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // リターンコード：正常をセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        
      // ロックエラー終了の場合  
      } else if ("2".equals(retFlag))
      {
        // ロールバック
        rollBack(trans);
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          sqlErrMsg,
          6);
        // ロックエラー
        throw new OAException(
          XxcmnConstants.APPL_XXINV, 
          XxinvConstants.XXINV10159);
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_AM_XXINV510001J + XxcmnConstants.DOT + apiName,
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
          rollBack(trans);
          XxcmnUtility.writeLog(
            trans,
            XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
            s.toString(),
            6);
          // エラーメッセージ出力
          throw new OAException(
            XxcmnConstants.APPL_XXCMN, 
            XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // updateMovLotDetails

  /***************************************************************************
   * ロールバック処理を行うメソッドです。
   * @param trans - トランザクション
   ***************************************************************************
   */
   public static void rollBack(
     OADBTransaction trans
   )
   {
     // ロールバック発行
     trans.executeCommand("ROLLBACK ");
   } // rollBack
   
  /***************************************************************************
   * コミット処理を行うメソッドです。
   * @param trans - トランザクション
   ***************************************************************************
   */
  public static void commit(
    OADBTransaction trans
  )
  {
    // コミット発行
    trans.executeCommand("COMMIT ");
  } // commit

  /*****************************************************************************
   * 移動ロット詳細IDシーケンスより、新規IDを取得するメソッドです。
   * @param trans   - トランザクション
   * @throws OAException - OA例外
   ****************************************************************************/
  public static Number getMovLotDtlId(
    OADBTransaction trans
  ) throws OAException
  {
    String apiName   = "getMovLotDtlId";
    Number movLotDtlId = null;
    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                              );
    sb.append("  SELECT xxinv_mov_lot_s1.NEXTVAL  " ); // 1:移動ロット詳細アドオンID
    sb.append("  INTO   :1 "                        );
    sb.append("  FROM   DUAL; "                     );
    sb.append("END; "                               );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.INTEGER);
      
      // PL/SQL実行
      cstmt.execute();

      // OUTパラメータ取得
      movLotDtlId = new Number(cstmt.getObject(1)); // 移動ロット詳細アドオンID

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    return movLotDtlId;
  } // getMovLotDtlId

  /*****************************************************************************
   * OPMロットマスタの妥当性チェックを行うメソッドです。
   * @param trans             - トランザクション
   * @param lotNo             - ロットNo
   * @param manufacturedDate  - 製造年月日
   * @param useByDate         - 賞味期限
   * @param koyuCode          - 固有記号
   * @param itemId            - 品目ID
   * @param productFlg        - 製品識別区分 1:製品 2:製品以外
   * @return HashMap          - ロットマスタ情報
   * @throws OAException - OA例外
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
    
    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                                            );
    sb.append("  SELECT ilm.lot_no                     lot_no                  "                  ); // 1:ロットNo
    sb.append("        ,FND_DATE.STRING_TO_DATE(ilm.attribute1,'YYYY/MM/DD')  manufactured_date " ); // 2:製造年月日
    sb.append("        ,FND_DATE.STRING_TO_DATE(ilm.attribute3,'YYYY/MM/DD')  use_by_date       " ); // 3:賞味期限
    sb.append("        ,ilm.attribute2                 koyu_code               "                  ); // 4:固有記号
    sb.append("        ,ilm.lot_id                     lot_id                  "                  ); // 5:ロットID
    sb.append("        ,xlsv.move_inst_rel             move_inst_rel           "                  ); // 6:移動指示(実績)
    sb.append("        ,xlsv.status_desc               status_desc             "                  ); // 7:ロットステータス名称
    sb.append("        ,REPLACE(TO_CHAR(ilm.attribute6,'99990.000'),' ')      stock_quantity    " ); // 8:在庫入数
    sb.append("  INTO   :1 "                                                                      );
    sb.append("        ,:2 "                                                                      );
    sb.append("        ,:3 "                                                                      );
    sb.append("        ,:4 "                                                                      );
    sb.append("        ,:5 "                                                                      );
    sb.append("        ,:6 "                                                                      );
    sb.append("        ,:7 "                                                                      );
    sb.append("        ,:8 "                                                                      );
    sb.append("  FROM   ic_lots_mst            ilm "                                              ); // OPMロットマスタ
    sb.append("        ,xxcmn_lot_status_v     xlsv "                                             ); // ロットステータス情報VIEW
    sb.append("  WHERE  ilm.attribute23 = xlsv.lot_status "                                       );
    sb.append("  AND    ilm.item_id = :9 "                                                        ); // 品目ID
    sb.append("  AND    xlsv.prod_class_code = FND_PROFILE.VALUE('XXCMN_ITEM_DIV_SECURITY') "     ); // 商品区分
    // 製品識別区分が1:製品でない場合
    sb.append("  AND  (((:10 <> '1') "                                                             );
    sb.append("  AND    (:11 IS NULL OR ilm.lot_no = :11)) "                                      ); // ロットNo      
    // 製品識別区分が1:製品の場合
    sb.append("  OR    ((:10 = '1') "                                                              );
    sb.append("  AND    (:12 IS NULL OR ilm.attribute1 = TO_CHAR(:12, 'YYYY/MM/DD')) "            ); // 製造年月日
    sb.append("  AND    (:13 IS NULL OR ilm.attribute3 = TO_CHAR(:13, 'YYYY/MM/DD')) "            ); // 賞味期限
    sb.append("  AND    (:14 IS NULL OR ilm.attribute2 = :14))); "                                ); // 固有記号      
    sb.append("  :15 := '1'; "                                                                    );
    sb.append("EXCEPTION "                                                                        );
    sb.append("  WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN "                                       );
    sb.append("    :15 := '0'; "                                                                  );
    sb.append("END; "                                                                             );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt   (9, XxcmnUtility.intValue(itemId));            // 品目ID
      cstmt.setString(10, productFlg);                               // 製品識別区分
      cstmt.setString(11, lotNo);                                   // ロットNo
      cstmt.setDate  (12, XxcmnUtility.dateValue(manufacturedDate)); // 製造年月日
      cstmt.setDate  (13, XxcmnUtility.dateValue(useByDate));       // 賞味期限
      cstmt.setString(14, koyuCode);                                // 固有記号

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1,  Types.VARCHAR);
      cstmt.registerOutParameter(2,  Types.DATE);
      cstmt.registerOutParameter(3,  Types.DATE);
      cstmt.registerOutParameter(4,  Types.VARCHAR);
      cstmt.registerOutParameter(5,  Types.INTEGER);
      cstmt.registerOutParameter(6,  Types.VARCHAR);
      cstmt.registerOutParameter(7,  Types.VARCHAR);
      cstmt.registerOutParameter(8,  Types.VARCHAR);
      cstmt.registerOutParameter(15, Types.VARCHAR);

      // PL/SQL実行
      cstmt.execute();

      // OUTパラメータ取得
      ret.put("lotNo"               , cstmt.getString(1));          // ロットNo
      ret.put("manufacturedDate"    , cstmt.getObject(2));          // 製造年月日
      ret.put("useByDate"           , cstmt.getObject(3));          // 賞味期限
      ret.put("koyuCode"            , cstmt.getString(4));          // 固有記号
      ret.put("lotId"               , new Number(cstmt.getInt(5))); // ロットID
      ret.put("movInstRel"          , cstmt.getString(6));          // 移動指示(実績)
      ret.put("statusDesc"          , cstmt.getString(7));          // ステータスコード名称
      ret.put("stock_quantity"      , cstmt.getString(8));          // 在庫入数
      ret.put("retCode"             , cstmt.getString(15));         // 戻り値

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    return ret;
  } // seachOpmLotMst

  /*****************************************************************************
   * ロット逆転防止チェックAPIを実行します。
   * @param trans        - トランザクション
   * @param itemNo       - 品目No
   * @param lotNo        - ロットNo
   * @param moveToId     - 配送先ID
   * @param standardDate - 基準日
   * @return HashMap 
   * @throws OAException - OA例外
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
    
    // OUTパラメータ
    String exeType = XxcmnConstants.RETURN_NOT_EXE;
    
    //PL/SQL作成
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                                    );
    sb.append("  xxwsh_common910_pkg.check_lot_reversal( ");
    sb.append("    iv_lot_biz_class    => '6',           ");   //  .ロット逆転処理種別 6:移動実績
    sb.append("    iv_item_no          => :1,            ");   // 1.品目コード
    sb.append("    iv_lot_no           => :2,            ");   // 2.ロットNo
    sb.append("    iv_move_to_id       => :3,            ");   // 3.配送先ID/取引先サイトID/入庫先ID
    sb.append("    iv_arrival_date     => NULL,          ");   //  .着日
    sb.append("    id_standard_date    => :4,            ");   // 4.基準日(適用日基準日)
    sb.append("    ov_retcode          => :5,            ");   // 5.リターンコード
    sb.append("    ov_errmsg_code      => :6,            ");   // 6.エラーメッセージコード
    sb.append("    ov_errmsg           => :7,            ");   // 7.エラーメッセージ
    sb.append("    on_result           => :8,            ");   // 8.処理結果
    sb.append("    on_reversal_date    => :9);           ");   // 9.逆転日付
    sb.append("END; "                                     );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, itemNo);                           // 品目コード
      cstmt.setString(2, lotNo);                            // ロットNo
      cstmt.setInt(3, XxcmnUtility.intValue(moveToId));     // 配送先ID
      cstmt.setDate(4, XxcmnUtility.dateValue(standardDate));// 基準日(適用日基準日)
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(5, Types.VARCHAR); // リターンコード
      cstmt.registerOutParameter(6, Types.VARCHAR); // エラーメッセージコード
      cstmt.registerOutParameter(7, Types.VARCHAR); // エラーメッセージ
      cstmt.registerOutParameter(8, Types.INTEGER); // 処理結果
      cstmt.registerOutParameter(9, Types.DATE);    // 逆転日付

      //PL/SQL実行
      cstmt.execute();

      String retCode      = cstmt.getString(5);              // リターンコード
      String errmsgCode   = cstmt.getString(6);              // エラーメッセージコード
      String errmsg       = cstmt.getString(7);              // エラーメッセージ

      // API正常終了の場合、値をセット
      if (XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {
        ret.put("result",  new Number(cstmt.getInt(8))); // 処理結果
        ret.put("revDate", new Date(cstmt.getDate(9)));  // 逆転日付
        
      // API正常終了でない場合、エラー  
      } else
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          cstmt.getString(7), // エラーメッセージ
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        // PL/SQLクローズ
        cstmt.close();
        
      // クローズ中ににエラーが発生した場合
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    return ret;
  } // doCheckLotReversal


  /*****************************************************************************
   * 手持在庫数量算出APIを実行します。
   * @param trans   - トランザクション
   * @param whseId  - OPM保管倉庫ID
   * @param itemId  - OPM品目ID
   * @param lotId   - ロットID
   * @param lotCtl  - ロット管理区分
   * @return Number - 手持在庫数量
   * @throws OAException - OA例外
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

    // OUTパラメータ
    Number stockQty    = new Number();
    
    //PL/SQL作成
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                                    );
    sb.append("  :1 := xxcmn_common_pkg.get_stock_qty( "  ); // 1.手持在庫数量
    sb.append("          in_whse_id  => :2,  "            ); // 2.OPM保管倉庫ID
    sb.append("          in_item_id  => :3,  "            ); // 3.OPM品目ID
    sb.append("          in_lot_id   => :4); "            ); // 4.ロットID
    sb.append("END; "                                     );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt   (2, XxcmnUtility.intValue(whseId)); // 保管倉庫ID
      cstmt.setInt   (3, XxcmnUtility.intValue(itemId)); // 品目ID
      // ロット管理外品の場合、ロットIDはNULL
      if (XxinvConstants.LOT_CTL_N.equals(lotCtl))
      {
        cstmt.setNull(4, Types.INTEGER); // ロットID
      } else
      {
        cstmt.setInt(4, XxcmnUtility.intValue(lotId));  // ロットID        
      }
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.NUMERIC); // 手持在庫数量

      //PL/SQL実行
      cstmt.execute();

      // OUTパラメータ取得
      stockQty = new Number(cstmt.getObject(1));  // 手持在庫数量

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        // PL/SQLクローズ
        cstmt.close();
        
      // クローズ中ににエラーが発生した場合
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }

    return stockQty;
    
  } // getStockQty
  
  /*****************************************************************************
   * 引当可能数算出APIを実行します。
   * @param trans - トランザクション
   * @param whseId  - OPM保管倉庫ID
   * @param itemId  - OPM品目ID
   * @param lotId   - ロットID
   * @param lotCtl  - ロット管理区分
   * @return Number - 引当可能数
   * @throws OAException - OA例外
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

    // OUTパラメータ
    Number canEncQty    = new Number();
    
    //PL/SQL作成
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                                    );
    sb.append("  :1 := xxcmn_common_pkg.get_can_enc_qty( "); // 1.引当可能数
    sb.append("        in_whse_id  => :2,  "              ); // 2.OPM保管倉庫ID
    sb.append("        in_item_id  => :3,  "              ); // 3.OPM品目ID
    sb.append("        in_lot_id   => :4,  "              ); // 4.ロットID
    sb.append("        in_active_date => SYSDATE); "      ); //  .有効日
    sb.append("END; "                                     );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(whseId)); // 保管倉庫ID
      cstmt.setInt(3, XxcmnUtility.intValue(itemId)); // 品目ID
      // ロット管理外品の場合、ロットIDはNULL
      if (XxinvConstants.LOT_CTL_N.equals(lotCtl))
      {
        cstmt.setNull(4, Types.INTEGER); // ロットID
      } else
      {
        cstmt.setInt(4, XxcmnUtility.intValue(lotId));  // ロットID        
      }
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.NUMERIC); // 引当可能数

      //PL/SQL実行
      cstmt.execute();

      // OUTパラメータ取得
      canEncQty = new Number(cstmt.getObject(1));  // 引当可能数

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        // PL/SQLクローズ
        cstmt.close();
        
      // クローズ中ににエラーが発生した場合
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }

    return canEncQty;
    
  } // getCanEncQty 

  /*****************************************************************************
   * 移動ロット詳細アドオンが存在するかチェックするメソッドです。
   * @param trans            - トランザクション
   * @param movLineId        - 受注明細アドオンID
   * @param documentTypeCode - 文書タイプ(10:出荷依頼、30:支給指示)
   * @param recordTypeCode   - レコードタイプ(10：指示、20：出庫実績  30：入庫実績)
   * @param lotId            - ロットID
   * @return boolean         - true:あり false:なし
   * @throws OAException - OA例外
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

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                        );
    sb.append("  lv_temp VARCHAR2(1); "                         );
    sb.append("BEGIN "                                          );
    sb.append("  SELECT 1  "                                    );
    sb.append("  INTO   lv_temp "                               );
    sb.append("  FROM   xxinv_mov_lot_details xmld "            ); //   移動ロット詳細アドオン
    sb.append("  WHERE  xmld.mov_line_id        = :1 "          ); // 1.受注明細アドオンID
    sb.append("  AND    xmld.document_type_code = :2 "          ); // 2.文書タイプ
    sb.append("  AND    xmld.record_type_code   = :3 "          ); // 3.レコードタイプ
    sb.append("  AND    xmld.lot_id             = :4 "          ); // 4.ロットID
    sb.append("  AND    ROWNUM                  = 1; "          );
    sb.append("    :5 := 'Y'; "                                 ); // 5.戻り値Y:ロット情報あり
    sb.append("EXCEPTION "                                      );
    sb.append("  WHEN NO_DATA_FOUND THEN "                      );
    sb.append("    :5 := 'N'; "                                 ); // 5.戻り値N:ロット情報なし
    sb.append("END; "                                           );

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    { 
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1, XxcmnUtility.intValue(movLineId)); // 受注明細アドオンID
      cstmt.setString(2, documentTypeCode);              // 文書タイプ
      cstmt.setString(3, recordTypeCode);                // レコードタイプ
      cstmt.setInt(4, XxcmnUtility.intValue(lotId));     // ロットID
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(5, Types.VARCHAR);
      
      // PL/SQL実行
      cstmt.execute();

      // OUTパラメータ取得
      String ret = cstmt.getString(5);  // 戻り値

      // Yの場合、ロットがあるのでtrueを返す。
      if (XxcmnConstants.STRING_Y.equals(ret))
      {
        return true;

      // Nの場合、ロットがないのでfalseを返す。
      } else
      {
        return false;
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // checkMovLotDtl

  /*****************************************************************************
   * 移動ロット詳細アドオンロックを取得します。
   * @param trans            - トランザクション
   * @param movHdrId        - 移動ヘッダID
   * @return boolean         - true ロック成功 false ロック失敗
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean getMovLotDetailsLock(
    OADBTransaction trans,
// 2010-02-18 H.Itou MOD START E_本稼動_01612
//    Number movLineId,
//    String documentTypeCode,
//    String recordTypeCode
      Number movHdrId
// 2010-02-18 H.Itou MOD END
  ) throws OAException
  {
    String apiName = "getMovLotDetailsLock";
    
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                     );
    sb.append("  lock_expt             EXCEPTION; "          ); 
    sb.append("  PRAGMA EXCEPTION_INIT(lock_expt, -54); "    );
    sb.append("CURSOR lock_cur IS "                          );
    sb.append("  SELECT 1 "                                  );
    sb.append("  FROM   xxinv_mov_lot_details xmld "         );
// 2010-02-18 H.Itou MOD START E_本稼動_01612 実績計上済フラグを更新するので、移動ヘッダに紐づくロットすべてをロックする。
//    sb.append("  WHERE  xmld.mov_line_id        = :1 "       ); // 1.移動明細ID
//    sb.append("  AND    xmld.document_type_code = :2 "       ); // 2.文書タイプ
//    sb.append("  AND    xmld.record_type_code   = :3 "       ); // 3.レコードタイプ
    sb.append("        ,xxinv_mov_req_instr_lines  xmril    ");
    sb.append("  WHERE  xmld.document_type_code = '20'      "); // 文書タイプ 20:移動
    sb.append("  AND    xmld.mov_line_id = xmril.mov_line_id");
    sb.append("  AND    xmril.delete_flg = 'N'              "); // 削除されていない明細
    sb.append("  AND    xmril.mov_hdr_id = :1               "); // 1.移動ヘッダID
 // 2010-02-18 H.Itou MOD END
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
// 2010-02-18 H.Itou MOD START E_本稼動_01612
//    sb.append("    :4 := '1'; "                              );
//    sb.append("    :5 := SQLERRM; "                          );
    sb.append("    :2 := '1'; "                              );
    sb.append("    :3 := SQLERRM; "                          );
// 2010-02-18 H.Itou MOD END
    sb.append("END; "                                        );

    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
// 2010-02-18 H.Itou MOD START E_本稼動_01612
//      // パラメータ設定(INパラメータ)
//      cstmt.setInt   (1, XxcmnUtility.intValue(movLineId)); // 移動明細ID
//      cstmt.setString(2, documentTypeCode);                 // 文書タイプ
//      cstmt.setString(3, recordTypeCode);                   // レコードタイプ
//      
//      // パラメータ設定(OUTパラメータ)
//      cstmt.registerOutParameter(4, Types.VARCHAR);   // リターンコード
//      cstmt.registerOutParameter(5, Types.VARCHAR);   // エラーメッセージ
      // パラメータ設定(INパラメータ)
      cstmt.setInt   (1, XxcmnUtility.intValue(movHdrId)); // 移動明細ID
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(2, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(3, Types.VARCHAR);   // エラーメッセージ
// 2010-02-18 H.Itou MOD END
      
      //PL/SQL実行
      cstmt.execute();

      // ロックエラー終了の場合  
// 2010-02-18 H.Itou MOD START E_本稼動_01612
//      if ("1".equals(cstmt.getString(4)))
      if ("1".equals(cstmt.getString(2)))
// 2010-02-18 H.Itou MOD END
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
// 2010-02-18 H.Itou MOD START E_本稼動_01612
//          cstmt.getString(5),
          cstmt.getString(3),
// 2010-02-18 H.Itou MOD END
          6);

        return false;

      // 正常終了の場合
      } else
      {
        return true;
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        // PL/SQLクローズ
        cstmt.close();
        
      // close中に例外が発生した場合
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getMovLotDetailsLock

   /*****************************************************************************
   * 移動依頼/指示明細ロックを取得します。
   * @param trans トランザクション
   * @param lineId - 移動明細ID
   * @return boolean - true ロック成功  false ロック失敗
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean getMovReqInstrLineLock(
   OADBTransaction trans,
   Number lineId
  ) throws OAException
  {
    String apiName = "getMovReqInstrLineLock";
    boolean retFlag = true; // 戻り値

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                      );
    sb.append("  lock_expt             EXCEPTION; "           ); 
    sb.append("  PRAGMA EXCEPTION_INIT(lock_expt, -54); "     );
    sb.append("  CURSOR xmril_cur IS "                        );
    sb.append("    SELECT xmril.mov_line_id "                 );
    sb.append("    FROM   xxinv_mov_req_instr_lines xmril "   ); // 移動依頼/指示明細アドオン
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

    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                               sb.toString(),
                               OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1, XxcmnUtility.intValue(lineId)); // 移動明細ID
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(2, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(3, Types.VARCHAR);   // エラーメッセージ
      // PL/SQL実行
      cstmt.execute();

      // ロックエラー終了の場合  
      if ("1".equals(cstmt.getString(2)))
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          cstmt.getString(3),
          6);

        return false;

      // 正常終了の場合
      } else
      {
        return true;
      }
    
    // PL/SQL実行時例外の場合
    } catch (SQLException s) 
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
       // PL/SQLクローズ
       cstmt.close();

      // close中に例外が発生した場合
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
                     XxcmnConstants.APPL_XXCMN,
                     XxcmnConstants.XXCMN10123);
      }
    }
  } // getMovReqInstrLineLock
  /***************************************************************************
  * 移動依頼/指示明細アドオンの排他制御チェックを行うメソッドです。
  * @param trans          - トランザクション
  * @param lineId         - 移動明細ID
  * @param lastUpdateDate - 移動依頼/指示明細最終更新日
  * @return boolean       - true 排他エラーなし  false 排他エラーあり
  * @throws OAException   - OA例外
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
    boolean retFlag = true; // 戻り値

    try
    {
      // PL/SQLの作成を行います
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN "                                                            );
      sb.append("  SELECT TO_CHAR(xmril.last_update_date, 'YYYY/MM/DD HH24:MI:SS') ");
      sb.append("  INTO   :1 "                                                      );
      sb.append("  FROM   xxinv_mov_req_instr_lines xmril "                         ); // 移動依頼/指示明細アドオン
      sb.append("  WHERE  xmril.mov_line_id = TO_NUMBER(:2) "                       );
      sb.append("  AND    ROWNUM               = 1  "                               );
      sb.append("  ;  "                                                             );
      sb.append("END; "                                                             );

      // PL/SQLの設定を行います
      cstmt = trans.createCallableStatement(
                                 sb.toString(),
                                 OADBTransaction.DEFAULT);

      // パラメータ設定(INパラメータ)
      cstmt.setString(2, XxcmnUtility.stringValue(lineId));

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR);
      
      // SQL実行
      cstmt.execute();

      String dbLastUpdateDate = cstmt.getString(1);
       
      // 排他エラーの場合
      if (!XxcmnUtility.isEquals(lastUpdateDate, dbLastUpdateDate))
      {
        retFlag = false;
      }
    } catch (SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
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
       // ロールバック
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
   * 重量容積小口個数更新関数を実行するメソッドです。
   * @param trans      - トランザクション
   * @param bizType    - 業務種別
   * @param requestNo  - 依頼No
   * @return Number    -  1：エラー  0：正常
   * @throws OAException - OA例外
   ****************************************************************************/
  public static Number doUpdateLineItems(
    OADBTransaction trans,
     String bizType,
     String requestNo
  ) throws OAException
  {
    String apiName   = "doUpdateLineItems";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                      );
    sb.append("  :1 := xxwsh_common_pkg.update_line_items( "); // 1.戻り値  1：エラー  0：正常
    sb.append("         iv_biz_type   => :2, "              ); // 2.業務種別
    sb.append("         iv_request_no => :3 ); "            ); // 3.依頼No
    sb.append("END; "                                       );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(2, bizType);   // 業務種別
      cstmt.setString(3, requestNo); // 依頼Np

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.INTEGER);   // 戻り値

      // PL/SQL実行
      cstmt.execute();
 
      return new Number(cstmt.getInt(1));

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        
        cstmt.close();
      
      //CLOSE処理中にエラーが発生した場合
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // doUpdateLineItems


  /*****************************************************************************
   * 移動ロット詳細アドオンに追加処理を行うメソッドです。
   * @param trans   - トランザクション
   * @param params  - パラメータ
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void insertMovLotDetails(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "insertMovLotDetails";

    Number movLineId        = (Number)params.get("movLineId");        // 明細ID
    String documentTypeCode = (String)params.get("documentTypeCode"); // 文書タイプ
    String recordTypeCode   = (String)params.get("recordTypeCode");   // レコードタイプ
    Number itemId           = (Number)params.get("itemId");           // 品目ID
    String itemCode         = (String)params.get("itemCode");         // 品目
    Number lotId            = (Number)params.get("lotId");            // ロットID
    String lotNo            = (String)params.get("lotNo");            // ロットNo
    Date   actualDate       = (Date)params.get("actualDate");         // 実績日
    String actualQuantity   = (String)params.get("actualQuantity");   // 実績数量

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                      );
    sb.append("  INSERT INTO xxinv_mov_lot_details xmld ( " ); // 移動ロット詳細アドオン
    sb.append("     xmld.mov_lot_dtl_id  "                  ); // ロット詳細ID
    sb.append("    ,xmld.mov_line_id  "                     ); // 1.明細ID
    sb.append("    ,xmld.document_type_code  "              ); // 2.文書タイプ
    sb.append("    ,xmld.record_type_code  "                ); // 3.レコードタイプ
    sb.append("    ,xmld.item_id  "                         ); // 4.OPM品目ID
    sb.append("    ,xmld.item_code  "                       ); // 5.品目
    sb.append("    ,xmld.lot_id  "                          ); // 6.ロットID
    sb.append("    ,xmld.lot_no  "                          ); // 7.ロットNo
    sb.append("    ,xmld.actual_date  "                     ); // 8.実績日
    sb.append("    ,xmld.actual_quantity  "                 ); // 9.実績数量
    sb.append("    ,xmld.created_by  "                      ); // 10.作成者
    sb.append("    ,xmld.creation_date  "                   ); // 11.作成日
    sb.append("    ,xmld.last_updated_by  "                 ); // 12.最終更新者
    sb.append("    ,xmld.last_update_date  "                ); // 13.最終更新日
    sb.append("    ,xmld.last_update_login)  "              ); // 14.最終更新ログイン
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
    sb.append("    ,FND_GLOBAL.USER_ID "                    ); // 作成者          
    sb.append("    ,SYSDATE "                               ); // 作成日          
    sb.append("    ,FND_GLOBAL.USER_ID "                    ); // 最終更新者      
    sb.append("    ,SYSDATE "                               ); // 最終更新日      
    sb.append("    ,FND_GLOBAL.LOGIN_ID); "                 ); // 最終更新ログイン
    sb.append("END; "                                       );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt   (1, XxcmnUtility.intValue(movLineId));   // 明細ID
      cstmt.setString(2, documentTypeCode);                   // 文書タイプ
      cstmt.setString(3, recordTypeCode);                     // レコードタイプ
      cstmt.setInt   (4, XxcmnUtility.intValue(itemId));      // OPM品目ID
      cstmt.setString(5, itemCode);                           // 品目
      cstmt.setInt   (6, XxcmnUtility.intValue(lotId));       // ロットID
      cstmt.setString(7, lotNo);                              // ロットNo
      cstmt.setDate  (8, XxcmnUtility.dateValue(actualDate)); // 実績日
      cstmt.setString(9, actualQuantity);                     // 実績数量

      // PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // insertMovLotDetails

  /*****************************************************************************
   * 移動ロット明細アドオンの実績数量を更新するメソッドです。
   * @param trans        - トランザクション
   * @param params       - パラメータ
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void updateActualQuantity(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "updateActualQuantity";

    // INパラメータ取得
    Number movLineId        = (Number)params.get("movLineId");        // 明細ID
    String documentTypeCode = (String)params.get("documentTypeCode"); // 文書タイプ
    String recordTypeCode   = (String)params.get("recordTypeCode");   // レコードタイプ
    Number lotId            = (Number)params.get("lotId");            // ロットID
    String actualQuantity   = (String)params.get("actualQuantity");   // 実績数量

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                 );
    sb.append("  UPDATE xxinv_mov_lot_details xmld "                   ); // 移動ロット明細アドオン
    sb.append("  SET    xmld.actual_quantity   = TO_NUMBER(:1) "       ); // 1.実績数量
    sb.append("        ,xmld.last_updated_by   = FND_GLOBAL.USER_ID "  ); // 最終更新者
    sb.append("        ,xmld.last_update_date  = SYSDATE "             ); // 最終更新日
    sb.append("        ,xmld.last_update_login = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン
    sb.append("  WHERE  xmld.mov_line_id        = :2 "                 ); // 2.明細ID
    sb.append("  AND    xmld.document_type_code = :3 "                 ); // 3.文書タイプ
    sb.append("  AND    xmld.record_type_code   = :4 "                 ); // 4.レコードタイプ
    sb.append("  AND    xmld.lot_id             = :5; "                ); // 5.ロットID
    sb.append("END; "                                                  );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, actualQuantity);                     // 実績数量
      cstmt.setInt   (2, XxcmnUtility.intValue(movLineId));   // 明細ID
      cstmt.setString(3, documentTypeCode);                   // 文書タイプ
      cstmt.setString(4, recordTypeCode);                     // レコードタイプ
      cstmt.setInt   (5, XxcmnUtility.intValue(lotId));       // ロットID

      // PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        
        cstmt.close();
      
      //CLOSE処理中にエラーが発生した場合
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updateActualQuantity

 /*****************************************************************************
   * 移動ロット詳細アドオンから実績数量の合計値を取得するメソッドです。
   * @param trans            - トランザクション
   * @param movLineId        - 移動明細ID
   * @param documentTypeCode - 文書タイプ(10:出荷依頼、30:支給指示)
   * @param recordTypeCode   - レコードタイプ(10：指示、20：出庫実績  30：入庫実績)
   * @return String          - 実績数量合計
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String getActualQuantitySum(
    OADBTransaction trans,
    Number movLineId,
    String documentTypeCode,
    String recordTypeCode
  ) throws OAException
  {
    String apiName     = "getActualQuantitySum";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                        );
    sb.append("  lv_temp VARCHAR2(1); "                         );
    sb.append("BEGIN "                                          );
    sb.append("  SELECT TO_CHAR(SUM(xmld.actual_quantity))  "   ); // 1.実績数量合計
    sb.append("  INTO   :1 "                                    );
    sb.append("  FROM   xxinv_mov_lot_details xmld "            ); //   移動ロット詳細アドオン
    sb.append("  WHERE  xmld.mov_line_id        = :2 "          ); // 2.移動明細ID
    sb.append("  AND    xmld.document_type_code = :3 "          ); // 3.文書タイプ
    sb.append("  AND    xmld.record_type_code   = :4; "         ); // 4.レコードタイプ
    sb.append("END; "                                           );

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    { 
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(movLineId)); // 移動明細ID
      cstmt.setString(3, documentTypeCode);              // 文書タイプ
      cstmt.setString(4, recordTypeCode);                // レコードタイプ
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR);      // 実績数量合計
      
      // PL/SQL実行
      cstmt.execute();

      // OUTパラメータ取得
      return cstmt.getString(1);  // 実績数量合計

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getActualQuantitySum

  /*****************************************************************************
   * 移動依頼/指示明細アドオンの出庫実績数量を更新するメソッドです。
   * @param trans        - トランザクション
   * @param movLineId  - 移動依頼/指示明細アドオンID
   * @param shippedQty   - 出庫実績数量
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void updateShippedQuantity(
    OADBTransaction trans,
     Number movLineId,
     String shippedQty
  ) throws OAException
  {
    String apiName   = "updateShippedQuantity";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                  );
    sb.append("  UPDATE xxinv_mov_req_instr_lines xmril "               ); // 移動依頼/指示明細アドオン
    sb.append("  SET    xmril.shipped_quantity  = TO_NUMBER(:1) "       ); // 1.出庫実績数量
    sb.append("        ,xmril.last_updated_by   = FND_GLOBAL.USER_ID "  ); // 最終更新者
    sb.append("        ,xmril.last_update_date  = SYSDATE "             ); // 最終更新日
    sb.append("        ,xmril.last_update_login = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン
    sb.append("  WHERE xmril.mov_line_id = :2; "                        ); // 2.移動明細ID
    sb.append("END; "                                                   );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, shippedQty);                       // 出庫実績数量
      cstmt.setInt   (2, XxcmnUtility.intValue(movLineId)); // 移動明細ID

      // PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        
        cstmt.close();
      
      //CLOSE処理中にエラーが発生した場合
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updateShippedQuantity

  /*****************************************************************************
   * 移動依頼/指示明細アドオンの入庫実績数量を更新するメソッドです。
   * @param trans        - トランザクション
   * @param movLineId    - 移動依頼/指示明細アドオンID
   * @param shipToQty    - 入庫実績数量
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void updateShipToQuantity(
    OADBTransaction trans,
     Number movLineId,
     String shipToQty
  ) throws OAException
  {
    String apiName   = "updateShipToQuantity";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                  );
    sb.append("  UPDATE xxinv_mov_req_instr_lines xmril "               ); // 移動依頼/指示明細アドオン
    sb.append("  SET    xmril.ship_to_quantity  = TO_NUMBER(:1) "       ); // 1.入庫実績数量
    sb.append("        ,xmril.last_updated_by   = FND_GLOBAL.USER_ID "  ); // 最終更新者
    sb.append("        ,xmril.last_update_date  = SYSDATE "             ); // 最終更新日
    sb.append("        ,xmril.last_update_login = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン
    sb.append("  WHERE xmril.mov_line_id = :2; "                        ); // 2.移動明細ID
    sb.append("END; "                                                   );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, shipToQty);                        // 入庫実績数量
      cstmt.setInt   (2, XxcmnUtility.intValue(movLineId)); // 移動明細ID

      // PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        // PLSQLクローズ
        cstmt.close();
      
      //CLOSE処理中にエラーが発生した場合
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updateShipToQuantity

  /*****************************************************************************
   * 出庫実績数量または入庫実績数量がすべて登録されているかどうかを判定するメソッドです。
   * @param trans         - トランザクション
   * @param movHeaderId   - 移動ヘッダID
   * @param mode          - 1:出庫実績数量をチェック  2:入庫実績数量をチェック
   * @return boolean      - true:すべて登録済  false:未登録あり
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean isQuantityAllEntry(
    OADBTransaction trans,
     Number movHeaderId,
     String mode
  ) throws OAException
  {
    String apiName   = "isQuantityAllEntry";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                      );
    sb.append("  SELECT COUNT(1) "                          );
    sb.append("  INTO   :1 "                                ); // 1.実績数未登録カウント
    sb.append("  FROM   xxinv_mov_req_instr_lines xmril "   ); // 移動依頼/指示明細
    sb.append("  WHERE xmril.mov_hdr_id = :2 "              ); // 2.移動ヘッダID
    // modeが1の場合、出庫実績数量をチェック
    if ("1".equals(mode))
    {
      sb.append("  AND   xmril.shipped_quantity IS NULL "   ); // 出庫実績数量      

    // modeが2の場合、入庫実績数量をチェック
    } else
    {
      sb.append("  AND   xmril.ship_to_quantity IS NULL "  ); // 入庫実績数量      
    }
// 2008-12-06 H.Itou Add Start
    sb.append("  AND   NVL(xmril.delete_flg,'N') = 'N' "    ); // 削除フラグがN
    sb.append("  AND   ROWNUM = 1; "                        );
    sb.append("END; "                                       );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt   (2, XxcmnUtility.intValue(movHeaderId)); // 移動ヘッダID

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.INTEGER);   // リターンコード

      // PL/SQL実行
      cstmt.execute();

      // 0件の場合、すべて登録済
      if (cstmt.getInt(1) == 0)
      {
        return true;

      // 0件以外の場合、未登録あり
      } else
      {
        return false;
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        
        cstmt.close();
      
      //CLOSE処理中にエラーが発生した場合
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // isQuantityAllEntry

  /*****************************************************************************
   * 移動依頼/指示ヘッダのステータスを更新するメソッドです。
   * @param trans          - トランザクション
   * @param movHeaderId    - 移動ヘッダID
   * @param status      - ステータス
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void updateStatus(
    OADBTransaction trans,
     Number movHeaderId,
     String status
  ) throws OAException
  {
    String apiName   = "updateStatus";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                  );
    sb.append("  UPDATE xxinv_mov_req_instr_headers xmrih "             ); // 移動依頼/指示ヘッダ
    sb.append("  SET    xmrih.status        = :1 "                      ); // 1.ステータス
    sb.append("        ,xmrih.last_updated_by   = FND_GLOBAL.USER_ID "  ); // 最終更新者
    sb.append("        ,xmrih.last_update_date  = SYSDATE "             ); // 最終更新日
    sb.append("        ,xmrih.last_update_login = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン
    sb.append("  WHERE xmrih.mov_hdr_id         = :2; "                 ); // 2.移動ヘッダID
    sb.append("END; "                                                   );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, status);                             // ステータス
      cstmt.setInt   (2, XxcmnUtility.intValue(movHeaderId)); // 移動ヘッダID

      // PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        
        cstmt.close();
      
      //CLOSE処理中にエラーが発生した場合
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updateStatus

  /*****************************************************************************
   * 移動依頼/指示ヘッダの実績訂正フラグをYに更新するメソッドです。
   * @param trans          - トランザクション
   * @param movHeaderId    - 移動ヘッダID
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void updateCorrectActualFlg(
    OADBTransaction trans,
     Number movHeaderId
  ) throws OAException
  {
    String apiName   = "updateCorrectActualFlg";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                  );
    sb.append("  UPDATE xxinv_mov_req_instr_headers xmrih "             ); // 移動依頼/指示ヘッダ
    sb.append("  SET    xmrih.correct_actual_flg = 'Y' "                ); // 実績訂正フラグ
    sb.append("        ,xmrih.last_updated_by    = FND_GLOBAL.USER_ID "  ); // 最終更新者
    sb.append("        ,xmrih.last_update_date   = SYSDATE "             ); // 最終更新日
    sb.append("        ,xmrih.last_update_login  = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン
    sb.append("  WHERE xmrih.mov_hdr_id          = :1; "                 ); // 1.移動ヘッダID
    sb.append("END; "                                                   );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1, XxcmnUtility.intValue(movHeaderId)); // 移動ヘッダID

      // PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        // PLSQLクローズ
        cstmt.close();
      
      //CLOSE処理中にエラーが発生した場合
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updateCorrectActualFlg

  /*****************************************************************************
   * 移動ロット詳細アドオンから実績数量を取得するメソッドです。
   * @param trans            - トランザクション
   * @param movLineId        - 受注明細アドオンID
   * @param documentTypeCode - 文書タイプ(10:出荷依頼、30:支給指示)
   * @param recordTypeCode   - レコードタイプ(10：指示、20：出庫実績  30：入庫実績)
   * @param lotId            - ロットID
   * @return Number          - 実績数量
   * @throws OAException - OA例外
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

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                          );
    sb.append("  SELECT xmld.actual_quantity actual_quantity "  ); // 実績数量
    sb.append("  INTO   :1 "                                    );
    sb.append("  FROM   xxinv_mov_lot_details xmld "            ); //   移動ロット詳細アドオン
    sb.append("  WHERE  xmld.mov_line_id        = :2 "          ); // 2.受注明細アドオンID
    sb.append("  AND    xmld.document_type_code = :3 "          ); // 3.文書タイプ
    sb.append("  AND    xmld.record_type_code   = :4 "          ); // 4.レコードタイプ
    sb.append("  AND    xmld.lot_id             = :5; "         ); // 5.ロットID
    sb.append("END; "                                           );

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    { 
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(movLineId)); // 受注明細アドオンID
      cstmt.setString(3, documentTypeCode);              // 文書タイプ
      cstmt.setString(4, recordTypeCode);                // レコードタイプ
      cstmt.setInt(5, XxcmnUtility.intValue(lotId));     // ロットID
      
      // パラメータ設定(OUTパラメータ)
// 2008-12-05 H.Itou Mod Start 本番障害#481 小数点を考慮
//      cstmt.registerOutParameter(1, Types.INTEGER);
      cstmt.registerOutParameter(1, Types.NUMERIC);
// 2008-12-05 H.Itou Mod End
      
      // PL/SQL実行
      cstmt.execute();

// 2008-12-05 H.Itou Mod Start 本番障害#481 小数点を考慮
//      return new Number(cstmt.getInt(1));  // 実績数量を返す。
      return new Number(cstmt.getObject(1));  // 実績数量を返す。
// 2008-12-05 H.Itou Mod End

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getActualQuantity
// 2008-07-10 H.Itou ADD START

 /*****************************************************************************
   * 移動依頼/指示ヘッダアドオンが自分自身のコンカレント起動により更新されたかどうかチェックするメソッドです。
   * @param trans          - トランザクション
   * @param movHeaderId    - ヘッダID
   * @param concName       - コンカレント名
   * @return boolean  - true:自分が起動したコンカレントより更新されている
   *                   - false:自分が起動したコンカレントより更新されていない
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean isMovHdrUpdForOwnConc(
    OADBTransaction trans,
    Number movHeaderId,
    String concName
  ) throws OAException
  {
    String apiName     = "isMovHdrUpdForOwnConc";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);

    sb.append("BEGIN                                                                        ");
    sb.append("  SELECT TO_CHAR(COUNT(1))                                                   ");
    sb.append("  INTO   :1                                                                  "); // 1:件数
    sb.append("  FROM   xxinv_mov_req_instr_headers xmrih                                   "); // 移動依頼/指示ヘッダアドオン
    sb.append("  WHERE  xmrih.mov_hdr_id  = :2                                              "); // 2:ヘッダID
    sb.append("  AND    xmrih.last_updated_by  = FND_GLOBAL.USER_ID                         "); // ユーザーID
    sb.append("  AND    xmrih.last_update_date = xmrih.program_update_date                  "); // 最終更新日とプログラム更新日が同じ
    sb.append("  AND    EXISTS (                                                            "); // 指定したコンカレントで更新されたレコード
    sb.append("           SELECT 1                                                          ");
    sb.append("           FROM   fnd_concurrent_programs     fcp                            "); // コンカレントプログラムテーブル
    sb.append("           WHERE  fcp.concurrent_program_name = :3                           "); // 3:コンカレント名
    sb.append("           AND    fcp.concurrent_program_id   = xmrih.program_id             "); // コンカレントプログラムID
    sb.append("           AND    fcp.application_id          = xmrih.program_application_id "); // アプリケーションID
    sb.append("           )                                                                 ");
    sb.append("  AND    ROWNUM = 1;                                                         ");
    sb.append("END;                                                                         ");

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    { 
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR);
      
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(movHeaderId));   // ヘッダID
      cstmt.setString(3, concName);                          // コンカレント名
      
      // PL/SQL実行
      cstmt.execute();

      // OUTパラメータ取得
      String cnt = cstmt.getString(1);  // 戻り値

      // 0件の場合、自分が起動したコンカレントより更新されていないので、falseを返す。
      if (XxcmnConstants.STRING_ZERO.equals(cnt))
      {
        return false;

      // 1件の場合、自分が起動したコンカレントより更新されているので、trueを返す。
      } else
      {
        return true;
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
        // ロールバック
        XxinvUtility.rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        XxinvUtility.rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // isMovHdrUpdForOwnConc

 /*****************************************************************************
   * 移動依頼/指示明細アドオンが自分自身のコンカレント起動により更新されたかどうかチェックするメソッドです。
   * @param trans          - トランザクション
   * @param movLineId      - 明細ID
   * @param concName       - コンカレント名
   * @return boolean   - true:自分が起動したコンカレントより更新されている
   *                   - false:自分が起動したコンカレントより更新されていない
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean isMovLineUpdForOwnConc(
    OADBTransaction trans,
    Number movLineId,
    String concName
  ) throws OAException
  {
    String apiName     = "isMovLineUpdForOwnConc";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);

    sb.append("BEGIN                                                                        ");
    sb.append("  SELECT TO_CHAR(COUNT(1))                                                   ");
    sb.append("  INTO   :1                                                                  "); // 1:件数
    sb.append("  FROM   xxinv_mov_req_instr_lines xmril                                     "); // 移動依頼/指示明細アドオン
    sb.append("  WHERE  xmril.mov_line_id  = :2                                             "); // 2:明細ID
    sb.append("  AND    xmril.last_updated_by  = FND_GLOBAL.USER_ID                         "); // ユーザーID
    sb.append("  AND    xmril.last_update_date = xmril.program_update_date                  "); // 最終更新日とプログラム更新日が同じ
    sb.append("  AND    EXISTS (                                                            "); // 指定したコンカレントで更新されたレコード
    sb.append("           SELECT 1                                                          ");
    sb.append("           FROM   fnd_concurrent_programs     fcp                            "); // コンカレントプログラムテーブル
    sb.append("           WHERE  fcp.concurrent_program_name = :3                           "); // 3:コンカレント名
    sb.append("           AND    fcp.concurrent_program_id   = xmril.program_id             "); // コンカレントプログラムID
    sb.append("           AND    fcp.application_id          = xmril.program_application_id "); // アプリケーションID
    sb.append("           )                                                                 ");
    sb.append("  AND    ROWNUM = 1;                                                         ");
    sb.append("END;                                                                         ");

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    { 
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR);
      
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(movLineId));     // 明細ID
      cstmt.setString(3, concName);                          // コンカレント名
      
      // PL/SQL実行
      cstmt.execute();

      // OUTパラメータ取得
      String cnt = cstmt.getString(1);  // 戻り値

      // 0件の場合、自分が起動したコンカレントより更新されていないので、falseを返す。
      if (XxcmnConstants.STRING_ZERO.equals(cnt))
      {
        return false;

      // 1件の場合、自分が起動したコンカレントより更新されているので、trueを返す。
      } else
      {
        return true;
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
        // ロールバック
        XxinvUtility.rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        XxinvUtility.rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // isMovLineUpdForOwnConc
// 2008-07-10 H.Itou ADD END
// 2010-02-18 H.Itou ADD START E_本稼動_01612
  /*****************************************************************************
   * 移動ロット詳細の実績計上済フラグを更新するメソッドです。
   * @param trans          - トランザクション
   * @param movHeaderId    - 移動ヘッダID
   * @param movHeaderId    - 実績計上済フラグ
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void updateActualConfirmClass(
    OADBTransaction trans,
     Number movHeaderId,
     String actualConfirmClass
  ) throws OAException
  {
    String apiName   = "updateActualConfirmClass";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE                                                                    ");
    sb.append("  lt_mov_hdr_id         xxinv_mov_req_instr_lines.mov_hdr_id    %TYPE;     ");
    sb.append("  lt_actual_confirm_class xxinv_mov_lot_details.actual_confirm_class%TYPE; ");
  	sb.append("BEGIN                                                                      ");
                 // INパラメータ設定
    sb.append("  lt_mov_hdr_id           := :1;                                           "); // 1.移動ヘッダID
    sb.append("  lt_actual_confirm_class := :2;                                           "); // 2.実績計上済フラグ
                 // 移動ロット詳細UPDATE
    sb.append("  UPDATE xxinv_mov_lot_details xmld                                        "); // 移動ロット詳細
    sb.append("  SET    xmld.actual_confirm_class = lt_actual_confirm_class               "); // 実績計上済フラグ
    sb.append("        ,xmld.last_updated_by    = FND_GLOBAL.USER_ID                      "); // 最終更新者
    sb.append("        ,xmld.last_update_date   = SYSDATE                                 "); // 最終更新日
    sb.append("        ,xmld.last_update_login  = FND_GLOBAL.LOGIN_ID                     "); // 最終更新ログイン
    sb.append("  WHERE  xmld.document_type_code = '20'                                    "); // 文書タイプ 20:移動
    sb.append("  AND    xmld.record_type_code  <> '10'                                    "); // レコードタイプ 10:指示以外
    sb.append("  AND    xmld.mov_line_id       IN (                                       "); // 同一移動ヘッダIDで、取消されていない移動明細ID
    sb.append("           SELECT xmril.mov_line_id          mov_line_id                   ");
    sb.append("           FROM   xxinv_mov_req_instr_lines  xmril                         ");
    sb.append("           WHERE  xmril.mov_hdr_id = lt_mov_hdr_id                         ");
    sb.append("           AND    xmril.delete_flg = 'N')                                  ");
    sb.append("  ;                                                                        ");
    sb.append("END;                                                                       ");
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1, XxcmnUtility.intValue(movHeaderId)); // 1.移動ヘッダID
      cstmt.setString(2, actualConfirmClass);                // 2.実績計上済フラグ

      // PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
        // PLSQLクローズ
        cstmt.close();
      
      //CLOSE処理中にエラーが発生した場合
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updateActualConfirmClass
// 2010-02-18 H.Itou ADD END
}