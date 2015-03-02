/*============================================================================
* ファイル名 : XxwshUtility
* 概要説明   : 出荷・引当/配車共通関数
* バージョン : 1.16
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-27 1.0  伊藤ひとみ   新規作成
* 2008-06-27 1.1  伊藤ひとみ   結合不具合TE080_400#157
* 2008-07-02 1.2  二瓶大輔　   内部変更要求対応#152
* 2008-07-23 1.3  伊藤ひとみ   内部課題#32 checkNumOfCases、getItemCode追加
* 2008-08-01 1.4  伊藤ひとみ   内部変更要求#176対応
* 2008-08-07 1.5  二瓶大輔　   内部変更要求#166対応
* 2008-09-19 1.6  伊藤ひとみ   T_TE080_BPO_400指摘76対応
* 2008-10-07 1.7  伊藤ひとみ   統合テスト指摘240対応
* 2008-10-24 1.8  二瓶大輔     TE080_BPO_600 No22
* 2008-12-05 1.9  伊藤ひとみ   本番障害#452対応
* 2008-12-06 1.10 宮田         本番障害#484対応
* 2008-12-15 1.11 二瓶大輔     本番障害#648対応
* 2009-01-22 1.12 伊藤ひとみ   本番障害#1000対応
* 2009-01-26 1.13 伊藤ひとみ   本番障害#936対応
* 2009-02-13 1.14 伊藤ひとみ   本番障害#863対応
* 2009-12-04 1.15 伊藤ひとみ     本稼動障害#11対応
* 2014-11-11 1.16 桐生和幸     E_本稼働_12237対応
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
 * 出荷・引当/配車共通関数クラスです。
 * @author  ORACLE 伊藤ひとみ
 * @version 1.15
 ***************************************************************************
 */
public class XxwshUtility 
{
  public XxwshUtility()
  {
  }

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
   * OPMロットマスタの妥当性チェックを行うメソッドです。
   * @param trans     - トランザクション
   * @param params    - パラメータ
   * @return HashMap  - ロットマスタ情報
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void seachOpmLotMst(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "seachOpmLotMst";

    String lotNo            = (String)params.get("lotNo");          // ロットNo
    Date   manufacturedDate = (Date)params.get("manufacturedDate"); // 製造年月日
    Date   useByDate        = (Date)params.get("useByDate");        // 賞味期限
    String koyuCode         = (String)params.get("koyuCode");       // 固有記号
    Number itemId           = (Number)params.get("itemId");         // 品目ID
    String prodClassCode    = (String)params.get("prodClassCode");  // 商品区分
    String itemClassCode    = (String)params.get("itemClassCode");  // 品目区分

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                                            );
    sb.append("  SELECT xlsv.status_desc               status_desc             "                  ); // 1:ロットステータス名称
    sb.append("        ,xlsv.raw_mate_turn_m_reserve   raw_mate_turn_m_reserve "                  ); // 2:生産原料投入(手動引当)
    sb.append("        ,xlsv.raw_mate_turn_rel         raw_mate_turn_rel       "                  ); // 3:生産原料投入(実績)
    sb.append("        ,xlsv.pay_provision_m_reserve   pay_provision_m_reserve "                  ); // 4:有償支給(手動引当)
    sb.append("        ,xlsv.pay_provision_rel         pay_provision_rel       "                  ); // 5:有償支給(実績)
    sb.append("        ,xlsv.move_inst_m_reserve       move_inst_m_reserve     "                  ); // 6:移動指示(手動引当)
    sb.append("        ,xlsv.move_inst_a_reserve       move_inst_a_reserve     "                  ); // 7:移動指示(自動引当)
    sb.append("        ,xlsv.move_inst_rel             move_inst_rel           "                  ); // 8:移動指示(実績)
    sb.append("        ,xlsv.ship_req_m_reserve        ship_req_m_reserve      "                  ); // 9:出荷依頼(手動引当)
    sb.append("        ,xlsv.ship_req_a_reserve        ship_req_a_reserve      "                  ); // 10:出荷依頼(自動引当)
    sb.append("        ,xlsv.ship_req_rel              ship_req_rel            "                  ); // 11:出荷依頼(実績)
    sb.append("        ,ilm.lot_no                     lot_no                  "                  ); // 12:ロットNo
    sb.append("        ,FND_DATE.STRING_TO_DATE(ilm.attribute1,'YYYY/MM/DD')  manufactured_date " ); // 13:製造年月日
    sb.append("        ,FND_DATE.STRING_TO_DATE(ilm.attribute3,'YYYY/MM/DD')  use_by_date       " ); // 14:賞味期限
    sb.append("        ,ilm.attribute2                 koyu_code               "                  ); // 15:固有記号
    sb.append("        ,ilm.lot_id                     lot_id                  "                  ); // 16:ロットID
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
    sb.append("  FROM   ic_lots_mst            ilm "                                              ); // OPMロットマスタ
    sb.append("        ,xxcmn_lot_status_v     xlsv "                                             ); // ロットステータス情報VIEW
    sb.append("  WHERE  ilm.attribute23 = xlsv.lot_status "                                       );
    sb.append("  AND    ilm.item_id = :17 "                                                       ); // 品目ID
    sb.append("  AND    xlsv.prod_class_code = :18 "                                              ); // 商品区分
    // 品目区分が5:製品でない場合
    sb.append("  AND  (((:19 <> '5') "                                                            );
    sb.append("  AND    (:20 IS NULL OR ilm.lot_no = :20)) "                                      ); // ロットNo      
    // 品目区分が5:製品の場合
    sb.append("  OR    ((:19 = '5') "                                                             );
    sb.append("  AND    (:21 IS NULL OR ilm.attribute1 = TO_CHAR(:21, 'YYYY/MM/DD')) "            ); // 製造年月日
    sb.append("  AND    (:22 IS NULL OR ilm.attribute3 = TO_CHAR(:22, 'YYYY/MM/DD')) "            ); // 賞味期限
    sb.append("  AND    (:23 IS NULL OR ilm.attribute2 = :23))); "                                ); // 固有記号      
    sb.append("  :24 := '1'; "                                                                    );
    sb.append("EXCEPTION "                                                                        );
    sb.append("  WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN "                                       );
    sb.append("    :24 := '0'; "                                                                  );
    sb.append("END; "                                                                             );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(17,    XxcmnUtility.intValue(itemId));            // 品目ID
      cstmt.setString(18, prodClassCode);                            // 商品区分
      cstmt.setString(19, itemClassCode);                            // 品目区分
      cstmt.setString(20, lotNo);                                    // ロットNo
      cstmt.setDate(21,   XxcmnUtility.dateValue(manufacturedDate)); // 製造年月日
      cstmt.setDate(22,   XxcmnUtility.dateValue(useByDate));        // 賞味期限
      cstmt.setString(23, koyuCode);                                 // 固有記号
      
      // パラメータ設定(OUTパラメータ)
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
      
      // PL/SQL実行
      cstmt.execute();

      // OUTパラメータ取得
      params.put("statusDesc"          , cstmt.getString(1));           // ステータスコード名称
      params.put("rawMateTurnMReserve" , cstmt.getString(2));           // 生産原料投入(手動引当)
      params.put("rawMateTurnRel"      , cstmt.getString(3));           // 生産原料投入(実績)
      params.put("payProvisionMReserve", cstmt.getString(4));           // 有償支給(手動引当)
      params.put("payProvisionRel"     , cstmt.getString(5));           // 有償支給(実績)
      params.put("moveInstMReserve"    , cstmt.getString(6));           // 移動指示(手動引当)
      params.put("moveInstAReserve"    , cstmt.getString(7));           // 移動指示(自動引当)
      params.put("moveInstRel"         , cstmt.getString(8));           // 移動指示(実績)
      params.put("shipReqMReserve"     , cstmt.getString(9));           // 出荷依頼(手動引当)
      params.put("shipReqAReserve"     , cstmt.getString(10));          // 出荷依頼(自動引当)
      params.put("shipReqRel"          , cstmt.getString(11));          // 出荷依頼(実績)
      params.put("lotNo"               , cstmt.getString(12));          // ロットNo
      params.put("manufacturedDate"    , cstmt.getObject(13));          // 製造年月日
      params.put("useByDate"           , cstmt.getObject(14));          // 賞味期限
      params.put("koyuCode"            , cstmt.getString(15));          // 固有記号
      params.put("lotId"               , new Number(cstmt.getInt(16))); // ロットID
      params.put("retCode"             , cstmt.getString(24));          // 戻り値

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // seachOpmLotMst

  /*****************************************************************************
   * 移動ロット詳細IDシーケンスより、新規IDを取得するメソッドです。
   * @param trans   - トランザクション
   * @throws OAException - OA例外
   ****************************************************************************/
  public static Number getMovLotDtlId(
    OADBTransaction trans
  ) throws OAException
  {
    return XxcmnUtility.getSeq(trans, XxwshConstants.XXINV_MOV_LOT_S1);
  } // getMovLotDtlId
  
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
    sb.append("DECLARE "                                                      );
    sb.append("  lv_close_date VARCHAR2(30); "                                ); // クローズ日付
    sb.append("BEGIN "                                                        );
                 // OPM在庫会計期間CLOSE年月取得
    sb.append("   lv_close_date := xxcmn_common_pkg.get_opminv_close_period; ");
    sb.append("   :1 := lv_close_date; "                                      );
                 // 比較日付がクローズ日付以前の場合、N：クローズをセット
    sb.append("   IF (lv_close_date >= TO_CHAR(:2, 'YYYYMM')) THEN "          ); 
    sb.append("     :3 := 'N'; "                                              );
                 // 比較日付がクローズ日付以降の場合、Y：クローズ前をセット
    sb.append("   ELSE "                                                      );
    sb.append("     :3 := 'Y'; "                                              );
    sb.append("   END IF; "                                                   ); 
    sb.append("END; "                                                         );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setDate(2, XxcmnUtility.dateValue(chkDate)); // 日付
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR); // CLOSE年月
      cstmt.registerOutParameter(3, Types.VARCHAR); // 戻り値
      
      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      String closeDate = cstmt.getString(1);
      String plSqlRet  = cstmt.getString(3);

      // クローズしている場合
      if (XxcmnConstants.STRING_N.equals(cstmt.getString(3)))
      {
        // 在庫会計期間チェックエラー
        // トークン生成
        MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_DATE, cstmt.getString(1)) };
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH13304, 
          tokens);  
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    } 
  } // chkStockClose

  /*****************************************************************************
   * 配車解除関数を呼び出します。
   * @param bizType - 業務種別 1:出荷,2:支給,3:移動
   * @param reqNo   - 依頼No/移動番号
   * @return String - 戻り値 0:成功,1:パラメータチェックエラー,-1:配車解除失敗
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String cancelCareersSchedile(
    OADBTransaction trans,
    String bizType,
    String reqNo
  ) throws OAException
  {
    String apiName = "cancelCareersSchedile";  // API名

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
// 2008-10-24 D.Nihei MOD START TE080_BPO_600 No22
//    sb.append("  :1 := xxwsh_common_pkg.cancel_careers_schedule(:2, :3, :4); ");
    sb.append("  :1 := xxwsh_common_pkg.cancel_careers_schedule(:2, :3, '1', :4); ");
// 2008-10-24 D.Nihei MOD END
    sb.append("END; ");

    // PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try 
    {
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR); // 戻り値

      // パラメータ設定(INパラメータ)
      cstmt.setString(2, bizType); // 業務種別
      cstmt.setString(3, reqNo);   // 依頼No/移動番号

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(4, Types.VARCHAR); // エラーメッセージ

      // PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      String retCode = cstmt.getString(1);
      // 戻り値が処理成功以外はログにエラーメッセージを出力
      if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {
        // ロールバック
        rollBack(trans);

        String errMsg = cstmt.getString(4);
        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              errMsg,
                              6);
      }

      // 戻り値返却
      return retCode;

    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);

      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);

      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                             XxcmnConstants.XXCMN10123
                             );

    } finally 
    {
      try
      {
        // 処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // cancelCareersSchedile

  /*****************************************************************************
   * ロット逆転防止チェックAPIを実行します。
   * @param trans - トランザクション
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
    sb.append("    iv_lot_biz_class    => '2',           ");   //  .ロット逆転処理種別 2:出荷
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

      String retCode = cstmt.getString(5);             // リターンコード
      String errmsgCode = cstmt.getString(6);          // エラーメッセージコード
      String errmsg = cstmt.getString(7);              // エラーメッセージ

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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
      cstmt.setInt(2, XxcmnUtility.intValue(whseId)); // 保管倉庫ID
      cstmt.setInt(3, XxcmnUtility.intValue(itemId)); // 品目ID
      // ロット管理外品の場合、ロットIDはNULL
      if (XxwshConstants.LOT_CTL_N.equals(lotCtl))
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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
      if (XxwshConstants.LOT_CTL_N.equals(lotCtl))
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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
   * 引当可能数算出APIを実行します。(有効日指定バージョン)
   * @param trans      - トランザクション
   * @param whseId     - OPM保管倉庫ID
   * @param itemId     - OPM品目ID
   * @param lotId      - ロットID
   * @param lotCtl     - ロット管理区分
   * @param activeDate - 有効日
   * @return Number - 引当可能数
   * @throws OAException - OA例外
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

    // OUTパラメータ
    Number canEncQty    = new Number();
    
    //PL/SQL作成
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                                    );
    sb.append("  :1 := xxcmn_common_pkg.get_can_enc_qty( "); // 1.引当可能数
    sb.append("        in_whse_id  => :2,  "              ); // 2.OPM保管倉庫ID
    sb.append("        in_item_id  => :3,  "              ); // 3.OPM品目ID
    sb.append("        in_lot_id   => :4,  "              ); // 4.ロットID
    sb.append("        in_active_date => :5); "           ); // 5.有効日
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
      if (XxwshConstants.LOT_CTL_N.equals(lotCtl))
      {
        cstmt.setNull(4, Types.INTEGER); // ロットID
      } else
      {
        cstmt.setInt(4, XxcmnUtility.intValue(lotId));  // ロットID        
      }
      
      cstmt.setDate(5, XxcmnUtility.dateValue(activeDate)); // 有効日
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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
   * @return boolean - true:あり
   *                  - false:なし
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
      cstmt.setString(3, recordTypeCode);              // 文書タイプ
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
        XxwshUtility.rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
        XxwshUtility.rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
   * 受注ヘッダアドオンロックを取得します。
   * @param trans          - トランザクション
   * @param orderHeaderId  - 受注ヘッダアドオンID
   * @return HashMap
   * @throws OAException - OA例外
   ****************************************************************************/
  public static HashMap getXxwshOrderHeadersAllLock(
    OADBTransaction trans,
    Number orderHeaderId
  ) throws OAException
  {
    String apiName = "getXxwshOrderHeadersAllLock";
    HashMap ret = new HashMap();
    
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                                                          );
                 // ユーザー定義エラー
    sb.append("  lock_expt             EXCEPTION; "                                               );
    sb.append("  PRAGMA EXCEPTION_INIT(lock_expt, -54); "                                         );
    sb.append("BEGIN "                                                                            );
                 // ロック取得
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

    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR);   // 最終更新日
      cstmt.registerOutParameter(3, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(4, Types.VARCHAR);   // エラーメッセージ
      
      //PL/SQL実行
      cstmt.execute();

      // ロックエラー終了の場合  
      if ("1".equals(cstmt.getString(3)))
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          cstmt.getString(4),
          6);

        ret.put("retFlag", XxcmnConstants.RETURN_ERR1); // 戻り値 E1:ロックエラー

      // 正常終了の場合
      } else
      {
        ret.put("retFlag",        XxcmnConstants.RETURN_SUCCESS); // 戻り値 1:正常
        ret.put("lastUpdateDate", cstmt.getString(1));            // 最終更新日
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    // 戻り値
    return ret;
  } // getXxwshOrderHeadersAllLock

  /*****************************************************************************
   * 受注明細アドオンロックを取得します。
   * @param trans          - トランザクション
   * @param orderHeaderId    - 受注ヘッダアドオンID
   * @return HashMap
   * @throws OAException - OA例外
   ****************************************************************************/
  public static HashMap getXxwshOrderLinesAllLock(
    OADBTransaction trans,
    Number orderHeaderId
  ) throws OAException
  {
    String apiName = "getXxwshOrderLinesAllLock";
    HashMap ret = new HashMap();
    
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                                                               );
                 // ユーザー定義エラー
    sb.append("  lock_expt             EXCEPTION; "                                                    );
    sb.append("  PRAGMA EXCEPTION_INIT(lock_expt, -54); "                                              );
    sb.append("  CURSOR lock_cur IS "                                                                  );
    sb.append("    SELECT xola.order_header_id  order_header_id "                                      );
    sb.append("    FROM   xxwsh_order_lines_all xola "                                                 );
    sb.append("    WHERE  xola.order_header_id = :1 "                                                  );
    sb.append("    FOR UPDATE NOWAIT; "                                                                );
    sb.append("  lock_rec lock_cur%ROWTYPE; "                                                          );
    sb.append("BEGIN "                                                                                 );
                 // ロック取得
    sb.append("  OPEN lock_cur; "                                                                      );
    sb.append("  FETCH lock_cur INTO lock_rec; "                                                                      );
    sb.append("  CLOSE lock_cur; "                                                                     );
                 // 最終更新日最大値を取得
    sb.append("  SELECT TO_CHAR(MAX(xola.last_update_date),'YYYY/MM/DD HH24:MI:SS')  last_update_date ");
    sb.append("  INTO   :2  "                                                                          );
    sb.append("  FROM   xxwsh_order_lines_all xola "                                                   );
    sb.append("  WHERE  xola.order_header_id = :1 "                                                    );
// 2008-07-02 D.Nihei UPD Start
//    sb.append("  AND   NVL(xola.delete_flag,'N') = 'N' ;"                                              ); // 削除フラグ
    sb.append("  ;");
// 2008-07-02 D.Nihei UPD Start
    sb.append("EXCEPTION "                                                                             );
    sb.append("  WHEN lock_expt THEN "                                                                 );
    sb.append("    :3 := '1'; "                                                                        );
    sb.append("    :4 := SQLERRM; "                                                                    );
    sb.append("END; "                                                                                  );

    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1, XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(2, Types.VARCHAR);   // 最終更新日
      cstmt.registerOutParameter(3, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(4, Types.VARCHAR);   // エラーメッセージ
      
      //PL/SQL実行
      cstmt.execute();

      // ロックエラー終了の場合  
      if ("1".equals(cstmt.getString(3)))
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          cstmt.getString(4),
          6);

        ret.put("retFlag", XxcmnConstants.RETURN_ERR1); // 戻り値 E1:ロックエラー

      // 正常終了の場合
      } else
      {
        ret.put("retFlag",        XxcmnConstants.RETURN_SUCCESS); // 戻り値 1:正常
        ret.put("lastUpdateDate", cstmt.getString(2));            // 最終更新日
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    // 戻り値
    return ret;
  } // getXxwshOrderLinesAllLock

  /*****************************************************************************
   * 移動ロット詳細アドオンロックを取得します。
   * @param trans            - トランザクション
   * @param movLineId        - 受注明細アドオンID
   * @param documentTypeCode - 文書タイプ(10:出荷依頼、30:支給指示)
   * @param recordTypeCode   - レコードタイプ(10：指示、20：出庫実績  30：入庫実績)
   * @return String - 1:正常  0:異常  E1:ロックエラー
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String getXxinvMovLotDetailsLock(
    OADBTransaction trans,
    Number movLineId,
    String documentTypeCode,
    String recordTypeCode
  ) throws OAException
  {
    String apiName = "getXxinvMovLotDetailsLock";
    String retCode = XxcmnConstants.RETURN_NOT_EXE; // 戻り値
    
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                     );
    sb.append("  lock_expt             EXCEPTION; "          ); 
    sb.append("  PRAGMA EXCEPTION_INIT(lock_expt, -54); "    );
    sb.append("CURSOR lock_cur IS "                          );
    sb.append("  SELECT 1 "                                  );
    sb.append("  FROM   xxinv_mov_lot_details xmld "         );
    sb.append("  WHERE  xmld.mov_line_id        = :1 "       ); // 1.受注明細アドオンID
    sb.append("  AND    xmld.document_type_code = :2 "       ); // 2.文書タイプ
    sb.append("  AND    xmld.record_type_code   = :3 "       ); // 3.レコードタイプ
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

    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1,    XxcmnUtility.intValue(movLineId)); // 受注明細アドオンID
      cstmt.setString(2, documentTypeCode);                 // 文書タイプ
      cstmt.setString(3, recordTypeCode);                   // レコードタイプ
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(4, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(5, Types.VARCHAR);   // エラーメッセージ
      
      //PL/SQL実行
      cstmt.execute();

      // ロックエラー終了の場合  
      if ("1".equals(cstmt.getString(4)))
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          cstmt.getString(5),
          6);

        retCode = XxcmnConstants.RETURN_ERR1;// 戻り値 E1:ロックエラー

      // 正常終了の場合
      } else
      {
        retCode = XxcmnConstants.RETURN_SUCCESS;// 戻り値 1:正常
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    // 戻り値
    return retCode;
  } // getXxinvMovLotDetailsLock

  /*****************************************************************************
   * 移動ロット詳細アドオンに追加処理を行うメソッドです。
   * @param trans   - トランザクション
   * @param params  - パラメータ
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void insertXxinvMovLotDetails(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "insertXxinvMovLotDetails";

    Number orderLineId      = (Number)params.get("orderLineId");      // 明細ID
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
      cstmt.setInt(1,    XxcmnUtility.intValue(orderLineId)); // 明細ID
      cstmt.setString(2, documentTypeCode);                   // 文書タイプ
      cstmt.setString(3, recordTypeCode);                     // レコードタイプ
      cstmt.setInt(4,    XxcmnUtility.intValue(itemId));      // OPM品目ID
      cstmt.setString(5, itemCode);                           // 品目
      cstmt.setInt(6,    XxcmnUtility.intValue(lotId));       // ロットID
      cstmt.setString(7, lotNo);                              // ロットNo
      cstmt.setDate(8,   XxcmnUtility.dateValue(actualDate)); // 実績日
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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // insertXxinvMovLotDetails

  /*****************************************************************************
   * 受注明細アドオンの出荷実績数量を更新するメソッドです。
   * @param trans        - トランザクション
   * @param orderLineId  - 受注明細アドオンID
   * @param shippedQty   - 出荷実績数量
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void updateShippedQuantity(
    OADBTransaction trans,
     Number orderLineId,
     String shippedQty
  ) throws OAException
  {
    String apiName   = "updateShippedQuantity";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
// 2008-09-19 H.Itou Add Start
    sb.append("DECLARE "                                                                        );
    sb.append("  lt_in_param_quantity      xxwsh_order_lines_all.shipped_quantity%TYPE; "       ); // INパラメータ.更新する出荷実績数量
    sb.append("  lt_in_param_order_line_id xxwsh_order_lines_all.order_line_id%TYPE; "          ); // INパラメータ.受注明細ID
    sb.append("  lt_shipped_quantity       xxwsh_order_lines_all.shipped_quantity%TYPE; "       ); // DB出荷実績数量
    sb.append("  lt_shipping_result_if_flg xxwsh_order_lines_all.shipping_result_if_flg%TYPE; " ); // DB出荷実績インタフェース済フラグ
    sb.append("  lt_req_status             xxwsh_order_headers_all.req_status%TYPE; "           ); // DBステータス
// 2008-09-19 H.Itou Add End
    sb.append("BEGIN "                                                                          );
// 2008-09-19 H.Itou Add Start
                 // INパラメータ取得
    sb.append("  lt_in_param_quantity := TO_NUMBER(:1); "                                       ); // INパラメータ.更新する出荷実績数量
    sb.append("  lt_in_param_order_line_id := :2; "                                             ); // INパラメータ.受注明細ID

                 // 更新前の出荷実績数量とステータスを取得
    sb.append("  SELECT xola.shipped_quantity       shipped_quantity "                          ); // DB出荷実績数量
    sb.append("        ,xola.shipping_result_if_flg shipping_result_if_flg "                    ); // DB出荷実績インタフェース済フラグ
    sb.append("        ,xoha.req_status             req_status "                                ); // DBステータス
    sb.append("  INTO   lt_shipped_quantity "                                                   );
    sb.append("        ,lt_shipping_result_if_flg "                                             );
    sb.append("        ,lt_req_status "                                                         );
    sb.append("  FROM   xxwsh_order_headers_all xoha "                                          ); // 受注ヘッダアドオン
    sb.append("        ,xxwsh_order_lines_all   xola "                                          ); // 受注明細アドオン
    sb.append("  WHERE xoha.order_header_id = xola.order_header_id "                            );
    sb.append("  AND   xola.order_line_id   = lt_in_param_order_line_id; "                      );

                 // 出荷実績計上済(04)かつ、出荷実績数量が違う値に更新する場合(出荷のデータのみ)
// 2008-12-06 T.Miyata Add Start 本番#484 実績未修正のデータについてもインターフェース済フラグをNにするひつようがある。
//    sb.append("  IF (((lt_shipped_quantity <> lt_in_param_quantity ) "                          );
//    sb.append("    OR (lt_shipped_quantity IS NULL)) "                                          );
    sb.append("  IF (lt_req_status       =  '04')                 THEN "                      );
// 2008-12-06 T.Miyata Add End 本番#484
                   // 出荷実績インタフェース済フラグをNに更新
    sb.append("    lt_shipping_result_if_flg := 'N'; "                                          );
    sb.append("  END IF; "                                                                      );
// 2008-09-19 H.Itou Add End

    sb.append("  UPDATE xxwsh_order_lines_all xola "                                            ); // 受注明細アドオン
    sb.append("  SET    xola.shipped_quantity  = lt_in_param_quantity "                         ); // 1.出荷実績数量
    sb.append("        ,xola.last_updated_by   = FND_GLOBAL.USER_ID "                           ); // 最終更新者
    sb.append("        ,xola.last_update_date  = SYSDATE "                                      ); // 最終更新日
    sb.append("        ,xola.last_update_login = FND_GLOBAL.LOGIN_ID "                          ); // 最終更新ログイン
// 2008-09-19 H.Itou Add Start
    sb.append("        ,xola.shipping_result_if_flg = lt_shipping_result_if_flg "               ); // 出荷実績インタフェース済フラグ
// 2008-09-19 H.Itou Add End
    sb.append("  WHERE  xola.order_line_id = lt_in_param_order_line_id; "                       ); // 2.受注明細アドオンID
    sb.append("END; "                                                                           );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, shippedQty);                         // 出荷実績数量
      cstmt.setInt(2,    XxcmnUtility.intValue(orderLineId)); // 明細ID

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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
    Number movLineId        = (Number)params.get("orderLineId");      // 明細ID
    String documentTypeCode = (String)params.get("documentTypeCode"); // 文書タイプ
    String recordTypeCode   = (String)params.get("recordTypeCode");   // レコードタイプ
    Number lotId            = (Number)params.get("lotId");            // ロットID
    String actualQuantity   = (String)params.get("actualQuantity");        // 実績数量

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                 );
    sb.append("  UPDATE xxinv_mov_lot_details xmld "                   ); // 移動ロット明細アドオン
    sb.append("  SET    xmld.actual_quantity   = TO_NUMBER(:1) "       ); // 1.実績数量
    sb.append("        ,xmld.last_updated_by   = FND_GLOBAL.USER_ID "  ); // 最終更新者
    sb.append("        ,xmld.last_update_date  = SYSDATE "             ); // 最終更新日
    sb.append("        ,xmld.last_update_login = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン
    sb.append("  WHERE  xmld.mov_line_id        = :2 "                 ); // 2.受注明細アドオンID
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
      cstmt.setString(1, actualQuantity);                   // 実績数量
      cstmt.setInt(2,    XxcmnUtility.intValue(movLineId)); // 受注明細アドオンID
      cstmt.setString(3, documentTypeCode);                 // 文書タイプ
      cstmt.setString(4, recordTypeCode);                   // レコードタイプ
      cstmt.setInt(5,    XxcmnUtility.intValue(lotId));     // ロットID

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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
   * 受注ヘッダアドオンのステータスを更新するメソッドです。
   * @param trans          - トランザクション
   * @param orderHeaderId  - 受注ヘッダアドオンID
   * @param reqStatus      - ステータス
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void updateReqStatus(
    OADBTransaction trans,
     Number orderHeaderId,
     String reqStatus
  ) throws OAException
  {
    String apiName   = "updateReqStatus";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                 );
    sb.append("  UPDATE xxwsh_order_headers_all xoha "                 ); // 受注ヘッダアドオン
    sb.append("  SET    xoha.req_status        = :1 "                  ); // 1.ステータス
    sb.append("        ,xoha.last_updated_by   = FND_GLOBAL.USER_ID "  ); // 最終更新者
    sb.append("        ,xoha.last_update_date  = SYSDATE "             ); // 最終更新日
    sb.append("        ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン
    sb.append("  WHERE xoha.order_header_id    = :2; "                 ); // 2.受注ヘッダアドオンID
    sb.append("END; "                                                  );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, reqStatus);                            // ステータス
      cstmt.setInt(2,    XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID

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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updateReqStatus

  /*****************************************************************************
   * 受注明細アドオンの出荷実績数量がすべて登録されているかどうかを判定するメソッドです。
   * @param trans         - トランザクション
   * @param orderHeaderId - 受注ヘッダアドオンID
   * @return boolean      - true:すべて登録済  false:未登録あり
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean checkShippedQuantityEntry(
    OADBTransaction trans,
     Number orderHeaderId
  ) throws OAException
  {
    String apiName   = "checkShippedQuantityEntry";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                      );
    sb.append("  SELECT COUNT(1) "                          ); // 受注明細アドオン
    sb.append("  INTO   :1 "                                ); // 1.出荷実績数未登録カウント
    sb.append("  FROM   xxwsh_order_lines_all xola "        ); // 受注明細アドオン
    sb.append("  WHERE xola.order_header_id    = :2 "       ); // 2.受注ヘッダアドオンID
    sb.append("  AND   NVL(xola.delete_flag,'N') = 'N' "    ); // 削除フラグ
    sb.append("  AND   xola.shipped_quantity IS NULL "      ); // 出荷実績数量
    sb.append("  AND   ROWNUM = 1; "                        );
    sb.append("END; "                                       );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID

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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // checkShippedQuantityEntry

  /*****************************************************************************
   * 受注明細アドオンの最終更新日を取得するメソッドです。
   * @param trans          - トランザクション
   * @param orderHeaderId  - 受注ヘッダアドオンID
   * @return String        - 最終更新日
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String getOrderLineUpdateDate(
    OADBTransaction trans,
     Number orderHeaderId
  ) throws OAException
  {
    String apiName   = "getOrderLineUpdateDate";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                           );
    sb.append("  SELECT TO_CHAR(MAX(xola.last_update_date),'YYYY/MM/DD HH24:MI:SS')  last_update_date "); // 1.最終更新日
    sb.append("  INTO   :1  "                                                                          );
    sb.append("  FROM   xxwsh_order_lines_all xola "                                                   ); // 受注明細アドオン
    sb.append("  WHERE  xola.order_header_id = :2 "                                                    ); // 2.受注ヘッダアドオンID
// 2008-07-02 D.Nihei UPD Start
//    sb.append("  AND   NVL(xola.delete_flag,'N') = 'N' ;"                                              ); // 削除フラグ
    sb.append("  ;");
// 2008-07-02 D.Nihei UPD Start
    sb.append("END; "                                                            );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR);   // 最終更新日

      // PL/SQL実行
      cstmt.execute();
      
      return cstmt.getString(1);

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getOrderLineUpdateDate

  /*****************************************************************************
   * 受注ヘッダアドオンの最終更新日を取得するメソッドです。
   * @param trans            - トランザクション
   * @param orderHeaderId    - 受注ヘッダアドオンID
   * @return String          - 最終更新日
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String getOrderHeaderUpdateDate(
    OADBTransaction trans,
     Number orderHeaderId
  ) throws OAException
  {
    String apiName   = "getOrderHeaderUpdateDate";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                           );
    sb.append("  SELECT TO_CHAR(xoha.last_update_date, 'YYYY/MM/DD HH24:Mi:SS') "); // 1.最終更新日
    sb.append("  INTO   :1 "                                                     );
    sb.append("  FROM   xxwsh_order_headers_all xoha "                           ); // 受注明細アドオン
    sb.append("  WHERE  xoha.order_header_id    = :2; "                          ); // 2.受注ヘッダアドオンID
    sb.append("END; "                                                            );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR);   // 最終更新日

      // PL/SQL実行
      cstmt.execute();
      
      return cstmt.getString(1);

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getOrderHeaderUpdateDate

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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
   * コンカレント：出荷依頼/出荷実績作成処理を発行します。
   * @param  trans       - トランザクション
   * @param  requestNo   - 依頼No
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void doShipRequestAndResultEntry(
    OADBTransaction trans,
    String requestNo
  ) throws OAException
  {
    String apiName      = "doShipRequestAndResultEntry";

// 2008-12-15 D.Nihei Del Start 本番障害#648対応 コメント化
//    //PL/SQLの作成を行います
//    StringBuffer sb = new StringBuffer(1000);
//    sb.append("DECLARE "   );
//    sb.append("  ln_request_id NUMBER; "                                             );
//    sb.append("BEGIN "                                                               );
//                 // 出荷依頼/出荷実績作成処理(コンカレント)呼び出し
//    sb.append("  ln_request_id := fnd_request.submit_request( "                      );
//    sb.append("     application  => 'XXWSH' "                                        ); // アプリケーション名
//    sb.append("    ,program      => 'XXWSH420001C' "                                 ); // プログラム短縮名
//    sb.append("    ,argument1    => NULL "                                           ); // ブロック
//    sb.append("    ,argument2    => NULL "                                           ); // 出荷元
//    sb.append("    ,argument3    => :1 );"                                           ); // 依頼No
//                 // 要求IDがある場合、正常
//    sb.append("  IF ln_request_id > 0 THEN "                                         );
//    sb.append("    :2 := '1'; "                                                      ); // 1:正常終了
//    sb.append("    :3 := ln_request_id; "                                            ); // 要求ID
//// 2008-08-01 H.Itou Del Start
////    sb.append("    COMMIT; "                                                         );
//// 2008-08-01 H.Itou Del End
//                 // 要求IDがない場合、異常
//    sb.append("  ELSE "                                                              );
//    sb.append("    :2 := '0'; "                                                      ); // 0:異常終了
//    sb.append("    :3 := ln_request_id; "                                            ); // 要求ID
//    sb.append("    ROLLBACK; "                                                       );
//    sb.append("  END IF; "                                                           );
//    sb.append("END; "                                                                );
//    
//    //PL/SQLの設定
//    CallableStatement cstmt = trans.createCallableStatement(
//                                sb.toString(),
//                                OADBTransaction.DEFAULT);
//    try
//    {
//      // パラメータ設定(INパラメータ)
//      cstmt.setString(1, requestNo);                  // 依頼No
//      
//      // パラメータ設定(OUTパラメータ)
//      cstmt.registerOutParameter(2, Types.VARCHAR);   // リターンコード
//      cstmt.registerOutParameter(3, Types.INTEGER);   // 要求ID
//      
//      //PL/SQL実行
//      cstmt.execute();
//
//      // 戻り値取得
//      String retFlag  = cstmt.getString(2); // リターンコード
//      int requestId  = cstmt.getInt(3); // 要求ID
//
//      // コンカレント登録失敗の場合
//      if (XxcmnConstants.RETURN_NOT_EXE.equals(retFlag)) 
//      {
//        //トークン生成
//        MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PRG_NAME,
//                                                   XxwshConstants.TOKEN_NAME_PGM_NAME_420001C) };
//        // コンカレント登録エラーメッセージ出力
//        throw new OAException(
//          XxcmnConstants.APPL_XXWSH, 
//          XxwshConstants.XXWSH13314, 
//          tokens);
//      }
//
//    // PL/SQL実行時例外の場合
//    } catch(SQLException s)
//    {
//      // ロールバック
//      rollBack(trans);
//      // ログ出力
//      XxcmnUtility.writeLog(
//        trans,
//        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
//        s.toString(),
//        6);
//      // エラーメッセージ出力
//      throw new OAException(
//        XxcmnConstants.APPL_XXCMN, 
//        XxcmnConstants.XXCMN10123);
//
//    } finally
//    {
//      try
//      {
//        //処理中にエラーが発生した場合を想定する
//        cstmt.close();
//      } catch(SQLException s)
//      {
//        // ロールバック
//        rollBack(trans);
//        // ログ出力
//        XxcmnUtility.writeLog(
//          trans,
//          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
//          s.toString(),
//          6);
//        // エラーメッセージ出力
//        throw new OAException(
//          XxcmnConstants.APPL_XXCMN, 
//          XxcmnConstants.XXCMN10123);
//      }
//    }
// 2008-12-15 D.Nihei Del End
  } // doShipRequestAndResultEntry 

  /*****************************************************************************
   * 受注情報をコピーするメソッドです。
   * @param trans          - トランザクション
   * @param orderHeaderId  - 受注ヘッダアドオンID
   * @throws OAException - OA例外
   ****************************************************************************/
  public static Number copyOrderData(
    OADBTransaction trans,
     Number orderHeaderId
  ) throws OAException
  {
    String apiName   = "copyOrderData";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                           );
    sb.append("  :1 := xxwsh_common2_pkg.copy_order_data(it_header_id => :2); "    ); // 1.新規受注明細アドオンID
    sb.append("END; "                                                            );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.INTEGER);        // 新規受注ヘッダアドオンID

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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // copyOrderData

 /*****************************************************************************
   * 移動ロット詳細アドオンから実績数量の合計値を取得するメソッドです。
   * @param trans            - トランザクション
   * @param movLineId        - 受注明細アドオンID
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
    sb.append("  WHERE  xmld.mov_line_id        = :2 "          ); // 2.受注明細アドオンID
    sb.append("  AND    xmld.document_type_code = :3 "          ); // 3.文書タイプ
    sb.append("  AND    xmld.record_type_code   = :4; "         ); // 4.レコードタイプ
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
        XxwshUtility.rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
        XxwshUtility.rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
   * 受注ヘッダアドオンIDと明細番号から受注明細アドオンIDを取得するメソッドです。
   * @param trans            - トランザクション
   * @param orderHeaderId    - 受注ヘッダアドオンID
   * @param orderLineNumber  - 明細番号
   * @return Number          - 受注明細アドオンID
   * @throws OAException - OA例外
   ****************************************************************************/
  public static Number getOrderLineId(
    OADBTransaction trans,
     Number orderHeaderId,
     Number orderLineNumber
  ) throws OAException
  {
    String apiName   = "getOrderLineId";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                 );
    sb.append("  SELECT xola.order_line_id  order_line_id "            ); // 1.受注明細アドオンID
    sb.append("  INTO   :1 "                                           );
    sb.append("  FROM   xxwsh_order_lines_all xola "                   ); // 受注明細アドオン
    sb.append("  WHERE  xola.order_header_id   = :2 "                  ); // 2.受注ヘッダアドオンID
    sb.append("  AND    xola.order_line_number = :3  "                 ); // 3.明細番号
    sb.append("  AND    xola.delete_flag       = 'N'; "                );
    sb.append("END; "                                                  );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(orderHeaderId));   // 受注ヘッダアドオンID
      cstmt.setInt(3, XxcmnUtility.intValue(orderLineNumber)); // 明細番号

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.INTEGER);            // 受注明細アドオンID

      // PL/SQL実行
      cstmt.execute();
      
      return new Number(cstmt.getObject(1));

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getOrderLineId

  /*****************************************************************************
   * 受注明細アドオンの入庫実績数量を更新するメソッドです。
   * @param trans        - トランザクション
   * @param orderLineId  - 受注明細アドオンID
   * @param shipToQty    - 入庫実績数量
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void updateShipToQuantity(
    OADBTransaction trans,
     Number orderLineId,
     String shipToQty
  ) throws OAException
  {
    String apiName   = "updateShipToQuantity";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                 );
    sb.append("  UPDATE xxwsh_order_lines_all xola "                   ); // 受注明細アドオン
    sb.append("  SET    xola.ship_to_quantity  = TO_NUMBER(:1) "       ); // 1.入庫実績数量
    sb.append("        ,xola.last_updated_by   = FND_GLOBAL.USER_ID "  ); // 最終更新者
    sb.append("        ,xola.last_update_date  = SYSDATE "             ); // 最終更新日
    sb.append("        ,xola.last_update_login = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン
    sb.append("  WHERE xola.order_line_id = :2; "                      ); // 2.受注明細アドオンID
    sb.append("END; "                                       );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, shipToQty);                          // 入庫実績数量
      cstmt.setInt(2,    XxcmnUtility.intValue(orderLineId)); // 明細ID

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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
   * 受注明細アドオンIDから依頼Noを取得するメソッドです。
   * @param trans        - トランザクション
   * @param orderLineId  - 受注明細アドオンID
   * @return String      - 依頼No
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String getRequestNo(
    OADBTransaction trans,
    String orderLineId
  ) throws OAException
  {
    String apiName   = "getRequestNo";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                           );
    sb.append("  SELECT xola.request_no  request_no "                            ); // 1.依頼No
    sb.append("  INTO   :1 "                                                     );
    sb.append("  FROM   xxwsh_order_lines_all xola "                             ); // 受注明細アドオン
    sb.append("  WHERE  xola.order_line_id     = TO_NUMBER(:2); "                ); // 2.受注明細アドオンID
    sb.append("END; "                                                            );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(2, orderLineId);   // 受注明細アドオンID

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR); // 依頼No

      // PL/SQL実行
      cstmt.execute();
      
      return cstmt.getString(1);

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getRequestNo
  /*****************************************************************************
   * 移動依頼/指示明細アドオンロックを取得します。
   * @param trans          - トランザクション
   * @param movHeaderId    - 移動ヘッダID
   * @return HashMap
   * @throws OAException - OA例外
   ****************************************************************************/
  public static HashMap getXxinvMovLinesLock(
    OADBTransaction trans,
    Number movHeaderId
  ) throws OAException
  {
    String apiName = "getXxinvMovLinesLock";
    HashMap ret = new HashMap();
    
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                                                                 );
                 // ユーザー定義エラー
    sb.append("  lock_expt             EXCEPTION; "                                                      );
    sb.append("  PRAGMA EXCEPTION_INIT(lock_expt, -54); "                                                );
    sb.append("  CURSOR lock_cur IS "                                                                    );
    sb.append("    SELECT xmril.mov_hdr_id    mov_header_id "                                            );
    sb.append("    FROM   xxinv_mov_req_instr_lines xmril "                                              );
    sb.append("    WHERE  xmril.mov_hdr_id = :1 "                                                        );
    sb.append("    FOR UPDATE NOWAIT; "                                                                  );
    sb.append("  lock_rec lock_cur%ROWTYPE; "                                                            );
    sb.append("BEGIN "                                                                                   );
                 // ロック取得
    sb.append("  OPEN lock_cur; "                                                                        );
    sb.append("  FETCH lock_cur INTO lock_rec; "                                                         );
    sb.append("  CLOSE lock_cur; "                                                                       );
                 // 最終更新日最大値を取得
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

    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1, XxcmnUtility.intValue(movHeaderId)); // 移動ヘッダID
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(2, Types.VARCHAR);   // 最終更新日
      cstmt.registerOutParameter(3, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(4, Types.VARCHAR);   // エラーメッセージ
      
      //PL/SQL実行
      cstmt.execute();

      // ロックエラー終了の場合  
      if ("1".equals(cstmt.getString(3)))
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          cstmt.getString(4),
          6);

        ret.put("retCode", XxcmnConstants.RETURN_ERR1); // 戻り値 E1:ロックエラー

      // 正常終了の場合
      } else
      {
        ret.put("retCode",        XxcmnConstants.RETURN_SUCCESS); // 戻り値 1:正常
        ret.put("lastUpdateDate", cstmt.getString(2));            // 最終更新日
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    // 戻り値
    return ret;
  } // getXxwshMovLinesLock
  /*****************************************************************************
   * 移動依頼/指示ヘッダ(アドオン)ロックを取得します。
   * @param OADBTransaction trans トランザクション
   * @param Number  movHeaderId  - 移動ヘッダID
   * @return HashMap
   * @throws OAException - OA例外
   ****************************************************************************/
  public static HashMap getXxinvMovHeadersLock(
    OADBTransaction trans,
    Number movHeaderId
  ) throws OAException
  {
    String apiName = "getXxinvMovHeadersLock";
    HashMap ret = new HashMap();
    
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                                                           );
                 // ユーザー定義エラー
    sb.append("  lock_expt             EXCEPTION; "                                                );
    sb.append("  PRAGMA EXCEPTION_INIT(lock_expt, -54); "                                          );
    sb.append("BEGIN "                                                                             );
                 // ロック取得
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

    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(movHeaderId)); // 移動ヘッダID
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR);   // 最終更新日
      cstmt.registerOutParameter(3, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(4, Types.VARCHAR);   // エラーメッセージ
      
      //PL/SQL実行
      cstmt.execute();

      // ロックエラー終了の場合  
      if ("1".equals(cstmt.getString(3)))
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          cstmt.getString(4),
          6);

        ret.put("retCode", XxcmnConstants.RETURN_ERR1); // 戻り値 E1:ロックエラー

      // 正常終了の場合
      } else
      {
        ret.put("retCode",        XxcmnConstants.RETURN_SUCCESS); // 戻り値 1:正常
        ret.put("lastUpdateDate", cstmt.getString(1));            // 最終更新日
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    // 戻り値
    return ret;
  } // getXxinvMovHeadersLock
  /*****************************************************************************
   * 移動依頼/指示明細(アドオン)の最終更新日を取得するメソッドです。
   * @param OADBTransaction trans   - トランザクション
   * @param Number movHeaderId      - 移動ヘッダID
   * @return String                 - 最終更新日
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String getMovLineLastUpdateDate(
    OADBTransaction trans,
    Number movHeaderId
  ) throws OAException
  {
    String apiName   = "getMovLineLastUpdateDate";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                                 );
    sb.append("  SELECT TO_CHAR(MAX(xmril.last_update_date), 'YYYY/MM/DD HH24:MI:SS') "); // 1.最終更新日
    sb.append("  INTO   :1 "                                                           );
    sb.append("  FROM   xxinv_mov_req_instr_lines xmril "                              ); // 移動依頼/指示明細(アドオン)
    sb.append("  WHERE  xmril.mov_hdr_id    = :2 "                                     ); // 2.移動ヘッダID
    sb.append("  WHERE  NVL(xmril.delete_flg,'N') = 'N'; "                            );
    sb.append("END; "                                                                  );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(movHeaderId)); // 移動ヘッダID

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR);   // 最終更新日

      // PL/SQL実行
      cstmt.execute();
      
      return cstmt.getString(1);

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getMovLineLastUpdateDate
  /*****************************************************************************
   * 合計数量・合計容積を算出します。
   * @param itemNo   - 品目コード
   * @param quantity - 数量
   * @param standardDate - 基準日
   * @return HashMap  - 戻り値群
   * @throws OAException - OA例外
   ****************************************************************************/
  public static HashMap calcTotalValue(
    OADBTransaction trans,
    String itemNo,
    String quantity,
// 2008-10-07 H.Itou Add Start 統合テスト指摘240
    Date standardDate
// 2008-10-07 H.Itou Add End
  ) throws  OAException
  {
    String apiName = "calcTotalValue";

    HashMap retHashMap = new HashMap();  // 戻り値用

    // PL/SQLの作成を行います。
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
// 2008-10-07 H.Itou Add Start 統合テスト指摘240
    sb.append("   ,id_standard_date     => :6 ");
// 2008-10-07 H.Itou Add End
    sb.append("  ); ");
// 2008-10-07 H.Itou Mod Start 統合テスト指摘240
//    sb.append("  :6 := TO_CHAR(ln_sum_weight);        ");
//    sb.append("  :7 := TO_CHAR(ln_sum_capacity);      ");
//    sb.append("  :8 := TO_CHAR(ln_sum_pallet_weight); ");
    sb.append("  :7 := TO_CHAR(ln_sum_weight);        ");
    sb.append("  :8 := TO_CHAR(ln_sum_capacity);      ");
    sb.append("  :9 := TO_CHAR(ln_sum_pallet_weight); ");
// 2008-10-07 H.Itou Mod End
    sb.append("END; ");

    // PL/SQLの設定を行います。
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      int i = 1;
      cstmt.setString(i++, itemNo);   // 品目コード
      cstmt.setString(i++, quantity); // 数量

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1);         // ステータスコード
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);      // エラーメッセージ
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);      // システムメッセージ
// 2008-10-07 H.Itou Add Start 統合テスト指摘240
      cstmt.setDate(i++, XxcmnUtility.dateValue(standardDate)); // 基準日
// 2008-10-07 H.Itou Add End
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);

      // PL/SQL実行
      cstmt.execute();

      // 実行結果格納
      String retCode         = cstmt.getString(3);  // リターンコード
      String errMsg          = cstmt.getString(4);  // エラーメッセージ
      String systemMsg       = cstmt.getString(5);  // システムメッセージ
// 2008-10-07 H.Itou Mod Start 統合テスト指摘240
//      String sumWeight       = cstmt.getString(6);  // 重量
//      String sumCapacity     = cstmt.getString(7);  // 容積
//      String sumPalletWeight = cstmt.getString(8);  // パレット重量
      String sumWeight       = cstmt.getString(7);  // 重量
      String sumCapacity     = cstmt.getString(8);  // 容積
      String sumPalletWeight = cstmt.getString(9);  // パレット重量
// 2008-10-07 H.Itou Mod End

      // 戻り値取得
      retHashMap.put("retCode",         retCode);
      retHashMap.put("errMsg",          errMsg);
      retHashMap.put("sumWeight",       sumWeight);
      retHashMap.put("sumCapacity",     sumCapacity);
      retHashMap.put("sumPalletWeight", sumPalletWeight);

      // エラーの場合
      if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {
        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              errMsg + systemMsg,
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                               XxcmnConstants.XXCMN10123);
      }
      return retHashMap; 
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                             XxcmnConstants.XXCMN10123);

    } finally 
    {
      try 
      {
        // 処理中にエラーが発生した場合を想定する。
        cstmt.close();
      } catch(SQLException s) 
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);

      }
    }
  } // calcTotalValue
  /*****************************************************************************
   * 指定した明細以外の受注明細アドオンの各種数量、重量、容積をサマリーして返します。
   * @param orderHeaderId - 受注ヘッダアドオンID
   * @param orderLineId   - 受注明細アドオンID
   * @param activeDate    - 適用日
   * @return HashMap  - 戻り値群
   * @throws OAException - OA例外
   ****************************************************************************/
  public static HashMap getDeliverSummaryOrderLine(
    OADBTransaction trans,
    Number orderHeaderId,
    Number orderLineId,
    Date   activeDate
  ) throws  OAException
  {
    String apiName = "getDeliverSummaryOrderLine";

    HashMap retHashMap = new HashMap(); // 戻り値

    // PL/SQLの作成を行います。
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  SELECT TO_CHAR(SUM(NVL(xola.quantity,0))) quantity,"               ); // 数量
    sb.append("         TO_CHAR(SUM(NVL(xola.weight,0))) weight,"                   ); // 重量
    sb.append("         TO_CHAR(SUM(NVL(xola.capacity,0))) capacity,"               ); // 容積
    sb.append("         TO_CHAR(SUM(NVL(xola.pallet_weight,0))) pallet_weight,"     ); // パレット重量
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
    sb.append("        )) small_quantity,"                                          ); // 小口個数
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
    sb.append("        )) label_quantity"                                           ); // ラベル枚数
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

    // PL/SQLの設定を行います。
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try 
    {
      int i = 1;

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // 数量
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // 重量
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // 容積
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // パレット重量
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // 小口個数
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // ラベル枚数
      // パラメータ設定(INパラメータ)
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));
      cstmt.setInt(i++, XxcmnUtility.intValue(orderLineId));
      cstmt.setDate(i++, XxcmnUtility.dateValue(activeDate));

      // PL/SQL実行
      cstmt.execute();
      // 実行結果格納
      i = 1;
      String sumQuantity      = cstmt.getString(i++);     // 数量
      String sumWeight        = cstmt.getString(i++);     // 重量
      String sumCapacity      = cstmt.getString(i++);     // 容積
      String sumPalletWeight  = cstmt.getString(i++);     // パレット重量
      String sumSmallQuantity = cstmt.getString(i++);     // 小口個数
      String sumLabelQuantity = cstmt.getString(i++);     // ラベル枚数
      // 戻り値設定
      retHashMap.put("sumQuantity",sumQuantity);
      retHashMap.put("sumWeight",sumWeight);
      retHashMap.put("sumCapacity",sumCapacity);
      retHashMap.put("sumPalletWeight",sumPalletWeight);
      retHashMap.put("sumSmallQuantity",sumSmallQuantity);
      retHashMap.put("sumLabelQuantity",sumLabelQuantity);

      return retHashMap;
      
    } catch (SQLException s) 
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                             XxcmnConstants.XXCMN10123);

      
    } finally 
    {
      try 
      {
        // 処理中にエラーが発生した場合を想定する。
        cstmt.close();
      } catch(SQLException s) 
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
        
      }
    }
  } // getDeliverSummaryOrderLine
  /*****************************************************************************
   * 指定した明細以外の移動依頼/指示明細(アドオン)の
   * 各種数量、重量、容積をサマリーして返します。
   * @param orderHeaderId - 受注ヘッダアドオンID
   * @param orderLineId   - 受注明細アドオンID
   * @param activeDate    - 適用日
   * @return HashMap  - 戻り値群
   * @throws OAException - OA例外
   ****************************************************************************/
  public static HashMap getDeliverSummaryMoveLine(
    OADBTransaction trans,
    Number movHdrId,
    Number movLineId,
    Date   activeDate
  ) throws  OAException
  {
    String apiName = "getDeliverSummaryMoveLine";

    HashMap retHashMap = new HashMap(); // 戻り値

    // PL/SQLの作成を行います。
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  SELECT TO_CHAR(SUM(NVL(xmril.instruct_qty,0))) quantity,"          ); // 数量
    sb.append("         TO_CHAR(SUM(NVL(xmril.weight,0))) weight,"                  ); // 重量
    sb.append("         TO_CHAR(SUM(NVL(xmril.capacity,0))) capacity,"              ); // 容積
    sb.append("         TO_CHAR(SUM(NVL(xmril.pallet_weight,0))) pallet_weight,"    ); // パレット重量
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
    sb.append("        )) small_quantity,"                                          ); // 小口個数
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
    sb.append("        )) label_quantity"                                           ); // ラベル枚数
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

    // PL/SQLの設定を行います。
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try 
    {
      int i = 1;

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // 数量
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // 重量
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // 容積
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // パレット重量
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // 小口個数
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // ラベル枚数
      // パラメータ設定(INパラメータ)
      cstmt.setInt(i++, XxcmnUtility.intValue(movHdrId));
      cstmt.setInt(i++, XxcmnUtility.intValue(movLineId));
      cstmt.setDate(i++, XxcmnUtility.dateValue(activeDate));

      // PL/SQL実行
      cstmt.execute();
      // 実行結果格納
      i = 1;
      String sumQuantity      = cstmt.getString(i++);     // 数量
      String sumWeight        = cstmt.getString(i++);     // 重量
      String sumCapacity      = cstmt.getString(i++);     // 容積
      String sumPalletWeight  = cstmt.getString(i++);     // パレット重量
      String sumSmallQuantity = cstmt.getString(i++);     // 小口個数
      String sumLabelQuantity = cstmt.getString(i++);     // ラベル枚数
      // 戻り値設定
      retHashMap.put("sumQuantity",sumQuantity);
      retHashMap.put("sumWeight",sumWeight);
      retHashMap.put("sumCapacity",sumCapacity);
      retHashMap.put("sumPalletWeight",sumPalletWeight);
      retHashMap.put("sumSmallQuantity",sumSmallQuantity);
      retHashMap.put("sumLabelQuantity",sumLabelQuantity);

      return retHashMap;
      
    } catch (SQLException s) 
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                             XxcmnConstants.XXCMN10123);

      
    } finally 
    {
      try 
      {
        // 処理中にエラーが発生した場合を想定する。
        cstmt.close();
      } catch(SQLException s) 
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
        
      }
    }
  } // getDeliverSummaryMoveLine
  /*****************************************************************************
   * 最大配送区分の算出を行います。
   * @param trans - トランザクション
   * @param codeClass1 - コード区分1
   * @param whseCode1  - 入出庫場所コード1
   * @param codeClass2 - コード区分2
   * @param whseCode2  - 入出庫場所コード2
   * @param weightCapacityClass - 重量容積区分
   * @param prodClass  - 商品区分
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
    String prodClass,
    String autoProcessType,
    Date   originalDate
  ) throws OAException
  {
    String apiName   = "getMaxShipMethod";

    // PL/SQLの作成を行います
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
    sb.append("          :4    "); // コード区分1
    sb.append("         ,:5    "); // 入出庫場所コード1
    sb.append("         ,:6    "); // コード区分2
    sb.append("         ,:7    "); // 入出庫場所コード2
    sb.append("         ,lv_prod_class            "); // 商品区分
    sb.append("         ,lv_weight_capacity_class "); // 重量容積区分
    sb.append("         ,:8    "); // 自動配車対象区分
    sb.append("         ,:9    "); // 基準日
    sb.append("         ,:10   "); // 最大配送区分
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
    sb.append("    ln_deadweight       := ln_drink_deadweight; ");
    // ドリンク・容積の場合
    sb.append("  ELSIF (('2' = lv_prod_class) AND ('2' = lv_weight_capacity_class)) THEN ");
    sb.append("    ln_loading_capacity := ln_leaf_loading_capacity; ");
    // それ以外
    sb.append("  ELSE ");
    sb.append("    ln_deadweight := null; ");
    sb.append("    ln_loading_capacity := null; ");
    sb.append("  END IF; ");
    sb.append("  :11 := TO_CHAR(ln_palette_max_qty,  'FM9,999,990'); ");
    sb.append("  :12 := TO_CHAR(ln_deadweight,       'FM9,999,990'); ");
    sb.append("  :13 := TO_CHAR(ln_loading_capacity, 'FM9,999,990'); ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      int i = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setString(i++, prodClass);              // 商品区分
      cstmt.setString(i++, weightCapacityClass);    // 重量容積区分

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(i++, Types.INTEGER); // 戻り値

      // パラメータ設定(INパラメータ)
      cstmt.setString(i++, codeClass1);   // コード区分1
      cstmt.setString(i++, whseCode1);    // 入出庫場所コード1
      cstmt.setString(i++, codeClass2);   // コード区分2
      cstmt.setString(i++, whseCode2);    // 入出庫場所コード2
      cstmt.setString(i++, autoProcessType);        // 自動配車対象区分
      cstmt.setDate(i++, originalDate.dateValue()); // 基準日

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 最大配送区分
      cstmt.registerOutParameter(i++, Types.VARCHAR); // パレット最大枚数
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 積載重量
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 積載容積

      // PL/SQL実行
      cstmt.execute();
      if (cstmt.getInt(3) == 1) 
      {
        // ログに出力
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              "戻り値がエラーで返りました。",
                              6);
        // エラーにせず戻り値にエラーコード以外はすべてnullをセットして戻す。
        HashMap paramsRet = new HashMap();
        paramsRet.put("maxShipMethods",  null); 
        paramsRet.put("paletteMaxQty",   null);
        paramsRet.put("deadWeight",      null);
        paramsRet.put("loadingCapacity", null);
        return paramsRet;
      }

      // 戻り値取得
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
      
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ログに出力
      XxcmnUtility.writeLog(trans,
                            XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーにせず戻り値にすべてnullをセットして戻す。
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
        //処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getMaxShipMethod
  /*****************************************************************************
   * 積載効率チェックを行い、積載率を算出します。
   * @param sumWeight     - 合計重量
   * @param sumCapacity   - 合計容積
   * @param code1         - コード区分１
   * @param whseCode1     - 入出庫場所コード１
   * @param code2         - コード区分２
   * @param whseCode2     - 入出庫場所コード２
   * @param maxShipToCode - 配送区分
   * @param originalDate  - 基準日
   * @param prodClass     - 商品区分
   * @return HashMap  - 戻り値群
   * @throws OAException - OA例外
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

    HashMap retHashMap = new HashMap();  // 戻り値用
    // PL/SQLの作成を行います。
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  ln_load_efficiency_weight         NUMBER; ");
    sb.append("  ln_load_efficiency_capacity       NUMBER; ");
    sb.append("BEGIN ");
    sb.append("  xxwsh_common910_pkg.calc_load_efficiency( ");
    sb.append("    in_sum_weight                 => TO_NUMBER(:1)  "); // 1.合計重量
    sb.append("   ,in_sum_capacity               => TO_NUMBER(:2)  "); // 2.合計容積
    sb.append("   ,iv_code_class1                => :3  "); // 3.コード区分１
    sb.append("   ,iv_entering_despatching_code1 => :4  "); // 4.入出庫場所コード１
    sb.append("   ,iv_code_class2                => :5  "); // 5.コード区分２
    sb.append("   ,iv_entering_despatching_code2 => :6  "); // 6.入出庫場所コード２
    sb.append("   ,iv_ship_method                => :7  "); // 7.出荷方法(最大配送区分)
    sb.append("   ,iv_prod_class                 => :8 ");  // 8.商品区分
    sb.append("   ,iv_auto_process_type          => null  "); // 9.自動配車対象区分
    sb.append("   ,id_standard_date              => :9  "); // 10.基準日(適用日基準日)
    sb.append("   ,ov_retcode                    => :10  "); // 11.リターンコード
    sb.append("   ,ov_errmsg_code                => :11 "); // 12.エラーメッセージコード
    sb.append("   ,ov_errmsg                     => :12 "); // 13.エラーメッセージ
    sb.append("   ,ov_loading_over_class         => :13 "); // 14.積載オーバー区分
    sb.append("   ,ov_ship_methods               => :14 "); // 15.出荷方法
    sb.append("   ,on_load_efficiency_weight     => ln_load_efficiency_weight "); // 16.重量積載効率
    sb.append("   ,on_load_efficiency_capacity   => ln_load_efficiency_capacity "); // 17.容積積載効率
    sb.append("   ,ov_mixed_ship_method          => :15 "); // 18.混載配送区分
    sb.append("   ); ");
    sb.append("  :16 := TO_CHAR(ln_load_efficiency_weight);   ");
    sb.append("  :17 := TO_CHAR(ln_load_efficiency_capacity); ");
    sb.append("END; ");

    // PL/SQLの設定を行います。
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      int i = 1;
      cstmt.setString(i++, sumWeight);    // 1.合計重量
      cstmt.setString(i++, sumCapacity);  // 2.合計容積
      cstmt.setString(i++, code1);        // 3.コード区分１
      cstmt.setString(i++, whseCode1);    // 4.入出庫場所コード１
      cstmt.setString(i++, code2);        // 5.コード区分２
      cstmt.setString(i++, whseCode2);    // 6.入出庫場所コード２
      cstmt.setString(i++, maxShipToCode); // 7.配送区分
      cstmt.setString(i++, prodClass); // 8.商品区分
      cstmt.setDate(i++, XxcmnUtility.dateValue(originalDate)); // 9.基準日

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(i++, Types.VARCHAR);            // 10.ステータスコード
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);      // 11.エラーメッセージ
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);      // 12.システムメッセージ
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);

      // PL/SQL実行
      cstmt.execute();

      // 実行結果格納
      String retCode   = cstmt.getString(10);   // リターンコード
      String errMsg    = cstmt.getString(11);  // エラーメッセージ
      String systemMsg = cstmt.getString(12);  // システムメッセージ
      String loadingOverClass = cstmt.getString(13);  // 積載オーバー区分
      String shipMethod       = cstmt.getString(14);  // 配送区分
      String mixedShipMethod  = cstmt.getString(15);  // 混載配送区分
      String loadEfficiencyWeight    = cstmt.getString(16);  // 重量積載効率
      String loadEfficiencyCapacity  = cstmt.getString(17);  // 容積積載効率

      // 戻り値取得
      retHashMap.put("loadingOverClass",       loadingOverClass);
      retHashMap.put("shipMethod",             shipMethod);
      retHashMap.put("mixedShipMethod",        mixedShipMethod);
      retHashMap.put("loadEfficiencyWeight",   loadEfficiencyWeight);
      retHashMap.put("loadEfficiencyCapacity", loadEfficiencyCapacity);
      retHashMap.put("retCode",        retCode);
      retHashMap.put("errMsg",   errMsg);
      retHashMap.put("systemMsg", systemMsg);

      // エラーの場合
      if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              errMsg + systemMsg,
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                               XxcmnConstants.XXCMN10123);
      }
      // 積載オーバーの場合はエラーにせず正常終了する。（エラーメッセージを加工する必要があるため)
      return retHashMap; 
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                             XxcmnConstants.XXCMN10123);

    } finally 
    {
      try 
      {
        // 処理中にエラーが発生した場合を想定する。
        cstmt.close();
      } catch(SQLException s) 
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);

      }
    }
  } // calcLoadEfficiency
  /*****************************************************************************
   * 指定した配送区分により小口区分を算出
   * @param maxShipToCode - 配送区分
   * @param originalDate  - 基準日
   * @return String  - 小口区分
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String getSmallKbn(
    OADBTransaction trans,
    String shipToCode,
    Date originalDate
    ) throws  OAException
  {
    String apiName = "getSmallKbn";

    HashMap retHashMap = new HashMap();  // 戻り値用

    // PL/SQLの作成を行います。
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  SELECT xsmv.small_amount_class "            ); // 小口区分
    sb.append("    INTO :1 "                                 );
    sb.append("    FROM xxwsh_ship_method2_v xsmv "          );
    sb.append("   WHERE xsmv.ship_method_code = :2 "         );
    sb.append("     AND :3 "                                 );
    sb.append("       BETWEEN xsmv.start_date_active "       );
    sb.append("           AND NVL(xsmv.end_date_active,:4); ");
    sb.append("END; "                                        );

    // PL/SQLの設定を行います。
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      int i = 1;
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1);         // 小口区分

      // パラメータ設定(INパラメータ)
      cstmt.setString(i++, shipToCode);    // 配送区分
      cstmt.setDate(i++, XxcmnUtility.dateValue(originalDate)); // 基準日
      cstmt.setDate(i++, XxcmnUtility.dateValue(originalDate)); // 基準日

      // PL/SQL実行
      cstmt.execute();

      // 実行結果格納
      String small_amount_class   = cstmt.getString(1);   // 小口区分

      return small_amount_class; 
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                             XxcmnConstants.XXCMN10123);

    } finally 
    {
      try 
      {
        // 処理中にエラーが発生した場合を想定する。
        cstmt.close();
      } catch(SQLException s) 
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);

      }
    }
  } // getSmallKbn
  /*****************************************************************************
   * 出荷と移動のロット逆転防止チェックAPIを実行します。
   * @param trans - トランザクション
   * @param lotBizClass  - ロット逆転処理種別
   * @param itemNo       - 品目No
   * @param lotNo        - ロットNo
   * @param moveToId     - 配送先ID/入庫先ID
   * @param arrivalDate  - 着日
   * @param standardDate - 基準日
   * @return HashMap 
   * @throws OAException - OA例外
   ****************************************************************************/
  public static HashMap doCheckLotReversalMov(
    OADBTransaction trans,
    String lotBizClass,
    String itemNo,
    String lotNo,
    Number moveToId,
    Date   arrivalDate,
// 2009-01-22 H.Itou MOD START 本番障害#1000対応
//    Date   standardDate
    Date   standardDate,
    String requestNo
// 2009-01-22 H.Itou MOD END
  ) throws OAException
  {
    String apiName = "doCheckLotReversalMov";
    HashMap ret    = new HashMap();
    
    // OUTパラメータ
    String exeType = XxcmnConstants.RETURN_NOT_EXE;
    
    //PL/SQL作成
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                                    );
// 2009-01-22 H.Itou MOD START 本番障害#1000対応
//    sb.append("  xxwsh_common910_pkg.check_lot_reversal( ");
//    sb.append("    iv_lot_biz_class    => :1,            ");   // 1.ロット逆転処理種別 1:出荷(指示)、5:移動(指示)
//    sb.append("    iv_item_no          => :2,            ");   // 2.品目コード
//    sb.append("    iv_lot_no           => :3,            ");   // 3.ロットNo
//    sb.append("    iv_move_to_id       => :4,            ");   // 4.配送先ID/取引先サイトID/入庫先ID
//    sb.append("    iv_arrival_date     => :5,            ");   // 5.着日
//    sb.append("    id_standard_date    => :6,            ");   // 6.基準日(適用日基準日)
//    sb.append("    ov_retcode          => :7,            ");   // 7.リターンコード
//    sb.append("    ov_errmsg_code      => :8,            ");   // 8.エラーメッセージコード
//    sb.append("    ov_errmsg           => :9,            ");   // 9.エラーメッセージ
//    sb.append("    on_result           => :10,           ");   // 10.処理結果
//    sb.append("    on_reversal_date    => :11);          ");   // 11.逆転日付
    sb.append("  xxwsh_common910_pkg.check_lot_reversal2( ");
    sb.append("    iv_lot_biz_class    => :1,            ");   // 1.ロット逆転処理種別 1:出荷(指示)、5:移動(指示)
    sb.append("    iv_item_no          => :2,            ");   // 2.品目コード
    sb.append("    iv_lot_no           => :3,            ");   // 3.ロットNo
    sb.append("    iv_move_to_id       => :4,            ");   // 4.配送先ID/取引先サイトID/入庫先ID
    sb.append("    iv_arrival_date     => :5,            ");   // 5.着日
    sb.append("    id_standard_date    => :6,            ");   // 6.基準日(適用日基準日)
    sb.append("    iv_request_no       => :7,            ");   // 7.依頼No
    sb.append("    ov_retcode          => :8,            ");   // 8.リターンコード
    sb.append("    ov_errmsg_code      => :9,            ");   // 9.エラーメッセージコード
    sb.append("    ov_errmsg           => :10,           ");   // 10.エラーメッセージ
    sb.append("    on_result           => :11,           ");   // 11.処理結果
    sb.append("    on_reversal_date    => :12);          ");   // 12.逆転日付
// 2009-01-22 H.Itou MOD END
    sb.append("END; "                                     );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, lotBizClass);                         // ロット逆転処理種別
      cstmt.setString(2, itemNo);                              // 品目コード
      cstmt.setString(3, lotNo);                               // ロットNo
      cstmt.setInt(4,    XxcmnUtility.intValue(moveToId));     // 配送先ID
      cstmt.setDate(5,   XxcmnUtility.dateValue(arrivalDate)); // 着日
      cstmt.setDate(6,   XxcmnUtility.dateValue(standardDate));// 基準日(適用日基準日)
// 2009-01-22 H.Itou ADD START 本番障害#1000対応
      cstmt.setString(7, requestNo);                            // 依頼No
// 2009-01-22 H.Itou ADD END
      
      // パラメータ設定(OUTパラメータ)
// 2009-01-22 H.Itou MOD START 本番障害#1000対応
//      cstmt.registerOutParameter(7,  Types.VARCHAR); // リターンコード
//      cstmt.registerOutParameter(8,  Types.VARCHAR); // エラーメッセージコード
//      cstmt.registerOutParameter(9,  Types.VARCHAR); // エラーメッセージ
//      cstmt.registerOutParameter(10, Types.INTEGER); // 処理結果
//      cstmt.registerOutParameter(11, Types.DATE);    // 逆転日付
      cstmt.registerOutParameter(8,  Types.VARCHAR); // リターンコード
      cstmt.registerOutParameter(9,  Types.VARCHAR); // エラーメッセージコード
      cstmt.registerOutParameter(10,  Types.VARCHAR); // エラーメッセージ
      cstmt.registerOutParameter(11, Types.INTEGER); // 処理結果
      cstmt.registerOutParameter(12, Types.DATE);    // 逆転日付
// 2009-01-22 H.Itou MOD END

      //PL/SQL実行
      cstmt.execute();
      
// 2009-01-22 H.Itou MOD START 本番障害#1000対応
//      String retCode    = cstmt.getString(7);               // リターンコード
//      String errmsgCode = cstmt.getString(8);               // エラーメッセージコード
//      String errmsg     = cstmt.getString(9);               // エラーメッセージ
      String retCode    = cstmt.getString(8);               // リターンコード
      String errmsgCode = cstmt.getString(9);               // エラーメッセージコード
      String errmsg     = cstmt.getString(10);               // エラーメッセージ
// 2009-01-22 H.Itou MOD END

      // API正常終了の場合、値をセット
      if (XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {
// 2009-01-22 H.Itou MOD START 本番障害#1000対応
//        ret.put("result",  new Number(cstmt.getInt(10))); // 処理結果
//        ret.put("revDate", new Date(cstmt.getDate(11)));  // 逆転日付
        ret.put("result",  new Number(cstmt.getInt(11))); // 処理結果
        ret.put("revDate", new Date(cstmt.getDate(12)));  // 逆転日付
// 2009-01-22 H.Itou MOD END
        
      // API正常終了でない場合、エラー  
      } else
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
// 2009-01-22 H.Itou MOD START 本番障害#1000対応
//          cstmt.getString(9), // エラーメッセージ
          errmsg,
// 2009-01-22 H.Itou MOD END
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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    return ret;
  } // doCheckLotReversalMov
  /*****************************************************************************
   * 鮮度条件チェックAPIを実行します。
   * @param trans - トランザクション
   * @param moveToId     - 配送先ID
   * @param lotId        - ロットId
   * @param arrivalDate  - 着日
   * @param standard_date  - 基準日(適用日基準日)
   * @return HashMap 
   * @throws OAException - OA例外
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
    
    // OUTパラメータ
    String exeType = XxcmnConstants.RETURN_NOT_EXE;
    
    //PL/SQL作成
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                                    );
    sb.append("  xxwsh_common910_pkg.check_fresh_condition( ");
    sb.append("    iv_move_to_id       => :1,            ");   // 1.配送先ID
    sb.append("    iv_lot_id           => :2,            ");   // 2.ロットId
    sb.append("    iv_arrival_date     => :3,            ");   // 3.着日
    sb.append("    id_standard_date    => :4,            ");   // 4.基準日
    sb.append("    ov_retcode          => :5,            ");   // 5.リターンコード
    sb.append("    ov_errmsg_code      => :6,            ");   // 6.エラーメッセージコード
    sb.append("    ov_errmsg           => :7,            ");   // 7.エラーメッセージ
    sb.append("    on_result           => :8,            ");   // 8.処理結果
    sb.append("    od_standard_date    => :9);           ");   // 9.基準日付
    sb.append("END; "                                     );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1,    XxcmnUtility.intValue(moveToId));     // 配送先ID
      cstmt.setInt(2,    XxcmnUtility.intValue(lotId));        // ロットId
      cstmt.setDate(3,   XxcmnUtility.dateValue(arrivalDate)); // 着日
      cstmt.setDate(4,   XxcmnUtility.dateValue(standard_date)); // 基準日
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(5,  Types.VARCHAR); // リターンコード
      cstmt.registerOutParameter(6,  Types.VARCHAR); // エラーメッセージコード
      cstmt.registerOutParameter(7,  Types.VARCHAR); // エラーメッセージ
      cstmt.registerOutParameter(8,  Types.INTEGER); // 処理結果
      cstmt.registerOutParameter(9,  Types.DATE);    // 基準日付

      //PL/SQL実行
      cstmt.execute();

      String retCode    = cstmt.getString(5);               // リターンコード
      String errmsgCode = cstmt.getString(6);               // エラーメッセージコード
      String errmsg     = cstmt.getString(7);               // エラーメッセージ

      // API正常終了の場合、値をセット
      if (XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {
        ret.put("result",       new Number(cstmt.getInt(8))); // 処理結果
        ret.put("standardDate", new Date(cstmt.getDate(9)));  // 逆転日付
        
      // API正常終了でない場合、エラー  
      } else
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          errmsg, // エラーメッセージ
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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    return ret;
  } // doCheckFreshCondition


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
      cstmt.setInt(2,    XxcmnUtility.intValue(movLineId)); // 受注明細アドオンID
      cstmt.setString(3, documentTypeCode);              // 文書タイプ
      cstmt.setString(4, recordTypeCode);                // レコードタイプ
      cstmt.setInt(5,    XxcmnUtility.intValue(lotId));     // ロットID
      
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getActualQuantity
  /*****************************************************************************
   * 移動ロット詳細アドオンに追加処理を行うメソッドです。
   * @param trans   - トランザクション
   * @param params  - パラメータ
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void insXxinvMovLotDetails(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "insXxinvMovLotDetails";

    Number orderLineId            = (Number)params.get("orderLineId");            // 明細ID
    String documentTypeCode       = (String)params.get("documentTypeCode");       // 文書タイプ
    String recordTypeCode         = (String)params.get("recordTypeCode");         // レコードタイプ
    Number itemId                 = (Number)params.get("itemId");                 // 品目ID
    String itemCode               = (String)params.get("itemCode");               // 品目
    Number lotId                  = (Number)params.get("lotId");                  // ロットID
    String lotNo                  = (String)params.get("lotNo");                  // ロットNo
    String actualQuantity         = (String)params.get("actualQuantity");         // 実績数量
    Date   actualDate             = (Date)params.get("actualDate");               // 実績日
    String automanualReserveClass = (String)params.get("automanualReserveClass"); // 自動手動引当区分
    

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
    sb.append("    ,xmld.automanual_reserve_class "         ); // 10.自動手動引当区分
    sb.append("    ,xmld.created_by  "                      ); // 11.作成者
    sb.append("    ,xmld.creation_date  "                   ); // 12.作成日
    sb.append("    ,xmld.last_updated_by  "                 ); // 13.最終更新者
    sb.append("    ,xmld.last_update_date  "                ); // 14.最終更新日
    sb.append("    ,xmld.last_update_login)  "              ); // 15.最終更新ログイン
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
      cstmt.setInt(1,     XxcmnUtility.intValue(orderLineId)); // 明細ID
      cstmt.setString(2,  documentTypeCode);                   // 文書タイプ
      cstmt.setString(3,  recordTypeCode);                     // レコードタイプ
      cstmt.setInt(4,     XxcmnUtility.intValue(itemId));      // OPM品目ID
      cstmt.setString(5,  itemCode);                           // 品目
      cstmt.setInt(6,     XxcmnUtility.intValue(lotId));       // ロットID
      cstmt.setString(7,  lotNo);                              // ロットNo
      cstmt.setDate(8,    XxcmnUtility.dateValue(actualDate)); // 実績日
      cstmt.setString(9,  actualQuantity);                     // 実績数量
      cstmt.setString(10, automanualReserveClass);            // 自動手動引当区分

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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // insXxinvMovLotDetails
  /*****************************************************************************
   * 移動ロット詳細アドオンの実績数量を更新するメソッドです。
   * @param trans        - トランザクション
   * @param params       - パラメータ
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void updActualQuantity(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "updActualQuantity";

    // INパラメータ取得
    Number movLotDtlId            = (Number)params.get("movLotDtlId");            // 移動ロット詳細ID
    String actualQuantity         = (String)params.get("actualQuantity");         // 実績数量
    String automanualReserveClass = (String)params.get("automanualReserveClass"); // 自動手動引当区分

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                            );
    sb.append("  UPDATE xxinv_mov_lot_details xmld "                              ); // 移動ロット明細アドオン
    sb.append("  SET    xmld.actual_quantity              = TO_NUMBER(:1) "       ); // 1.実績数量
    sb.append("        ,xmld.automanual_reserve_class     = :2 "                  ); // 2.自動手動引当区分
    sb.append("        ,xmld.last_updated_by              = FND_GLOBAL.USER_ID "  ); // 最終更新者
    sb.append("        ,xmld.last_update_date             = SYSDATE "             ); // 最終更新日
    sb.append("        ,xmld.last_update_login            = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン
    sb.append("  WHERE  xmld.mov_lot_dtl_id               = :3 ;"                 ); // 3.移動ロット詳細ID
    sb.append("END; "                                                             );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, actualQuantity);                     // 実績数量
      cstmt.setString(2, automanualReserveClass);             // レコードタイプ
      cstmt.setInt(3,    XxcmnUtility.intValue(movLotDtlId)); // ロット詳細ID

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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updActualQuantity
  /*****************************************************************************
   * 移動ロット詳細アドオンを削除するメソッドです。
   * @param trans        - トランザクション
   * @param movLotDtlId  - 移動ロット詳細ID
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void deleteActualQuantity(
    OADBTransaction trans,
    Number movLotDtlId
  ) throws OAException
  {
    String apiName   = "deleteActualQuantity";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                             );
    sb.append("  DELETE xxinv_mov_lot_details xmld "                ); // 移動ロット詳細アドオン
    sb.append("  WHERE  xmld.mov_lot_dtl_id = :1 ;"                ); // 1.ロット詳細ID
    sb.append("END; "                                              );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1, XxcmnUtility.intValue(movLotDtlId)); // 移動ロット詳細ID

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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // deleteActualQuantity
  /*****************************************************************************
   * 受注明細アドオンの指示数量を更新するメソッドです。
   * @param trans        - トランザクション
   * @param params       - パラメータ
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void updOrderLineInstructQty(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "updOrderLineInstructQty";

    // INパラメータ取得
    Number orderLineId            = (Number)params.get("orderLineId");            // 受注明細アドオンID
    String reservedQuantity       = (String)params.get("reservedQuantity");       // 引当数量
    String warningClass           = (String)params.get("warningClass");           // 警告区分
    Date warningDate              = (Date)params.get("warningDate");              // 警告日付
    String automanualReserveClass = (String)params.get("automanualReserveClass"); // 自動手動引当区分
    String instructQty            = (String)params.get("instructQty");            // 指示数量
    String weight                 = (String)params.get("weight");                 // 重量
    String capacity               = (String)params.get("capacity");               // 容積
    
    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                 );
    sb.append("  UPDATE xxwsh_order_lines_all xola "                   ); // 受注明細アドオン
    sb.append("  SET    xola.reserved_quantity = TO_NUMBER(:1) "       ); // 1.引当数量
    sb.append("        ,xola.warning_class = :2 "                      ); // 2.警告区分
    sb.append("        ,xola.warning_date = :3 "                       ); // 3.警告日付
    sb.append("        ,xola.automanual_reserve_class = :4 "           ); // 4.自動手動引当区分
    sb.append("        ,xola.quantity = TO_NUMBER(:5) "                ); // 5.指示数量
    sb.append("        ,xola.weight = TO_NUMBER(:6) "                  ); // 6.重量
    sb.append("        ,xola.capacity = TO_NUMBER(:7) "                ); // 7.容積
    sb.append("        ,xola.last_updated_by = FND_GLOBAL.USER_ID "    ); // 最終更新者
    sb.append("        ,xola.last_update_date = SYSDATE "              ); // 最終更新日
    sb.append("        ,xola.last_update_login = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン
    sb.append("  WHERE xola.order_line_id = :8; "                      ); // 8.受注明細アドオンID
    sb.append("END; "                                                  );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, reservedQuantity);                    // 引当数量
      cstmt.setString(2, warningClass);                        // 警告区分
      cstmt.setDate(3,   XxcmnUtility.dateValue(warningDate)); // 警告日付
      cstmt.setString(4, automanualReserveClass);              // 自動手動引当区分
      cstmt.setString(5, instructQty);                         // 指示数量
      cstmt.setString(6, weight);                             // 重量        
      cstmt.setString(7, capacity);                            // 容積
      cstmt.setInt(8,    XxcmnUtility.intValue(orderLineId));  // 明細ID
      

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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updOrderLineInstructQty
  /*****************************************************************************
   * 受注明細アドオンの引当数量を更新するメソッドです。
   * @param trans        - トランザクション
   * @param params       - パラメータ
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void updOrderLineReservedQty(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "updOrderLineReservedQty";

    // INパラメータ取得
    Number orderLineId            = (Number)params.get("orderLineId");            // 受注明細アドオンID
    String reservedQuantity       = (String)params.get("reservedQuantity");       // 引当数量
    String warningClass           = (String)params.get("warningClass");           // 警告区分
    Date warningDate              = (Date)params.get("warningDate");              // 警告日付
    String automanualReserveClass = (String)params.get("automanualReserveClass"); // 自動手動引当区分
    
    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                 );
    sb.append("  UPDATE xxwsh_order_lines_all xola "                   ); // 受注明細アドオン
    sb.append("  SET    xola.reserved_quantity = TO_NUMBER(:1) "       ); // 1.引当数量
    sb.append("        ,xola.warning_class = :2 "                      ); // 2.警告区分
    sb.append("        ,xola.warning_date = :3 "                       ); // 3.警告日付
    sb.append("        ,xola.automanual_reserve_class = :4 "           ); // 4.自動手動引当区分
    sb.append("        ,xola.last_updated_by = FND_GLOBAL.USER_ID "    ); // 最終更新者
    sb.append("        ,xola.last_update_date = SYSDATE "              ); // 最終更新日
    sb.append("        ,xola.last_update_login = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン
    sb.append("  WHERE xola.order_line_id = :5; "                      ); // 5.受注明細アドオンID
    sb.append("END; "                                       );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, reservedQuantity);                    // 引当数量
      cstmt.setString(2, warningClass);                        // 警告区分
      cstmt.setDate(3,   XxcmnUtility.dateValue(warningDate)); // 警告日付
      cstmt.setString(4, automanualReserveClass);              // 自動手動引当区分
      cstmt.setInt(5,    XxcmnUtility.intValue(orderLineId));  // 明細ID
      

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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updOrderLineReservedQty
 /*****************************************************************************
   * 受注ヘッダアドオンの配車関連データを更新するメソッドです。
   * @param trans        - トランザクション
   * @param params       - パラメータ
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void updOrderHeaderDelivery(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "updOrderHeaderDelivery";

    // INパラメータ取得
    Number orderHeaderId             = (Number)params.get("orderHeaderId");             // 受注ヘッダアドオンID
    String sumQuantity               = (String)params.get("sumQuantity");               // 合計数量
    String smallQuantity             = (String)params.get("smallQuantity");             // 小口個数
    String labelQuantity             = (String)params.get("labelQuantity");             // ラベル枚数
    String loadingEfficiencyWeight   = (String)params.get("loadingEfficiencyWeight");   // 重量積載効率
    String loadingEfficiencyCapacity = (String)params.get("loadingEfficiencyCapacity"); // 容積積載効率
    String sumWeight                 = (String)params.get("sumWeight");                 // 積載重量合計
    String sumCapacity               = (String)params.get("sumCapacity");               // 積載容積合計
    
    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                    );
    sb.append("  UPDATE xxwsh_order_headers_all xoha "                    ); // 受注ヘッダアドオン
    sb.append("  SET    xoha.sum_quantity = TO_NUMBER(:1) "               ); // 1.合計数量
    sb.append("        ,xoha.small_quantity = TO_NUMBER(:2) "             ); // 2.小口個数
    sb.append("        ,xoha.label_quantity = TO_NUMBER(:3) "             ); // 3.ラベル枚数
    sb.append("        ,xoha.loading_efficiency_weight = TO_NUMBER(:4) "  ); // 4.重量積載効率
    sb.append("        ,xoha.loading_efficiency_capacity = TO_NUMBER(:5) "); // 5.容積積載効率
    sb.append("        ,xoha.sum_weight = TO_NUMBER(:6) "                 ); // 6.積載重量合計
    sb.append("        ,xoha.sum_capacity = TO_NUMBER(:7) "               ); // 7.積載容積合計
    sb.append("        ,xoha.screen_update_by = FND_GLOBAL.USER_ID "      ); // 画面更新者
    sb.append("        ,xoha.screen_update_date = SYSDATE "               ); // 画面更新日時
    sb.append("        ,xoha.last_updated_by = FND_GLOBAL.USER_ID "       ); // 最終更新者
    sb.append("        ,xoha.last_update_date = SYSDATE "                 ); // 最終更新日
    sb.append("        ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID "    ); // 最終更新ログイン
    sb.append("  WHERE xoha.order_header_id = :8; "                       ); // 8.受注ヘッダアドオンID
    sb.append("END; "                                                     );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, sumQuantity);                          // 合計数量
      cstmt.setString(2, smallQuantity);                        // 小口個数
      cstmt.setString(3, labelQuantity);                        // ラベル枚数
      cstmt.setString(4, loadingEfficiencyWeight);              // 重量積載効率
      cstmt.setString(5, loadingEfficiencyCapacity);            // 容積積載効率
      cstmt.setString(6, sumWeight);                            // 積載重量合計
      cstmt.setString(7, sumCapacity);                          // 積載容積合計
      cstmt.setInt(8,    XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダID

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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updOrderHeaderDelivery
  /*****************************************************************************
   * 受注ヘッダアドオンの画面更新情報を更新するメソッドです。
   * @param trans         - トランザクション
   * @param orderHeaderId - 受注ヘッダアドオンID
   * @throws OAException  - OA例外
   ****************************************************************************/
  public static void updOrderHeaderScreen(
    OADBTransaction trans,
    Number orderHeaderId
  ) throws OAException
  {
    String apiName   = "updOrderHeaderScreen";

    // INパラメータ取得
    
    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                  );
    sb.append("  UPDATE xxwsh_order_headers_all xoha "                  ); // 受注ヘッダアドオン
    sb.append("     SET xoha.screen_update_by = FND_GLOBAL.USER_ID "    ); // 画面更新者
    sb.append("        ,xoha.screen_update_date = SYSDATE "             ); // 画面更新日時
    sb.append("        ,xoha.last_updated_by = FND_GLOBAL.USER_ID "     ); // 最終更新者
    sb.append("        ,xoha.last_update_date = SYSDATE "               ); // 最終更新日
    sb.append("        ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID "  ); // 最終更新ログイン
    sb.append("  WHERE xoha.order_header_id = :1; "                     ); // 8.受注ヘッダアドオンID
    sb.append("END; "                                                   );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1, XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダID

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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updOrderHeaderScreen
  /*****************************************************************************
   * 移動依頼/指示明細(アドオン)の指示数量を更新するメソッドです。
   * @param trans        - トランザクション
   * @param params       - パラメータ
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void updMoveLineInstructQty(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "updMoveLineInstructQty";

    // INパラメータ取得
    Number movLineId              = (Number)params.get("movLineId");              // 移動明細ID
    String reservedQuantity       = (String)params.get("reservedQuantity");       // 引当数量
    String warningClass           = (String)params.get("warningClass");           // 警告区分
    Date warningDate              = (Date)params.get("warningDate");              // 警告日付
    String automanualReserveClass = (String)params.get("automanualReserveClass"); // 自動手動引当区分
    String instructQty            = (String)params.get("instructQty");            // 指示数量
    String weight                 = (String)params.get("weight");                 // 重量
    String capacity               = (String)params.get("capacity");               // 容積
    
    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                  );
    sb.append("  UPDATE xxinv_mov_req_instr_lines xmril "               ); // 移動依頼/指示明細(アドオン)
    sb.append("  SET    xmril.reserved_quantity = TO_NUMBER(:1) "       ); // 1.引当数量
    sb.append("        ,xmril.warning_class = :2 "                      ); // 2.警告区分
    sb.append("        ,xmril.warning_date = :3 "                       ); // 3.警告日付
    sb.append("        ,xmril.automanual_reserve_class = :4 "           ); // 4.自動手動引当区分
    sb.append("        ,xmril.instruct_qty = TO_NUMBER(:5) "            ); // 5.指示数量
    sb.append("        ,xmril.weight = TO_NUMBER(:6) "                  ); // 6.重量
    sb.append("        ,xmril.capacity = TO_NUMBER(:7) "                ); // 7.容積
    sb.append("        ,xmril.last_updated_by = FND_GLOBAL.USER_ID "    ); // 最終更新者
    sb.append("        ,xmril.last_update_date = SYSDATE "              ); // 最終更新日
    sb.append("        ,xmril.last_update_login = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン
    sb.append("  WHERE  xmril.mov_line_id = :8; "                       ); // 8.移動明細ID
    sb.append("END; "                                                   );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, reservedQuantity);                    // 引当数量
      cstmt.setString(2, warningClass);                        // 警告区分
      cstmt.setDate(3,   XxcmnUtility.dateValue(warningDate)); // 警告日付
      cstmt.setString(4, automanualReserveClass);              // 警告区分
      cstmt.setString(5, instructQty);                         // 指示数量
      cstmt.setString(6, weight);                              // 重量
      cstmt.setString(7, capacity);                            // 容積
      cstmt.setInt(8,    XxcmnUtility.intValue(movLineId));    // 明細ID
      

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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updMoveLineInstructQty
  /*****************************************************************************
   * 移動依頼/指示明細(アドオン)の引当数量を更新するメソッドです。
   * @param trans        - トランザクション
   * @param params       - パラメータ
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void updMoveLineReservedQty(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "updMoveLineReservedQty";

    // INパラメータ取得
    Number movLineId              = (Number)params.get("movLineId");              // 移動明細ID
    String reservedQuantity       = (String)params.get("reservedQuantity");       // 引当数量
    String warningClass           = (String)params.get("warningClass");           // 警告区分
    Date warningDate              = (Date)params.get("warningDate");              // 警告日付
    String automanualReserveClass = (String)params.get("automanualReserveClass"); // 自動手動引当区分
    
    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                  );
    sb.append("  UPDATE xxinv_mov_req_instr_lines xmril "               ); // 移動依頼/指示明細(アドオン)
    sb.append("  SET    xmril.reserved_quantity = TO_NUMBER(:1) "       ); // 1.引当数量
    sb.append("        ,xmril.warning_class = :2 "                      ); // 2.警告区分
    sb.append("        ,xmril.warning_date = :3 "                       ); // 3.警告日付
    sb.append("        ,xmril.automanual_reserve_class = :4 "           ); // 4.自動手動引当区分
    sb.append("        ,xmril.last_updated_by = FND_GLOBAL.USER_ID "    ); // 最終更新者
    sb.append("        ,xmril.last_update_date = SYSDATE "              ); // 最終更新日
    sb.append("        ,xmril.last_update_login = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン
    sb.append("  WHERE  xmril.mov_line_id = :5; "                       ); // 5.移動明細ID
    sb.append("END; "                                                   );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, reservedQuantity);                    // 引当数量
      cstmt.setString(2, warningClass);                        // 警告区分
      cstmt.setDate(3,   XxcmnUtility.dateValue(warningDate)); // 警告日付
      cstmt.setString(4, automanualReserveClass);              // 自動手動引当区分
      cstmt.setInt(5,    XxcmnUtility.intValue(movLineId));    // 明細ID
      

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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // uupdMoveLineReservedQty
 /*****************************************************************************
   * 移動依頼/指示ヘッダ(アドオン)の配車関連データを更新するメソッドです。
   * @param trans        - トランザクション
   * @param params       - パラメータ
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void updMoveHeaderDelivery(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName   = "updMoveHeaderDelivery";

    // INパラメータ取得
    Number movHdrId                  = (Number)params.get("movHdrId");                  // 移動ヘッダID
    String sumQuantity               = (String)params.get("sumQuantity");               // 合計数量
    String smallQuantity             = (String)params.get("smallQuantity");             // 小口個数
    String labelQuantity             = (String)params.get("labelQuantity");             // ラベル枚数
    String loadingEfficiencyWeight   = (String)params.get("loadingEfficiencyWeight");   // 重量積載効率
    String loadingEfficiencyCapacity = (String)params.get("loadingEfficiencyCapacity"); // 容積積載効率
    String sumWeight                 = (String)params.get("sumWeight");                 // 積載重量合計
    String sumCapacity               = (String)params.get("sumCapacity");               // 積載容積合計
    
    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                     );
    sb.append("  UPDATE xxinv_mov_req_instr_headers xmrih "                ); // 移動依頼/指示ヘッダ(アドオン)
    sb.append("  SET    xmrih.sum_quantity = TO_NUMBER(:1) "               ); // 1.合計数量
    sb.append("        ,xmrih.small_quantity = TO_NUMBER(:2) "             ); // 2.小口個数
    sb.append("        ,xmrih.label_quantity = TO_NUMBER(:3) "             ); // 3.ラベル枚数
    sb.append("        ,xmrih.loading_efficiency_weight = TO_NUMBER(:4) "  ); // 4.重量積載効率
    sb.append("        ,xmrih.loading_efficiency_capacity = TO_NUMBER(:5) "); // 5.容積積載効率
    sb.append("        ,xmrih.sum_weight = TO_NUMBER(:6) "                 ); // 6.積載重量合計
    sb.append("        ,xmrih.sum_capacity = TO_NUMBER(:7) "               ); // 7.積載容積合計
    sb.append("        ,xmrih.screen_update_by = FND_GLOBAL.USER_ID "      ); // 画面更新者
    sb.append("        ,xmrih.screen_update_date = SYSDATE "               ); // 画面更新日時
    sb.append("        ,xmrih.last_updated_by = FND_GLOBAL.USER_ID "       ); // 最終更新者
    sb.append("        ,xmrih.last_update_date = SYSDATE "                 ); // 最終更新日
    sb.append("        ,xmrih.last_update_login = FND_GLOBAL.LOGIN_ID "    ); // 最終更新ログイン
    sb.append("  WHERE  xmrih.mov_hdr_id = :8; "                           ); // 8.移動ヘッダID
    sb.append("END; "                                                      );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, sumQuantity);                          // 合計数量
      cstmt.setString(2, smallQuantity);                        // 小口個数
      cstmt.setString(3, labelQuantity);                        // ラベル枚数
      cstmt.setString(4, loadingEfficiencyWeight);              // 重量積載効率
      cstmt.setString(5, loadingEfficiencyCapacity);            // 容積積載効率
      cstmt.setString(6, sumWeight);                            // 積載重量合計
      cstmt.setString(7, sumCapacity);                          // 積載容積合計
      cstmt.setInt   (8, XxcmnUtility.intValue(movHdrId));      // 移動ヘッダID
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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updMoveHeaderDelivery
 /*****************************************************************************
   * 移動依頼/指示ヘッダ(アドオン)の画面更新情報を更新するメソッドです。
   * @param trans        - トランザクション
   * @param movHdrId      - 移動ヘッダID
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void updMoveHeaderScreen(
    OADBTransaction trans,
    Number movHdrId
  ) throws OAException
  {
    String apiName   = "updMoveHeaderScreen";
    
    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                   );
    sb.append("  UPDATE xxinv_mov_req_instr_headers xmrih "              ); // 移動依頼/指示ヘッダ(アドオン)
    sb.append("  SET    xmrih.screen_update_by = FND_GLOBAL.USER_ID "    ); // 画面更新者
    sb.append("        ,xmrih.screen_update_date = SYSDATE "             ); // 画面更新日時
    sb.append("        ,xmrih.last_updated_by = FND_GLOBAL.USER_ID "     ); // 最終更新者
    sb.append("        ,xmrih.last_update_date = SYSDATE "               ); // 最終更新日
    sb.append("        ,xmrih.last_update_login = FND_GLOBAL.LOGIN_ID "  ); // 最終更新ログイン
    sb.append("  WHERE  xmrih.mov_hdr_id = :1; "                         ); // 1.移動ヘッダID
    sb.append("END; "                                                    );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1, XxcmnUtility.intValue(movHdrId));      // 移動ヘッダID

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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // updMoveHeaderScreen
  /*****************************************************************************
   * 配車解除関数を実行します。
   * @param trans        - トランザクション
   * @param bizType      - 業務種別
   * @param requestNo    - 依頼No/移動番号
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void doCancelCareersSchedule(
    OADBTransaction trans,
    String bizType,
    String requestNo
  ) throws OAException
  {
    String apiName = "doCancelCareersSchedule";
    HashMap ret    = new HashMap();
    
    //PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  :1 := xxwsh_common_pkg.cancel_careers_schedule( ");
    sb.append("         iv_biz_type     => :2, "); // 2.業務種別
    sb.append("         iv_request_no   => :3, "); // 3.依頼No/移動番号
// 2008-10-24 D.Nihei ADD START TE080_BPO_600 No22
    sb.append("          iv_calcel_flag => '1', "); // 4.配車解除フラグ
// 2008-10-24 D.Nihei ADD END
    sb.append("         ov_errmsg       => :4); "); // 5.エラーメッセージ
    sb.append("END; ");


    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1,  Types.VARCHAR); // 1.リターンコード
      // パラメータ設定(INパラメータ)
      cstmt.setString(2, bizType);                   // 2.業務種別
      cstmt.setString(3, requestNo);                 // 3.依頼No/移動番号

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(4,  Types.VARCHAR); // エラーメッセージ
      
      //PL/SQL実行
      cstmt.execute();

      String retCode    = cstmt.getString(1);               // リターンコード
      String errmsg     = cstmt.getString(4);               // エラーメッセージ

      // API正常終了でない場合、エラー  
      if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode))
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          errmsg, // エラーメッセージ
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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // doCancelCareersSchedule
  
  /*****************************************************************************
   * 移動依頼/指示明細(アドオン)の最終更新日を取得するメソッドです。
   * @param trans          - トランザクション
   * @param movHdrId       - 移動ヘッダID
   * @return String        - 最終更新日
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String getMoveLineUpdateDate(
    OADBTransaction trans,
     Number movHdrId
  ) throws OAException
  {
    String apiName   = "getMoveLineUpdateDate";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                                                  );
    sb.append("  SELECT TO_CHAR(MAX(xmril.last_update_date),'YYYY/MM/DD HH24:MI:SS')  last_update_date "); // 1.最終更新日
    sb.append("  INTO   :1  "                                                                           );
    sb.append("  FROM   xxinv_mov_req_instr_lines xmril"                                                ); // 受注明細アドオン
    sb.append("  WHERE  xmril.mov_hdr_id = :2 "                                                         ); // 2.移動ヘッダID
    sb.append("  AND    NVL(xmril.delete_flg,'N') = 'N'; "                                             ); // 削除フラグ
    sb.append("END; "                                                            );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(movHdrId)); // 移動ヘッダID

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR);   // 最終更新日

      // PL/SQL実行
      cstmt.execute();
      
      return cstmt.getString(1);

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getMoveLineUpdateDate

  /*****************************************************************************
   * 移動依頼/指示ヘッダ(アドオン)の最終更新日を取得するメソッドです。
   * @param trans            - トランザクション
   * @param movHdrId         - 移動ヘッダID
   * @return String          - 最終更新日
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String getMoveHeaderUpdateDate(
    OADBTransaction trans,
     Number movHdrId
  ) throws OAException
  {
    String apiName   = "getMoveHeaderUpdateDate";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                            );
    sb.append("  SELECT TO_CHAR(xmrih.last_update_date, 'YYYY/MM/DD HH24:Mi:SS') "); // 1.最終更新日
    sb.append("  INTO   :1 "                                                      );
    sb.append("  FROM   xxinv_mov_req_instr_headers xmrih "                       ); // 移動依頼/指示ヘッダ(アドオン)
    sb.append("  WHERE  xmrih.mov_hdr_id    = :2; "                               ); // 2.移動ヘッダID
    sb.append("END; "                                                             );
  
    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(movHdrId)); // 移動ヘッダID

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR);   // 最終更新日

      // PL/SQL実行
      cstmt.execute();
      
      return cstmt.getString(1);

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getMoveHeaderUpdateDate

// 2008-06-27 H.Itou ADD Start
 /*****************************************************************************
   * 受注ヘッダアドオンが自分自身のコンカレント起動により更新されたかどうかチェックするメソッドです。
   * @param trans            - トランザクション
   * @param orderHeaderId    - 受注ヘッダアドオンID
   * @param concName         - コンカレント名
   * @return boolean  - true:自分が起動したコンカレントより更新されている
   *                   - false:自分が起動したコンカレントより更新されていない
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean isOrderHdrUpdForOwnConc(
    OADBTransaction trans,
    Number orderHeaderId,
    String concName
  ) throws OAException
  {
    String apiName     = "isOrderHdrUpdForOwnConc";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN                                                                       ");
    sb.append("  SELECT TO_CHAR(COUNT(1))                                                  ");
    sb.append("  INTO   :1                                                                 "); // 1:件数
    sb.append("  FROM   xxwsh_order_headers_all xoha                                       "); // 受注ヘッダアドオン
    sb.append("  WHERE  xoha.order_header_id  = :2                                         "); // 2:受注ヘッダアドオンID
    sb.append("  AND    xoha.last_updated_by  = FND_GLOBAL.USER_ID                         "); // ユーザーID
    sb.append("  AND    xoha.last_update_date = xoha.program_update_date                   "); // 最終更新日とプログラム更新日が同じ
    sb.append("  AND    EXISTS (                                                           "); // 指定したコンカレントで更新されたレコード
    sb.append("           SELECT 1                                                         ");
    sb.append("           FROM   fnd_concurrent_programs     fcp                           "); // コンカレントプログラムテーブル
    sb.append("           WHERE  fcp.concurrent_program_name = :3                          "); // 3:コンカレント名
    sb.append("           AND    fcp.concurrent_program_id   = xoha.program_id             "); // コンカレントプログラムID
    sb.append("           AND    fcp.application_id          = xoha.program_application_id "); // アプリケーションID
    sb.append("           )                                                                ");
    sb.append("  AND    ROWNUM = 1;                                                        ");
    sb.append("END;                                                                        ");

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    { 
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR);
      
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID
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
        XxwshUtility.rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
        XxwshUtility.rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // isOrderHdrUpdForOwnConc

 /*****************************************************************************
   * 受注明細アドオンが自分自身のコンカレント起動により更新されたかどうかチェックするメソッドです。
   * @param trans            - トランザクション
   * @param orderHeaderId    - 受注ヘッダアドオンID
   * @param concName         - コンカレント名
   * @return boolean  - true:自分が起動したコンカレントより更新されている
   *                   - false:自分が起動したコンカレントより更新されていない
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean isOrderLineUpdForOwnConc(
    OADBTransaction trans,
    Number orderHeaderId,
    String concName
  ) throws OAException
  {
    String apiName     = "isOrderLineUpdForOwnConc";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN                                                                       ");
    sb.append("  SELECT TO_CHAR(COUNT(1))                                                  ");
    sb.append("  INTO   :1                                                                 "); // 1:件数
    sb.append("  FROM   xxwsh_order_lines_all  xola                                        "); // 受注明細アドオン
    sb.append("  WHERE  xola.order_header_id  = :2                                         "); // 2:受注ヘッダアドオンID
    sb.append("  AND    xola.last_updated_by  = FND_GLOBAL.USER_ID                         "); // ユーザーID
    sb.append("  AND    xola.last_update_date = xola.program_update_date                   "); // 最終更新日とプログラム更新日が同じ
    sb.append("  AND    EXISTS (                                                           "); // 指定したコンカレントで更新されたレコード
    sb.append("           SELECT 1                                                         ");
    sb.append("           FROM   fnd_concurrent_programs     fcp                           "); // コンカレントプログラムテーブル
    sb.append("           WHERE  fcp.concurrent_program_name = :3                          "); // 3:コンカレント名
    sb.append("           AND    fcp.concurrent_program_id   = xola.program_id             "); // コンカレントプログラムID
    sb.append("           AND    fcp.application_id          = xola.program_application_id "); // アプリケーションID
    sb.append("           )                                                                ");
    sb.append("  AND    xola.last_update_date IN (                                         "); // 同一ヘッダID中、最大最終更新日を持つレコード
    sb.append("           SELECT MAX(xola1.last_update_date)                               ");
    sb.append("           FROM   xxwsh_order_lines_all  xola1                              ");
    sb.append("           WHERE  xola1.order_header_id = :4                                ");
    sb.append("           GROUP BY xola1.order_header_id                                   ");
    sb.append("           )                                                                ");
    sb.append("  AND    ROWNUM = 1;                                                        ");
    sb.append("END;                                                                        ");

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    { 
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR);
      
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID
      cstmt.setString(3, concName);                          // コンカレント名
      cstmt.setInt(4, XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID
      
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
        XxwshUtility.rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
        XxwshUtility.rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // isOrderLineUpdForOwnConc
// 2008-06-27 H.Itou ADD End
// 2008-07-23 H.Itou ADD Start
 /*****************************************************************************
   * 品目のケース入数に正しい数値が入っているかチェックするメソッドです。
   * @param trans            - トランザクション
   * @param itemCode         - 品目コード
   * @return boolean         - true :正しい
   *                         - false:エラー
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean checkNumOfCases(
    OADBTransaction trans,
    String itemCode
  ) throws OAException
  {
    String apiName     = "checkNumOfCases";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    // 品目区分が5：製品かつ、商品区分が1：リーフOR 2：ドリンクかつ、入出庫換算単位がNULLでない場合
    // ケース入数がNULLか0以下は、エラー。
    sb.append("BEGIN                                           ");
    sb.append("  SELECT COUNT(1) cnt                           ");
    sb.append("  INTO   :1                                     ");
    sb.append("  FROM   xxcmn_item_mst_v         ximv          "); // OPM品目マスタ
    sb.append("        ,xxcmn_item_categories5_v xicv          "); // 品目カテゴリ割当情報VIEW5
    sb.append("  WHERE  /** 結合条件 **/                       ");
    sb.append("         ximv.item_id = xicv.item_id            ");
    sb.append("         /** 抽出条件 **/                       ");
    sb.append("  AND    xicv.item_class_code       = '5'       "); // 品目区分が5：製品
    sb.append("  AND    xicv.prod_class_code       IN ('1','2')"); // 商品区分が1：リーフOR 2：ドリンク
    sb.append("  AND    ximv.conv_unit             IS NOT NULL "); // 入出庫換算単位がNULLでない
    sb.append("  AND    NVL(ximv.num_of_cases, 0) <= 0         "); // ケース入数が0以下
    sb.append("  AND    ximv.item_no               = :2        ");
    sb.append("  AND    ROWNUM = 1;                            ");
    sb.append("END;                                            ");

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    { 
      // パラメータ設定(INパラメータ)
      cstmt.setString(2, itemCode);                    // 品目コード
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.INTEGER);
      
      // PL/SQL実行
      cstmt.execute();

      // OUTパラメータ取得
      int cnt = cstmt.getInt(1);  // 戻り値

      // データを取得できる場合、換算の必要があるのにケース入数が0以下なので、falseを返す。
      if (cnt == 1)
      {
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          "ケース入数がNULLか0です。品目コード："+ itemCode,
          6);

        return false;

      // 0の場合、正常なのでtrueを返す。
      } else
      {
        return true;
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
        // ロールバック
        XxwshUtility.rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
        XxwshUtility.rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // checkNumOfCases
  
 /*****************************************************************************
   * 受注明細から品目コードを取得するメソッドです。
   * @param trans            - トランザクション
   * @param orderLlineId     - 受注明細ID
   * @return String          - 品目コード
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String getItemCode(
    OADBTransaction trans,
    String orderLlineId
  ) throws OAException
  {
    String apiName     = "getItemCode";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN                                                             ");
    sb.append("  SELECT xola.shipping_item_code  item_code                       ");
    sb.append("  INTO   :1                                                       ");
    sb.append("  FROM   xxwsh_order_lines_all    xola                            "); // 受注明細アドオン
    sb.append("  WHERE  xola.order_line_id = TO_NUMBER(:2);                      ");
    sb.append("END;                                                              ");

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    { 
      // パラメータ設定(INパラメータ)
      cstmt.setString(2, orderLlineId);  // 受注明細ID
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR);
      
      // PL/SQL実行
      cstmt.execute();

      // OUTパラメータ取得
      String itemCode = cstmt.getString(1);  // 戻り値

      return itemCode;

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
        // ロールバック
        XxwshUtility.rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
        XxwshUtility.rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // getItemCode
// 2008-07-23 H.Itou ADD End
// 2008-10-24 D.Nihei ADD START TE080_BPO_600 No22
  /*****************************************************************************
   * 通知ステータス更新関数（配車解除関数）を実行します。
   * @param trans        - トランザクション
   * @param bizType      - 業務種別
   * @param requestNo    - 依頼No/移動番号
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void updateNotifStatus(
    OADBTransaction trans,
    String bizType,
    String requestNo
  ) throws OAException
  {
    String apiName = "updateNotifStatus";
    HashMap ret    = new HashMap();
    
    //PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  :1 := xxwsh_common_pkg.cancel_careers_schedule( ");
    sb.append("          iv_biz_type    => :2,  "); // 2.業務種別
    sb.append("          iv_request_no  => :3,  "); // 3.依頼No/移動番号
    sb.append("          iv_calcel_flag => '0', "); // 4.配車解除フラグ
    sb.append("          ov_errmsg      => :4); "); // 5.エラーメッセージ
    sb.append("END; ");


    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1,  Types.VARCHAR); // 1.リターンコード
      // パラメータ設定(INパラメータ)
      cstmt.setString(2, bizType);                   // 2.業務種別
      cstmt.setString(3, requestNo);                 // 3.依頼No/移動番号

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(4,  Types.VARCHAR); // エラーメッセージ
      
      //PL/SQL実行
      cstmt.execute();

      String retCode    = cstmt.getString(1);               // リターンコード
      String errmsg     = cstmt.getString(4);               // エラーメッセージ

      // API正常終了でない場合、エラー  
      if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode))
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          errmsg, // エラーメッセージ
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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // doCancelCareersSchedule
// 2008-10-24 D.Nihei ADD END
// 2009-01-26 H.Itou ADD START 本番障害＃936対応
  /*****************************************************************************
   * 鮮度条件合格製造日を取得します。
   * @param trans - トランザクション
   * @param moveToId     - 配送先ID
   * @param itemNo       - 品目コード
   * @param arrivalDate  - 着日
   * @param standard_date  - 基準日(適用日基準日)
   * @return HashMap 
   * @throws OAException - OA例外
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
    
    // OUTパラメータ
    String exeType = XxcmnConstants.RETURN_NOT_EXE;

    // バインド変数
    int paramBind  = 1;
    //PL/SQL作成
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
                 // INパラメータ設定
    sb.append("  it_move_to_id     := :" + paramBind++ + ";         "); // IN:配送先ID
    sb.append("  it_item_no        := :" + paramBind++ + ";         "); // IN:品目コード
    sb.append("  id_arrival_date   := :" + paramBind++ + ";         "); // IN:着荷予定日
    sb.append("  id_standard_date  := :" + paramBind++ + ";         "); // IN:基準日(適用日基準日)
    sb.append("  xxwsh_common910_pkg.get_fresh_pass_date(           ");
    sb.append("    it_move_to_id       => it_move_to_id             ");
    sb.append("   ,it_item_no          => it_item_no                ");
    sb.append("   ,id_arrival_date     => id_arrival_date           ");
    sb.append("   ,id_standard_date    => id_standard_date          ");
    sb.append("   ,od_manufacture_date => od_manufacture_date       ");
    sb.append("   ,ov_retcode          => ov_retcode                ");
    sb.append("   ,ov_errmsg           => ov_errmsg                 ");
    sb.append("   );                                                ");
                 // OUTパラメータ設定
    sb.append("   :" + paramBind++ + " := ov_retcode;               "); // OUT:リターンコード
    sb.append("   :" + paramBind++ + " := ov_errmsg;                "); // OUT:エラーメッセージ
    sb.append("   :" + paramBind++ + " := od_manufacture_date;      "); // OUT:鮮度条件合格製造日
    sb.append("END;                                                 ");

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // INパラメータ設定
      paramBind  = 1;
      cstmt.setInt   (paramBind++, XxcmnUtility.intValue(moveToId));      // IN:配送先ID
      cstmt.setString(paramBind++, itemNo);                               // IN:品目コード
      cstmt.setDate  (paramBind++, XxcmnUtility.dateValue(arrivalDate));  // IN:着荷予定日
      cstmt.setDate  (paramBind++, XxcmnUtility.dateValue(standardDate)); // IN:基準日(適用日基準日)

      // OUTパラメータ設定
      int outParamStart = paramBind; // OUTパラメータ開始を保持。
      cstmt.registerOutParameter(paramBind++, Types.VARCHAR); // OUT:リターンコード
      cstmt.registerOutParameter(paramBind++, Types.VARCHAR); // OUT:エラーメッセージ
      cstmt.registerOutParameter(paramBind++, Types.DATE);    // OUT:鮮度条件合格製造日

      //PL/SQL実行
      cstmt.execute();

      // OUTパラメータ取得
      paramBind  = outParamStart;
      String retCode         = cstmt.getString(paramBind++);         // OUT:リターンコード
      String errMsg          = cstmt.getString(paramBind++);         // OUT:エラーメッセージ
      Date   manufactureDate = new Date(cstmt.getDate(paramBind++)); // OUT:鮮度条件合格製造日

      // APIエラー終了でない場合
      if (!XxcmnConstants.API_RETURN_ERROR.equals(retCode))
      {
        ret.put("retCode",         retCode);         // OUT:リターンコード
        ret.put("manufactureDate", manufactureDate); // OUT:鮮度条件合格製造日

      // API正常終了でない場合、エラー  
      } else
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          errMsg, // エラーメッセージ
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
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
    return ret;
  } // getFreshPassDate
// 2009-01-26 H.Itou ADD END
// 2009-02-13 H.Itou ADD START 本番障害#863対応
  /*****************************************************************************
   * 配車解除するかどうか判断し、配車解除または配車更新を行います。
   * @param bizType - 業務種別 1:出荷,2:支給,3:移動
   * @param reqNo   - 依頼No/移動番号
   * @return String - 戻り値 0:成功,1:パラメータチェックエラー,-1:配車解除失敗
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String careerCancelOrUpd(
    OADBTransaction trans,
    String bizType,
    String requestNo
  ) throws OAException
  {
    String apiName = "careerCancelOrUpd";
    HashMap ret    = new HashMap();
    
    //PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
  	sb.append("DECLARE ");
    sb.append("BEGIN ");
    sb.append("  :1 := xxwsh_common_pkg.cancel_careers_schedule( ");
    sb.append("          iv_biz_type    => :2,  "); // 2.業務種別
    sb.append("          iv_request_no  => :3,  "); // 3.依頼No/移動番号
    sb.append("          iv_calcel_flag => '2', "); // 4.配車解除フラグ
    sb.append("          ov_errmsg      => :4); "); // 5.エラーメッセージ
    sb.append("END; ");


    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1,  Types.VARCHAR); // 1.リターンコード
      // パラメータ設定(INパラメータ)
      cstmt.setString(2, bizType);                   // 2.業務種別
      cstmt.setString(3, requestNo);                 // 3.依頼No/移動番号

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(4,  Types.VARCHAR); // エラーメッセージ
      
      //PL/SQL実行
      cstmt.execute();

      String retCode    = cstmt.getString(1);               // リターンコード
      String errmsg     = cstmt.getString(4);               // エラーメッセージ

      // API正常終了でない場合、エラー  
      if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode))
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(
          trans,
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          errmsg, // エラーメッセージ
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }

      // 戻り値返却
      return retCode;

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(
        trans,
        XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
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
          XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
          s.toString(),
          6);
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10123);
      }
    }
  } // careerCancelOrUpd
// 2009-02-13 H.Itou ADD END
// 2009-12-04 H.Itou Add Start 本稼動障害#11
  /*****************************************************************************
   * オープン日付を取得します。
   * @param trans   - トランザクション
   * @return String - オープン日付(YYYY/MM/DD)
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String getOpenDate(
    OADBTransaction trans
  ) throws OAException
  {
    String apiName = "getOpenDate";  // API名

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                                                                    );
    sb.append("  SELECT TO_CHAR(ADD_MONTHS(TO_DATE(xxcmn_common_pkg.get_opminv_close_period,'YYYYMM'), 1), 'YYYY/MM/DD') ");
    sb.append("  INTO   :1 "                                                                                              );
    sb.append("  FROM   DUAL; "                                                                                           );
    sb.append("END; "                                                                                                     );

    // PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try 
    {
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR); // 戻り値

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR); // エラーメッセージ

      // PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      String openDate = cstmt.getString(1);

      // 戻り値返却
      return openDate;

    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);

      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);

      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                             XxcmnConstants.XXCMN10123
                             );

    } finally 
    {
      try
      {
        // 処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);

        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);

        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getOpenDate
// 2009-12-04 H.Itou Add End 本稼動障害#11
// 2014-11-11 K.Kiriu Add Start E_本稼動_12237対応
  /*****************************************************************************
   * 直送の場合に顧客IDを取得します。
   * @param  trans       - トランザクション
   * @param  deliverToId - 出荷先ID
   * @return Number      - 顧客ID
   * @throws OAException - OA例外
   ****************************************************************************/
  public static Number getCustID(
    OADBTransaction trans,
    Number deliverToId
  ) throws OAException
  {
    String apiName = "getCustID";  // API名

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE                                   ");
    sb.append("BEGIN                                     ");
    sb.append("  :1 := xxcoi_common_pkg.get_customer_id( ");
    sb.append("          in_deliver_to_id => :2          "); // 2.出荷先ID
    sb.append("        );                                ");
    sb.append("  IF ( :1 IS NULL ) THEN                  ");
    sb.append("   :1 := -1;                              ");
    sb.append("  END IF;                                 ");
    sb.append("END;                                      ");

    // PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try 
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(deliverToId)); // 出荷先ID

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.INTEGER); // 顧客ID

      // PL/SQL実行
      cstmt.execute();

      // 戻り値の設定
      return new Number(cstmt.getObject(1));

    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);

      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);

      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                             XxcmnConstants.XXCMN10123
                             );

    } finally 
    {
      try
      {
        // 処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);

        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);

        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getCustID
  /*****************************************************************************
   * 子品目から親品目IDを取得します。
   * @param  trans        - トランザクション
   * @param  standardDate - 日付
   * @param  childItemId  - 子品目ID
   * @return Number       - 親品目ID
   * @throws OAException  - OA例外
   ****************************************************************************/
  public static Number getParentItemId(
    OADBTransaction trans,
    Date   standardDate,
    Number childItemId
  ) throws OAException
  {
    String apiName = "getParentItemId";  // API名

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE                                                             ");
    sb.append("  gt_item_info_tab  xxcoi_common_pkg.item_info_ttype;               ");
    sb.append("BEGIN                                                               ");
    sb.append("  xxcoi_common_pkg.get_parent_child_item_info(                      ");
    sb.append("    id_date            => :1,                                       "); // 1.日付
    sb.append("    in_inv_org_id      => FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID'), "); // 2.在庫組織ID
    sb.append("    in_parent_item_id  => NULL,                                     "); //   親品目ID
    sb.append("    in_child_item_id   => :2,                                       "); // 3.子品目ID
    sb.append("    ot_item_info_tab   => gt_item_info_tab,                         "); // 4.品目情報
    sb.append("    ov_errbuf          => :3,                                       "); //   エラーバッファ
    sb.append("    ov_retcode         => :4,                                       "); //   リターンコード
    sb.append("    ov_errmsg          => :5                                        "); //   エラーメッセージ
    sb.append("  );                                                                ");
    sb.append("  IF ( :4 = xxccp_common_pkg.set_status_normal ) THEN               ");
    sb.append("    FOR i IN gt_item_info_tab.FIRST..gt_item_info_tab.LAST LOOP     ");
    sb.append("      :6 := gt_item_info_tab(i).item_id;                            ");
    sb.append("    END LOOP;                                                       ");
    sb.append("  ELSE                                                              ");
    sb.append("    :6 := -1;                                                       ");
    sb.append("  END IF;                                                           ");
    sb.append("END;                                                                ");

    // PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try 
    {
      // パラメータ設定(INパラメータ)
      cstmt.setDate(1, XxcmnUtility.dateValue(standardDate)); // 基準日(システム日付)
      cstmt.setInt(2, XxcmnUtility.intValue(childItemId));    // 子品目ID

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(3, Types.VARCHAR, 5000);     // システムメッセージ
      cstmt.registerOutParameter(4, Types.VARCHAR, 1);        // ステータスコード
      cstmt.registerOutParameter(5, Types.VARCHAR, 5000);     // エラーメッセージ
      cstmt.registerOutParameter(6, Types.NUMERIC);           // 親品目ID

      // PL/SQL実行
      cstmt.execute();

      // 戻り値の取得
      String retCode   = cstmt.getString(4);  // リターンコード

      if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {

        // ログ出力
        XxcmnUtility.writeLog(trans,
                            XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                            cstmt.getString(5),
                            6);

        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                               XxcmnConstants.XXCMN10123
                               );
      }

      // 戻り値返却
      return new Number(cstmt.getObject(6));  // 親品目ID

    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);

      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);

      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                             XxcmnConstants.XXCMN10123
                             );

    } finally 
    {
      try
      {
        // 処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);

        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);

        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getParentItemId
  /*****************************************************************************
   * ロット情報保持マスタの追加・更新を行います。
   * @param  trans        - トランザクション
   * @param  params       - パラメータ
   * @throws OAException  - OA例外
   ****************************************************************************/
  public static void insUpdLotHoldInfo(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName = "insUpdLotHoldInfo";  // API名

    // パラメータ取得
    Number custId                 = (Number)params.get("cutId");                  // 顧客ID
    Number resultDeliverToId      = (Number)params.get("resultDeliverToId");      // 出荷先ID_実績
    Number parentItemId           = (Number)params.get("parentItemId");           // 親品目ID
    Date   deliverLot             = (Date)params.get("deliverLot");               // 納品ロット
    Date   deliveryDate           = (Date)params.get("deliveryDate");             // 納品日
    String eSKbn                  = (String)params.get("eSKbn");                  // 営業生産区分
    String cancelKbn              = (String)params.get("cancelKbn");              // 取消区分

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE                                               ");
    sb.append("BEGIN                                                 ");
    sb.append("  xxcoi_common_pkg.ins_upd_lot_hold_info(             ");
    sb.append("    in_customer_id      => :1,                        "); // 1.顧客ID
    sb.append("    in_deliver_to_id    => :2,                        "); // 2.出荷先ID
    sb.append("    in_parent_item_id   => :3,                        "); // 3.親品目ID
    sb.append("    iv_deliver_lot      => TO_CHAR(:4, 'YYYY/MM/DD'), "); // 4.納品ロット(賞味期限)
    sb.append("    id_delivery_date    => :5,                        "); // 5.納品日(着荷日)
    sb.append("    iv_e_s_kbn          => :6,                        "); // 6.営業生産区分
    sb.append("    iv_cancel_kbn       => :7,                        "); // 7.取消区分
    sb.append("    ov_errbuf           => :8,                        "); //   エラーバッファ
    sb.append("    ov_retcode          => :9,                        "); //   リターンコード
    sb.append("    ov_errmsg           => :10                        "); //   エラーメッセージ
    sb.append("  );                                                  ");
    sb.append("END;                                                  ");

    // PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try 
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1, XxcmnUtility.intValue(custId));            // 顧客ID
      cstmt.setInt(2, XxcmnUtility.intValue(resultDeliverToId)); // 出荷先ID_実績
      cstmt.setInt(3, XxcmnUtility.intValue(parentItemId));      // 親品目ID
      cstmt.setDate(4, XxcmnUtility.dateValue(deliverLot));      // 納品ロット(賞味期限)
      cstmt.setDate(5, XxcmnUtility.dateValue(deliveryDate));    // 納品日(着荷日)
      cstmt.setString(6, eSKbn);                                 // 営業生産区分
      cstmt.setString(7, cancelKbn);                             // 取消区分

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(8, Types.VARCHAR, 5000);     // システムメッセージ
      cstmt.registerOutParameter(9, Types.VARCHAR, 1);        // ステータスコード
      cstmt.registerOutParameter(10, Types.VARCHAR, 5000);    // エラーメッセージ

      // PL/SQL実行
      cstmt.execute();

      // 戻り値の取得
      String retCode   = cstmt.getString(9);  // リターンコード

      if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {

        // ロールバック
        rollBack(trans);

        // ログ出力
        XxcmnUtility.writeLog(trans,
                            XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                            cstmt.getString(10),
                            6);

        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                               XxcmnConstants.XXCMN10123
                               );
      }

    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);

      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);

      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                             XxcmnConstants.XXCMN10123
                             );

    } finally 
    {
      try
      {
        // 処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);

        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxwshConstants.CLASS_XXWSH_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);

        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // insUpdLotHoldInfo
// 2014-11-11 K.Kiriu Add End E_本稼動_12237対応
}