/*============================================================================
* ファイル名 : XxpoUtility
* 概要説明   : 仕入共通関数
* バージョン : 1.28
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-10 1.0  伊藤ひとみ   新規作成
* 2008-06-11 1.1  吉元強樹     ST不具合ログ#72を対応
* 2008-06-17 1.2  二瓶大輔     ST不具合ログ#126を対応
* 2008-06-18 1.3  伊藤ひとみ   結合バグ 発注明細IFの単価、仕入定価を
*                              仕入/標準単価ヘッダの内訳合計に変更。
* 2008-06-30 1.4  吉元強樹     ST不具合ログ#41を対応
* 2008-07-02 1.5  吉元強樹     ST不具合ログ#104を対応
* 2008-07-11 1.6  二瓶大輔     ST不具合ログ#421対応
* 2008-07-17 1.7  伊藤ひとみ   ST不具合ログ#83対応
* 2008-07-29 1.8  二瓶大輔     内部変更要求#164,166,173、課題#32
* 2008-08-07 1.9  二瓶大輔     内部変更要求#166修正
* 2008-08-19 1.10 二瓶大輔     ST不具合#249対応
* 2008-10-07 1.11 伊藤ひとみ   統合テスト指摘240対応
* 2008-10-21 1.12 二瓶大輔     統合障害#384
* 2008-10-22 1.13 伊藤ひとみ   変更要求#217,238,統合テスト指摘49対応
* 2008-10-22 1.14 吉元強樹     統合テスト指摘426対応
* 2008-10-23 1.15 伊藤ひとみ   T_TE080_BPO_340 指摘5
* 2008-11-04 1.16 二瓶大輔     統合障害#51,103、104対応
* 2008-12-05 1.17 伊藤ひとみ   本番障害#481対応
* 2008-12-06 1.18 吉元強樹     本番障害#788対応
* 2008-12-24 1.19 二瓶大輔     本番障害#743対応
* 2008-12-26 1.20 伊藤ひとみ   本番障害#809対応
* 2009-01-16 1.21 吉元強樹     本番障害#1006対応
* 2009-01-20 1.22 吉元強樹     本番障害#739,985対応
* 2009-02-06 1.23 伊藤ひとみ   本番障害#1147対応
* 2009-02-18 1.24 伊藤ひとみ   本番障害#1096対応
* 2009-02-27 1.25 伊藤ひとみ   本番障害#32対応
* 2009-05-13 1.26 吉元強樹     本番障害#1282対応
* 2009-07-08 1.27 伊藤ひとみ   本番障害#1566対応
* 2011-06-01 1.28 窪和重       本番障害#1786対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.util;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
// 2009-02-27 H.Itou Add Start 本番障害#32
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
 * 仕入共通関数クラスです。
 * @author  ORACLE 伊藤ひとみ
 * @version 1.27
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
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return sysdate;
  } // getSysdate
  
  /*****************************************************************************
   * 賞味期限日の算出を行います。
   * @param trans - トランザクション
   * @param itemId - 品目ID
   * @param productedDate - 製造日
   * @param itemCode - 品目コード
   * @return Date 賞味期限日
   * @throws OAException - OA例外
   ****************************************************************************/
  public static Date getUseByDate(
    OADBTransaction trans,
    Number itemId,
    Date productedDate,
// 2009-02-06 H.Itou Mod Start 本番障害#1147対応
//    String expirationDay
    String itemCode
// 2009-02-06 H.Itou Mod End
  ) throws OAException
  {
    String apiName   = "getUseByDate";
    Date   useByDate = null;

    // 品目ID、製造日がNullの場合は処理を行わない。
    if (XxcmnUtility.isBlankOrNull(itemId) 
      || XxcmnUtility.isBlankOrNull(productedDate)
// 2009-02-06 H.Itou Mod Start 本番障害#1147
//      || XxcmnUtility.isBlankOrNull(expirationDay)) 
        )
// 2009-02-06 H.Itou Mod End
    {
      // 賞味期限の計算はしません。
      return null;      
    }

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                                     );
    sb.append("   SELECT :1 + NVL(ximv.expiration_day, 0) "); // 賞味期限
    sb.append("   INTO   :2 "                              );
// 2009-02-06 H.Itou Add Start 本番障害#1147
//    sb.append("   FROM   xxcmn_item_mst_v ximv "           ); // OPM品目情報V
    sb.append("   FROM   xxcmn_item_mst2_v ximv "          ); // OPM品目情報V
// 2009-02-06 H.Itou Add End
    sb.append("   WHERE  ximv.item_id = :3     "           ); // 品目ID
// 2009-02-06 H.Itou Add Start 本番障害#1147
    sb.append("   AND    ximv.start_date_active <= :4 "    ); // 適用開始日
    sb.append("   AND    ximv.end_date_active   >= :5 "    ); // 適用終了日
// 2009-02-06 H.Itou Add End
    sb.append("   ; "                                      );
// 2009-02-06 H.Itou Add Start 本番障害#1147
    sb.append("EXCEPTION "                                 );
    sb.append("  WHEN NO_DATA_FOUND THEN "                 );
    sb.append("    NULL; "                                 );
// 2009-02-06 H.Itou Add End
    sb.append("END; "                                      );

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setDate(1, XxcmnUtility.dateValue(productedDate)); // 製造日
      cstmt.setInt(3, XxcmnUtility.intValue(itemId));          // 品目ID
// 2009-02-06 H.Itou Add Start 本番障害#1147
      cstmt.setDate(4, XxcmnUtility.dateValue(productedDate)); // 製造日
      cstmt.setDate(5, XxcmnUtility.dateValue(productedDate)); // 製造日
// 2009-02-06 H.Itou Add End

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(2, Types.DATE);               // 賞味期限

      // PL/SQL実行
      cstmt.execute();

// 2009-02-06 H.Itou Add Start 本番障害#1147
      // 賞味期限がNULLの場合(適用日内に品目データがない場合)
      if (XxcmnUtility.isBlankOrNull(cstmt.getDate(2)))
      {
        // 品目取得失敗エラー
        MessageToken[] tokens = {new MessageToken(XxpoConstants.ITEM_VALUE, itemCode)};
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                               XxpoConstants.XXPO10278,
                               tokens);
      } else
      {
        // 戻り値取得
        useByDate = new Date(cstmt.getDate(2));
      }
// 2009-02-06 H.Itou Add End

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return useByDate;
  } // getUseByDate

  /*****************************************************************************
   * 購買担当者従業員コードを取得します。
   * @param trans - トランザクション
   * @return String - 購買担当者従業員コード
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String getPurchaseEmpNumber(
    OADBTransaction trans
  ) throws OAException
  {
    String apiName   = "getPurchaseEmpNumber";
    String   purchaseEmpNumber = null;

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                                                                 );
    sb.append("   SELECT papf.employee_number "                                        );
    sb.append("   INTO   :1 "                                                          );
    sb.append("   FROM  per_all_people_f papf "                                        );
    sb.append("   WHERE papf.person_id  = FND_PROFILE.VALUE('XXPO_PURCHASE_EMP_ID') "  );
    sb.append("   AND   papf.effective_start_date <= TRUNC(SYSDATE) "                  ); // 適用開始日
    sb.append("   AND   papf.effective_end_date   >= TRUNC(SYSDATE); "                 ); // 適用終了日
    sb.append("END; "                                                                  );

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR); // purchaseEmpNumber

      // PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      purchaseEmpNumber = cstmt.getString(1);

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return purchaseEmpNumber;
  } // getPurchaseEmpNumber
  
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
    // 変更に関する警告をクリア
    trans.setPlsqlState(OADBTransaction.STATUS_UNMODIFIED);
  } // commit

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
    // ロールバック
    trans.executeCommand("ROLLBACK ");
  } // rollBack
  
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
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
   * ロット存在確認チェックを行います。
   * @param trans            - トランザクション
   * @param itemId           - 品目ID
   * @param manufacturedDate - 製造日
   * @param koyuCode         - 固有記号
   * @return boolean  - ロットが存在する場合   true
   *                   - ロットが存在しない場合 false
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean chkLotMst(
    OADBTransaction trans,
    Number itemId,
    Date   manufacturedDate,
    String koyuCode
  ) throws OAException
  {
    String apiName   = "chkLotMst"; // API名
    String plSqlRet;                // PL/SQL戻り値
    
    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                               );
    sb.append("   SELECT TO_CHAR(COUNT(1)) "                         ); // ロットカウント数
    sb.append("   INTO   :1 "                                        ); 
    sb.append("   FROM   ic_lots_mst ilm "                           ); // OPMロットマスタ
    sb.append("   WHERE  ilm.item_id    = :2 "                       ); // 品目ID
    sb.append("   AND    ilm.attribute1 = TO_CHAR(:3, 'YYYY/MM/DD') "); // 製造日
    sb.append("   AND    ilm.attribute2 = :4; "                      ); // 固有記号
    sb.append("END; "                                                );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(itemId));             // 品目ID
      cstmt.setDate(3, XxcmnUtility.dateValue(manufacturedDate)); // 製造日
      cstmt.setString(4, koyuCode);                               // 固有記号
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR); // ロットカウント数
      
      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      plSqlRet = cstmt.getString(1);

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    // PL/SQL戻り値が0の場合 false
    if ("0".equals(plSqlRet))
    {
      return false;
    
    // PL/SQL戻り値が0以外の場合 true
    } else
    {
      return true;
    }
  } // chkLotMst

  /*****************************************************************************
   * 引当可能数量チェックを行います。
   * @param trans             - トランザクション
   * @param productedQuantity - 数量
   * @param txnsId            - 実績ID
   * @return HashMap
   * @throws OAException - OA例外
   ****************************************************************************/
  public static HashMap chkReservedQuantity(
    OADBTransaction trans,
    String          productedQuantity,
    Number          txnsId
  ) throws OAException
  {
    String apiName      = "chkReservedQuantity";
    HashMap paramsRet = new HashMap();
 
    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                                                                );
                 // 変数宣言
    sb.append("  ln_can_enc_in_time_qty  NUMBER; "                                                      ); // 有効日ベース引当可能数
    sb.append("  ln_can_enc_total_qty    NUMBER; "                                                      ); // 総引当可能数
    sb.append("  ln_can_encl_qty         NUMBER; "                                                      ); // 引当可能数
                 // カーソル宣言
    sb.append("  CURSOR xxpo_vendor_supply_txns_cur IS "                                                );
    sb.append("    SELECT xvst.quantity - "                                                             ); 
    sb.append("           TO_NUMBER(:1) * "                                                             ); 
    sb.append("           xvst.conversion_factor  gap_qty "                                             ); // 差分数  = DB.数量 - RN.数量
    sb.append("          ,xvst.item_id            item_id "                                             ); // DB.品目ID
    sb.append("          ,ximv.item_short_name    item_name "                                           ); // DB.品目名
    sb.append("          ,xvst.lot_id             lot_id "                                              ); // DB.ロットID
    sb.append("          ,xvst.lot_number         lot_number "                                          ); // DB.ロット番号
    sb.append("          ,xvst.location_id        location_id"                                          ); // DB.納入先ID
    sb.append("          ,xilv.description        location_name "                                       ); // DB.保管場所名
    sb.append("    FROM   xxpo_vendor_supply_txns xvst "                                                ); // 外注出来高実績
    sb.append("          ,xxcmn_item_mst2_v       ximv "                                                ); // OPM品目情報2V
    sb.append("          ,xxcmn_item_locations_v  xilv "                                                ); // OPM保管場所情報V
    sb.append("    WHERE  xvst.txns_id   = :2 "                                                         ); // 実績ID
    sb.append("    AND    xvst.item_id   = ximv.item_id "                                               ); // 品目ID
    sb.append("    AND    xvst.location_code = xilv.segment1 "                                          ); // 納入先コード    
    sb.append("    AND    ximv.start_date_active <= TRUNC(xvst.manufactured_date) "                     ); // 適用開始日
    sb.append("    AND    ximv.end_date_active   >= TRUNC(xvst.manufactured_date); "                    ); // 適用終了日    
    sb.append("  xxpo_vendor_supply_txns_rec xxpo_vendor_supply_txns_cur%ROWTYPE; "                     );   
    sb.append("BEGIN "                                                                                  );
                 // DBの外注出来高数量を取得
    sb.append("  OPEN  xxpo_vendor_supply_txns_cur; "                                                   );
    sb.append("  FETCH xxpo_vendor_supply_txns_cur INTO xxpo_vendor_supply_txns_rec; "                  );
    sb.append("  CLOSE xxpo_vendor_supply_txns_cur; "                                                   );
                 // 有効日ベース引当可能数を取得
    sb.append("  ln_can_enc_in_time_qty := xxcmn_common_pkg.get_can_enc_in_time_qty( "                  );
    sb.append("                              in_whse_id     => xxpo_vendor_supply_txns_rec.location_id "); // OPM保管倉庫ID
    sb.append("                             ,in_item_id     => xxpo_vendor_supply_txns_rec.item_id "    ); // OPM品目ID
    sb.append("                             ,in_lot_id      => xxpo_vendor_supply_txns_rec.lot_id "     ); // ロットID
    sb.append("                             ,in_active_date => SYSDATE                           );"    ); // 有効日
                 // 総引当可能数を取得
    sb.append("  ln_can_enc_total_qty   := xxcmn_common_pkg.get_can_enc_total_qty( "                    );
    sb.append("                              in_whse_id     => xxpo_vendor_supply_txns_rec.location_id "); // OPM保管倉庫ID
    sb.append("                             ,in_item_id     => xxpo_vendor_supply_txns_rec.item_id "    ); // OPM品目ID
    sb.append("                             ,in_lot_id      => xxpo_vendor_supply_txns_rec.lot_id );"   ); // ロットID
                 // 引当可能数取得 有効日ベース引当可能数と総引当可能数で数の少ないほうを引当可能数とする。
    sb.append("  IF (ln_can_enc_in_time_qty > ln_can_enc_total_qty) THEN "                              );
    sb.append("      ln_can_encl_qty := ln_can_enc_total_qty; "                                         );
    sb.append("  ELSE "                                                                                 );
    sb.append("      ln_can_encl_qty := ln_can_enc_in_time_qty; "                                       );
    sb.append("  END IF; "                                                                              );
                 // 差分数が0以下(数量が変更されていないか、増量された場合)は差分数チェックを行わない。
    sb.append("  IF (xxpo_vendor_supply_txns_rec.gap_qty <= 0) THEN "                                   );
    sb.append("    :3 := '1'; "                                                                         );
    sb.append("    :4 := xxpo_vendor_supply_txns_rec.item_name; "                                       );
    sb.append("    :5 := xxpo_vendor_supply_txns_rec.lot_number; "                                      );
    sb.append("    :6 := xxpo_vendor_supply_txns_rec.location_name; "                                   );
                 // 引当可能数チェック 差分数が減量で引当可能数を超える場合、警告
    sb.append("  ELSIF (xxpo_vendor_supply_txns_rec.gap_qty > ln_can_encl_qty) THEN "                   );
    sb.append("    :3 := '2'; "                                                                         );
    sb.append("    :4 := xxpo_vendor_supply_txns_rec.item_name; "                                       );
    sb.append("    :5 := xxpo_vendor_supply_txns_rec.lot_number; "                                      );
    sb.append("    :6 := xxpo_vendor_supply_txns_rec.location_name; "                                   );
                 // 引当可能数チェック 差分数が減量で引当可能数を超えない場合、正常
    sb.append("  ELSE "                                                                                 );
    sb.append("    :3 := '1'; "                                                                         );
    sb.append("    :4 := xxpo_vendor_supply_txns_rec.item_name; "                                       );
    sb.append("    :5 := xxpo_vendor_supply_txns_rec.lot_number; "                                      );
    sb.append("    :6 := xxpo_vendor_supply_txns_rec.location_name; "                                   );
    sb.append("  END IF; "                                                                              );
    sb.append("END; "                                                                                   );

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, productedQuantity); // RN出来高数量
      cstmt.setInt(2, XxcmnUtility.intValue(txnsId)); // 実績ID
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(3, Types.VARCHAR); // 処理結果
      cstmt.registerOutParameter(4, Types.VARCHAR); // 品目名
      cstmt.registerOutParameter(5, Types.VARCHAR); // ロット番号
      cstmt.registerOutParameter(6, Types.VARCHAR); // 保管場所名
      
      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      paramsRet.put("PlSqlRet", cstmt.getString(3)); // 処理結果
      paramsRet.put("ItemName", cstmt.getString(4)); // 品目名
      paramsRet.put("LotNumber", cstmt.getString(5)); // ロット番号
      paramsRet.put("LocationName", cstmt.getString(6)); // 保管場所名

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return paramsRet;
  } // chkReservedQuantity

  /*****************************************************************************
   * ユーザー情報を取得します。
   * @param trans            - トランザクション
   * @return HashMap         - 納入先情報
   * @throws OAException - OA例外
   ****************************************************************************/
  public static HashMap getUserData(
    OADBTransaction trans
  ) throws OAException
  {
    String apiName  = "getUserData"; // API名

    HashMap retHashMap = new HashMap();  // 戻り値用

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                             );
    sb.append("  SELECT papf.attribute4          vendor_code "                     ); // 仕入先コード
    sb.append("        ,papf.attribute3          people_code "                     ); // 従業員区分
    sb.append("        ,xvv.vendor_id            vendor_id "                       ); // 仕入先ID
    sb.append("        ,xvv.vendor_short_name    vendor_name "                     ); // 仕入先名
    sb.append("        ,xvv.product_result_type  product_result_type "             ); // 処理タイプ
    sb.append("        ,xvv.department           department "                      ); // 部署
    sb.append("        ,papf.attribute6          factory_code "                    ); // 工場コード
    sb.append("  INTO   :1 "                                                       );
    sb.append("        ,:2 "                                                       );
    sb.append("        ,:3 "                                                       );
    sb.append("        ,:4 "                                                       );
    sb.append("        ,:5 "                                                       );
    sb.append("        ,:6 "                                                       );
    sb.append("        ,:7 "                                                       );
    sb.append("  FROM   fnd_user              fu "                                 ); // ユーザーマスタ
    sb.append("        ,per_all_people_f      papf "                               ); // 従業員マスタ
    sb.append("        ,xxcmn_vendors_v       xvv "                                ); // 仕入先情報V
    sb.append("  WHERE  fu.employee_id              = papf.person_id "             ); // 従業員ID
    sb.append("  AND    papf.attribute4             = xvv.segment1(+) "            ); // 仕入先コード
    sb.append("  AND    fu.start_date <= TRUNC(SYSDATE) "                          ); // 適用開始日
    sb.append("  AND    ((fu.end_date IS NULL) OR (fu.end_date >= TRUNC(SYSDATE))) " ); // 適用終了日
    sb.append("  AND    papf.effective_start_date <= TRUNC(SYSDATE) "              ); // 適用開始日
    sb.append("  AND    papf.effective_end_date   >= TRUNC(SYSDATE) "              ); // 適用終了日
    sb.append("  AND    fu.user_id                  = FND_GLOBAL.USER_ID; "        ); // ユーザーID
    sb.append("END; "                                                              );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR); // 仕入先コード
      cstmt.registerOutParameter(2, Types.VARCHAR); // 従業員区分
      cstmt.registerOutParameter(3, Types.INTEGER); // 仕入先ID
      cstmt.registerOutParameter(4, Types.VARCHAR); // 仕入先名
      cstmt.registerOutParameter(5, Types.VARCHAR); // 処理タイプ
      cstmt.registerOutParameter(6, Types.VARCHAR); // 部署
      cstmt.registerOutParameter(7, Types.VARCHAR); // 工場コード
      
      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      retHashMap.put("VendorCode",        cstmt.getObject(1)); // 仕入先コード
      retHashMap.put("PeopleCode",        cstmt.getObject(2)); // 従業員区分
      retHashMap.put("VendorId",          cstmt.getObject(3)); // 仕入先ID
      retHashMap.put("VendorName",        cstmt.getObject(4)); // 仕入先名
      retHashMap.put("ProductResultType", cstmt.getObject(5)); // 処理タイプ
      retHashMap.put("Department",        cstmt.getObject(6)); // 部署
      retHashMap.put("FactoryCode",       cstmt.getString(7)); // 工場コード

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
      rollBack(trans);
      // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // getUserData
  
  /*****************************************************************************
   * 在庫単価を取得します。
   * @param trans            - トランザクション
   * @param params           - パラメータ
   * @return String          - 在庫単価
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String getStockValue(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName    = "getStockValue"; // API名
    String stockValue = "";    // 在庫単価

    // パラメータ値取得
    String costManageCode    = (String)params.get("CostManageCode");   // 原価管理区分
    String productResultType = (String)params.get("ProductResultType");// 処理タイプ
    String unitPriceCalcCode = (String)params.get("UnitPriceCalcCode");// 仕入単価導出日タイプ
    Number itemId            = (Number)params.get("ItemId");           // 品目ID
    Number vendorId          = (Number)params.get("VendorId");         // 取引先ID
    Number factoryId         = (Number)params.get("FactoryId");        // 工場ID
    Date   manufacturedDate  = (Date)params.get("ManufacturedDate");   // 生産日
    Date   productedDate     = (Date)params.get("ProductedDate");      // 製造日

    // 原価管理区分が1:標準原価の場合、在庫単価はNULL
    if (XxpoConstants.COST_MANAGE_CODE_N.equals(costManageCode))
    {
      stockValue = null;
    
    // 原価管理区分が0:実際原価の場合
    } else if (XxpoConstants.COST_MANAGE_CODE_R.equals(costManageCode))
    {
        // 処理タイプが1:相手先在庫の場合、在庫単価は0
        if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType))
        {
          stockValue = "0";
        
      // 処理タイプが2:即時仕入の場合、仕入/標準単価ヘッダから取得
      } else if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(productResultType))
      {
        // PL/SQL作成
        StringBuffer sb = new StringBuffer(1000);
        sb.append("DECLARE "                                                 );
        sb.append("  lt_total_amount  xxpo_price_headers.total_amount%TYPE; ");
        sb.append("BEGIN "                                                   );
        sb.append("  SELECT xph.total_amount    total_amount "               ); // 内訳合計
        sb.append("  INTO   lt_total_amount "                                );
        sb.append("  FROM   xxpo_price_headers  xph "                        ); // 仕入･標準単価ヘッダ
        sb.append("  WHERE  xph.item_id             = :1 "                   ); // 品目ID
        sb.append("  AND    xph.vendor_id           = :2 "                   ); // 取引先ID
        sb.append("  AND    xph.factory_id          = :3 "                   ); // 工場ID
        sb.append("  AND    xph.futai_code          = '0' "                  ); // 付帯コード
        sb.append("  AND    xph.price_type          = '1' "                  ); // マスタ区分1:仕入
// 20080702 yoshimoto add Start
        sb.append("  AND    xph.supply_to_code IS NULL "                     ); // 支給先コード IS NULL
// 20080702 yoshimoto add End
        sb.append("  AND    (((:4                   = '1') "                 ); // 仕入単価導入日タイプが1:製造日の場合、条件が製造日
        sb.append("    AND  (xph.start_date_active <= :5) "                  ); // 適用開始日 <= 製造日
        sb.append("    AND  (xph.end_date_active   >= :5)) "                 ); // 適用終了日 >= 製造日
        sb.append("  OR     ((:4                    = '2') "                 ); // 仕入単価導入日タイプが2:納入日の場合、条件が生産日
        sb.append("    AND  (xph.start_date_active <= :6) "                  ); // 適用開始日 <= 生産日
        sb.append("    AND  (xph.end_date_active   >= :6))); "               ); // 適用終了日 >= 生産日
        sb.append("  :7 := TO_CHAR(lt_total_amount); "                       );
        sb.append("EXCEPTION "                                               );
        sb.append("  WHEN OTHERS THEN "                                      ); // データがない場合は0
        sb.append("    :7 := '0'; "                                          );
        sb.append("END; "                                                    );

        //PL/SQL設定
        CallableStatement cstmt
          = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

        try
        {
          // パラメータ設定(INパラメータ)
          cstmt.setInt(1, XxcmnUtility.intValue(itemId));            // 品目ID
          cstmt.setInt(2, XxcmnUtility.intValue(vendorId));          // 取引先ID
          cstmt.setInt(3, XxcmnUtility.intValue(factoryId));         // 工場ID
          cstmt.setString(4, unitPriceCalcCode);                     // 仕入単価導入タイプ
          cstmt.setDate(5, XxcmnUtility.dateValue(productedDate));   // 製造日
          cstmt.setDate(6, XxcmnUtility.dateValue(manufacturedDate));// 生産日
          
          // パラメータ設定(OUTパラメータ)
          cstmt.registerOutParameter(7, Types.VARCHAR); // 在庫単価
          
          //PL/SQL実行
          cstmt.execute();
          
          // 戻り値取得
          stockValue = cstmt.getString(7);

        // PL/SQL実行時例外の場合
        } catch(SQLException s)
        {
          // ロールバック
          rollBack(trans);
          XxcmnUtility.writeLog(trans,
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
            rollBack(trans);
            XxcmnUtility.writeLog(trans,
                                  XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                  s.toString(),
                                  6);
            // エラーメッセージ出力
            throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                  XxcmnConstants.XXCMN10123);
          }
        }
      }
    }
    return stockValue;
  } // getStockValue

  /*****************************************************************************
   * 発注番号を取得します。
   * @param trans            - トランザクション
   * @return String          - 発注番号
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String getPoNumber(
    OADBTransaction trans
  ) throws OAException
  {
    String apiName  = "getPoNumber"; // API名
    String poNumber;  // 発注番号
    String errBuf;    // エラーメッセージ
    String retCode;   // リターンコード
    String errMsg;    // ユーザー・エラー・メッセージ
    
    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                          );
    sb.append("  xxcmn_common_pkg.get_seq_no( " );
    sb.append("    iv_seq_class  => '2' "       ); // 採番する番号を表す区分 2:発注番号
    sb.append("   ,ov_seq_no     => :1 "        ); // 発注番号
    sb.append("   ,ov_errbuf     => :2 "        ); // エラーメッセージ
    sb.append("   ,ov_retcode    => :3 "        ); // リターンコード
    sb.append("   ,ov_errmsg     => :4 ); "     ); // ユーザー・エラー・メッセージ
    sb.append("END; "                           );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR); // 発注番号
      cstmt.registerOutParameter(2, Types.VARCHAR); // エラーメッセージ
      cstmt.registerOutParameter(3, Types.VARCHAR); // リターンコード
      cstmt.registerOutParameter(4, Types.VARCHAR); // ユーザー・エラー・メッセージ
      
      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      poNumber = cstmt.getString(1); // 発注番号
      errBuf   = cstmt.getString(2); // エラーメッセージ
      retCode  = cstmt.getString(3); // リターンコード
      errMsg   = cstmt.getString(4); // ユーザー・エラー・メッセージ
      
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return poNumber;
  } // getPoNumber

  /*****************************************************************************
   * ロット番号を取得します。
   * @param trans            - トランザクション
   * @param itemId           - パラメータ
   * @return String          - ロット番号
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String getLotNumber(
    OADBTransaction trans,
    Number itemId,
    String itemCode
  ) throws OAException
  {
    String apiName = "getLotNumber"; // API名
    String lotNumber;    // ロット番号
    String subLotNumber; // サブロット番号
    int returnStatus;   // リターンコード

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                             );
    sb.append("  lv_lot_no     VARCHAR2(5000); "     );
    sb.append("  lv_sublot_no  VARCHAR2(5000); "     );
    sb.append("  ln_lot_status VARCHAR2(5000); "     );
    sb.append("BEGIN "                               );
                 // ロット採番ルールアドオン
    sb.append("  gmi_autolot.generate_lot_number( "  );
    sb.append("    p_item_id        => :1 "          ); // IN:品目ID
    sb.append("   ,p_in_lot_no      => NULL "        ); // IN:仕入･標準単価ヘッダ
    sb.append("   ,p_orgn_code      => NULL "        ); // IN:品目ID
    sb.append("   ,p_doc_id         => NULL "        ); // IN:取引先ID
    sb.append("   ,p_line_id        => NULL "        ); // IN:工場ID
    sb.append("   ,p_doc_type       => NULL "        ); // IN:付帯コード
    sb.append("   ,p_out_lot_no     => :2 "          ); // OUT:ロット番号
    sb.append("   ,p_sublot_no      => :3 "          ); // OUT:サブロット番号
    sb.append("   ,p_return_status  => :4); "        ); // OUT:リターンコード
    sb.append("END; "                                );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1, XxcmnUtility.intValue(itemId)); // 品目ID
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(2, Types.VARCHAR); // ロット番号
      cstmt.registerOutParameter(3, Types.VARCHAR); // サブロット番号
      cstmt.registerOutParameter(4, Types.INTEGER); // リターンコード
      
      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      lotNumber    = cstmt.getString(2); // ロット番号
      subLotNumber = cstmt.getString(3); // サブロット番号
      returnStatus = cstmt.getInt(4);    // リターンコード 

      // ロット番号がNULLの場合、エラー
      if (XxcmnUtility.isBlankOrNull(lotNumber))
      {
        //トークン生成します。
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_ITEM_NO, itemCode) };
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                               XxpoConstants.XXPO10110, 
                               tokens);        
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return lotNumber;
  } // getLotNumber

  /*****************************************************************************
   * 納入先情報を取得します。
   * @param trans            - トランザクション
   * @param locationCode     - 納入先コード
   * @return HashMap         - 納入先情報
   * @throws OAException - OA例外
   ****************************************************************************/
  public static HashMap getLocationData(
    OADBTransaction trans,
    String locationCode
  ) throws OAException
  {
    String apiName  = "getLocationData"; // API名

    HashMap retHashMap = new HashMap();  // 戻り値用

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                    );
    sb.append("  SELECT xilv.inventory_location_id inventory_location_id "); // 1:納入先ID
    sb.append("        ,xilv.whse_code             whse_code "            ); // 2:倉庫コード
    sb.append("        ,somb.co_code               co_code "              ); // 3:会社コード
    sb.append("        ,somb.orgn_code             orgn_code "            ); // 4:組織コード
    sb.append("        ,haou.location_id           ship_to_location_id "  ); // 5:納入先事業所ID
    sb.append("        ,xilv.mtl_organization_id   organization_id "      ); // 6:在庫組織ID
// 2008-10-23 H.Itou Add Start T_TE080_BPO_340 指摘5 相手先在庫管理対象チェック追加
    sb.append("        ,xilv.customer_stock_whse   customer_stock_whse "  ); // 7:相手先在庫管理対象
// 2008-10-23 H.Itou Add End
    sb.append("  INTO   :1 "                                              );
    sb.append("        ,:2 "                                              );
    sb.append("        ,:3 "                                              );
    sb.append("        ,:4 "                                              );
    sb.append("        ,:5 "                                              );
    sb.append("        ,:6 "                                              );
// 2008-10-23 H.Itou Add Start T_TE080_BPO_340 指摘5 相手先在庫管理対象チェック追加
    sb.append("        ,:7 "                                              );
// 2008-10-23 H.Itou Add End
    sb.append("  FROM   xxcmn_item_locations_v     xilv "                 ); // OPM保管場所情報V
    sb.append("        ,ic_whse_mst                iwm "                  ); // OPM倉庫マスタ
    sb.append("        ,sy_orgn_mst_b              somb "                 ); // OPMプラントマスタ
    sb.append("        ,hr_all_organization_units  haou "                 ); // 組織マスタ
    sb.append("  WHERE  xilv.whse_code = iwm.whse_code "                  ); // 倉庫コード
    sb.append("  AND    iwm.orgn_code  = somb.orgn_code "                 ); // プラントコード
    sb.append("  AND    xilv.mtl_organization_id  = haou.organization_id "); // 組織ID
    sb.append("  AND    xilv.segment1  = :7 "                             ); // 保管場所コード
    sb.append("  AND    haou.date_from <= TRUNC(SYSDATE) "                ); // 適用日 <= SYSDATE
    sb.append("  AND  ((haou.date_to >= TRUNC(SYSDATE))  "                ); // 適用日 >= SYSDATE
    sb.append("        OR (haou.date_to IS NULL)); "                      );
    sb.append("END; "                                                     );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(7, locationCode); // 納入先コード
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.INTEGER); // 納入先ID
      cstmt.registerOutParameter(2, Types.VARCHAR); // 倉庫コード
      cstmt.registerOutParameter(3, Types.VARCHAR); // 会社コード
      cstmt.registerOutParameter(4, Types.VARCHAR); // 組織コード
      cstmt.registerOutParameter(5, Types.INTEGER); // 納入先事業所ID
      cstmt.registerOutParameter(6, Types.INTEGER); // 在庫組織ID
// 2008-10-23 H.Itou Add Start T_TE080_BPO_340 指摘5 相手先在庫管理対象チェック追加
      cstmt.registerOutParameter(7, Types.VARCHAR); // 相手先在庫管理対象
// 2008-10-23 H.Itou Add End

      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      retHashMap.put("LocationId",       cstmt.getObject(1)); // 納入先ID
      retHashMap.put("WhseCode",         cstmt.getObject(2)); // 倉庫コード
      retHashMap.put("CoCode",           cstmt.getObject(3)); // 会社コード
      retHashMap.put("OrgnCode",         cstmt.getObject(4)); // 組織コード
      retHashMap.put("ShipToLocationId", cstmt.getObject(5)); // 納入先事業所ID
      retHashMap.put("OrganizationId",   cstmt.getObject(6)); // 在庫組織ID
// 2008-10-23 H.Itou Add Start T_TE080_BPO_340 指摘5 相手先在庫管理対象チェック追加
      retHashMap.put("CustomerStockWhse", cstmt.getObject(7)); // 相手先在庫管理対象
// 2008-10-23 H.Itou Add End

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // getLocationData

  /*****************************************************************************
   * 検査依頼Noを取得します。
   * @param trans            - トランザクション
   * @param params     - 
   * @return Object    - 検査依頼No
   * @throws OAException - OA例外
   ****************************************************************************/
  public static Object getQtInspectReqNo(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName  = "getQtInspectReqNo"; // API名

    // INパラメータ取得
    Number itemId  = (Number)params.get("ItemId"); // 品目ID
    Number lotId   = (Number)params.get("LotId");  // ロットID
    
    Object qtInspectReqNo = new Object();  // 戻り値用

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                     );
    sb.append("  SELECT ilm.attribute22 qt_inspect_req_no "); // 検査依頼No
    sb.append("  INTO   :1 "                               );
    sb.append("  FROM   ic_lots_mst ilm "                  ); // OPMロットマスタ
    sb.append("  WHERE  ilm.item_id = :2 "                 ); // 品目ID
    sb.append("  AND    ilm.lot_id = :3; "                 ); // ロットID
    sb.append("END; "                                      );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(itemId)); // 品目ID
      cstmt.setInt(3, XxcmnUtility.intValue(lotId));  // ロットID
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR);   // 検査依頼No
      
      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      qtInspectReqNo = cstmt.getObject(1); // 検査依頼No

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return qtInspectReqNo;
  } // getQtInspectReqNo
  
  /*****************************************************************************
   * ロット作成APIを起動します。
   * @param trans - トランザクション
   * @param params - パラメータ
   * @return HashMap
   * @throws OAException - OA例外
   ****************************************************************************/
  public static HashMap insertLotMst(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertLotMst"; // API名

    // INパラメータ取得
    String itemNo            = (String)params.get("ItemCode");   // 品目
    String lotNo             = (String)params.get("LotNumber");  // ロット番号
    Date productedDate       = (Date)params.get("ProductedDate");// 製造年月日
    String koyuCode          = (String)params.get("KoyuCode");   // 固有記号
    Date useByDate           = (Date)params.get("UseByDate");    // 賞味期限
    String stockQty          = (String)params.get("StockQty");   // 在庫入数
    String stockValue        = (String)params.get("StockValue"); // 在庫単価
    String lotStatus         = (String)params.get("LotStatus");  // ロットステータス
    String vendorCode        = (String)params.get("VendorCode"); // 取引先コード
    String productResultType = (String)params.get("ProductResultType"); // 処理タイプ

    HashMap retHashMap = new HashMap(); // 戻り値
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lr_lot_in              GMIGAPI.lot_rec_typ; "                  );
    sb.append("  lr_lot_out             ic_lots_mst%ROWTYPE; "                  );
    sb.append("  lr_lot_cpg_out         ic_lots_cpg%ROWTYPE; "                  );
    sb.append("  ln_api_version_number  CONSTANT NUMBER := 3.0; "               );
    sb.append("  lb_setup_return_sts    BOOLEAN; "                              );
    sb.append("BEGIN "                                                          );
                 // GMI系APIグローバル定数の設定
    sb.append("  lb_setup_return_sts  :=  GMIGUTL.Setup(FND_GLOBAL.USER_NAME); "); 
                 // パラメータ作成
    sb.append("  lr_lot_in.item_no          := :1; "                            ); // 品目
    sb.append("  lr_lot_in.lot_no           := :2; "                            ); // ロット番号
    sb.append("  lr_lot_in.lot_created      := SYSDATE; "                       ); // 作成日
// 2008-12-24 v.1.6 D.Nihei Add Start 本番障害#743
    sb.append("  lr_lot_in.expaction_date   := TO_DATE('2099/12/31', 'YYYY/MM/DD'); "); // 再テスト日付
    sb.append("  lr_lot_in.expire_date      := TO_DATE('2099/12/31', 'YYYY/MM/DD'); "); // 失効日付
// 2008-12-24 v.1.6 D.Nihei Add End
    sb.append("  lr_lot_in.attribute1       := TO_CHAR(:3,'YYYY/MM/DD'); "      ); // 製造年月日
    sb.append("  lr_lot_in.attribute2       := :4; "                            ); // 固有記号
    sb.append("  lr_lot_in.attribute3       := TO_CHAR(:5,'YYYY/MM/DD'); "      ); // 賞味期限
    sb.append("  lr_lot_in.attribute6       := :6; "                            ); // 在庫入数
    sb.append("  lr_lot_in.attribute7       := :7; "                            ); // 在庫単価
    sb.append("  lr_lot_in.attribute23      := :8; "                            ); // ロットステータス
    sb.append("  lr_lot_in.attribute8       := :9; "                            ); // 取引先コード
    // 処理タイプが1:相手先在庫管理の場合
    if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType)) 
    {
      sb.append("  lr_lot_in.attribute24      := '2'; "                         ); // 作成区分

    // 処理タイプが2:即時仕入の場合
    } else if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(productResultType))
    {
      sb.append("  lr_lot_in.attribute24      := '3'; "                         ); // 作成区分
    }    
                 // API:ロット作成実行
    sb.append("  GMIPAPI.CREATE_LOT(  "                                         );
    sb.append("     p_api_version      => ln_api_version_number "               ); // IN:APIのバージョン番号
    sb.append("    ,p_init_msg_list    => FND_API.G_FALSE "                     ); // IN:メッセージ初期化フラグ
    sb.append("    ,p_commit           => FND_API.G_FALSE "                     ); // IN:処理確定フラグ
    sb.append("    ,p_validation_level => FND_API.G_VALID_LEVEL_FULL "          ); // IN:検証レベル
    sb.append("    ,p_lot_rec          => lr_lot_in "                           ); // IN:作成するロット情報を指定
    sb.append("    ,x_ic_lots_mst_row  => lr_lot_out "                          ); // OUT:作成されたロット情報が返却
    sb.append("    ,x_ic_lots_cpg_row  => lr_lot_cpg_out "                      ); // OUT:作成されたロット情報が返却
    sb.append("    ,x_return_status    => :10 "                                  ); // OUT:終了ステータス( 'S'-正常終了, 'E'-例外発生, 'U'-システム例外発生)
    sb.append("    ,x_msg_count        => :11 "                                 ); // OUT:メッセージ・スタック数
    sb.append("    ,x_msg_data         => :12); "                               ); // OUT:メッセージ   
    sb.append("  :13 := lr_lot_out.lot_id; "                                    ); // ロットID  
    sb.append("END; "                                                           );
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, itemNo);                              // 品目コード
      cstmt.setString(2, lotNo);                               // ロット番号
      cstmt.setDate(3, XxcmnUtility.dateValue(productedDate)); // 製造日
      cstmt.setString(4, koyuCode);                            // 固有記号
      cstmt.setDate(5, XxcmnUtility.dateValue(useByDate));     // 賞味期限
      cstmt.setString(6, stockQty);                            // 在庫入数
      cstmt.setString(7, stockValue);                          // 在庫単価
      cstmt.setString(8, lotStatus);                           // ロットステータス
      cstmt.setString(9, vendorCode);                          // 取引先コード
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(10,  Types.VARCHAR); // リターンステータス
      cstmt.registerOutParameter(11, Types.INTEGER); // メッセージカウント
      cstmt.registerOutParameter(12, Types.VARCHAR); // メッセージ
      cstmt.registerOutParameter(13, Types.INTEGER); // ロットID

      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      String retStatus = cstmt.getString(10);  // リターンステータス
      int msgCnt       = cstmt.getInt(11);   // メッセージカウント
      String msgData   = cstmt.getString(12); // メッセージ

      // 正常終了の場合
      if (XxcmnConstants.API_STATUS_SUCCESS.equals(retStatus)) 
      {
        // ロットID、リターンコード正常をセット
        retHashMap.put("LotId", cstmt.getObject(13));
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);

      // 正常終了でない場合、エラー  
      } else
      {
        // APIエラーを出力する。
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              msgData,
                              6);
        //トークン生成
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                   XxpoConstants.TAB_IC_LOTS_MST) };
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                               XxpoConstants.XXPO10007, 
                               tokens);
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
          rollBack(trans);
          XxcmnUtility.writeLog(trans,
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // insertLotMst

  /*****************************************************************************
   * 完了在庫トランザクションAPIを起動します。
   * @param trans - トランザクション
   * @param params - パラメータ
   * @return String -   XxcmnConstants.RETURN_SUCCESS:1 正常
   *                    XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String insertInventoryPosting(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertInventoryPosting";

    // INパラメータ取得
    String itemNo            = (String)params.get("ItemCode");          // 品目
    String fromWhseCode      = (String)params.get("WhseCode");          // 倉庫コード
    String fromLocation      = (String)params.get("LocationCode");      // 相手先在庫入庫先
    String itemUm            = (String)params.get("Uom");               // 数量(単位コード)
    String lotNo             = (String)params.get("LotNumber");         // ロット番号
    String productedQuantity = (String)params.get("ProductedQuantity"); // 出来高数量
    Number quantity          = (Number)params.get("Quantity");          // 数量
    Number conversionFactor  = (Number)params.get("ConversionFactor");  // 換算入数
    Date   transDate         = (Date)params.get("ManufacturedDate");    // 生産日
    String coCode            = (String)params.get("CoCode");            // 会社コード
    String orgnCode          = (String)params.get("OrgnCode");          // 組織コード
    Number txnsId            = (Number)params.get("TxnsId");            // 実績ID
    String processFlag       = (String)params.get("ProcessFlag");       // 処理フラグ

    // API戻り値
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; 

    //PL/SQLの作成を行います
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
                 // GMI系APIグローバル定数の設定
    sb.append("  lb_setup_return_sts  :=  GMIGUTL.Setup(FND_GLOBAL.USER_NAME); "            ); 
                 // パラメータ作成
    sb.append("  lr_qty_in.trans_type     := 2;  "                                          ); // 取引タイプ
    sb.append("  lr_qty_in.item_no        := :1; "                                          ); // 品目
    sb.append("  lr_qty_in.from_whse_code := :2; "                                          ); // 倉庫
    sb.append("  lr_qty_in.item_um        := :3; "                                          ); // 単位
    sb.append("  lr_qty_in.lot_no         := :4; "                                          ); // ロット
    sb.append("  lr_qty_in.from_location  := :5; "                                          ); // 保管場所
    sb.append("  ln_quantity  := :6; "                                                      ); // 保管場所
    sb.append("  IF (:7 = '1') THEN "                                                       ); // 登録の場合、数量は画面出来高数量 * 換算入数
    sb.append("    lr_qty_in.trans_qty    := TO_NUMBER(:8) * "                              );
    sb.append("                              :9; "                                          );    
    sb.append("  ELSE "                                                                     ); // 更新の場合、数量は登録済数量 - 画面出来高数量 * 換算入数
    sb.append("    lr_qty_in.trans_qty    := TO_NUMBER(:8) * "                              );
    sb.append("                              :9 "                                           );    
    sb.append("                              - NVL(ln_quantity,0); "                        );
    sb.append("  END IF; "                                                                  ); 
    sb.append("  lr_qty_in.co_code        := :10; "                                         ); // 会社コード
    sb.append("  lr_qty_in.orgn_code      := :11; "                                         ); // 組織コード
    sb.append("  lr_qty_in.trans_date     := :12; "                                         ); // 取引日
    sb.append("  lr_qty_in.reason_code    := FND_PROFILE.VALUE('XXPO_CTPTY_INV_RCV_RSN'); " ); // 事由コード
    sb.append("  lr_qty_in.user_name      := FND_GLOBAL.USER_NAME; "                        ); // ユーザー名
    sb.append("  lr_qty_in.attribute1     := TO_CHAR(:13); "                                ); // ソース文書ID
// 2008-12-26 H.Itou Add Start 発注(相手先在庫仕入)と区別するため、外注出来高の場合はDFF4にYを立てる。
    sb.append("  lr_qty_in.attribute4     := 'Y'; "                                         );
// 2008-12-26 H.Itou Add End
                 // API:完了在庫トランザクション実行 
    sb.append("  GMIPAPI.INVENTORY_POSTING(  "                                              );
    sb.append("     p_api_version      => ln_api_version_number "                           ); // IN:APIのバージョン番号
    sb.append("    ,p_init_msg_list    => FND_API.G_FALSE "                                 ); // IN:メッセージ初期化フラグ
    sb.append("    ,p_commit           => FND_API.G_FALSE "                                 ); // IN:処理確定フラグ
    sb.append("    ,p_validation_level => FND_API.G_VALID_LEVEL_FULL"                       ); // IN:検証レベル
    sb.append("    ,p_qty_rec          => lr_qty_in "                                       ); // IN:調整する在庫数量情報を指定
    sb.append("    ,x_ic_jrnl_mst_row  => ic_jrnl_out "                                     ); // OUT:調整された在庫数量情報が返却
    sb.append("    ,x_ic_adjs_jnl_row1  => ic_adjs_jnl_out1 "                               ); // OUT:調整された在庫数量情報が返却
    sb.append("    ,x_ic_adjs_jnl_row2  => ic_adjs_jnl_out2 "                               ); // OUT:
    sb.append("    ,x_return_status    => :14 "                                             ); // OUT:終了ステータス( 'S'-正常終了, 'E'-例外発生, 'U'-システム例外発生)
    sb.append("    ,x_msg_count        => :15 "                                             ); // OUT:メッセージ・スタック数
    sb.append("    ,x_msg_data         => :16); "                                           ); // OUT:メッセージ   
    sb.append("END; "                                                                       );
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, itemNo);                                   // 品目
      cstmt.setString(2, fromWhseCode);                             // 倉庫
      cstmt.setString(3, itemUm);                                   // 単位
      cstmt.setString(4, lotNo);                                    // ロット番号
      cstmt.setString(5, fromLocation);                             // 保管場所コード
// 2009-07-08 H.Itou Mod Start 本番障害#1566対応 小数点も計算に入れる。
//      cstmt.setInt(6, XxcmnUtility.intValue(quantity));             // 数量
      cstmt.setDouble(6, XxcmnUtility.doubleValue(quantity));             // 数量
// 2009-07-08 H.Itou Mod End
      cstmt.setString(7, processFlag);                              // 処理フラグ
      cstmt.setString(8, productedQuantity);                        // 出来高数量
      cstmt.setInt(9, XxcmnUtility.intValue(conversionFactor));     // 換算入数
      cstmt.setString(10, coCode);                                  // 会社コード
      cstmt.setString(11, orgnCode);                                // 組織コード
      cstmt.setDate(12, XxcmnUtility.dateValue(transDate));         // 生産日        
      cstmt.setInt(13, XxcmnUtility.intValue(txnsId));              // 実績ID

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(14, Types.VARCHAR); // リターンコード
      cstmt.registerOutParameter(15, Types.INTEGER); // メッセージカウント
      cstmt.registerOutParameter(16, Types.VARCHAR); // メッセージ
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      String retStatus = cstmt.getString(14); // リターンコード
      int msgCnt    = cstmt.getInt(15);       // メッセージカウント
      String msgData   = cstmt.getString(16); // メッセージ

      // 正常終了の場合、フラグを1:正常に。
      if (XxcmnConstants.API_STATUS_SUCCESS.equals(retStatus)) 
      {
        // リターンコード正常をセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;

      // 正常終了でない場合、エラー  
      } else
      {

        // APIエラーを出力する。
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              msgData,
                              6);
        //トークン生成
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                   XxpoConstants.TAB_IC_TRAN_CMP) };
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                               XxpoConstants.XXPO10007, 
                               tokens);
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
          rollBack(trans);
          XxcmnUtility.writeLog(trans,
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // insertInventoryPosting

  /*****************************************************************************
   * ロット原価APIを起動します。
   * @param trans - トランザクション
   * @param params - パラメータ
   * @return String -   XxcmnConstants.RETURN_SUCCESS:1 正常
   *                     XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String insertLotCostAdjustment(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertLotCostAdjustment";

    // INパラメータ取得
    String coCode   = (String)params.get("CoCode");  // 会社コード
    Number itemId   = (Number)params.get("ItemId");  // 品目ID
    String whseCode = (String)params.get("WhseCode");// 倉庫コード
    Number lotId    = (Number)params.get("LotId");   // ロットID
    
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // 戻り値

    //PL/SQLの作成を行います
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
                 // GMI系APIグローバル定数の設定
    sb.append("  lb_setup_return_sts  :=  GMIGUTL.Setup(FND_GLOBAL.USER_NAME); "                               ); 
                 // パラメータ作成
    sb.append("  lr_lc_adjustment_header.co_code          := :1; "                                             ); // 1:会社コード
    sb.append("  lr_lc_adjustment_header.cost_mthd_code   := FND_PROFILE.VALUE('XXPO_COST_MTHD_CODE'); "       ); // ロット原価方法
    sb.append("  lr_lc_adjustment_header.item_id          := :2; "                                             ); // 2:品目ID
    sb.append("  lr_lc_adjustment_header.whse_code        := :3; "                                             ); // 3:保管場所
    sb.append("  lr_lc_adjustment_header.lot_id           := :4; "                                             ); // 4:ロットID
    sb.append("  lr_lc_adjustment_header.adjustment_date  := SYSDATE; "                                        ); // 
    sb.append("  lr_lc_adjustment_header.reason_code      := FND_PROFILE.VALUE('XXPO_CTPTY_COST_RSN'); "       ); // 事由コード
    sb.append("  lr_lc_adjustment_header.delete_mark      := 0; "                                              ); // 
    sb.append("  lr_lc_adjustment_header.user_name        := FND_GLOBAL.USER_NAME; "                           ); // ユーザー名
    sb.append("  lr_lc_adjustment_dtls(0).cost_cmpntcls_code := FND_PROFILE.VALUE('XXPO_COST_CMPNTCLS_CODE'); "); // コンポーネント区分コード
    sb.append("  lr_lc_adjustment_dtls(0).cost_analysis_code := FND_PROFILE.VALUE('XXPO_COST_ANALYSIS_CODE'); "); // 分析コード
    sb.append("  lr_lc_adjustment_dtls(0).adjustment_cost    := 0; "                                           ); // 原価
                 // API:ロット作成実行 
    sb.append("  GMF_LotCostAdjustment_PUB.Create_LotCost_Adjustment(  "                                       );
    sb.append("     p_api_version      => ln_api_version_number "                                              ); // IN:APIのバージョン番号
    sb.append("    ,p_init_msg_list    => FND_API.G_FALSE "                                                    ); // IN:メッセージ初期化フラグ
    sb.append("    ,p_commit           => FND_API.G_FALSE "                                                    ); // IN:処理確定フラグ
    sb.append("    ,x_return_status    => lv_ret_status "                                                      ); // OUT:終了ステータス( 'S'-正常終了, 'E'-例外発生, 'U'-システム例外発生)
    sb.append("    ,x_msg_count        => ln_msg_cnt "                                                         ); // OUT:メッセージ・スタック数
    sb.append("    ,x_msg_data         => lv_msg_data "                                                        ); // OUT:メッセージ   
    sb.append("    ,p_header_rec       => lr_lc_adjustment_header "                                            ); // IN OUT:登録するロット原価ヘッダ情報を指定、返却
    sb.append("    ,p_dtl_tbl       => lr_lc_adjustment_dtls); "                                               ); // IN OUT:登録するロット原価明細情報を指定、返却
                 // エラーメッセージをFND_LOG_MESSAGESに出力
    sb.append("  IF (ln_msg_cnt > 0) THEN "                                                                    ); 
    sb.append("    xxcmn_common_pkg.put_api_log( "                                                             );
    sb.append("       ov_errbuf  => lv_errbuf"                                                                 );
    sb.append("      ,ov_retcode => lv_retcode"                                                                );
    sb.append("      ,ov_errmsg  => lv_errmsg );"                                                              );
    sb.append("  END IF; "                                                                                     );
                 // OUTパラメータ出力
    sb.append("  :5 := lv_ret_status;"                                                                         );
    sb.append("  :6 := ln_msg_cnt;"                                                                            );
    sb.append("  :7 := lv_msg_data;"                                                                           );
    sb.append("END; "                                                                                          );
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, coCode);                     // 会社コード
      cstmt.setInt(2, XxcmnUtility.intValue(itemId)); // 品目
      cstmt.setString(3, whseCode);                   // 倉庫コード
      cstmt.setInt(4, XxcmnUtility.intValue(lotId));  // ロットID
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(5, Types.VARCHAR); // リターンコード
      cstmt.registerOutParameter(6, Types.INTEGER); // メッセージ数
      cstmt.registerOutParameter(7, Types.VARCHAR); // メッセージ
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      String retStatus = cstmt.getString(5); // リターンコード
      int msgCnt    = cstmt.getInt(6);    // メッセージ数
      String msgData   = cstmt.getString(7); // メッセージ

      // 正常終了の場合、フラグを1:正常に。
      if (XxcmnConstants.API_STATUS_SUCCESS.equals(retStatus)) 
      {
        // リターンコード正常をセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;

      // 正常終了でない場合、エラー  
      } else
      {
        // APIエラーを出力する。
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              msgData,
                              6);
        //トークン生成
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                   XxpoConstants.TAB_GMF_LOT_COST_ADJUSTMENTS) };
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                               XxpoConstants.XXPO10007, 
                               tokens);
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
          rollBack(trans);
          XxcmnUtility.writeLog(trans,
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // insertLotCostAdjustment

  /*****************************************************************************
   * 外注出来高実績にデータを追加します。
   * @param trans - トランザクション
   * @param params - パラメータ
   * @return HashMap -   
   * @throws OAException - OA例外
   ****************************************************************************/
  public static HashMap insertXxpoVendorSupplyTxns(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertXxpoVendorSupplyTxns";

    // INパラメータ取得
    String txnsType          = (String)params.get("ProductResultType"); // 処理タイプ
    Date   manufacturedDate  = (Date)params.get("ManufacturedDate");    // 生産日
    Number vendorId          = (Number)params.get("VendorId");          // 取引先ID
    String vendorCode        = (String)params.get("VendorCode");        // 取引先
    Number factoryId         = (Number)params.get("FactoryId");         // 工場ID
    String factoryCode       = (String)params.get("FactoryCode");       // 工場コード
    Number locationId        = (Number)params.get("LocationId");        // 納入先ID
    String locationCode      = (String)params.get("LocationCode");      // 納入先コード
    Number itemId            = (Number)params.get("ItemId");            // 品目ID
    String itemCode          = (String)params.get("ItemCode");          // 品目コード
    Number lotId             = (Number)params.get("LotId");             // ロットID    
    String lotNumber         = (String)params.get("LotNumber");         // ロット番号
    Date   productedDate     = (Date)params.get("ProductedDate");       // 製造日
    String koyuCode          = (String)params.get("KoyuCode");          // 固有記号
    String productedQuantity = (String)params.get("ProductedQuantity"); // 出来高数量
    Number conversionFactor  = (Number)params.get("ConversionFactor");  // 換算入数
    String uom               = (String)params.get("Uom");               // 数量(単位コード)
    String productedUom      = (String)params.get("ProductedUom");      // 出来高数量(単位コード)
    String description       = (String)params.get("Description");       // 備考
    
    // OUTパラメータ用
    HashMap retHashMap = new HashMap();
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                            );
    sb.append("  lt_txns_id xxpo_vendor_supply_txns.txns_id%TYPE; " );
    sb.append("BEGIN "                                              );
    sb.append("  SELECT xxpo_vendor_supply_txns_s1.NEXTVAL  "       );
    sb.append("  INTO   lt_txns_id  "                               );
    sb.append("  FROM   DUAL;  "                                    );
                 // 外注出来高実績登録
    sb.append("  INSERT INTO xxpo_vendor_supply_txns xvst( "        );
    sb.append("     xvst.txns_id "                                  ); //   実績ID
    sb.append("    ,xvst.txns_type "                                ); // 1:処理タイプ
    sb.append("    ,xvst.manufactured_date "                        ); // 2:生産日
    sb.append("    ,xvst.vendor_id "                                ); // 3:取引先ID
    sb.append("    ,xvst.vendor_code "                              ); // 4:取引先コード
    sb.append("    ,xvst.factory_id "                               ); // 5:工場ID
    sb.append("    ,xvst.factory_code "                             ); // 6:工場コード
    sb.append("    ,xvst.location_id "                              ); // 7:納入先ID
    sb.append("    ,xvst.location_code "                            ); // 8:納入先コード
    sb.append("    ,xvst.item_id "                                  ); // 9:品目ID
    sb.append("    ,xvst.item_code "                                ); // 10:品目コード
    sb.append("    ,xvst.lot_id "                                   ); // 11:ロットID
    sb.append("    ,xvst.lot_number "                               ); // 12:ロットNo
    sb.append("    ,xvst.producted_date "                           ); // 13:製造日
    sb.append("    ,xvst.koyu_code "                                ); // 14:固有記号
    sb.append("    ,xvst.producted_quantity "                       ); // 15:出来高数量
    sb.append("    ,xvst.conversion_factor "                        ); // 16:換算入数
    sb.append("    ,xvst.quantity "                                 ); //    数量
    sb.append("    ,xvst.uom "                                      ); // 17:単位コード
    sb.append("    ,xvst.producted_uom "                            ); // 18:出来高単位コード
    sb.append("    ,xvst.order_created_flg "                        ); //    発注作成フラグ
    sb.append("    ,xvst.order_created_date "                       ); //    発注作成日
    sb.append("    ,xvst.description "                              ); // 19:摘要
    sb.append("    ,xvst.created_by "                               ); //   作成者
    sb.append("    ,xvst.creation_date "                            ); //   作成日
    sb.append("    ,xvst.last_updated_by "                          ); //   最終更新者
    sb.append("    ,xvst.last_update_date "                         ); //   最終更新日
    sb.append("    ,xvst.last_update_login) "                       ); //   最終更新ログイン
    sb.append("  VALUES( "                                          );
    sb.append("     lt_txns_id "                                    ); // 実績ID
    sb.append("    ,:1 "                                            ); // 処理タイプ  
    sb.append("    ,:2 "                                            ); // 生産日  
    sb.append("    ,:3 "                                            ); // 取引先ID  
    sb.append("    ,:4 "                                            ); // 取引先コード  
    sb.append("    ,:5 "                                            ); // 工場ID  
    sb.append("    ,:6 "                                            ); // 工場コード  
    sb.append("    ,:7 "                                            ); // 納入先ID  
    sb.append("    ,:8 "                                            ); // 納入先コード  
    sb.append("    ,:9 "                                            ); // 品目ID  
    sb.append("    ,:10 "                                           ); // 品目コード  
    sb.append("    ,:11 "                                           ); // ロットID
    sb.append("    ,:12 "                                           ); // ロットNo
    sb.append("    ,:13 "                                           ); // 製造日
    sb.append("    ,:14 "                                           ); // 固有記号
    sb.append("    ,TO_NUMBER(:15) "                                ); // 出来高数量
    sb.append("    ,:16 "                                           ); // 換算入数
    sb.append("    ,TO_NUMBER(:15) * TO_NUMBER(:16) "               ); // 数量 = 出来高数量 × 換算入数
    sb.append("    ,:17 "                                           ); // 単位コード
    sb.append("    ,:18 "                                           ); // 出来高単位コード
    // 処理タイプが1:相手先在庫管理の場合
    if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(txnsType)) 
    {
      sb.append("  ,'N' "                                           ); // 発注作成フラグ
      sb.append("  ,NULL "                                          ); // 発注作成日

    // 処理タイプが2:即時仕入の場合
    } else if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(txnsType))
    {
      sb.append("  ,'Y' "                                           ); // 発注作成フラグ
      sb.append("  ,SYSDATE "                                       ); // 発注作成日     
    }
    sb.append("    ,:19 "                                           ); // 摘要
    sb.append("    ,FND_GLOBAL.USER_ID "                            ); // 作成者
    sb.append("    ,SYSDATE "                                       ); // 作成日
    sb.append("    ,FND_GLOBAL.USER_ID "                            ); // 最終更新者
    sb.append("    ,SYSDATE "                                       ); // 最終更新日
    sb.append("    ,FND_GLOBAL.LOGIN_ID); "                         ); // 最終更新ログイン
                 // OUTパラメータ
    sb.append("  :20 := '1'; "                                      ); // 1:正常終了
    sb.append("  :21 := lt_txns_id; "                               ); // 実績ID
    sb.append("END; "                                               );
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1,  txnsType);                               // 処理タイプ
      cstmt.setDate(2,  XxcmnUtility.dateValue(manufacturedDate)); // 生産日
      cstmt.setInt(3,  XxcmnUtility.intValue(vendorId));           // 取引先ID
      cstmt.setString(4,  vendorCode);                             // 取引先
      cstmt.setInt(5,  XxcmnUtility.intValue(factoryId));          // 工場ID
      cstmt.setString(6,  factoryCode);                            // 工場コード
      cstmt.setInt(7,  XxcmnUtility.intValue(locationId));         // 納入先ID
      cstmt.setString(8,  locationCode);                           // 納入先コード
      cstmt.setInt(9,  XxcmnUtility.intValue(itemId));             // 品目ID
      cstmt.setString(10, itemCode);                               // 品目コード
      cstmt.setInt(11, XxcmnUtility.intValue(lotId));              // ロットID
      cstmt.setString(12, lotNumber);                              // ロット番号
      cstmt.setDate(13, XxcmnUtility.dateValue(productedDate));    // 製造日
      cstmt.setString(14, koyuCode);                               // 固有記号
      cstmt.setString(15, productedQuantity);                      // 出来高数量
      cstmt.setInt(16, XxcmnUtility.intValue(conversionFactor));   // 換算入数
      cstmt.setString(17, uom);                                    // 数量(単位コード)
      cstmt.setString(18, productedUom);                           // 出来高数量(単位コード)
      cstmt.setString(19, description);                            // 備考
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(20, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(21, Types.INTEGER);   // 実績ID
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      String retFlag = cstmt.getString(20);

      // 正常終了の場合
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // リターンコード：正常をセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);
        retHashMap.put("TxnsId", cstmt.getObject(21));
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //トークン生成
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_XXPO_VENDOR_SUPPLY_TXNS) };
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // insertXxpoVendorSupplyTxns

  /*****************************************************************************
   * 発注ヘッダアドオンにデータを追加します。
   * @param trans - トランザクション
   * @param params - パラメータ
   * @return String - XxcmnConstants.RETURN_SUCCESS:1 正常
   *                   XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String insertXxpoHeadersAll(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertXxpoHeadersAll";

    // INパラメータ取得
    String poHeaderNumber    = (String)params.get("PoNumber");       // 発注番号
    Date   orderCreatedDate  = (Date)params.get("ManufacturedDate"); // 生産日

    // OUTパラメータ用
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // 戻り値

    // 購買担当者従業員コードを取得します
    String purchaseEmpNumber = getPurchaseEmpNumber(trans);
  
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                           );
                 // 発注ヘッダ(アドオン)登録
    sb.append("  INSERT INTO xxpo_headers_all xha( "             );
    sb.append("     xha.xxpo_header_id   "                       ); // 発注ヘッダ(アドオンID)
    sb.append("    ,xha.po_header_number   "                     ); // 1:発注番号
    sb.append("    ,xha.order_created_by_code   "                ); // 作成者コード
    sb.append("    ,xha.order_created_date   "                   ); // 2:作成日
    sb.append("    ,xha.order_approved_flg   "                   ); // 発注承諾フラグ
    sb.append("    ,xha.purchase_approved_flg   "                ); // 仕入承諾フラグ
    sb.append("    ,xha.created_by   "                           ); // 作成者
    sb.append("    ,xha.creation_date   "                        ); // 作成日
    sb.append("    ,xha.last_updated_by   "                      ); // 最終更新者
    sb.append("    ,xha.last_update_date   "                     ); // 最終更新日
    sb.append("    ,xha.last_update_login)   "                   ); // 最終更新ログイン
    sb.append("  VALUES( "                                       );
    sb.append("     xxpo_headers_all_s1.NEXTVAL "                ); // 発注ヘッダ(アドオンID)
    sb.append("    ,:1 "                                         ); // 発注番号  
    sb.append("    ,:2 "                                         ); // 作成者コード  
    sb.append("    ,:3 "                                         ); // 作成日  
    sb.append("    ,'N' "                                        ); // 発注承諾フラグ  
    sb.append("    ,'N' "                                        ); // 仕入承諾フラグ  
    sb.append("    ,FND_GLOBAL.USER_ID "                         ); // 作成者
    sb.append("    ,SYSDATE "                                    ); // 作成日
    sb.append("    ,FND_GLOBAL.USER_ID "                         ); // 最終更新者
    sb.append("    ,SYSDATE "                                    ); // 最終更新日
    sb.append("    ,FND_GLOBAL.LOGIN_ID); "                      ); // 最終更新ログイン
                 // OUTパラメータ
    sb.append("  :4 := '1'; "                                    ); // 1:正常終了
    sb.append("END; "                                            );

    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1,  poHeaderNumber);                         // 発注番号
      cstmt.setString(2,  purchaseEmpNumber);                      // 購買担当者従業員コード
      cstmt.setDate(3,  XxcmnUtility.dateValue(orderCreatedDate)); // 生産日
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(4, Types.VARCHAR);   // リターンコード
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      retFlag = cstmt.getString(4); // リターンコード

      // 正常終了の場合
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        retFlag = XxcmnConstants.RETURN_SUCCESS;
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //トークン生成
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_XXPO_HEADERS_ALL) };
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }

    return retFlag;
  } // insertXxpoHeadersAll

  /*****************************************************************************
   * 発注ヘッダオープンIFにデータを追加します。
   * @param trans - トランザクション
   * @param params - パラメータ
   * @return String - XxcmnConstants.RETURN_SUCCESS:1 正常
   *                   XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String insertPoHeadersIf(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertPoHeadersIf";

    // INパラメータ取得
    String poHeaderNumber   = (String)params.get("PoNumber");         // 発注番号
    Number vendorId         = (Number)params.get("VendorId");         // 取引先ID
    Number vendorSiteId     = (Number)params.get("FactoryId");        // 工場ID
    Number shipToLocationId = (Number)params.get("ShipToLocationId"); // 納入先ID
    Date   manufacturedDate = (Date)params.get("ManufacturedDate");   // 生産日
    String locationCode     = (String)params.get("LocationCode");     // 納入先コード
    String department       = (String)params.get("Department");       // 部署

    // OUTパラメータ用
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // 戻り値

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                 );
                 // 発注ヘッダオープンIF登録
    sb.append("  INSERT INTO po_headers_interface phi  ( "             ); // 発注ヘッダオープンIF
    sb.append("     phi.interface_header_id "                          ); //   IFヘッダID
    sb.append("    ,phi.batch_id "                                     ); // 1:バッチID 
    sb.append("    ,phi.process_code "                                 ); //   処理
    sb.append("    ,phi.action "                                       ); //   処理
    sb.append("    ,phi.org_id "                                       ); //   営業単位ID
    sb.append("    ,phi.document_type_code "                           ); //   文書タイプ
    sb.append("    ,phi.document_num "                                 ); // 1:文書番号
    sb.append("    ,phi.agent_id "                                     ); //   購買担当者ID
    sb.append("    ,phi.vendor_id "                                    ); // 2:仕入先ID
    sb.append("    ,phi.vendor_site_id "                               ); // 3:仕入先サイトID
    sb.append("    ,phi.ship_to_location_id "                          ); // 4:納入先事業所ID
    sb.append("    ,phi.bill_to_location_id "                          ); //   請求先事業所ID
    sb.append("    ,phi.approval_status "                              ); //   承認ステータス
    sb.append("    ,phi.attribute1 "                                   ); //   ステータス
    sb.append("    ,phi.attribute2 "                                   ); //   仕入先承諾要フラグ
    sb.append("    ,phi.attribute4 "                                   ); // 5:納入日
    sb.append("    ,phi.attribute5 "                                   ); // 6:納入先コード
    sb.append("    ,phi.attribute6 "                                   ); //   直送区分
    sb.append("    ,phi.attribute10 "                                  ); // 7:部署コード
    sb.append("    ,phi.attribute11 "                                  ); //   発注区分
    sb.append("    ,phi.load_sourcing_rules_flag "                     ); //   ソースルール作成フラグ
    sb.append("    ,phi.created_by "                                   ); //   作成日
    sb.append("    ,phi.creation_date "                                ); //   作成者
    sb.append("    ,phi.last_updated_by "                              ); //   最終更新日
    sb.append("    ,phi.last_update_date "                             ); //   最終更新者
    sb.append("    ,phi.last_update_login) "                           ); //   最終更新ログイン
    sb.append("  VALUES( "                                             );
    sb.append("     po_headers_interface_s.NEXTVAL "                   ); // IFヘッダID
    sb.append("    ,TO_CHAR(po_headers_interface_s.CURRVAL) ||  :1 "   ); // バッチID = IFヘッダID || 発注番号
    sb.append("    ,'PENDING' "                                        ); // 処理
    sb.append("    ,'ORIGINAL' "                                       ); // 処理
    sb.append("    ,FND_PROFILE.VALUE('ORG_ID') "                      ); // 営業単位ID
    sb.append("    ,'STANDARD' "                                       ); // 文書タイプ
    sb.append("    ,:1 "                                               ); // 文書番号(発注番号)
    sb.append("    ,FND_PROFILE.VALUE('XXPO_PURCHASE_EMP_ID') "        ); // 購買担当者ID
    sb.append("    ,:2 "                                               ); // 仕入先ID
    sb.append("    ,:3 "                                               ); // 仕入先サイトID
    sb.append("    ,:4 "                                               ); // 納入先事業所ID
    sb.append("    ,FND_PROFILE.VALUE('XXPO_BILL_TO_LOCATION_ID') "    ); // 請求先事業所ID
    sb.append("    ,'APPROVED' "                                       ); // 承認ステータス
    sb.append("    ,'20' "                                             ); // ステータス
    sb.append("    ,'N' "                                              ); // 仕入先承諾要フラグ
    sb.append("    ,TO_CHAR(:5,'YYYY/MM/DD') "                         ); // 納入日
    sb.append("    ,:6 "                                               ); // 納入先コード
    sb.append("    ,'1' "                                              ); // 直送区分
    sb.append("    ,:7 "                                               ); // 部署コード
    sb.append("    ,'1' "                                              ); // 発注区分 1:新規
    sb.append("    ,'N' "                                              ); // ソースルール作成フラグ
    sb.append("    ,FND_GLOBAL.USER_ID "                               ); // 作成者
    sb.append("    ,SYSDATE "                                          ); // 作成日
    sb.append("    ,FND_GLOBAL.USER_ID "                               ); // 最終更新者
    sb.append("    ,SYSDATE "                                          ); // 最終更新日
    sb.append("    ,FND_GLOBAL.LOGIN_ID); "                            ); // 最終更新ログイン
                 // OUTパラメータ
    sb.append("  :8 := '1'; "                                          ); // 1:正常終了
    sb.append("END; "                                                  );

    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, poHeaderNumber);                         // 発注番号
      cstmt.setInt(2, XxcmnUtility.intValue(vendorId));           // 取引先ID
      cstmt.setInt(3, XxcmnUtility.intValue(vendorSiteId));       // 工場ID
      cstmt.setInt(4, XxcmnUtility.intValue(shipToLocationId));   // 納入先ID
      cstmt.setDate(5, XxcmnUtility.dateValue(manufacturedDate)); // 生産日
      cstmt.setString(6, locationCode);                           // 納入先コード
      cstmt.setString(7, department);                             // 部署
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(8, Types.VARCHAR);   // リターンコード
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      retFlag = cstmt.getString(8); // リターンコード

      // 正常終了の場合
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // リターンコード：正常、実績IDをセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //トークン生成
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_PO_HEADERS_INTERFACE) };
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // insertPoHeadersIf 

  /*****************************************************************************
   * 発注明細オープンIFにデータを追加します。
   * @param trans - トランザクション
   * @param params - パラメータ
   * @return String - XxcmnConstants.RETURN_SUCCESS:1 正常
   *                   XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String insertPoLinesIf(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertPoLinesIf";

    // INパラメータ取得
    String poHeaderNumber    = (String)params.get("PoNumber");          // 発注番号
    Number itemId            = (Number)params.get("InventoryItemId");   // INV品目ID
    String uomCode           = (String)params.get("Uom");               // 単位コード
    String productedQuantity = (String)params.get("ProductedQuantity"); // 出来高数量
    Number conversionFactor  = (Number)params.get("ConversionFactor");  // 換算入数    
// 2008-06-18 H.Itou MOD START
//    String unitPrice         = (String)params.get("StockValue");        // 在庫単価    
    String unitPrice         = getTotalAmount(trans, params);           // 内訳合計
// 2008-06-18 H.Itou MOD END
    Date   promisedDate      = (Date)params.get("ManufacturedDate");    // 生産日
    String lotNumber         = (String)params.get("LotNumber");         // ロット番号
    String factoryCode       = (String)params.get("FactoryCode");       // 工場コード
    String stockQty          = (String)params.get("StockQty");          // 在庫入数
    String productedUom      = (String)params.get("ProductedUom");      // 出来高数量単位コード
    Number organizationId    = (Number)params.get("OrganizationId");    // 在庫組織ID

    // OUTパラメータ用
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // 戻り値

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
// 2008-07-11 D.Nihei ADD START
    sb.append("DECLARE "                    );
    sb.append("  lt_quantity      po_lines_interface.quantity%TYPE; " ); // 数量
    sb.append("  lt_po_quantity   po_lines_interface.line_attribute11%TYPE; " ); // 発注数量
    sb.append("  ln_unit_price    NUMBER; " );
    sb.append("  ln_kobiki_price  NUMBER; " );
    sb.append("  ln_kobiki_amount NUMBER; " );
// 2008-07-11 D.Nihei ADD END
    sb.append("BEGIN "                                          );
// 2008-07-11 D.Nihei ADD START
    sb.append("  lt_po_quantity   := :1;                              "); // 発注数量
    sb.append("  lt_quantity      := TO_NUMBER(lt_po_quantity) * :2;  "); // 数量
    sb.append("  ln_unit_price    := :3;                              "); // 単価
    sb.append("  ln_kobiki_price  := ln_unit_price * (100 - 0) / 100; "); // 粉引後単価
    sb.append("  ln_kobiki_amount := ln_kobiki_price * lt_quantity;   "); // 粉引後金額
// 2008-07-11 D.Nihei ADD END
                 // 発注明細オープンIF登録
    sb.append("  INSERT INTO po_lines_interface pli  ("         ); // 発注明細オープンIF
    sb.append("     pli.interface_line_id "                     ); //    IF明細ID
    sb.append("    ,pli.interface_header_id "                   ); //    IFヘッダID
    sb.append("    ,pli.line_num "                              ); //    明細番号
    sb.append("    ,pli.shipment_num "                          ); //    納入番号
    sb.append("    ,pli.line_type_id "                          ); //    明細タイプID
    sb.append("    ,pli.item_id "                               ); //  1:品目ID
    sb.append("    ,pli.uom_code "                              ); //  2:単位
    sb.append("    ,pli.quantity "                              ); //    数量 3:出来高数量× 4:換算入数
    sb.append("    ,pli.unit_price "                            ); //  5:価格
    sb.append("    ,pli.promised_date "                         ); //  6:納入日
    sb.append("    ,pli.line_attribute1 "                       ); //  7:ロット番号
    sb.append("    ,pli.line_attribute2 "                       ); //  8:工場コード
    sb.append("    ,pli.line_attribute3 "                       ); //    付帯コード
    sb.append("    ,pli.line_attribute4 "                       ); //  9:在庫入数
    sb.append("    ,pli.line_attribute8 "                       ); //  5:仕入定価
    sb.append("    ,pli.line_attribute10 "                      ); // 10:発注単位
    sb.append("    ,pli.line_attribute11 "                      ); //  3:発注数量(出来高数量)
    sb.append("    ,pli.line_attribute13 "                      ); //    数量確定フラグ
    sb.append("    ,pli.line_attribute14 "                      ); //    金額確定フラグ
// 2008-07-11 D.Nihei ADD START
    sb.append("    ,pli.shipment_attribute2 "                   ); //    粉引後単価
// 2008-07-11 D.Nihei ADD END
    sb.append("    ,pli.shipment_attribute3 "                   ); //    口銭区分
    sb.append("    ,pli.shipment_attribute6 "                   ); //    賦課金区分
// 2008-07-11 D.Nihei ADD START
    sb.append("    ,pli.shipment_attribute9 "                   ); //    粉引後金額
// 2008-07-11 D.Nihei ADD END
    sb.append("    ,pli.ship_to_organization_id "               ); //  11:在庫組織ID(入庫)
    sb.append("    ,pli.created_by "                            ); //    作成日
    sb.append("    ,pli.creation_date "                         ); //    作成者
    sb.append("    ,pli.last_updated_by "                       ); //    最終更新日
    sb.append("    ,pli.last_update_date "                      ); //    最終更新者
    sb.append("    ,pli.last_update_login) "                    ); //    最終更新ログイン
    sb.append("  VALUES( "                                      );
    sb.append("     po_lines_interface_s.NEXTVAL  "             ); // IF明細ID
    sb.append("    ,po_headers_interface_s.CURRVAL "            ); // IFヘッダID
    sb.append("    ,1 "                                         ); // 明細番号
    sb.append("    ,1 "                                         ); // 納入番号
    sb.append("    ,FND_PROFILE.VALUE('XXPO_PO_LINE_TYPE_ID') " ); // 明細タイプID
// 2008-07-11 D.Nihei MOD START
//    sb.append("    ,:1 "                                        ); // 品目ID
//    sb.append("    ,:2 "                                        ); // 単位コード
//    sb.append("    ,TO_NUMBER(:3) * :4 "                        ); // 数量
//    sb.append("    ,:5  "                                       ); // 価格
//    sb.append("    ,:6  "                                       ); // 納入日
//    sb.append("    ,:7  "                                       ); // ロット番号
//    sb.append("    ,:8  "                                       ); // 工場コード
//    sb.append("    ,0   "                                       ); // 付帯コード
//    sb.append("    ,:9  "                                       ); // 在庫入数
//    sb.append("    ,:5  "                                       ); // 仕入定価
//    sb.append("    ,:10 "                                       ); // 発注単位
//    sb.append("    ,:3  "                                       ); // 発注数量
//    sb.append("    ,'N' "                                       ); // 数量確定フラグ
//    sb.append("    ,'N' "                                       ); // 金額確定フラグ
//    sb.append("    ,'3'  "                                      ); // 口銭区分
//    sb.append("    ,'3'  "                                      ); // 賦課金区分
//    sb.append("    ,:11  "                                      ); // 在庫組織ID(入庫)
    sb.append("    ,:4  "                                       ); // 品目ID
    sb.append("    ,:5  "                                       ); // 単位
    sb.append("    ,lt_quantity "                               ); // 数量
    sb.append("    ,ln_unit_price "                             ); // 価格
    sb.append("    ,:6  "                                       ); // 納入日
    sb.append("    ,:7  "                                       ); // ロット番号
    sb.append("    ,:8  "                                       ); // 工場コード
    sb.append("    ,'0' "                                       ); // 付帯コード
    sb.append("    ,:9  "                                       ); // 在庫入数
    sb.append("    ,ln_unit_price "                             ); // 仕入定価
    sb.append("    ,:10 "                                       ); // 発注単位
    sb.append("    ,lt_po_quantity "                            ); // 発注数量
    sb.append("    ,'N' "                                       ); // 数量確定フラグ
    sb.append("    ,'N' "                                       ); // 金額確定フラグ
    sb.append("    ,ln_kobiki_price "                           ); // 粉引後単価
    sb.append("    ,'3' "                                       ); // 口銭区分
    sb.append("    ,'3' "                                       ); // 賦課金区分
    sb.append("    ,ln_kobiki_amount "                          ); // 粉引後金額
    sb.append("    ,:11 "                                       ); // 在庫組織ID(入庫)
// 2008-07-11 D.Nihei MOD END
    sb.append("    ,FND_GLOBAL.USER_ID "                        ); // 作成者
    sb.append("    ,SYSDATE "                                   ); // 作成日
    sb.append("    ,FND_GLOBAL.USER_ID "                        ); // 最終更新者
    sb.append("    ,SYSDATE "                                   ); // 最終更新日
    sb.append("    ,FND_GLOBAL.LOGIN_ID); "                     ); // 最終更新ログイン
                 // OUTパラメータ
    sb.append("  :12 := '1'; "                                  ); // 1:正常終了
    sb.append("END; "                                           );

    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
// 2008-07-11 D.Nihei MOD START
//      cstmt.setInt(1, XxcmnUtility.intValue(itemId));             // 品目ID
//      cstmt.setString(2, uomCode);                                // 単位コード
//      cstmt.setString(3, productedQuantity);                      // 出来高数量
//      cstmt.setInt(4, XxcmnUtility.intValue(conversionFactor));   // 換算入数    
//      cstmt.setString(5, unitPrice);                              // 在庫単価    
//      cstmt.setDate(6, XxcmnUtility.dateValue(promisedDate));     // 生産日
//      cstmt.setString(7, lotNumber);                              // ロット番号
//      cstmt.setString(8, factoryCode);                            // 工場コード
//      cstmt.setString(9, stockQty);                               // 在庫入数
//      cstmt.setString(10, productedUom);                          // 出来高数量単位コード
//      cstmt.setInt(11, XxcmnUtility.intValue(organizationId));    // 在庫組織ID(入庫)
//      
//      // パラメータ設定(OUTパラメータ)
//      cstmt.registerOutParameter(12, Types.VARCHAR);   // リターンコード
      int i = 1;
      cstmt.setString(i++, productedQuantity);                      // 出来高数量
      cstmt.setInt(i++, XxcmnUtility.intValue(conversionFactor));   // 換算入数    
      cstmt.setString(i++, unitPrice);                              // 在庫単価    
      cstmt.setInt(i++, XxcmnUtility.intValue(itemId));             // 品目ID
      cstmt.setString(i++, uomCode);                                // 単位
      cstmt.setDate(i++, XxcmnUtility.dateValue(promisedDate));     // 生産日
      cstmt.setString(i++, lotNumber);                              // ロット番号
      cstmt.setString(i++, factoryCode);                            // 工場コード
      cstmt.setString(i++, stockQty);                               // 在庫入数
      cstmt.setString(i++, productedUom);                           // 出来高数量単位コード
      cstmt.setInt(i++, XxcmnUtility.intValue(organizationId));     // 在庫組織ID(入庫)
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(i++, Types.VARCHAR);   // リターンコード
// 2008-07-11 D.Nihei MOD END
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      retFlag = cstmt.getString(12); // リターンコード

      // 正常終了の場合
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // リターンコード正常をセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //トークン生成
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_PO_LINES_INTERFACE) };
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
   * 搬送明細オープンIFにデータを追加します。
   * @param trans - トランザクション
   * @param params - パラメータ
   * @return String - XxcmnConstants.RETURN_SUCCESS:1 正常
   *                   XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String insertPoDistributionsIf(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertPoDistributionsIf";

    // INパラメータ取得
    String productedQuantity = (String)params.get("ProductedQuantity"); // 出来高数量
    Number conversionFactor  = (Number)params.get("ConversionFactor");  // 換算入数    

    // OUTパラメータ用
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // 戻り値

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                          );
                 // 搬送明細オープンIF登録
    sb.append("  INSERT INTO po_distributions_interface pdi ( " ); // 搬送明細オープンIF
    sb.append("     pdi.interface_header_id "                   ); // IFヘッダID
    sb.append("    ,pdi.interface_line_id "                     ); // IF明細ID
    sb.append("    ,pdi.interface_distribution_id "             ); // IF搬送明細ID
    sb.append("    ,pdi.distribution_num "                      ); // 明細番号
    sb.append("    ,pdi.quantity_ordered "                      ); // 数量 1:出来高数量× 2:換算入数
    sb.append("    ,pdi.created_by "                            ); // 作成日
    sb.append("    ,pdi.creation_date "                         ); // 作成者
    sb.append("    ,pdi.last_updated_by "                       ); // 最終更新日
    sb.append("    ,pdi.last_update_date "                      ); // 最終更新者
    sb.append("    ,pdi.last_update_login "                     ); // 最終更新ログイン
    sb.append("    ,pdi.recovery_rate) "                        ); // 
    sb.append("  VALUES( "                                      );
    sb.append("     po_headers_interface_s.CURRVAL "            ); // IF発注ヘッダID
    sb.append("    ,po_lines_interface_s.CURRVAL  "             ); // IF発注明細ID
    sb.append("    ,po_distributions_interface_s.NEXTVAL  "     ); // IF搬送明細ID
    sb.append("    ,1 "                                         ); // 明細番号
    sb.append("    ,TO_NUMBER(:1) * :2 "                        ); // 数量
    sb.append("    ,FND_GLOBAL.USER_ID "                        ); // 作成者
    sb.append("    ,SYSDATE "                                   ); // 作成日
    sb.append("    ,FND_GLOBAL.USER_ID "                        ); // 最終更新者
    sb.append("    ,SYSDATE "                                   ); // 最終更新日
    sb.append("    ,FND_GLOBAL.LOGIN_ID "                       ); // 最終更新ログイン
    sb.append("    ,100); "                                     ); //
                 // OUTパラメータ
    sb.append("  :3 := '1'; "                                   ); // 1:正常終了
    sb.append("END; "                                           );

    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, productedQuantity);                      // 出来高数量
      cstmt.setInt(2, XxcmnUtility.intValue(conversionFactor));   // 換算入数    
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(3, Types.VARCHAR);   // リターンコード
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      retFlag = cstmt.getString(3); // リターンコード

      // 正常終了の場合
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // リターンコード正常をセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //トークン生成
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_PO_DISTRIBUTIONS_INTERFACE) };
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // insertPoDistributionsIf 

  /*****************************************************************************
   * 品質検査依頼情報作成処理を実行します。
   * @param trans - トランザクション
   * @param params - パラメータ
   * @return String - XxcmnConstants.RETURN_SUCCESS:1 正常
   *                   XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String doQtInspection(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName = "doQtInspection";
    // INパラメータ取得
    String division       = (String)params.get("Division");            // 区分
// 2009-02-27 H.Itou Add Start 本番障害#32
//    String disposalDiv    = (String)params.get("ProcessFlag");         // 処理区分
    String disposalDiv    = null;
// 2009-02-27 H.Itou Add End
    Number lotId          = (Number)params.get("LotId");               // ロットID
    Number itemId         = (Number)params.get("ItemId");              // 品目ID
    String qtObject       = (String)params.get("QtObject");            // 対象先
    Number batchId        = (Number)params.get("BatchId");             // 生産バッチID
    String qty            = (String)params.get("ProductedQuantity");   // 外注出来高数量
    Number conversionFactor  = (Number)params.get("ConversionFactor"); // 換算入数        
    Date   prodDelyDate   = (Date)params.get("ManufacturedDate");      // 生産日
    String vendorLine     = (String)params.get("VendorCode");          // 取引先コード
// 2009-02-18 H.Itou Mod Start 本番障害#1096
//    Number qtInspectReqNo = (Number)params.get("QtInspectReqNo");      // 検査依頼No
    String qtInspectReqNo = (String)params.get("QtInspectReqNo");      // 検査依頼No
// 2009-02-18 H.Itou Mod End
// 2009-02-27 H.Itou Add Start 本番障害#32
    BigDecimal beforeQty = new BigDecimal(0); // 前回登録数量
    BigDecimal inQty = new BigDecimal(0); // 品質検査APIに渡す数量
    // 更新の場合、前回数量を取得
  	if (!XxcmnUtility.isBlankOrNull(params.get("Quantity")))
  	{
      beforeQty = XxcmnUtility.bigDecimalValue(params.get("Quantity").toString());   // 前回登録数量
    }
    
    // 検査依頼Noに値がある場合･･･品質検査更新
    if (!XxcmnUtility.isBlankOrNull(qtInspectReqNo))
    {
      disposalDiv = "2";  // 処理区分:更新
      // 数量 ＝ 今回登録数量 － 前回登録数量
      inQty = XxcmnUtility.bigDecimalValue(qty).multiply(XxcmnUtility.bigDecimalValue(conversionFactor.toString())).subtract(beforeQty);


    // 検査依頼Noに値がない場合･･･品質検査追加
    } else
    {
      disposalDiv = "1";  // 処理区分:追加
      // 数量 ＝ 今回登録数量
      inQty = XxcmnUtility.bigDecimalValue(qty).multiply(XxcmnUtility.bigDecimalValue(conversionFactor.toString()));
    }
// 2009-02-27 H.Itou Add End
    
    // OUTパラメータ
    String exeType = XxcmnConstants.RETURN_NOT_EXE;
    
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(100);
// 2009-02-27 H.Itou Mod Start 本番障害#32
    int bindCount = 1;

    sb.append("DECLARE ");
    // INパラメータ設定
    sb.append("  it_division          VARCHAR2(1) := :" + bindCount++ + "; "             ); // IN  1.区分         必須（1:生産 2:発注 3:ロット情報 4:外注出来高 5:荒茶製造）
    sb.append("  iv_disposal_div      VARCHAR2(1) := :" + bindCount++ + "; "             ); // IN  2.処理区分     必須（1:追加 2:更新 3:削除）
    sb.append("  it_lot_id            NUMBER      := :" + bindCount++ + "; "             ); // IN  3.ロットID     必須
    sb.append("  it_item_id           NUMBER      := :" + bindCount++ + "; "             ); // IN  4.品目ID       必須
    sb.append("  iv_qt_object         VARCHAR2(1) := :" + bindCount++ + "; "             ); // IN  5.対象先       区分:5のみ必須（1:荒茶品目 2:副産物１ 3:副産物２ 4:副産物３）
    sb.append("  it_batch_id          NUMBER      := :" + bindCount++ + "; "             ); // IN  6.生産バッチID 処理区分3以外かつ区分:1のみ必須
    sb.append("  it_qty               NUMBER      := :" + bindCount++ + "; "             ); // IN  7.数量         処理区分3以外かつ区分:2のみ必須
    sb.append("  it_prod_dely_date    DATE        := :" + bindCount++ + "; "             ); // IN  8.納入日       処理区分3以外かつ区分:2のみ必須
    sb.append("  it_vendor_line       VARCHAR2(50):= :" + bindCount++ + "; "             ); // IN  9.仕入先コード 処理区分3以外かつ区分:2のみ必須    
    sb.append("  it_qt_inspect_req_no NUMBER      := TO_NUMBER(:" + bindCount++ + "); "  ); // IN 10.検査依頼No   処理区分:2、3のみ必須
    sb.append("  ot_qt_inspect_req_no NUMBER; "                                          ); // OUT11.検査依頼No
    sb.append("  ov_errbuf            VARCHAR2(5000); "                                  ); // OUT12.エラー・メッセージ           --# 固定 #
    sb.append("  ov_retcode           VARCHAR2(1); "                                     ); // OUT13.リターン・コード             --# 固定 #
    sb.append("  ov_errmsg            VARCHAR2(5000); "                                  ); // OUT14.ユーザー・エラー・メッセージ --# 固定 #
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
    // OUTパラメータ設定
    sb.append("  :" + bindCount++ + ":= ov_errbuf; "                                     );
    sb.append("  :" + bindCount++ + ":= ov_retcode; "                                    );
    sb.append("  :" + bindCount++ + ":= ov_errmsg; "                                     );
    sb.append("END; "                                                                    );
//    sb.append("BEGIN ");
//    sb.append("  xxwip_common_pkg.make_qt_inspection( "          );
//    sb.append("    it_division          => :1 "                  ); // IN  1.区分         必須（1:生産 2:発注 3:ロット情報 4:外注出来高 5:荒茶製造）
//    sb.append("   ,iv_disposal_div      => :2 "                  ); // IN  2.処理区分     必須（1:追加 2:更新 3:削除）
//    sb.append("   ,it_lot_id            => :3 "                  ); // IN  3.ロットID     必須
//    sb.append("   ,it_item_id           => :4 "                  ); // IN  4.品目ID       必須
//    sb.append("   ,iv_qt_object         => :5 "                  ); // IN  5.対象先       区分:5のみ必須（1:荒茶品目 2:副産物１ 3:副産物２ 4:副産物３）
//    sb.append("   ,it_batch_id          => :6 "                  ); // IN  6.生産バッチID 処理区分3以外かつ区分:1のみ必須
//    sb.append("   ,it_batch_po_id       => NULL "                ); // IN    明細番号 NULL
//    sb.append("   ,it_qty               => TO_NUMBER(:7) * :8 "  ); // IN    数量 7.外注出来高数量 × 8.換算入数        処理区分3以外かつ区分:2のみ必須
//    sb.append("   ,it_prod_dely_date    => :9 "                  ); // IN  9.納入日       処理区分3以外かつ区分:2のみ必須
//    sb.append("   ,it_vendor_line       => :10 "                 ); // IN 10.仕入先コード 処理区分3以外かつ区分:2のみ必須
//// 2009-02-18 H.Itou Mod Start 本番障害#1096
////    sb.append("   ,it_qt_inspect_req_no => :11 "                 ); // IN 11.検査依頼No   処理区分:2、3のみ必須            
//    sb.append("   ,it_qt_inspect_req_no => TO_NUMBER(:11) "      ); // IN 11.検査依頼No   処理区分:2、3のみ必須            
//// 2009-02-18 H.Itou Mod End
//    sb.append("   ,ot_qt_inspect_req_no => :12 "                 ); // OUT 12.検査依頼No
//    sb.append("   ,ov_errbuf            => :13 "                 ); // エラー・メッセージ           --# 固定 #
//    sb.append("   ,ov_retcode           => :14 "                 ); // リターン・コード             --# 固定 #
//    sb.append("   ,ov_errmsg            => :15); "               ); // ユーザー・エラー・メッセージ --# 固定 #
//    sb.append("END; "                                            );
// 2009-02-27 H.Itou Mod End

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
// 2009-02-27 H.Itou Mod Start 本番障害#32
      bindCount = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setString    (bindCount++, division);                      // 区分
      cstmt.setString    (bindCount++, disposalDiv);                   // 処理区分
      cstmt.setInt       (bindCount++, XxcmnUtility.intValue(lotId));  // ロットID
      cstmt.setInt       (bindCount++, XxcmnUtility.intValue(itemId)); // 品目ID
      cstmt.setNull      (bindCount++, Types.VARCHAR);                 // 対象先
      cstmt.setNull      (bindCount++, Types.INTEGER);                 // 生産バッチID
      cstmt.setBigDecimal(bindCount++, inQty);                         // 数量
      // 区分が2:発注の場合
      if (XxpoConstants.DIVISION_PO.equals(division))
      {
        cstmt.setDate  (bindCount++, XxcmnUtility.dateValue(prodDelyDate));   // 納入日
        cstmt.setString(bindCount++, vendorLine);      // 仕入先コード
        
      // 区分が4:外注出来高の場合
      } else if (XxpoConstants.DIVISION_SPL.equals(division))
      {
        cstmt.setNull(bindCount++, Types.DATE);    // 納入日
        cstmt.setNull(bindCount++, Types.INTEGER); // 仕入先コード
      }
      // 検査依頼Noに値がある場合･･･品質検査更新
      if (!XxcmnUtility.isBlankOrNull(qtInspectReqNo))
      {
        cstmt.setString(bindCount++, qtInspectReqNo); // 検査依頼No

      // 検査依頼Noに値がない場合･･･品質検査追加
      } else
      {
        cstmt.setNull(bindCount++, Types.VARCHAR); // NULL
      }
      
      // パラメータ設定(OUTパラメータ)
      int outBindStart = bindCount;
      cstmt.registerOutParameter(bindCount++, Types.INTEGER); // 検査依頼No
      cstmt.registerOutParameter(bindCount++, Types.VARCHAR); // エラー・メッセージ
      cstmt.registerOutParameter(bindCount++, Types.VARCHAR); // リターン・コード
      cstmt.registerOutParameter(bindCount++, Types.VARCHAR); // ユーザー・エラー・メッセージ

//      // パラメータ設定(INパラメータ)
//      cstmt.setString(1, division);                            // 区分
//// 2009-02-18 H.Itou Del Start 本番障害#1096
////      cstmt.setString(2, disposalDiv);                         // 処理区分
//// 2009-02-18 H.Itou Del End
//      cstmt.setInt(3, XxcmnUtility.intValue(lotId));           // ロットID
//      cstmt.setInt(4, XxcmnUtility.intValue(itemId));          // 品目ID
//      // 区分が2:発注の場合
//      if (XxpoConstants.DIVISION_PO.equals(division))
//      {
//        cstmt.setNull(5, Types.VARCHAR);                          // 対象先    
//        cstmt.setNull(6, Types.INTEGER);                          // 生産バッチID
//// 2009-02-18 H.Itou Add Start 本番障害#1096
//        // 検査依頼Noに値がある場合･･･品質検査更新 外注出来高即時仕入は数量を更新できないので、常に差分0を渡す。
//        if (!XxcmnUtility.isBlankOrNull(qtInspectReqNo))
//        {
//          cstmt.setString(7, "0");  // 外注出来高数量
//          cstmt.setInt(8, 0);       // 換算入数
//
//        // 検査依頼Noに値がない場合･･･品質検査追加
//        } else
//        { 
//// 2009-02-18 H.Itou Add End
//          cstmt.setString(7, qty);                                  // 外注出来高数量
//          cstmt.setInt(8, XxcmnUtility.intValue(conversionFactor)); // 換算入数
//// 2009-02-18 H.Itou Add Start 本番障害#1096
//        }
//// 2009-02-18 H.Itou Add End
//
//        cstmt.setDate(9, XxcmnUtility.dateValue(prodDelyDate));   // 納入日
//        cstmt.setString(10, vendorLine);      // 仕入先コード
//      // 区分が4:外注出来高の場合
//      } else if (XxpoConstants.DIVISION_SPL.equals(division))
//      {
//        cstmt.setNull(5, Types.VARCHAR);  // 対象先    
//        cstmt.setNull(6, Types.INTEGER);  // 生産バッチID
//        cstmt.setNull(7, Types.VARCHAR);  // 外注出来高数量
//        cstmt.setNull(8, Types.INTEGER);  // 換算入数
//        cstmt.setNull(9, Types.DATE);     // 納入日
//        cstmt.setNull(10, Types.INTEGER); // 仕入先コード
//      }
//// 2009-02-18 H.Itou Mod Start 本番障害#1096
////      // 追加以外の場合
////      if (XxpoConstants.PROCESS_FLAG_I.equals(disposalDiv) == false)
//      // 検査依頼Noに値がある場合･･･品質検査更新
//      if (!XxcmnUtility.isBlankOrNull(qtInspectReqNo))
//// 2009-02-18 H.Itou Mod End
//      {
//// 2009-02-18 H.Itou Add Start 本番障害#1096
//        cstmt.setString(2, "2");                         // 処理区分:更新
//// 2009-02-18 H.Itou Add End
//// 2009-02-18 H.Itou Mod Start 本番障害#1096
////        cstmt.setInt(11, XxcmnUtility.intValue(qtInspectReqNo)); // 検査依頼No
//        cstmt.setString(11, qtInspectReqNo); // 検査依頼No
//// 2009-02-18 H.Itou Mod End
//
//      // 検査依頼Noに値がない場合･･･品質検査追加
//      } else
//      {
//// 2009-02-18 H.Itou Add Start 本番障害#1096
//        cstmt.setString(2, "1");                         // 処理区分:追加
//// 2009-02-18 H.Itou Add End
//// 2009-02-18 H.Itou Mod Start 本番障害#1096
////        cstmt.setNull(11, Types.INTEGER); // NULL
//        cstmt.setNull(11, Types.VARCHAR); // NULL
//// 2009-02-18 H.Itou Mod End
//      }
//      
//      // パラメータ設定(OUTパラメータ)
//      cstmt.registerOutParameter(12, Types.INTEGER);           // 検査依頼No
//      cstmt.registerOutParameter(13, Types.VARCHAR, 5000);     // エラー・メッセージ
//      cstmt.registerOutParameter(14, Types.VARCHAR, 1);        // リターン・コード
//      cstmt.registerOutParameter(15, Types.VARCHAR, 5000);     // ユーザー・エラー・メッセージ
// 2009-02-27 H.Itou Mod End

      //PL/SQL実行
      cstmt.execute();

// 2009-02-27 H.Itou Mod Start 本番障害#32
      bindCount = outBindStart;
      int outQtInspectReqNo = cstmt.getInt(bindCount++); // 検査依頼No
      String errbuf  = cstmt.getString(bindCount++);     // エラー・メッセージ
      String retCode = cstmt.getString(bindCount++);     // リターン・コード
      String errmsg  = cstmt.getString(bindCount++);     // ユーザー・エラー・メッセージ

//      int outQtInspectReqNo = cstmt.getInt(12); // 検査依頼No
//      String errbuf = cstmt.getString(13);      // エラー・メッセージ
//      String retCode = cstmt.getString(14);     // リターン・コード
//      String errmsg = cstmt.getString(15);      // ユーザー・エラー・メッセージ
// 2009-02-27 H.Itou Mod End
      
      // 正常終了の場合
      if (XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {
        exeType = XxcmnConstants.RETURN_SUCCESS;
      
      // 警告終了の場合
      } else if (XxcmnConstants.API_RETURN_WARN.equals(retCode))
      {
        exeType = XxcmnConstants.RETURN_WARN;
      
      // 異常終了の場合
      } else if (XxcmnConstants.API_RETURN_ERROR.equals(retCode)) 
      {
        // ロールバック
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              errbuf,
                              6);
        // 追加の場合
        if (XxpoConstants.PROCESS_FLAG_I.equals(disposalDiv))
        {
          //トークン生成
          MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                     XxpoConstants.TAB_XXWIP_QT_INSPECTION) };

          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXPO, 
                                 XxpoConstants.XXPO10007, 
                                 tokens);

        // 更新の場合
        } else if (XxpoConstants.PROCESS_FLAG_U.equals(disposalDiv))
        {
          //トークン生成
          MessageToken[] tokens = new MessageToken[3];
          tokens[0] = new MessageToken(XxpoConstants.TOKEN_INFO_NAME, XxpoConstants.TAB_XXWIP_QT_INSPECTION);
          tokens[1] = new MessageToken(XxpoConstants.TOKEN_PARAMETER, XxpoConstants.COL_QT_INSPECT_REQ_NO);
// 2009-02-18 H.Itou Mod Start 本番障害#1096
//          tokens[2] = new MessageToken(XxpoConstants.TOKEN_VALUE,  XxcmnUtility.stringValue(qtInspectReqNo));
          tokens[2] = new MessageToken(XxpoConstants.TOKEN_VALUE,  qtInspectReqNo);
// 2009-02-18 H.Itou Mod End

          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXPO, 
                                 XxpoConstants.XXPO10006, 
                                 tokens);          
        }
      }
      
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return exeType;
  } // doQtInspection

  /*****************************************************************************
   * コンカレント：標準発注インポートを発行します。
   * @param trans - トランザクション
   * @param params - パラメータ
   * @return String - XxcmnConstants.RETURN_SUCCESS:1 正常
   *                   XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String doImportStandardPurchaseOrders(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "doImportStandardPurchaseOrders";

    // INパラメータ取得
    String poHeaderNumber    = (String)params.get("PoNumber");          // 発注番号

    // OUTパラメータ用
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // 戻り値

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "   );
    sb.append("  ln_request_id NUMBER; "                                             );
    sb.append("  lv_batch_id   VARCHAR2(5000); "                                     );
    sb.append("BEGIN "                                                               );
                 // バッチID取得
    sb.append("  SELECT TO_CHAR(po_headers_interface_s.CURRVAL) "                    );
    sb.append("  INTO   lv_batch_id "                                                );
    sb.append("  FROM   DUAL; "                                                      );
    sb.append("  lv_batch_id := lv_batch_id ||  :1; "                                );
                 // 標準発注インポート(コンカレント)呼び出し
    sb.append("  ln_request_id := fnd_request.submit_request( "                      );
    sb.append("     application  => 'PO' "                                           ); // アプリケーション名
    sb.append("    ,program      => 'POXPOPDOI' "                                    ); // プログラム短縮名
    sb.append("    ,argument1    => NULL "                                           ); // 購買担当ID
    sb.append("    ,argument2    => 'STANDARD' "                                     ); // 文書タイプ
    sb.append("    ,argument3    => NULL "                                           ); // 文書サブタイプ
    sb.append("    ,argument4    => 'N' "                                            ); // 品目の作成 N:行わない
    sb.append("    ,argument5    => NULL "                                           ); // ソース・ルールの作成
    sb.append("    ,argument6    => 'APPROVED' "                                     ); // 承認ステータス APPROVAL:承認
    sb.append("    ,argument7    => NULL "                                           ); // リリース生成方法
    sb.append("    ,argument8    => lv_batch_id "                                    ); // バッチID = IFヘッダID || 発注番号
    sb.append("    ,argument9    => NULL "                                           ); // 営業単位
    sb.append("    ,argument10   => NULL); "                                         ); // グローバル契約
                 // 要求IDがある場合、正常
    sb.append("  IF ln_request_id > 0 THEN "                                         );
    sb.append("    :2 := '1'; "                                                      ); // 1:正常終了
    sb.append("    :3 := ln_request_id; "                                            ); // 要求ID
    sb.append("    COMMIT; "                                                         );
                 // 要求IDがない場合、異常
    sb.append("  ELSE "                                                              );
    sb.append("    :2 := '0'; "                                                      ); // 0:異常終了
    sb.append("    :3 := ln_request_id; "                                            ); // 要求ID
    sb.append("    ROLLBACK; "                                                       );
    sb.append("  END IF; "                                                           );
    sb.append("END; "                                                                );

    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, poHeaderNumber);             // 発注番号
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(2, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(3, Types.INTEGER);   // 要求ID
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      retFlag = cstmt.getString(2); // リターンコード
      int requestId = cstmt.getInt(3); // 要求ID

      // 正常終了の場合
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // リターンコード正常をセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        
      // 正常終了でない場合、エラー  
      } else
      {
        //トークン生成
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PRG_NAME,
                                                   "標準発注インポート") };
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                               XxpoConstants.XXPO10025, 
                               tokens);
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
          rollBack(trans);
          XxcmnUtility.writeLog(trans,
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }

    return retFlag;
  } // doImportStandardPurchaseOrders 

  /*****************************************************************************
   * 外注出来高実績にデータを更新します。
   * @param trans - トランザクション
   * @param params - パラメータ
   * @return String - XxcmnConstants.RETURN_SUCCESS:1 正常
   *                  XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String updateXxpoVendorSupplyTxns(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "updateXxpoVendorSupplyTxns";

    // INパラメータ取得
    String txnsType          = (String)params.get("ProductResultType"); // 処理タイプ
    String productedQuantity = (String)params.get("ProductedQuantity"); // 出来高数量
    Number conversionFactor  = (Number)params.get("ConversionFactor");  // 換算入数
    String correctedQuantity = (String)params.get("CorrectedQuantity"); // 訂正数量
    String description       = (String)params.get("Description");       // 適要
    Number txnsId            = (Number)params.get("TxnsId");            // 実績ID
    String lastUpdateDate    = (String)params.get("LastUpdateDate");    // 最終更新日
    // 更新エラーメッセージ用キー
    Date   manufacturedDate  = (Date)params.get("ManufacturedDate");    // 生産日
    String vendorCode        = (String)params.get("VendorCode");        // 取引先
    String factoryCode       = (String)params.get("FactoryCode");       // 工場コード
    String itemCode          = (String)params.get("ItemCode");          // 品目コード
    String lotNumber         = (String)params.get("LotNumber");         // ロット番号
    // 更新エラーメッセージ用キー作成
    StringBuffer errKey = new StringBuffer(1000);
    errKey.append(XxpoConstants.COL_MANUFACTURED_DATE); // 生産日
    errKey.append(XxpoConstants.COLON);
    errKey.append(XxcmnUtility.stringValue(manufacturedDate));
    errKey.append(XxpoConstants.COMMA);
    errKey.append(XxpoConstants.SPACE);
    errKey.append(XxpoConstants.COL_VENDOR_CODE); // 取引先
    errKey.append(XxpoConstants.COLON);
    errKey.append(String.valueOf(vendorCode));
    errKey.append(XxpoConstants.COMMA);
    errKey.append(XxpoConstants.SPACE);
    errKey.append(XxpoConstants.COL_FACTORY_CODE); // 工場
    errKey.append(XxpoConstants.COLON);
    errKey.append(String.valueOf(factoryCode));
    errKey.append(XxpoConstants.COMMA);
    errKey.append(XxpoConstants.SPACE);
    errKey.append(XxpoConstants.COL_ITEM_CODE); // 品目
    errKey.append(XxpoConstants.COLON);
    errKey.append(String.valueOf(itemCode));
    errKey.append(XxpoConstants.COMMA);
    errKey.append(XxpoConstants.SPACE);
    errKey.append(XxpoConstants.COL_LOT_NUMBER); // ロット番号
    errKey.append(XxpoConstants.COLON);
    errKey.append(String.valueOf(lotNumber));

    // OUTパラメータ用
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // 戻り値

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                                                                    );
    sb.append("  lt_producted_quantity   xxpo_vendor_supply_txns.producted_quantity%TYPE := TO_NUMBER(:1); "); // 出来高数量
    sb.append("  lt_corrected_quantity   xxpo_vendor_supply_txns.corrected_quantity%TYPE := TO_NUMBER(:2); "); // 訂正数量
    sb.append("  lt_conversion_factor    xxpo_vendor_supply_txns.conversion_factor%TYPE  := :3; "           ); // 換算入数
    sb.append("  lt_description          xxpo_vendor_supply_txns.description%TYPE        := :4; "           ); // 適要
    sb.append("  lt_txns_id              xxpo_vendor_supply_txns.txns_id%TYPE            := :5; "           ); // 実績ID
    sb.append("  lv_last_update_date     VARCHAR2(100) := :6; "                                             ); // 最終更新日
    sb.append("  lv_temp_date            VARCHAR2(100) ; "                                                  ); // 最終更新日
                 // ユーザー定義エラー
    sb.append("  lock_expt             EXCEPTION; "                                                         ); // ロックエラー
    sb.append("  exclusive_expt        EXCEPTION; "                                                         ); // 排他エラー
    sb.append("  PRAGMA EXCEPTION_INIT(lock_expt, -54); "                                                   ); // 
    
    sb.append("BEGIN "                                                                                      );
                 // ロック取得
    sb.append("  SELECT TO_CHAR(xvst.last_update_date,'YYYY/MM/DD HH24:MI:SS')  last_update_date "          );
    sb.append("  INTO   lv_temp_date "                                                                      );
    sb.append("  FROM   xxpo_vendor_supply_txns xvst "                                                      );
    sb.append("  WHERE  xvst.txns_id = lt_txns_id "                                                         );
    sb.append("  FOR UPDATE NOWAIT; "                                                                       );
                 // 排他チェック・・・他のユーザーに更新されていないかチェック
    sb.append("  IF (lv_temp_date <> lv_last_update_date) THEN "                                            );
    sb.append("    RAISE exclusive_expt; "                                                                  );
    sb.append("  END IF; "                                                                                  );
                 // 外注出来高実績更新
    sb.append("  UPDATE xxpo_vendor_supply_txns xvst "                                                      );
    sb.append("  SET    xvst.description        = lt_description "                                          ); // 摘要
    // 処理タイプが1:相手先在庫管理の場合
    if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(txnsType)) 
    {
      sb.append("      ,xvst.quantity           = lt_producted_quantity * lt_conversion_factor "            ); // 数量 = 出来高数量 × 換算入数
      sb.append("      ,xvst.producted_quantity = lt_producted_quantity "                                   ); // 出来高数量 
      
    // 処理タイプが2:即時仕入の場合
    } else if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(txnsType))
    {
      sb.append("      ,xvst.corrected_quantity = lt_corrected_quantity "                                   ); // 訂正数量
    }
    sb.append("        ,xvst.last_updated_by    = FND_GLOBAL.USER_ID "                                      ); // 最終更新者
    sb.append("        ,xvst.last_update_date   = SYSDATE "                                                 ); // 最終更新日
    sb.append("        ,xvst.last_update_login  = FND_GLOBAL.LOGIN_ID "                                     ); // 最終更新ログイン
    sb.append("  WHERE  xvst.txns_id = lt_txns_id; "                                                        ); // 実績ID
                 // OUTパラメータ
    sb.append("  :7 := '1'; "                                                                               ); // 1:正常終了
    sb.append("EXCEPTION "                                                                                  );
    sb.append("  WHEN lock_expt THEN "                                                                      );
    sb.append("    :7 := '2'; "                                                                             ); // 2:ロックエラー
    sb.append("    :8 := SQLERRM; "                                                                         ); // SQLERRメッセージ    
    sb.append("  WHEN exclusive_expt THEN "                                                                 );
    sb.append("    :7 := '3'; "                                                                             ); // 3:排他チェックエラー
    sb.append("END; "                                                                                       );

    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, productedQuantity);                    // 出来高数量
      cstmt.setString(2, correctedQuantity);                    // 訂正数量
      cstmt.setInt(3, XxcmnUtility.intValue(conversionFactor)); // 換算入数
      cstmt.setString(4, description);                          // 摘要
      cstmt.setInt(5, XxcmnUtility.intValue(txnsId));           // 実績ID
      cstmt.setString(6, lastUpdateDate);                       // 最終更新日
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(7, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(8, Types.VARCHAR);   // エラーメッセージ
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      retFlag = cstmt.getString(7); // リターンコード
      String sqlErrMsg = cstmt.getString(8); // エラーメッセージ

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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              sqlErrMsg,
                              6);
        // ロックエラー
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                               XxpoConstants.XXPO10138);
       // 排他エラー終了の場合  
      } else if ("3".equals(retFlag))
      {
        rollBack(trans);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10147); 
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //トークン生成
      MessageToken[] tokens = new MessageToken[2];
      tokens[0] = new MessageToken(XxpoConstants.TOKEN_INFO_NAME, XxpoConstants.TAB_XXPO_VENDOR_SUPPLY_TXNS);
      tokens[1] = new MessageToken(XxpoConstants.TOKEN_ERRKEY,  errKey.toString());

      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10008, 
                             tokens);
                               
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // updateXxpoVendorSupplyTxns

    /*****************************************************************************
   * 固有記号を取得します。
   * @param trans - トランザクション
   * @param itemId - 品目ID
   * @param factoryId - 工場ID
   * @param manufacturedDate - 生産日
   * @return String 固有記号
   * @throws OAException - OA例外
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
    // 品目ID、工場ID、製造日いづれかががNullの場合はブランクを返す。
    if (XxcmnUtility.isBlankOrNull(itemId) 
      || XxcmnUtility.isBlankOrNull(factoryId)
      || XxcmnUtility.isBlankOrNull(manufacturedDate)) 
    {
      return "";
    }
    
    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                                   );
    sb.append("   SELECT xph.koyu_code       koyu_code " ); // 固有記号
    sb.append("   INTO   :1                            " );
    sb.append("   FROM   xxpo_price_headers  xph  "      ); // 仕入･標準単価ヘッダ
    sb.append("   WHERE  xph.item_id            = :2   " ); // 品目ID
    sb.append("   AND    xph.factory_id         = :3   " ); // 工場ID
    sb.append("   AND    xph.price_type         = '1'  " ); // マスタ区分 1(仕入)
// 2008-07-11 D.Nihei ADD START
    sb.append("   AND    xph.futai_code         = '0'  " ); // 付帯コード
// 2008-07-11 D.Nihei ADD END
// 20080702 yoshimoto add Start
    sb.append("   AND    xph.supply_to_code IS NULL    " ); // 支給先コード IS NULL
// 20080702 yoshimoto add End
    sb.append("   AND    xph.start_date_active <= :4   " ); // 適用開始日
    sb.append("   AND    xph.end_date_active   >= :4;  " ); // 適用終了日
               // 取得に失敗した場合
    sb.append("EXCEPTION                               " );
    sb.append("  WHEN OTHERS THEN                      " );
    sb.append("    :1 := '';                           " );
    sb.append("END; "                                    );

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      
      cstmt.setInt(2, XxcmnUtility.intValue(itemId));             // 品目ID
      cstmt.setInt(3, XxcmnUtility.intValue(factoryId));          // 工場ID
      cstmt.setDate(4, XxcmnUtility.dateValue(manufacturedDate)); // 生産日
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR);               // 固有記号

      // PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      koyuCode = cstmt.getString(1);

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return koyuCode;
  } // getKoyuCode

  /*****************************************************************************
   * 発注ヘッダーTblにデータを更新します。
   * @param trans トランザクション
   * @param params パラメータ用HashMap
   * @return String XxcmnConstants.RETURN_SUCCESS:1 正常
   *                  XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException OA例外
   ****************************************************************************/
  public static String updatePoHeadersAllTxns(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "updatePoHeadersAllTxns";

    // INパラメータ取得
    String headerId    = (String)params.get("HeaderId");    // ヘッダID
    String description = (String)params.get("Description"); // 摘要

    // OUTパラメータ用
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // 戻り値

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    
    sb.append("BEGIN ");
    sb.append("  UPDATE po_headers_all pha      ");   // 発注ヘッダ
    sb.append("  SET    pha.attribute15  = :1   ");   // 摘要(ヘッダ)
    sb.append("        ,pha.last_updated_by   = FND_GLOBAL.USER_ID "); // 最終更新者
    sb.append("        ,pha.last_update_date  = SYSDATE            "); // 最終更新日
    sb.append("        ,pha.last_update_login = FND_GLOBAL.LOGIN_ID"); // 最終更新ログイン
    sb.append("  WHERE  pha.po_header_id = :2;  ");   // ヘッダーID

//20080225 del Start
                 // OUTパラメータ
    //sb.append("  :3 := '1'; "                    ); // 1:正常終了
    //sb.append("EXCEPTION "                       );
    //sb.append("  WHEN OTHERS THEN "              ); 
    //sb.append("  :3 := '0'; "                    );  // 0:異常終了
//20080225 del End

    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
                                
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, description);                // 適用(ヘッダー)
      cstmt.setString(2, headerId);                   // ヘッダーID
      
//20080225 del Start
      // パラメータ設定(OUTパラメータ)
      //cstmt.registerOutParameter(3, Types.VARCHAR);   // リターンコード
//20080225 del End
    
      //PL/SQL実行
      cstmt.execute();

//20080225 del Start
      // 戻り値取得
      //cstmt.getString(3); // リターンコード
//20080225 del End

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }

    // 正常に処理された場合、"SUCCESS"(1)を返却
    return XxcmnConstants.RETURN_SUCCESS;

  } // updatePoHeadersAllTxns

  /*****************************************************************************
   * 発注明細Tblにデータを更新します。
   * @param trans トランザクション
   * @param params パラメータ用HashMap
   * @return String XxcmnConstants.RETURN_SUCCESS:1 正常
   *                  XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException OA例外
   ****************************************************************************/
  public static String updatePoLinesAllTxns(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "updatePoLinesAllTxns";

    // INパラメータ取得
    String headerId           = (String)params.get("HeaderId");          // ヘッダID
    String lineId             = (String)params.get("LineId");            // 明細ID
    String itemAmount         = (String)params.get("ItemAmount");        // 入数
    Date   deliveryDate       = (Date)params.get("DeliveryDate");        // 納入日
// 20080521 yoshimoto mod Start
    //String sDeliveryDate      = deliveryDate.toString();
    String sDeliveryDate      = XxcmnUtility.stringValue(deliveryDate);
// 20080521 yoshimoto mod End
    String leavingShedAmount  = (String)params.get("LeavingShedAmount"); // 出庫数
    Date   appointmentDate    = (Date)params.get("AppointmentDate");     // 日付指定

    String sAppointmentDate   = null;
    if (!XxcmnUtility.isBlankOrNull(appointmentDate)) 
    {
// 20080521 yoshimoto mod Start
      //sAppointmentDate   = appointmentDate.toString();                   // 日付指定
      sAppointmentDate      = XxcmnUtility.stringValue(appointmentDate); // 日付指定
// 20080521 yoshimoto mod End
    }

    String description        = (String)params.get("Description");       // 適用(明細)

    // OUTパラメータ用
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // 戻り値

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);

    sb.append("BEGIN ");
    sb.append("  UPDATE po_lines_all pla       ");                       // 発注明細
    sb.append("  SET    pla.attribute4  = :1   ");                       // 在庫入数
    sb.append("        ,pla.attribute5  = :2   ");                       // 仕入先出荷日
    sb.append("        ,pla.attribute6  = :3   ");                       // 仕入先出荷数量
    sb.append("        ,pla.attribute9  = :4   ");                       // 日付指定
    sb.append("        ,pla.attribute15 = :5   ");                       // 摘要   
    sb.append("        ,pla.last_updated_by   = FND_GLOBAL.USER_ID ");   // 最終更新者
    sb.append("        ,pla.last_update_date  = SYSDATE            ");   // 最終更新日
    sb.append("        ,pla.last_update_login = FND_GLOBAL.LOGIN_ID ");   // 最終更新ログイン
    sb.append("  WHERE  pla.po_header_id = :6   ");   // ヘッダーID
    sb.append("  AND    pla.po_line_id   = :7;  ");   // 明細ID
                 // OUTパラメータ
//20080225 del Start
    //sb.append("  :8 := '1'; "                    );   // 1:正常終了
    //sb.append("EXCEPTION "                       );
    //sb.append("  WHEN OTHERS THEN "              ); 
    //sb.append("  :8 := '0'; "                    );   // 0:異常終了
//20080225 del End

    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
                                
    try
    {
      // パラメータ設定(INパラメータ)
      if (XxcmnUtility.isBlankOrNull(itemAmount)) 
      {
        cstmt.setNull(1, Types.VARCHAR);        // 入数 
        
      } else
      {
        cstmt.setString(1, itemAmount);         // 入数
      }
      
      cstmt.setString(2, sDeliveryDate);       // 納入日
      cstmt.setString(3, leavingShedAmount);  // 出庫数

      if (XxcmnUtility.isBlankOrNull(sAppointmentDate)) 
      {
        cstmt.setNull(4, Types.VARCHAR);       // 日付指定 
        
      } else
      {
        cstmt.setString(4, sAppointmentDate);    // 日付指定
      }

      if (XxcmnUtility.isBlankOrNull(description)) 
      {
        cstmt.setNull(5, Types.VARCHAR);       // 摘要 
        
      } else
      {
        cstmt.setString(5, description);        // 摘要
      }
      
      cstmt.setString(6, headerId);           // ヘッダーID
      cstmt.setString(7, lineId);             // 明細行番号

      
//20080225 del Start      
      // パラメータ設定(OUTパラメータ)
      //cstmt.registerOutParameter(8, Types.VARCHAR);   // リターンコード
//20080225 del End
    
      //PL/SQL実行
      cstmt.execute();

//20080225 del Start
      // 戻り値取得
      //cstmt.getString(8); // リターンコード
//20080225 del End

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);

        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }

    // 正常に処理された場合、"SUCCESS"(1)を返却
    return XxcmnConstants.RETURN_SUCCESS;    
  }

  /*****************************************************************************
   * OPMロットマスタTblにデータを更新します。
   * @param trans トランザクション
   * @param params パラメータ用HashMap
   * @return String XxcmnConstants.RETURN_SUCCESS:1 正常
   *                  XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException OA例外
   ****************************************************************************/
  public static String updateIcLotsMstTxns(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
  
    String apiName      = "updateIcLotsMstTxns";

    // 入数
    String itemAmount        = (String)params.get("ItemAmount");
    // 製造日
    Date   productionDate    = (Date)params.get("ProductionDate");
// 20080521 yoshimoto mod Start  
    //String sProductionDate   = productionDate.toString();
    String sProductionDate      = XxcmnUtility.stringValue(productionDate);
// 20080521 yoshimoto mod End    
    // 賞味期限
    Date   useByDate          = (Date)params.get("UseByDate");
// 20080521 yoshimoto mod Start 
    //String sUseByDate         = useByDate.toString();
    String sUseByDate      = XxcmnUtility.stringValue(useByDate);
// 20080521 yoshimoto mod End

    // ランク1
    String rank              = (String)params.get("Rank");
// 2008-11-04 v1.16 D.Nihei Add Start 統合障害#51対応 
    // ランク2
    String rank2             = (String)params.get("Rank2");
// 2008-11-04 v1.16 D.Nihei Add End
    // 品目ID
    Number itemId            = (Number)params.get("ItemId");
    // ロットNo
    String lotNo             = (String)params.get("LotNo");
    // 最終更新日
    String lotLastUpdateDate = (String)params.get("LotLastUpdateDate");

    // OUTパラメータ用
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // 戻り値

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);

    sb.append("DECLARE "                                            );
    sb.append("  ln_api_version_number    CONSTANT NUMBER := 1.0; " );
    sb.append("  lv_ret_status            VARCHAR2(1); "            );
    sb.append("  ln_msg_cnt               NUMBER; "                 );
    sb.append("  lv_msg_data              VARCHAR2(5000); "         );
    sb.append("  lv_errbuf                VARCHAR2(5000); "         );
    sb.append("  lv_retcode               VARCHAR2(1); "            );
    sb.append("  lv_errmsg                VARCHAR2(5000); "         );
  
    // OPMロットマスタカーソル
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
    sb.append("          ,ilm.attribute1 "                          );  // 製造年月日
    sb.append("          ,ilm.attribute2 "                          );  // 固有記号
    sb.append("          ,ilm.attribute3 "                          );  // 賞味期限
    sb.append("          ,ilm.attribute4 "                          );  // 納入日（初回）
    sb.append("          ,ilm.attribute5 "                          );  // 納入日（最終）
    sb.append("          ,ilm.attribute6 "                          );  // 在庫入数
    sb.append("          ,ilm.attribute7 "                          );  // 在庫単価
    sb.append("          ,ilm.attribute8 "                          );  // 取引先
    sb.append("          ,ilm.attribute9 "                          );  // 仕入形態
    sb.append("          ,ilm.attribute10 "                         );  // 茶期区分
    sb.append("          ,ilm.attribute11 "                         );  // 年度
    sb.append("          ,ilm.attribute12 "                         );  // 産地
    sb.append("          ,ilm.attribute13 "                         );  // タイプ
    sb.append("          ,ilm.attribute14 "                         );  // ランク１
    sb.append("          ,ilm.attribute15 "                         );  // ランク２
    sb.append("          ,ilm.attribute16 "                         );  // 生産伝票区分
    sb.append("          ,ilm.attribute17 "                         );  // ライン№
    sb.append("          ,ilm.attribute18 "                         );  // 摘要
    sb.append("          ,ilm.attribute19 "                         );  // ランク３
    sb.append("          ,ilm.attribute20 "                         );  // 原料製造工場
    sb.append("          ,ilm.attribute22 "                         );  // 原料製造元ロット番号
    sb.append("          ,ilm.attribute21 "                         );  // 検査依頼No
    sb.append("          ,ilm.attribute23 "                         );  // ロットステータス
    sb.append("          ,ilm.attribute24 "                         );  // 作成区分
    sb.append("          ,ilm.attribute25 "                         );  // DFF項目25
    sb.append("          ,ilm.attribute26 "                         );  // DFF項目26
    sb.append("          ,ilm.attribute27 "                         );  // DFF項目27
    sb.append("          ,ilm.attribute28 "                         );  // DFF項目28
    sb.append("          ,ilm.attribute29 "                         );  // DFF項目29
    sb.append("          ,ilm.attribute30 "                         );  // DFF項目30
    sb.append("          ,ilm.attribute_category "                  );  // DFFカテゴリ
    sb.append("          ,ilm.odm_lot_number "                      );
    sb.append("    FROM   ic_lots_mst ilm "                           );
    sb.append("    WHERE  ilm.item_id = :1 "                         );  // 品目ID(35)
    sb.append("    AND    ilm.lot_no  = :2; "                        );  // ロットNo(238)
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
    sb.append("    WHERE  ilc.item_id = :1 "                         );  // 品目ID(35)
    sb.append("    AND    ilc.lot_id  = p_lot_id; "                  );  // ロットID(338)
    sb.append("  p_lot_cpg_rec ic_lots_cpg%ROWTYPE; "               );

    sb.append("BEGIN "                                              );

    // OPMロットMSTカーソル OPEN
    sb.append("  OPEN p_lot_cur; "                                  );
    sb.append("  FETCH p_lot_cur INTO p_lot_rec; "                  );

    sb.append("  OPEN p_lot_cpg_cur(p_lot_rec.lot_id); "           );
    sb.append("  FETCH p_lot_cpg_cur INTO p_lot_cpg_rec; "          );

    // 更新が発生する場合、更新データを格納
    sb.append("  p_lot_rec.attribute6       := :3; "                 );  // 在庫入数
    sb.append("  p_lot_rec.attribute1       := :4; "                 );  // 製造年月日
    sb.append("  p_lot_rec.attribute3       := :5; "                 );  // 賞味期限
    sb.append("  p_lot_rec.attribute14      := :6; "                 );  // ランク1
// 2008-11-04 v1.16 D.Nihei Add Start 統合障害#51対応 
    sb.append("  p_lot_rec.attribute15      := :7; "                 );  // ランク2
// 2008-11-04 v1.16 D.Nihei Add End
    sb.append("  p_lot_rec.last_updated_by  := FND_GLOBAL.USER_ID; " );  // 最終更新者
    sb.append("  p_lot_rec.last_update_date := SYSDATE; "            );  // 最終更新日

    // ロット更新API呼び出し
    sb.append("  GMI_LOTUPDATE_PUB.UPDATE_LOT( "                                       );
    sb.append("                     p_api_version      => ln_api_version_number "      );  // IN  APIのバージョン番号
    sb.append("                    ,p_init_msg_list    => FND_API.G_FALSE "            );  // IN  メッセージ初期化フラグ
    sb.append("                    ,p_commit           => FND_API.G_FALSE "            );  // IN  処理確定フラグ
    sb.append("                    ,p_validation_level => FND_API.G_VALID_LEVEL_FULL " );  // IN  検証レベル
    sb.append("                    ,x_return_status    => lv_ret_status "              );  // OUT 終了ステータス('S'-正常終了,'E'-例外発生,'U'-システム例外発生)
    sb.append("                    ,x_msg_count        => ln_msg_cnt "                 );  // OUT メッセージ・スタック数
    sb.append("                    ,x_msg_data         => lv_msg_data "                );  // OUT メッセージ
    sb.append("                    ,p_lot_rec          => p_lot_rec "                  );  // IN  更新するロット情報を指定
    sb.append("                    ,p_lot_cpg_rec      => p_lot_cpg_rec); "            );  // IN  更新するロット情報を指定

    sb.append("  CLOSE p_lot_cur; "                );
    sb.append("  CLOSE p_lot_cpg_cur; "            );

    // エラーメッセージをFND_LOG_MESSAGESに出力
    sb.append("  IF (ln_msg_cnt > 0) THEN "        );
    sb.append("    xxcmn_common_pkg.put_api_log( " );
    sb.append("       ov_errbuf  => lv_errbuf "    );
    sb.append("      ,ov_retcode => lv_retcode "   );
    sb.append("      ,ov_errmsg  => lv_errmsg ); " );
    sb.append("  END IF; "                         );

    // OUTパラメータ出力
    sb.append("  :8 := lv_ret_status; "            );
    sb.append("  :9 := ln_msg_cnt; "               );
    sb.append("  :10 := lv_msg_data; "              );

    sb.append("END; "                              );


    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
                                
    try
    {
      // パラメータ設定(INパラメータ)
      int i = 1;
      cstmt.setInt(i++, XxcmnUtility.intValue(itemId)); // 品目ID
      cstmt.setString(i++, lotNo);                      // ロットNo
      cstmt.setString(i++, itemAmount);                 // 在庫入数
      cstmt.setString(i++, sProductionDate);            // 製造年月日
      cstmt.setString(i++, sUseByDate);                 // 賞味期限
      cstmt.setString(i++, rank);                       // ランク1
// 2008-11-04 v1.16 D.Nihei Add Start 統合障害#51対応 
      cstmt.setString(i++, rank2);                       // ランク2
// 2008-11-04 v1.16 D.Nihei Add End

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(i++, Types.VARCHAR); // リターンコード
      cstmt.registerOutParameter(i++, Types.INTEGER); // メッセージ数
      cstmt.registerOutParameter(i++, Types.VARCHAR); // メッセージ
    
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      String retStatus = cstmt.getString(8);  // リターンコード
      int msgCnt       = cstmt.getInt(9);     // メッセージ数
      String msgData   = cstmt.getString(10); // メッセージ

//20080225 add Start
      // 正常終了の場合、フラグを1:正常に。
      if (XxcmnConstants.API_STATUS_SUCCESS.equals(retStatus)) 
      {
        // リターンコード正常をセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;

      // 正常終了でない場合、エラー  
      } else
      {
        // APIエラーを出力する。
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              msgData,
                              6);

        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);

      }
//20080225 add End      

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }

    // 正常に処理された場合、"SUCCESS"(1)を返却
    return XxcmnConstants.RETURN_SUCCESS;    
  } // updateIcLotsMstTxns

  /*****************************************************************************
   * コンカレント：直送仕入・出荷実績作成処理を発行します。
   * @param trans トランザクション
   * @param params パラメータ用HashMap
   * @return String XxcmnConstants.RETURN_SUCCESS:1 正常
   *                   XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException OA例外
   ****************************************************************************/
  public static String doDropShipResultsMake(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "doDropShipResultsMake";

    // INパラメータ取得
    String headerNumber    = (String)params.get("HeaderNumber");          // 発注番号

    // OUTパラメータ用
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // 戻り値

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "   );
    sb.append("  ln_request_id NUMBER; "                                       );
    sb.append("BEGIN "                                                         );
                 // 直送仕入・出荷実績作成処理(コンカレント)呼び出し
    sb.append("  ln_request_id := FND_REQUEST.SUBMIT_REQUEST( "                );
    sb.append("     application  => 'XXPO' "                                   ); // アプリケーション名
    sb.append("    ,program      => 'XXPO320001C' "                            ); // プログラム短縮名
    sb.append("    ,argument1    => :1 ); "                                    ); // 発注No.
                 // 要求IDがある場合、正常
    sb.append("  IF ln_request_id > 0 THEN "                                   );
    sb.append("    :2 := '1'; "                                                ); // 1:正常終了
    sb.append("    :3 := ln_request_id; "                                      ); // 要求ID
    //sb.append("    COMMIT; "                                                   );
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
      cstmt.setString(1, headerNumber);               // 発注番号
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(2, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(3, Types.INTEGER);   // 要求ID

      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      retFlag = cstmt.getString(2); // リターンコード
      int requestId = cstmt.getInt(3); // 要求ID

      // 正常終了の場合
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // リターンコード正常をセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        
      // 正常終了でない場合、エラー  
      } else
      {
        //トークン生成
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                   XxpoConstants.TOKEN_NAME_DS_RESULTS_MAKE) };
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                               XxcmnConstants.XXCMN05002, 
                               tokens);
      }
      
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }

    return retFlag;
  } // doDropShipResultsMake. 

// 20080226 add Start
  /*****************************************************************************
   * 賞味期限日の算出を行います。
   * @param trans トランザクション
   * @param itemId INV品目ID
   * @param productedDate 製造日
   * @param expirationDay 賞味期間
   * @return Date 賞味期限日
   * @throws OAException OA例外
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
    // 品目ID、製造日がNullの場合は処理を行わない。
    if (XxcmnUtility.isBlankOrNull(itemId) 
      || XxcmnUtility.isBlankOrNull(productedDate)
      || XxcmnUtility.isBlankOrNull(expirationDay)) 
    {
      return null;
    }
    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                                     );
    sb.append("   SELECT :1 + NVL(ximv.expiration_day, 0) "); // 賞味期限
    sb.append("   INTO   :2 "                              );
    sb.append("   FROM   xxcmn_item_mst_v ximv "           ); // OPM品目情報V
    sb.append("   WHERE  ximv.inventory_item_id = :3;    " ); // INV品目ID
    sb.append("END; "                                      );

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setDate(1, XxcmnUtility.dateValue(productedDate)); // 生産日
      cstmt.setInt(3, XxcmnUtility.intValue(itemId));          // 品目ID
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(2, Types.DATE);               // 賞味期限

      // PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      useByDate = new Date(cstmt.getDate(2));

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return useByDate;
  } // getUseByDateInvItem
// 20080226 add End

  /*****************************************************************************
   * 発注ヘッダアドオンロックを取得します。排他エラーチェックを行います。
   * @param trans トランザクション
   * @param xxpoHeaderId - 発注ヘッダアドオンID
   * @param lastUpdateDate - 最終更新日
   * @return String XxcmnConstants.RETURN_SUCCESS:1  正常
   *                 XxcmnConstants.RETURN_NOT_EXE:0  システムエラー
   *                 XxcmnConstants.RETURN_ERR1:   E1 ロックエラー
   *                 XxcmnConstants.RETURN_ERR2:   E2 排他エラー
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String getXxpoPoHeadersAllLock(
    OADBTransaction trans,
    Number xxpoHeaderId,
    String lastUpdateDate
  ) throws OAException
  {
    String apiName = "getXxpoPoHeadersAllLock";
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // 戻り値
    
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                                                          );
    sb.append("  lv_temp_date          VARCHAR2(100) ; "                                          ); // 最終更新日
                 // ユーザー定義エラー
    sb.append("  lock_expt             EXCEPTION; "                                               ); // ロックエラー
    sb.append("  exclusive_expt        EXCEPTION; "                                               ); // 排他エラー
    sb.append("  PRAGMA EXCEPTION_INIT(lock_expt, -54); "                                         );
    
    sb.append("BEGIN "                                                                            );
                 // ロック取得
    sb.append("  SELECT TO_CHAR(xpha.last_update_date,'YYYY/MM/DD HH24:MI:SS')  last_update_date ");
    sb.append("  INTO   lv_temp_date "                                                            );
    sb.append("  FROM   xxpo_headers_all xpha "                                                   );
    sb.append("  WHERE  xpha.xxpo_header_id = :1 "                                                );
    sb.append("  FOR UPDATE NOWAIT; "                                                             );
                 // 排他チェック・・・他のユーザーに更新されていないかチェック
    sb.append("  IF (lv_temp_date <> :2) THEN "                                                   );
    sb.append("    RAISE exclusive_expt; "                                                        );
    sb.append("  END IF; "                                                                        );
    sb.append("EXCEPTION "                                                                        );
    sb.append("  WHEN lock_expt THEN "                                                            );
    sb.append("    :3 := '1'; "                                                                   ); // 1:ロックエラー
    sb.append("    :4 := SQLERRM; "                                                               ); // SQLERRメッセージ
    sb.append("  WHEN exclusive_expt THEN "                                                       );
    sb.append("    :3 := '2'; "                                                                   ); // 2:排他チェックエラー
    sb.append("    :4 := SQLERRM; "                                                               ); // SQLERRメッセージ
    sb.append("END; "                                                                             );

    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1, XxcmnUtility.intValue(xxpoHeaderId));     // 発注ヘッダアドオンID
      cstmt.setString(2, lastUpdateDate);                         // 最終更新日
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(3, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(4, Types.VARCHAR);   // エラーメッセージ
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      String ret = cstmt.getString(3); // リターンコード

      // ロックエラー終了の場合  
      if ("1".equals(ret))
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(4),
                              6);
        // 戻り値 E1:ロックエラーをセット
        retFlag = XxcmnConstants.RETURN_ERR1;

       // 排他エラー終了の場合  
      } else if ("2".equals(ret))
      {
        // ロールバック
        rollBack(trans);
        // 戻り値 E2:排他エラーをセット
        retFlag = XxcmnConstants.RETURN_ERR2;

      // 正常終了の場合
      } else
      {
        // 戻り値 1:正常をセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
                              
      }
    }
    // 戻り値
    return retFlag;
  } // getXxpoPoHeadersAllLock
  
  /*****************************************************************************
   * 発注ヘッダアドオンの発注承諾フラグを更新します。
   * @param trans トランザクション
   * @param xxpoHeaderId - 発注ヘッダアドオンID
   * @return String XxcmnConstants.RETURN_SUCCESS:1 正常
   *                 XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String doOrderApproving(
    OADBTransaction trans,
    Number          xxpoHeaderId
  ) throws OAException
  {
    String apiName = "doOrderApproving";
  
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                    );
                 // 発注ヘッダ(アドオン)登録
    sb.append("  UPDATE xxpo_headers_all xha "                            );
    sb.append("  SET    xha.last_updated_by       = FND_GLOBAL.USER_ID "  ); // 最終更新者
    sb.append("        ,xha.last_update_date      = SYSDATE "             ); // 最終更新日
    sb.append("        ,xha.last_update_login     = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン
    sb.append("        ,xha.order_approved_flg    = 'Y'  "                ); // 発注承諾フラグ
    sb.append("        ,xha.order_approved_by     = FND_GLOBAL.USER_ID  " ); // 発注承諾者ユーザーID
    sb.append("        ,xha.order_approved_date   = SYSDATE  "            ); // 発注承諾日付
    sb.append("  WHERE  xha.xxpo_header_id        = :1;  "                ); // 発注ヘッダアドオンID
    sb.append("END; "                                                     );

    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1,  XxcmnUtility.intValue(xxpoHeaderId));    // 発注ヘッダアドオンID

      //PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return XxcmnConstants.RETURN_SUCCESS;
  } // doOrderApproving

  /*****************************************************************************
   * 発注ヘッダアドオンの仕入承諾フラグを更新します。
   * @param trans トランザクション
   * @return String XxcmnConstants.RETURN_SUCCESS:1 正常
   *                 XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String doPurchaseApproving(
    OADBTransaction trans,
    Number          xxpoHeaderId
  )throws OAException
  {
    String apiName = "doPurchaseApproving";
    
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                    );
                 // 発注ヘッダ(アドオン)登録
    sb.append("  UPDATE xxpo_headers_all xha "                            );
    sb.append("  SET    xha.last_updated_by       = FND_GLOBAL.USER_ID "  ); // 最終更新者
    sb.append("        ,xha.last_update_date      = SYSDATE "             ); // 最終更新日
    sb.append("        ,xha.last_update_login     = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン
    sb.append("        ,xha.purchase_approved_flg = 'Y'  "                ); // 仕入承諾フラグ
    sb.append("        ,xha.purchase_approved_by  = FND_GLOBAL.USER_ID  " ); // 仕入承諾者ユーザーID
    sb.append("        ,xha.purchase_approved_date= SYSDATE  "            ); // 仕入承諾日付
    sb.append("  WHERE  xha.xxpo_header_id        = :1;  "                ); // 発注ヘッダアドオンID
    sb.append("END; "                                                     );

    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1,  XxcmnUtility.intValue(xxpoHeaderId)); // 発注ヘッダアドオンID

      //PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        // PL/SQLクローズ
        cstmt.close();

      // クローズ中に例外が発生した場合
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return XxcmnConstants.RETURN_SUCCESS;
  } // doPurchaseApproving

  /*****************************************************************************
   * 受注ヘッダアドオンのステータスを更新します。
   * @param trans         - トランザクション
   * @param orderHeaderId - 受注ヘッダアドオンID
   * @param transStatus   - 更新対象ステータス
   * @throws OAException  - OA例外
   ****************************************************************************/
  public static void updateTransStatus(
    OADBTransaction trans,
    Number orderHeaderId,
    String transStatus
    ) throws OAException
  {
    String apiName = "updateTransStatus";
  
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                    );
    sb.append("  UPDATE xxwsh_order_headers_all xoha"); // 受注ヘッダアドオン
    sb.append("  SET    xoha.req_status        = :1 ");                  // ステータス
    sb.append("        ,xoha.last_updated_by   = FND_GLOBAL.USER_ID ");  // 最終更新者
    sb.append("        ,xoha.last_update_date  = SYSDATE ");             // 最終更新日
    sb.append("        ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID "); // 最終更新ログイン
    sb.append("  WHERE  xoha.order_header_id   = :2;  ");                // 発注ヘッダアドオンID
    // 更新ステータスが「取消」の場合
    if (XxpoConstants.PROV_STATUS_CAN.equals(transStatus)) 
    {
      // 明細行の削除フラグを更新します。
      sb.append("  UPDATE xxwsh_order_lines_all xola"); // 受注明細アドオン
      sb.append("  SET    xola.delete_flag       = 'Y' ");                 // 削除フラグ
      sb.append("        ,xola.last_updated_by   = FND_GLOBAL.USER_ID ");  // 最終更新者
      sb.append("        ,xola.last_update_date  = SYSDATE ");             // 最終更新日
      sb.append("        ,xola.last_update_login = FND_GLOBAL.LOGIN_ID "); // 最終更新ログイン
      sb.append("  WHERE  xola.order_header_id   = :3;  ");                // 発注ヘッダアドオンID
    }
    sb.append("END; ");
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, transStatus);                        // ステータス
      cstmt.setInt(2,  XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID
      if (XxpoConstants.PROV_STATUS_CAN.equals(transStatus)) 
      {
        cstmt.setInt(3,  XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID
      }
      //PL/SQL実行
      cstmt.execute();
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateTransStatus

  /*****************************************************************************
   * 受注ヘッダアドオンの通知ステータスを更新します。
   * @param trans           - トランザクション
   * @param orderHeaderId   - 受注ヘッダアドオンID
   * @param notifStatus     - 更新対象通知ステータス
   * @throws OAException    - OA例外
   ****************************************************************************/
  public static void updateNotifStatus(
    OADBTransaction trans,
    Number orderHeaderId,
    String notifStatus
    ) throws OAException
  {
    String apiName = "updateNotifStatus";
  
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                    );
    sb.append("  UPDATE xxwsh_order_headers_all xoha "); // 受注ヘッダアドオン
    sb.append("  SET    xoha.notif_status      = :1 ");                   // 通知ステータス
    sb.append("        ,xoha.prev_notif_status = xoha.notif_status   ");  // 前回通知ステータス
    sb.append("        ,xoha.notif_date        = SYSDATE             ");  // 確定通知実施日時
    sb.append("        ,xoha.last_updated_by   = FND_GLOBAL.USER_ID  ");  // 最終更新者
    sb.append("        ,xoha.last_update_date  = SYSDATE             ");  // 最終更新日
    sb.append("        ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID ");  // 最終更新ログイン
    sb.append("  WHERE  xoha.order_header_id   = :2;  ");                 // 発注ヘッダアドオンID
    sb.append("END; ");
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, notifStatus);                        // ステータス
      cstmt.setInt(2,  XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID
      //PL/SQL実行
      cstmt.execute();
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateNotifStatus

  /*****************************************************************************
   * 受注ヘッダアドオンの有償金額確定区分を更新します。
   * @param trans         - トランザクション
   * @param orderHeaderId - 受注ヘッダアドオンID
   * @param fixClass      - 有償金額確定区分
   * @throws OAException  - OA例外
   ****************************************************************************/
  public static void updateFixClass(
    OADBTransaction trans,
    Number orderHeaderId,
    String fixClass
    ) throws OAException
  {
    String apiName = "updateFixClass";
  
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
// 2009-05-13 v1.26 T.Yoshimoto Mod Start 本番#1282
/*
    sb.append("BEGIN "                                                    );
    sb.append("  UPDATE xxwsh_order_headers_all xoha "); // 受注ヘッダアドオン
    sb.append("  SET    xoha.amount_fix_class  = :1  "); // 有償金額確定区分
// 2009-01-20 v1.22 T.Yoshimoto Add Start 本番#739
    sb.append("        ,xoha.performance_management_dept = xxcmn_common_pkg.get_user_dept_code(FND_GLOBAL.USER_ID, NULL) " );
// 2009-01-20 v1.22 T.Yoshimoto Add Start 本番#739
    sb.append("        ,xoha.last_updated_by   = FND_GLOBAL.USER_ID  ");  // 最終更新者
    sb.append("        ,xoha.last_update_date  = SYSDATE             ");  // 最終更新日
    sb.append("        ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID ");  // 最終更新ログイン
    sb.append("  WHERE  xoha.order_header_id   = :2;  ");                 // 発注ヘッダアドオンID
    sb.append("END; ");
*/
    sb.append("DECLARE "                                                  );
    sb.append("  ln_count   NUMBER; "                                     ); 
    sb.append("BEGIN "                                                    );

    sb.append("  SELECT COUNT(header_id) "                                );
    sb.append("  INTO ln_count "                                          );
    sb.append("  FROM xxwsh_order_headers_all "                           );
    sb.append("  WHERE order_header_id = :1 "                             );  // 受注ヘッダアドオンID
    sb.append("  ; "                                                      );

    sb.append("  IF ( ln_count = 0) THEN "                                );
    sb.append("    UPDATE xxwsh_order_headers_all xoha "                  );  // 受注ヘッダアドオン
    sb.append("    SET    xoha.amount_fix_class  = :2  "                  );  // 有償金額確定区分
    sb.append("          ,xoha.performance_management_dept = xxcmn_common_pkg.get_user_dept_code(FND_GLOBAL.USER_ID, NULL) " );
    sb.append("          ,xoha.last_updated_by   = FND_GLOBAL.USER_ID  "  );  // 最終更新者
    sb.append("          ,xoha.last_update_date  = SYSDATE             "  );  // 最終更新日
    sb.append("          ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID "  );  // 最終更新ログイン
    sb.append("    WHERE  xoha.order_header_id   = :3;  "                 );  // 受注ヘッダアドオンID
    sb.append("  ELSE "                                                   );
    sb.append("    UPDATE xxwsh_order_headers_all xoha "                  );  // 受注ヘッダアドオン
    sb.append("    SET    xoha.amount_fix_class  = :4  "                  );  // 有償金額確定区分
    sb.append("          ,xoha.performance_management_dept = xxcmn_common_pkg.get_user_dept_code(FND_GLOBAL.USER_ID, NULL) " );
    sb.append("          ,xoha.last_updated_by   = FND_GLOBAL.USER_ID  "  );  // 最終更新者
    sb.append("          ,xoha.last_update_date  = SYSDATE             "  );  // 最終更新日
    sb.append("          ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID "  );  // 最終更新ログイン
    sb.append("    WHERE  xoha.order_header_id   = :5;  "                 );  // 受注ヘッダアドオンID

    sb.append("    UPDATE oe_order_headers_all o "                        );  // EBS標準.受注ヘッダ
    sb.append("    SET    o.attribute11  = xxcmn_common_pkg.get_user_dept_code(FND_GLOBAL.USER_ID, NULL) " );
    sb.append("    WHERE  o.header_id    = (SELECT header_id "             );
    sb.append("                             FROM xxwsh_order_headers_all " );
    sb.append("                             WHERE order_header_id = :6); " );  // 受注ヘッダアドオンID
    sb.append("  END IF; "                                                 );
    sb.append("END; "                                                      );
// 2009-05-13 v1.26 T.Yoshimoto Mod End 本番#1282

    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
// 2009-05-13 v1.26 T.Yoshimoto Mod Start 本番#1282
/*
      cstmt.setString(1, fixClass);                           // 有償金額確定区分
      cstmt.setInt(2,  XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID
*/
      cstmt.setInt(1,  XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID
      cstmt.setString(2, fixClass);                           // 有償金額確定区分
      cstmt.setInt(3,  XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID
      cstmt.setString(4, fixClass);                           // 有償金額確定区分
      cstmt.setInt(5,  XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID
      cstmt.setInt(6,  XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID
// 2009-05-13 v1.26 T.Yoshimoto Mod End 本番#1282
      //PL/SQL実行
      cstmt.execute();
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateFixClass

  /*****************************************************************************
   * 受注ヘッダ・明細アドオンロックを取得します。
   * @param trans トランザクション
   * @param orderHeaderId - 受注ヘッダアドオンID
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean getXxwshOrderLock(
    OADBTransaction trans,
    Number orderHeaderId
  ) throws OAException
  {
    String apiName = "getXxwshOrderLock";
    boolean retFlag = true; // 戻り値
    
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  CURSOR xo_cur ");
    sb.append("  IS ");
    sb.append("    SELECT xoha.order_header_id ");
    sb.append("    FROM   xxwsh_order_headers_all xoha   "); // 受注ヘッダアドオン
    sb.append("          ,xxwsh_order_lines_all   xola   "); // 受注明細アドオン
    sb.append("    WHERE  xoha.order_header_id = xola.order_header_id(+) ");
    sb.append("    AND    xoha.order_header_id = :1   ");
    sb.append("    FOR UPDATE OF xoha.order_header_id ");
    sb.append("                 ,xola.order_header_id NOWAIT; ");
    sb.append("BEGIN ");
    sb.append("  OPEN  xo_cur; ");
    sb.append("  CLOSE xo_cur; ");
    sb.append("END; ");
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1, XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID
      
      //PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
                              
      }
    }
    return retFlag;
  } // getXxwshOrderLock

  /***************************************************************************
   * 受注ヘッダ・明細アドオンの排他制御チェックを行うメソッドです。
   * @param trans トランザクション
   * @param orderHeaderId - 受注ヘッダアドオンID
   * @param xohaLastUpdateDate - 受注ヘッダ最終更新日
   * @param xolaLastUpdateDate - 受注明細の最大最終更新日
   * @throws OAException - OA例外
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
    boolean retFlag = true; // 戻り値

    try
    {
      // PL/SQLの作成を行います
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT TO_CHAR(xoha.last_update_date, 'YYYY/MM/DD HH24:MI:SS') ");
      sb.append("        ,TO_CHAR(xola.last_update_date, 'YYYY/MM/DD HH24:MI:SS') ");
      sb.append("  INTO   :1 ");
      sb.append("        ,:2 ");
      sb.append("  FROM   xxwsh_order_headers_all xoha "); // 受注ヘッダアドオン
      sb.append("        ,(SELECT xol.order_header_id       order_header_id  ");
      sb.append("                ,MAX(xol.last_update_date) last_update_date ");
      sb.append("          FROM   xxwsh_order_lines_all xol   ");
      sb.append("          GROUP BY xol.order_header_id) xola "); // 受注明細アドオン
      sb.append("  WHERE  xoha.order_header_id = xola.order_header_id ");
      sb.append("  AND    xoha.order_header_id = :3 ");
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
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));
      // SQL実行
      cstmt.execute();

      String dbXohaLastUpdateDate = cstmt.getString(1);
      String dbXolaLastUpdateDate = cstmt.getString(2);
      // 排他エラーの場合
      if (!XxcmnUtility.isEquals(xohaLastUpdateDate, dbXohaLastUpdateDate)
       || !XxcmnUtility.isEquals(xolaLastUpdateDate, dbXolaLastUpdateDate)) 
      {
        retFlag = false;
      }
    } catch (SQLException s) 
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
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
        // ロールバック
        rollBack(trans);
        // ログ出力
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
   * 受注明細の実績数量チェックを行います。
   * @param trans トランザクション
   * @param orderHeaderId - 受注ヘッダアドオンID
   * @param rec - レコードタイプ
   * @return boolean - 実績済フラグ true:実績未入力
   *                              false:実績有
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean chkOrderResult(
    OADBTransaction trans,
    Number orderHeaderId,
    String rec
  ) throws OAException
  {
    String apiName = "chkOrderResult";
    boolean retFlag = true; // 戻り値

    // 実績数量確認用のPL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  SELECT COUNT(1) ");
    sb.append("  INTO   :1 ");
    sb.append("  FROM   xxwsh_order_lines_all xola  "); // 受注明細アドオン
    sb.append("  WHERE  xola.order_header_id  = :2  ");
    // レコードタイプが'20'(出庫)
    if (XxpoConstants.REC_TYPE_20.equals(rec)) 
    {
      sb.append("  AND    xola.shipped_quantity IS NOT NULL ");

    // レコードタイプが'30'(入庫)
    } else if (XxpoConstants.REC_TYPE_30.equals(rec)) 
    {
      sb.append("  AND    xola.ship_to_quantity IS NOT NULL ");
    }
    sb.append("  AND    xola.delete_flag = 'N' ");
    sb.append("  AND    ROWNUM           = 1;  ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

     try
    {
      //バインド変数に値をセット
      cstmt.registerOutParameter(1, Types.INTEGER);
      cstmt.setInt(2, XxcmnUtility.intValue(orderHeaderId));

      // PL/SQL実行
      cstmt.execute();

      // パラメータの取得
      int cnt = cstmt.getInt(1);

      // 1件でも存在した場合
      if (cnt == 1)
      {
        // 実績入力有
        retFlag = false; 

      }
     
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // chkOrderResult

  /*****************************************************************************
   * 引当可能数量取得を行います。
   * @param trans トランザクション
   * @param itemId OPM品目ID
   * @param locationCode 納入先コード
   * @param lotId ロットID
   * @param orderDivision 発注区分
   * @return HashMap
   * @throws OAException OA例外
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

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" DECLARE                                                        ");
    // 変数宣言
    sb.append("   ln_can_enc_in_time_qty  NUMBER;                              ");   // 有効日ベース引当可能数
    sb.append("   ln_can_enc_total_qty    NUMBER;                              ");   // 総引当可能数
    sb.append("   ln_can_encl_qty         NUMBER;                              ");   // 引当可能数
    sb.append("   ln_location_id          NUMBER;                              ");   // OPM保管倉庫ID
    sb.append(" BEGIN ");
    
// 20080630 yoshimoto add Start
// 2008-10-22 H.Itou Del Start 統合テスト指摘49,変更要求#238
//    if (XxpoConstants.PO_TYPE_3.equals(orderDivision)) 
//    {
// 2008-10-22 H.Itou Del End
    sb.append("   SELECT xcilv.inventory_location_id                           ");
    sb.append("   INTO  ln_location_id                                         ");
    sb.append("   FROM xxcmn_item_locations_v xcilv                            ");
    sb.append("   WHERE xcilv.segment1 = :1;                                   ");     // INパラメータ1(相手先在庫入庫先コード)
// 2008-10-22 H.Itou Del Start 統合テスト指摘49,変更要求#238
//    } else 
//    {
//// 20080630 yoshimoto add Start
//      // OPM保管倉庫IDを取得
//      sb.append("   SELECT xcilv.location_id                                     ");
//      sb.append("   INTO  ln_location_id                                         ");
//      sb.append("   FROM xxcmn_item_locations_v xcilv                            ");
//      sb.append("   WHERE xcilv.segment1 = :1;                                   ");     // INパラメータ1(納入先コード)
//    }
// 2008-10-22 H.Itou Del End

    // 有効日ベース引当可能数を取得
    sb.append("   :2 := xxcmn_common_pkg.get_can_enc_in_time_qty(              ");     // OUTパラメータ4(有効日ベース引当可能数)
    sb.append("                               in_whse_id     => ln_location_id ");     // OPM保管倉庫ID
    sb.append("                              ,in_item_id     => :3             ");     // INパラメータ2(OPM品目ID)
    sb.append("                              ,in_lot_id      => :4             ");     // INパラメータ3(ロットID)
    sb.append("                              ,in_active_date => SYSDATE);      ");     // 有効日

    // 総引当可能数を取得
    sb.append("   :5 := xxcmn_common_pkg.get_can_enc_total_qty(                ");     // OUTパラメータ5(総引当可能数)
    sb.append("                               in_whse_id     => ln_location_id ");     // OPM保管倉庫ID
    sb.append("                              ,in_item_id     => :6             ");     // INパラメータ2(OPM品目ID)
    sb.append("                              ,in_lot_id      => :7);           ");     // INパラメータ3(ロットID)
    sb.append(" END;                                                           ");

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // ************************************** //
      // * 有効日ベース引当可能数へのバインド * //
      // ************************************** //
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, locationCode);               // 納入先コード
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(2, Types.INTEGER);   // 有効日ベース引当可能数

      cstmt.setInt(3, XxcmnUtility.intValue(itemId)); // OPM品目ID

      if (XxcmnUtility.isBlankOrNull(lotId))
      {
        cstmt.setNull(4, Types.INTEGER);
      } else
      {
        cstmt.setInt(4, XxcmnUtility.intValue(lotId));  // ロットID
      }
      
      // ************************************** //
      // * 総引当可能数へのバインド           * //
      // ************************************** //      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(5, Types.INTEGER);   // 総引当可能数

      cstmt.setInt(6, XxcmnUtility.intValue(itemId)); // OPM品目ID

      if (XxcmnUtility.isBlankOrNull(lotId))
      {
        cstmt.setNull(7, Types.INTEGER);
      } else
      {
        cstmt.setInt(7, XxcmnUtility.intValue(lotId));  // ロットID
      }
      
      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      paramsRet.put("InTimeQty", cstmt.getObject(2));   // 有効日ベース引当可能数
      paramsRet.put("TotalQty",  cstmt.getObject(5));   // 総引当可能数

      return paramsRet;

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getReservedQuantity

  /*****************************************************************************
   * 受入返品実績(アドオン)にデータを追加します。
   * @param trans トランザクション
   * @param setParams パラメータ
   * @return HashMap    
   * @throws OAException OA例外
   ****************************************************************************/
  public static HashMap insertRcvAndRtnTxns(
    OADBTransaction trans,
    HashMap setParams
  ) throws OAException
  {
    String apiName      = "insertRcvAndRtnTxns";

    // INパラメータ取得
    // 実績区分
    String txnsType              = (String)setParams.get("TxnsType");
    // 受入返品番号
    String rcvRtnNumber          = (String)setParams.get("RcvRtnNumber");
    // 元文書番号
    String sourceDocumentNumber  = (String)setParams.get("SourceDocumentNumber");
    // 取引先ID
    Number vendorId              = (Number)setParams.get("VendorId");
    // 取引先コード
    String vendorCode            = (String)setParams.get("VendorCode");
    // 入出庫先コード
    String locationCode          = (String)setParams.get("LocationCode");
    // 元文書明細番号
    Number sourceDocumentLineNum = (Number)setParams.get("SourceDocumentLineNum");
    // 受入返品明細番号
    Number rcvRtnLineNumber      = (Number)setParams.get("RcvRtnLineNumber");
    // 品目ID
    Number itemId                = (Number)setParams.get("ItemId");
    // 品目コード
    String itemCode              = (String)setParams.get("ItemCode");
    // ロットID
    Number lotId                 = (Number)setParams.get("LotId");
    // ロットNo
    String lotNumber             = (String)setParams.get("LotNumber");
    // 取引日
    Date txnsDate                = (Date)setParams.get("TxnsDate");
    // 受入返品数量
    String rcvRtnQuantity        = (String)setParams.get("RcvRtnQuantity");
    // 受入返品単位
    String rcvRtnUom             = (String)setParams.get("RcvRtnUom");
    // 単位コード
    String uom                   = (String)setParams.get("Uom");
    // 明細摘要
    String lineDescription       = (String)setParams.get("LineDescription");
    // 数量
    String quantity              = (String)setParams.get("Quantity");
    // 換算入数
    String conversionFactor      = (String)setParams.get("ConversionFactor");
    // 直送区分
    String dropshipCode          = (String)setParams.get("DropshipCode");
    // 単価
    Number unitPrice             = (Number)setParams.get("UnitPrice");
// 20080520 add yoshimoto Start
    // 発注部署コード
    String departmentCode        = (String)setParams.get("DepartmentCode");
// 20080520 add yoshimoto End

    // OUTパラメータ用
    HashMap retHashMap = new HashMap();
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" DECLARE "                                                       );
    sb.append("   lt_txns_id xxpo_rcv_and_rtn_txns.txns_id%TYPE; "              );
    sb.append(" BEGIN "                                                         );
    sb.append("   SELECT xxpo_rcv_and_rtn_txns_s1.NEXTVAL "                     );
    sb.append("   INTO   lt_txns_id "                                           );
    sb.append("   FROM   DUAL; "                                                );

    sb.append("   INSERT INTO xxpo_rcv_and_rtn_txns rart( "                     );
    sb.append("     rart.txns_id "                                              );  // 取引ID
    sb.append("     ,rart.txns_type "                                           );  // 実績区分        
    sb.append("     ,rart.rcv_rtn_number "                                      );  // 受入返品番号    
    sb.append("     ,rart.source_document_number "                              );  // 元文書番号      
    sb.append("     ,rart.vendor_id "                                           );  // 取引先ID        
    sb.append("     ,rart.vendor_code "                                         );  // 取引先コード    
    sb.append("     ,rart.location_code "                                       );  // 入出庫先コード  
    sb.append("     ,rart.source_document_line_num "                            );  // 元文書明細番号  
    sb.append("     ,rart.rcv_rtn_line_number "                                 );  // 受入返品明細番号
    sb.append("     ,rart.item_id "                                             );  // 品目ID          
    sb.append("     ,rart.item_code "                                           );  // 品目コード      
    sb.append("     ,rart.lot_id "                                              );  // ロットID        
    sb.append("     ,rart.lot_number "                                          );  // ロットNo        
    sb.append("     ,rart.txns_date "                                           );  // 取引日          
    sb.append("     ,rart.rcv_rtn_quantity "                                    );  // 受入返品数量    
    sb.append("     ,rart.rcv_rtn_uom "                                         );  // 受入返品単位    
    sb.append("     ,rart.quantity "                                            );  // 数量            
    sb.append("     ,rart.uom "                                                 );  // 単位コード      
    sb.append("     ,rart.conversion_factor "                                   );  // 換算入数        
    sb.append("     ,rart.line_description "                                    );  // 明細摘要        
    sb.append("     ,rart.drop_ship_type "                                      );  // 直送区分
    sb.append("     ,rart.unit_price "                                          );  // 単価
    sb.append("     ,rart.department_code "                                     );  // 発注部署コード  //20080520 add yoshimoto
    sb.append("     ,rart.created_by "                                          );  // 作成者          
    sb.append("     ,rart.creation_date "                                       );  // 作成日          
    sb.append("     ,rart.last_updated_by "                                     );  // 最終更新者      
    sb.append("     ,rart.last_update_date "                                    );  // 最終更新日      
    sb.append("     ,rart.last_update_login) "                                  );  // 最終更新ログイン

    sb.append("   VALUES( "                                                     );
    sb.append("     lt_txns_id "                                                );  // 取引ID
    sb.append("     ,:1 "                                                       );  // 実績区分        
    sb.append("     ,:2 "                                                       );  // 受入返品番号    
    sb.append("     ,:3 "                                                       );  // 元文書番号      
    sb.append("     ,:4 "                                                       );  // 取引先ID        
    sb.append("     ,:5 "                                                       );  // 取引先コード    
    sb.append("     ,:6 "                                                       );  // 入出庫先コード  
    sb.append("     ,:7 "                                                       );  // 元文書明細番号  
    sb.append("     ,:8 "                                                       );  // 受入返品明細番号
    sb.append("     ,:9 "                                                       );  // 品目ID          
    sb.append("     ,:10 "                                                       );  // 品目コード      
    sb.append("     ,:11 "                                                      );  // ロットID        
    sb.append("     ,:12 "                                                      );  // ロットNo        
    sb.append("     ,:13 "                                                      );  // 取引日          
    sb.append("     ,:14 "                                                      );  // 受入返品数量    
    sb.append("     ,:15 "                                                      );  // 受入返品単位    
    sb.append("     ,:16 "                                                      );  // 数量            
    sb.append("     ,:17 "                                                      );  // 単位コード      
    sb.append("     ,:18 "                                                      );  // 換算入数        
    sb.append("     ,:19 "                                                      );  // 明細摘要        
    sb.append("     ,:20 "                                                      );  // 直送区分        
    sb.append("     ,:21 "                                                      );  // 単価
    sb.append("     ,:22 "                                                      );  // 発注部署コード  //20080520 add yoshimoto
    sb.append("     ,FND_GLOBAL.USER_ID "                                       );  // 作成者          
    sb.append("     ,SYSDATE "                                                  );  // 作成日          
    sb.append("     ,FND_GLOBAL.USER_ID "                                       );  // 最終更新者      
    sb.append("     ,SYSDATE "                                                  );  // 最終更新日      
    sb.append("     ,FND_GLOBAL.LOGIN_ID "                                      );  // 最終更新ログイン
    sb.append("   ); "                                                          );

// 20080520 mod yoshimoto Start
//    sb.append("   :22 := '1'; "                                                 );
//    sb.append("   :23 := lt_txns_id; "                                          );
    sb.append("   :23 := '1'; "                                                 );
    sb.append("   :24 := lt_txns_id; "                                          );
// 20080520 mod yoshimoto End
    sb.append(" END; "                                                          );
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      
      cstmt.setString(1, txnsType);                                     // 実績区分
      cstmt.setString(2, rcvRtnNumber);                                 // 受入返品番号
      cstmt.setString(3, sourceDocumentNumber);                         // 元文書番号
      cstmt.setInt(4, XxcmnUtility.intValue(vendorId));                 // 取引先ID
      cstmt.setString(5, vendorCode);                                   // 取引先コード
      cstmt.setString(6, locationCode);                                 // 入出庫先コード
      cstmt.setInt(7, XxcmnUtility.intValue(sourceDocumentLineNum));    // 元文書明細番号
      cstmt.setInt(8, XxcmnUtility.intValue(rcvRtnLineNumber));         // 受入返品明細番号
      cstmt.setInt(9, XxcmnUtility.intValue(itemId));                   // 品目ID
      cstmt.setString(10, itemCode);                                     // 品目コード 

      if (XxcmnUtility.isBlankOrNull(lotId))
      {
        cstmt.setNull(11, Types.INTEGER);                                // ロットID(NULL)
      } else
      {
        cstmt.setInt(11, XxcmnUtility.intValue(lotId));                   // ロットID
      }

      cstmt.setString(12, lotNumber);                                   // ロットNo
      cstmt.setDate(13, XxcmnUtility.dateValue(txnsDate));              // 取引日
      cstmt.setDouble(14, Double.parseDouble(rcvRtnQuantity));          // 受入返品数量
      cstmt.setString(15, rcvRtnUom);                                   // 受入返品単位
      cstmt.setDouble(16, Double.parseDouble(quantity));                // 数量
      cstmt.setString(17, uom);                                         // 単位コード
      cstmt.setDouble(18, Double.parseDouble(conversionFactor));        // 換算入数
      cstmt.setString(19, lineDescription);                             // 明細摘要
      cstmt.setString(20, dropshipCode);                                // 直送区分
      cstmt.setInt(21, XxcmnUtility.intValue(unitPrice));               // 単価
      cstmt.setString(22, departmentCode);                              // 発注部署コード  // 20080520 add yoshimoto

      
      // パラメータ設定(OUTパラメータ)
// 20080520 mod yoshimoto Start
//      cstmt.registerOutParameter(22, Types.VARCHAR);   // リターンコード
//      cstmt.registerOutParameter(23, Types.INTEGER);   // 取引ID
      cstmt.registerOutParameter(23, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(24, Types.INTEGER);   // 取引ID
// 20080520 mod yoshimoto End
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
// 20080520 mod yoshimoto Start
//      String retFlag = cstmt.getString(22);
      String retFlag = cstmt.getString(23);
// 20080520 mod yoshimoto End

      // 正常終了の場合
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // リターンコード：正常をセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);
// 20080520 mod yoshimoto Start
//        retHashMap.put("TxnsId", new Number(cstmt.getObject(23)));
        retHashMap.put("TxnsId", new Number(cstmt.getObject(24)));
// 20080520 mod yoshimoto End
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {

      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //トークン生成
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_XXPO_RCV_AND_RTN_TXNS) };
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // insertXxpoVendorSupplyTxns

  /*****************************************************************************
   * 受入ヘッダオープンIFにデータを追加します。
   * @param trans トランザクション
   * @param params パラメータ
   * @return HashMap 
   * @throws OAException OA例外
   ****************************************************************************/
  public static HashMap insertRcvHeadersIf(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertRcvHeadersIf";

    // INパラメータ取得
    String headerNumber = (String)params.get("HeaderNumber"); // 発注番号
    Date deliveryDate   = (Date)params.get("DeliveryDate");   // 発注ヘッダ.納入日
    Number vendorId     = (Number)params.get("VendorId");     // 発注ヘッダ.仕入先ID
    Number groupId      = (Number)params.get("GroupId");      // グループID

    // OUTパラメータ用
    HashMap retHashMap = new HashMap();
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);    


    //PL/SQLの作成を行います
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

      // 発行されたGROUP_IDと発注番号を結合
      sb.append("   lt_group_id := lt_group_id_s; "                                  );   // RCV_INTERFACE_GROUPS_S
    }else
    {

      // 発行されたGROUP_ID
      sb.append("   lt_group_id := :" + (count++) + "; "                             );   // 採番済みRCV_INTERFACE_GROUPS_S

    }

    // 受入ヘッダオープンIF登録
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
    sb.append("     ,:" + (count++) + " "                                           );  // 発注ヘッダ.仕入先ID
    sb.append("     ,:" + (count++) + " "                                           );  // 発注ヘッダ.納入日
    sb.append("     ,'Y' "                                                          );
    sb.append("   ); "                                                              );
                 // OUTパラメータ
    sb.append("   :" + (count++) + " := '1'; "                                      );
    sb.append("   :" + (count++) + " := lt_header_if_id; "                          );
    sb.append("   :" + (count++) + " := lt_group_id; "                              );
    sb.append(" END; "                                                              );


    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      count = 1;

      // パラメータ設定(INパラメータ)

      if (!XxcmnUtility.isBlankOrNull(groupId)) 
      {
        cstmt.setLong(count++, XxcmnUtility.longValue(groupId));      // グループID
      }

      cstmt.setInt(count++, XxcmnUtility.intValue(vendorId));         // 発注ヘッダ.仕入先ID
      cstmt.setDate(count++, XxcmnUtility.dateValue(deliveryDate));   // 発注ヘッダ.納入日
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(count++, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(count++, Types.INTEGER);   // header_interface_id
      cstmt.registerOutParameter(count, Types.BIGINT);   // group_id

        
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      String retFlag = cstmt.getString(count-2); // リターンコード

      // 正常終了の場合
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // リターンコード：正常をセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        retHashMap.put("RetFlag",           XxcmnConstants.RETURN_SUCCESS);
        retHashMap.put("HeaderInterfaceId", new Number(cstmt.getObject(count-1)));
        retHashMap.put("GroupId",           new Number(cstmt.getObject(count)));       
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //トークン生成
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_RCV_HEADERS_INTERFACE) };
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    
    return retHashMap;
  } // insertRcvHeadersIf

  /*****************************************************************************
   * 受入トランザクションオープンIFにデータを追加します。
   * @param trans トランザクション
   * @param params パラメータ
   * @return HashMap
   * @throws OAException - OA例外
   ****************************************************************************/
  public static HashMap insertRcvTransactionsIf(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertRcvTransactionsIf";

    // INパラメータ取得
    String locationCode       = (String)params.get("LocationCode");         // 発注明細.納入先コード
    Number lineId             = (Number)params.get("LineId");               // 発注明細ID
    Number groupId            = (Number)params.get("GroupId");             // 受入ヘッダOIFのGROUP_IDと同値を指定
    Date txnsDate             = (Date)params.get("TxnsDate");               // 受入実績RN.納入日
    String rcvRtnQuantity     = (String)params.get("RcvRtnQuantity");       // 受入数量(換算注意)
    String unitMeasLookupCode = (String)params.get("UnitMeasLookupCode");   // 発注明細.品目基準単位
    Number plaItemId          = (Number)params.get("PlaItemId");            // 発注明細.品目ID(ITEM_ID)
    Number headerId           = (Number)params.get("HeaderId");             // 発注ヘッダ.発注ヘッダID
    Date deliveryDate         = (Date)params.get("DeliveryDate");           // 発注ヘッダ.納入日
    Number txnsId             = (Number)params.get("TxnsId");              // 受入返品実績(アドオン)の取引ID
    Number headerInterfaceId  = (Number)params.get("HeaderInterfaceId");   // 受入ヘッダOIFのINTERFACE_TRANSACTION_ID


    // OUTパラメータ用
    HashMap retHashMap = new HashMap();
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);    

    //PL/SQLの作成を行います
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
    // シーケンスを取得
    sb.append("   SELECT rcv_transactions_interface_s.NEXTVAL "                 );
    sb.append("   INTO   lt_if_transaction_id "                                 );
    sb.append("   FROM   DUAL; "                                                );

    // OPM保管場所情報を取得
    sb.append("   SELECT mil.organization_id "                                  );
    sb.append("         ,mil.subinventory_code "                                );
    sb.append("         ,mil.inventory_location_id "                            );
    sb.append("   INTO   lt_organization_id "                                   );
    sb.append("         ,lt_subinventory_code "                                 );
    sb.append("         ,lt_inventory_location_id "                             );
    sb.append("   FROM mtl_item_locations mil "                                 );
    sb.append("   WHERE mil.segment1 = :1; "                                    ); // 発注明細.納入先コード
  
    // 発注納入明細
    sb.append("   SELECT plla.line_location_id "                                );
// 2008-07-17 H.Itou Add Start
    sb.append("         ,plla.closed_code "                                     );
// 2008-07-17 H.Itou Add End
    sb.append("   INTO   lt_line_location_id "                                  );
// 2008-07-17 H.Itou Add Start
    sb.append("         ,lt_closed_code "                                       );
// 2008-07-17 H.Itou Add End
    sb.append("   FROM po_line_locations_all plla "                             );
    sb.append("   WHERE plla.po_line_id = :2; "                                 ); // 発注明細ID
// 2008-10-21 D.Nihei Del Start 統合障害#384
//// 2008-07-17 H.Itou Add Start
//    // 発注納入明細.closed_codeがCLOSED FOR RECEIVINGの場合、OPENに変更
//    sb.append("   IF (lt_closed_code = 'CLOSED FOR RECEIVING') THEN  "          );
//    sb.append("     UPDATE po_line_locations_all plla "                         ); // 発注納入明細
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
//    sb.append("     WHERE  plla.po_line_id  = :2;  "                            ); // 発注明細ID
//    sb.append("   END IF;  "                                                    );
//// 2008-07-17 H.Itou Add End
// 2008-10-21 D.Nihei Del End
    // 受入ロットトランザクションオープンIF登録
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
    sb.append("     ,:3 "                                                       ); // 受入ヘッダOIFのGROUP_IDと同値を指定
    sb.append("     ,SYSDATE "                                                  );
    sb.append("     ,FND_GLOBAL.USER_ID "                                       );
    sb.append("     ,SYSDATE "                                                  );
    sb.append("     ,FND_GLOBAL.USER_ID "                                       );
    sb.append("     ,FND_GLOBAL.LOGIN_ID "                                      );
    sb.append("     ,'RECEIVE' "                                                );
    sb.append("     ,:4 "                                                       ); // 受入実績RN.納入日
    sb.append("     ,'PENDING' "                                                );
    sb.append("     ,'BATCH' "                                                  );
    sb.append("     ,'PENDING' "                                                );
    sb.append("     ,:5 "                                                       ); // 受入数量(換算注意)
    sb.append("     ,:6 "                                                       ); // 発注明細.品目基準単位
    sb.append("     ,:7 "                                                       ); // 発注明細.品目ID(ITEM_ID)
    sb.append("     ,'DELIVER' "                                                );
    sb.append("     ,'VENDOR' "                                                 );
    sb.append("     ,lt_organization_id "                                       );
    sb.append("     ,'PO' "                                                     );
    sb.append("     ,:8 "                                                       ); // 発注ヘッダ.発注ヘッダID
    sb.append("     ,:9 "                                                       ); // 発注明細.発注明細ID
    sb.append("     ,lt_line_location_id "                                      );
    sb.append("     ,'INVENTORY' "                                              );
    sb.append("     ,lt_subinventory_code "                                     );
    sb.append("     ,lt_inventory_location_id "                                 );
    sb.append("     ,:10 "                                                      ); // 発注ヘッダ.納入日
    sb.append("     ,:11 "                                                      ); // 受入返品実績(アドオン)の取引ID
    sb.append("     ,:12 "                                                      ); // 受入ヘッダOIFのINTERFACE_TRANSACTION_ID
    sb.append("     ,'Y' "                                                      );
    sb.append("   ); "                                                          );

    sb.append("   :13 := '1'; "                                                 );
    sb.append("   :14 := lt_if_transaction_id; "                                );
    sb.append(" END; "                                                          );

    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, locationCode);                                // 発注明細.納入先コード
      cstmt.setInt(2,    XxcmnUtility.intValue(lineId));               // 発注明細ID
      cstmt.setLong(3,    XxcmnUtility.longValue(groupId));            // 受入ヘッダOIFのGROUP_IDと同値を指定
      cstmt.setDate(4,   XxcmnUtility.dateValue(txnsDate));            // 受入実績RN.納入日
      cstmt.setDouble(5, Double.parseDouble(rcvRtnQuantity));          // 受入数量(換算注意)
      cstmt.setString(6, unitMeasLookupCode);                          // 発注明細.品目基準単位
      cstmt.setInt(7,    XxcmnUtility.intValue(plaItemId));            // 発注明細.品目ID(ITEM_ID)
      cstmt.setInt(8,    XxcmnUtility.intValue(headerId));             // 発注ヘッダ.発注ヘッダID
      cstmt.setInt(9,    XxcmnUtility.intValue(lineId));               // 発注明細.発注明細ID
      cstmt.setDate(10,  XxcmnUtility.dateValue(deliveryDate));        // 発注ヘッダ.納入日
      cstmt.setInt(11,   XxcmnUtility.intValue(txnsId));               // 受入返品実績(アドオン)の取引ID
      cstmt.setInt(12,   XxcmnUtility.intValue(headerInterfaceId));    // 受入ヘッダOIFのINTERFACE_TRANSACTION_ID


      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(13, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(14, Types.INTEGER);   // リターンコード
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      String retFlag = cstmt.getString(13); // リターンコード

      // 正常終了の場合
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // リターンコード：正常をセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        retHashMap.put("RetFlag",                XxcmnConstants.RETURN_SUCCESS); // リターンコード
        retHashMap.put("InterfaceTransactionId", new Number(cstmt.getInt(14)));   // interface_transaction_id
        
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {

      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //トークン生成
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_RCV_TRANSACTIONS_INTERFACE) };
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // insertRcvTransactionsIf

  /*****************************************************************************
   * 受入トランザクションオープンIFに訂正データを追加します。
   * @param trans トランザクション
   * @param params パラメータ
   * @return HashMap 
   * @throws OAException OA例外
   ****************************************************************************/
  public static HashMap correctRcvTransactionsIf(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {

    String apiName      = "correctRcvTransactionsIf";

    // INパラメータ取得
    String headerNum = (String)params.get("HeaderNumber");    // 発注番号
    Number headerId = (Number)params.get("HeaderId");         // 発注ヘッダID
    Number lineId   = (Number)params.get("LineId");           // 発注明細ID
    Number txnsId   = (Number)params.get("TxnsId");           // 取引ID
    Number groupId  = (Number)params.get("GroupId");          // グループID
    String quantity = (String)params.get("RcvRtnQuantity");   // 訂正数量
    Number lotCtl   = (Number)params.get("LotCtl");           // ロット対象(2)、非対称(1)フラグ
    String processCode = (String)params.get("ProcessCode");   // 受入訂正(0)、搬送訂正(1)
// 2008-12-05 H.Itou Add Start 本番障害#481対応
    Date   txnsDate = (Date)params.get("TxnsDate"); // 取引日
// 2008-12-05 H.Itou Add End

    // OUTパラメータ用
    HashMap retHashMap = new HashMap();
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);    

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);

    int count = 1;

    sb.append(" DECLARE ");
    sb.append("   l_category_id               rcv_transactions_interface.category_id%TYPE; ");              // 品目カテゴリID
    sb.append("   l_quantity                  rcv_transactions_interface.quantity%TYPE; ");                 // 数量
    sb.append("   l_unit_of_measure           rcv_transactions_interface.unit_of_measure%TYPE; ");          // 単位
    sb.append("   l_item_id                   rcv_transactions_interface.item_id%TYPE; ");                  // 品目ID
    sb.append("   l_item_description          rcv_transactions_interface.item_description%TYPE; ");         // 品目摘要
    sb.append("   l_uom_code                  rcv_transactions_interface.uom_code%TYPE; ");                 // 単位コード
    sb.append("   l_employee_id               rcv_transactions_interface.employee_id%TYPE; ");              // 従業員ID
    sb.append("   l_shipment_header_id        rcv_transactions_interface.shipment_header_id%TYPE; ");       // 受入ヘッダID
    sb.append("   l_shipment_line_id          rcv_transactions_interface.shipment_line_id%TYPE; ");         // 受入明細ID
    sb.append("   l_primary_quantity          rcv_transactions_interface.primary_quantity%TYPE; ");         // 数量:品目基準単位
    sb.append("   l_primary_unit_of_measure   rcv_transactions_interface.primary_unit_of_measure%TYPE; ");  // 品目基準単位
    sb.append("   l_vendor_id                 rcv_transactions_interface.vendor_id%TYPE; ");                // 仕入先ID
    sb.append("   l_vendor_site_id            rcv_transactions_interface.vendor_site_id%TYPE; ");           // 仕入先サイトID
    sb.append("   l_from_organization_id      rcv_transactions_interface.from_organization_id%TYPE; ");     // 搬送元在庫組織ID
    sb.append("   l_from_subinventory         rcv_transactions_interface.from_subinventory%TYPE; ");        // 搬送元保管棚コード
    sb.append("   l_to_organization_id        rcv_transactions_interface.to_organization_id%TYPE; ");       // 搬送先在庫組織ID
    sb.append("   l_routing_header_id         rcv_transactions_interface.routing_header_id%TYPE; ");        // 搬送経路ヘッダID
    sb.append("   l_parent_transaction_id     rcv_transactions_interface.parent_transaction_id%TYPE; ");    // 親取引ID(訂正先:取引)
    sb.append("   l_po_header_id              rcv_transactions_interface.po_header_id%TYPE; ");             // 発注ヘッダID
    sb.append("   l_po_line_id                rcv_transactions_interface.po_line_id%TYPE; ");               // 発注明細ID
    sb.append("   l_po_line_location_id       rcv_transactions_interface.po_line_location_id%TYPE; ");      // 発注納入明細ID
    sb.append("   l_po_unit_price             rcv_transactions_interface.po_unit_price%TYPE; ");            // 単価：発注
    sb.append("   l_currency_code             rcv_transactions_interface.currency_code%TYPE; ");            // 通貨コード
    sb.append("   l_currency_conversion_rate  rcv_transactions_interface.currency_conversion_rate%TYPE; "); // 通貨変換レート
    sb.append("   l_po_distribution_id        rcv_transactions_interface.po_distribution_id%TYPE; ");       // 発注搬送明細ID
    sb.append("   l_use_mtl_lot               rcv_transactions_interface.use_mtl_lot%TYPE; ");              // ロット使用フラグ
    sb.append("   l_from_locator_id           rcv_transactions_interface.from_locator_id%TYPE; ");          // 搬送元保管棚ID
    sb.append("   lt_person_id                per_all_people_f.person_id%TYPE; ");                          // 従業員ID
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

    // 受入訂正
    if ("0".equals(processCode)) 
    {  
      sb.append("   WHERE rt.parent_transaction_id = -1 ");
      sb.append("     AND rt.transaction_type      = 'RECEIVE' ");
      sb.append("     AND rt.destination_type_code = 'RECEIVING' ");
      sb.append("     AND rt.destination_context   = 'RECEIVING' ");
      sb.append("     AND rt.shipment_line_id      = rsl.shipment_line_id ");
      sb.append("     AND rt.po_header_id          = :" + (count++) +" ");                // 発注ヘッダID
      sb.append("     AND rt.po_line_id            = :" + (count++) + " ");               // 発注明細ID
      sb.append("     AND rsl.attribute1           = :" + (count++) + "; ");              // 受入明細.取引ID

    // 搬送訂正
    } else 
    {
      sb.append("   WHERE rt.parent_transaction_id in (SELECT transaction_id ");
      sb.append("                                      FROM rcv_transactions");
      sb.append("                                      WHERE po_header_id = :" + (count++) + " "); // 発注ヘッダID
      sb.append("                                        AND po_line_id   = :" + (count++) + " "); // 発注明細ID
      sb.append("                                        AND parent_transaction_id = -1) ");
      sb.append("     AND rt.transaction_type      ='DELIVER' "             );
      sb.append("     AND rt.destination_type_code = 'INVENTORY' "          );
      sb.append("     AND rt.destination_context   = 'INVENTORY' "          );
      sb.append("     AND rt.shipment_line_id      = rsl.shipment_line_id " );
      sb.append("     AND rsl.attribute1           = :" + (count++) + "; "  );              // 受入明細.取引ID

    }

    // 従業員情報
    sb.append("   SELECT papf.person_id ");
    sb.append("   INTO lt_person_id ");
    sb.append("   FROM fnd_user fu ");
    sb.append("       ,per_all_people_f papf ");
    sb.append("   WHERE  fu.employee_id               = papf.person_id ");             // 従業員ID
    sb.append("     AND    fu.start_date <= TRUNC(SYSDATE) "                          ); // 適用開始日
    sb.append("     AND    ((fu.end_date IS NULL) OR (fu.end_date >= TRUNC(SYSDATE))) " ); // 適用終了日
    sb.append("     AND    papf.effective_start_date <= TRUNC(SYSDATE) "              ); // 適用開始日
    sb.append("     AND    papf.effective_end_date   >= TRUNC(SYSDATE) "              ); // 適用終了日
    sb.append("     AND  fu.user_id = FND_GLOBAL.USER_ID; ");

    // シーケンスの取得
    sb.append("   SELECT rcv_transactions_interface_s.NEXTVAL ");
    sb.append("   INTO   lt_rcv_transactions_if_id ");
    sb.append("   FROM   DUAL; ");

    // グループIDを新規採番する場合
    if (XxcmnUtility.isBlankOrNull(groupId)) 
    {
      sb.append("   SELECT rcv_interface_groups_s.NEXTVAL ");
      sb.append("   INTO   lt_group_id_s ");
      sb.append("   FROM   DUAL; ");
  
      sb.append("   lt_group_id := lt_group_id_s; ");   // RCV_INTERFACE_GROUPS_S

    // グループIDを採番済みの場合
    }else
    {
      sb.append("   lt_group_id := :" + (count++) + "; ");   // 採番済みRCV_INTERFACE_GROUPS_S
    }

    // 受入ロットトランザクションオープンIF登録
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
// 2008-12-05 H.Itou Add Start 本番障害#481対応
//    sb.append("     ,SYSDATE ");
    sb.append("     ,:" + (count++) +" ");                                // 取引日：transaction_date
// 2008-12-05 H.Itou Add End
    sb.append("     ,'PENDING' ");
    sb.append("     ,'BATCH' ");
    sb.append("     ,'PENDING' ");
    sb.append("     ,l_category_id ");
    sb.append("     ,:" + (count++) +" ");                                // 訂正数量
    sb.append("     ,l_unit_of_measure ");
    sb.append("     ,l_item_id ");
    sb.append("     ,l_item_description ");
    sb.append("     ,l_uom_code ");
    sb.append("     ,lt_person_id ");
    sb.append("     ,l_shipment_header_id ");
    sb.append("     ,l_shipment_line_id ");
    sb.append("     ,:" + (count++) +" ");                                // 訂正数量
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
    sb.append("     ,:" + (count++) +" ");                                // 発注ヘッダID
    sb.append("     ,:" + (count++) +" ");                                // 発注明細ID
    sb.append("     ,l_po_line_location_id ");
    sb.append("     ,l_po_unit_price ");
    sb.append("     ,l_currency_code ");
    sb.append("     ,l_currency_conversion_rate ");
    sb.append("     ,l_po_distribution_id ");
    sb.append("     ,'NOT INSPECTED' ");

    if ("0".equals(processCode)) 
    {
      sb.append("     ,'RECEIVING' ");    // 受入訂正処理
    } else 
    {
      sb.append("     ,'INVENTORY' ");    // 搬送訂正処理
    }

    sb.append("     ,l_from_locator_id ");

    if ("0".equals(processCode)) 
    {
      sb.append("     ,'RECEIVING' ");    // 受入訂正処理
    } else 
    {
      sb.append("     ,'INVENTORY' ");    // 搬送訂正処理
    }

    sb.append("     ,:" + (count++) +" ");                                // ロット対象(2)、非対称(1)
    sb.append("     ,1 ");
    sb.append("     ,l_from_locator_id ");
    sb.append("   ); ");
  
    sb.append("   :" + (count++) +" := '1'; ");
    sb.append("   :" + (count++) +" := lt_rcv_transactions_if_id; ");
    sb.append("   :" + (count++) +" := lt_group_id; ");
    sb.append(" END; ");
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {

      count = 1;

      // パラメータ設定(INパラメータ)
      cstmt.setInt(count++, XxcmnUtility.intValue(headerId));     // 発注ヘッダID
      cstmt.setInt(count++, XxcmnUtility.intValue(lineId));       // 発注明細ID
      cstmt.setString(count++, XxcmnUtility.stringValue(txnsId)); // 受入明細.取引ID
      // グループIDを採番済みの場合
      if (!XxcmnUtility.isBlankOrNull(groupId)) 
      {
        cstmt.setLong(count++, XxcmnUtility.longValue(groupId));  // groupId
      }
// 2008-12-05 H.Itou Add Start 本番障害#481対応
      cstmt.setDate(count++, XxcmnUtility.dateValue(txnsDate)); // 受入明細.取引日
// 2008-12-05 H.Itou Add End
      cstmt.setDouble(count++, Double.parseDouble(quantity));    // 訂正数量
      cstmt.setDouble(count++, Double.parseDouble(quantity));    // 訂正数量
      cstmt.setInt(count++, XxcmnUtility.intValue(headerId));    // 発注ヘッダID
      cstmt.setInt(count++, XxcmnUtility.intValue(lineId));      // 発注明細ID
      cstmt.setInt(count++, XxcmnUtility.intValue(lotCtl));      // ロット対象(2)、非対称(1)

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(count++, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(count++, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(count, Types.BIGINT);      // リターンコード
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      String retFlag = cstmt.getString(count-2); // リターンコード

      // 正常終了の場合
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // リターンコード：正常をセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        retHashMap.put("RetFlag",                XxcmnConstants.RETURN_SUCCESS); // リターンコード
        retHashMap.put("InterfaceTransactionId", new Number(cstmt.getObject(count-1)));   // interface_transaction_id
        retHashMap.put("GroupId",                new Number(cstmt.getObject(count)));     // group_id
        
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {

      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //トークン生成
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_RCV_TRANSACTIONS_INTERFACE) };
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // correctRcvTransactionsIf 

  /*****************************************************************************
   * 品目ロットトランザクションオープンIFにデータを追加します。
   * @param trans トランザクション
   * @param params パラメータ
   * @return String XxcmnConstants.RETURN_SUCCESS:1 正常
   *                XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException OA例外
   ****************************************************************************/
  public static String insertMtlTransactionLotsIf(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertMtlTransactionLotsIf";

    // INパラメータ取得
    String lotNo              = (String)params.get("LotNo");                // 発注明細.ロットNo
    String rcvRtnQuantity     = (String)params.get("RcvRtnQuantity");       // 受入数量(換算注意)
    Number interfaceTransactionId  = (Number)params.get("InterfaceTransactionId");    // 受入トランザクションOIFのINTERFACE_TRANSACTION_ID
                                             
    // OUTパラメータ用
    String retFlag = XxcmnConstants.RETURN_NOT_EXE;    

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append(" BEGIN "                                               );
    
    // 品目ロットトランザクションオープンIF登録
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
    sb.append("     ,:1 "                                             ); // 発注明細.ロットNo
    sb.append("     ,ABS(:2) "                                        ); // 受入数量(換算注意)、絶対値
    sb.append("     ,ABS(:3) "                                        ); // 受入数量(換算注意)、絶対値
    sb.append("     ,'RCV' "                                          );
    sb.append("     ,:4 "                                             ); // 受入トランザクションOIFのINTERFACE_TRANSACTION_ID
    sb.append("   ); "                                                );
    sb.append("   :5 := '1'; "                                        );
    sb.append(" END; "                                                );
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, lotNo);                                 // 発注明細.ロットNo
      cstmt.setDouble(2, Double.parseDouble(rcvRtnQuantity));    // 受入数量(換算注意)
      cstmt.setDouble(3, Double.parseDouble(rcvRtnQuantity));    // 受入数量(換算注意)
      cstmt.setInt(4, XxcmnUtility.intValue(interfaceTransactionId)); // 受入トランザクションOIFのINTERFACE_TRANSACTION_ID
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(5, Types.VARCHAR);   // リターンコード
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      retFlag = cstmt.getString(5); // リターンコード

      // 正常終了の場合
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // リターンコード正常をセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {

      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //トークン生成
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_MTL_TRANSACTION_LOTS_INTERFACE) };
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // insertMtlTransactionLotsIf 

  /*****************************************************************************
   * 品目ロットトランザクションオープンIFに訂正データを追加します。
   * @param trans トランザクション
   * @param params パラメータ
   * @return String 処理結果
   * @throws OAException OA例外
   ****************************************************************************/
  public static String correctMtlTransactionLotsIf(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {

    String apiName      = "correctMtlTransactionLotsIf";

    // INパラメータ取得
    String lotNo        = (String)params.get("LotNo");                              // 発注明細.ロットNo
    String quantity     = (String)params.get("RcvRtnQuantity");                     // 訂正数量
    Number interfaceTransactionId  = (Number)params.get("InterfaceTransactionId");  // INTERFACE_TRANSACTION_ID
// 20080611 yoshimoto add Start ST不具合#72
    Number opmItemId    = (Number)params.get("OpmItemId");                          // 発注明細.OPM品目ID
// 20080611 yoshimoto add End ST不具合#72

    // OUTパラメータ用
    String retFlag = XxcmnConstants.RETURN_NOT_EXE;    

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" DECLARE ");

    sb.append("   lt_expire_date ic_lots_mst.expire_date%TYPE; ");    // 失効日

    sb.append(" BEGIN ");

    sb.append("   SELECT ilm.expire_date ");
    sb.append("   INTO lt_expire_date ");
    sb.append("   FROM ic_lots_mst ilm ");
    sb.append("   WHERE ilm.lot_no = :1 ");     // 発注明細.ロットNo
// 20080611 yoshimoto add Start
    sb.append("   AND   ilm.item_id = :2; ");   // 発注明細.OPM品目ID
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
// 20080611 yoshimoto mod Start ST不具合#72
/*
    sb.append("     ,:2 ");                                // 発注明細.ロットNo
    sb.append("     ,lt_expire_date ");
    sb.append("     ,ABS(:3) ");                           // 訂正数量の絶対値
    sb.append("     ,ABS(:4) ");                           // 訂正数量の絶対値
    sb.append("     ,'1' ");
    sb.append("     ,'RCV' ");
    sb.append("     ,:5 ");                                // INTERFACE_TRANSACTION_ID
    sb.append("   ); ");
    sb.append("   :6 := '1'; ");
*/
    sb.append("     ,:3 ");                                // 発注明細.ロットNo
    sb.append("     ,lt_expire_date ");
    sb.append("     ,ABS(:4) ");                           // 訂正数量の絶対値
    sb.append("     ,ABS(:5) ");                           // 訂正数量の絶対値
    sb.append("     ,'1' ");
    sb.append("     ,'RCV' ");
    sb.append("     ,:6 ");                                // INTERFACE_TRANSACTION_ID
    sb.append("   ); ");
    sb.append("   :7 := '1'; ");
// 20080611 yoshimoto mod End ST不具合#72
    sb.append(" END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, lotNo);   // ロットNo
// 20080611 yoshimoto mod Start ST不具合#72
/*
      cstmt.setString(2, lotNo);   // ロットNo
      cstmt.setDouble(3, Double.parseDouble(quantity));   // 訂正数量
      cstmt.setDouble(4, Double.parseDouble(quantity));   // 訂正数量
      cstmt.setInt(5, XxcmnUtility.intValue(interfaceTransactionId));  // INTERFACE_TRANSACTION_ID

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(6, Types.VARCHAR);   // リターンコード
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      retFlag = cstmt.getString(6); // リターンコード
*/
      cstmt.setInt(2, XxcmnUtility.intValue(opmItemId));      // 発注明細.OPM品目ID
      cstmt.setString(3, lotNo);                              // ロットNo
      cstmt.setDouble(4, Double.parseDouble(quantity));       // 訂正数量
      cstmt.setDouble(5, Double.parseDouble(quantity));       // 訂正数量
      cstmt.setInt(6, XxcmnUtility.intValue(interfaceTransactionId));  // INTERFACE_TRANSACTION_ID

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(7, Types.VARCHAR);   // リターンコード

      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      retFlag = cstmt.getString(7); // リターンコード
// 20080611 yoshimoto mod End ST不具合#72

      // 正常終了の場合
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // リターンコード：正常をセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {

      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //トークン生成
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_MTL_TRANSACTION_LOTS_INTERFACE) };
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // correctRcvLotsIf

  /*****************************************************************************
   * 受入ロットトランザクションオープンIFに訂正データを追加します。
   * @param trans トランザクション
   * @param params パラメータ
   * @return String 処理結果 
   * @throws OAException OA例外
   ****************************************************************************/
  public static String correctRcvLotsIf(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {

    String apiName      = "correctRcvLotsIf";

    // INパラメータ取得
    String lotNo        = (String)params.get("LotNo");                              // 発注明細.ロットNo
    Number headerId     = (Number)params.get("HeaderId");                           // 発注ヘッダID
    Number lineId       = (Number)params.get("LineId");                             // 発注明細ID
    Number txnsId       = (Number)params.get("TxnsId");                             // 取引ID
    String quantity     = (String)params.get("RcvRtnQuantity");                     // 訂正数量
    Number interfaceTransactionId  = (Number)params.get("InterfaceTransactionId");  // INTERFACE_TRANSACTION_ID
// 20080611 yoshimoto add Start ST不具合#72
    Number opmItemId    = (Number)params.get("OpmItemId");                          // 発注明細.OPM品目ID
// 20080611 yoshimoto add End ST不具合#72

    // OUTパラメータ用
    String retFlag = XxcmnConstants.RETURN_NOT_EXE;    

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" DECLARE ");

    sb.append("   l_item_id          rcv_transactions_interface.item_id%TYPE; ");           // 品目ID
    sb.append("   l_shipment_line_id rcv_transactions_interface.shipment_line_id%TYPE; ");  // 受入明細ID
    sb.append("   lt_expire_date     ic_lots_mst.expire_date%TYPE; ");                      // 失効日

    sb.append(" BEGIN ");

    sb.append("   SELECT ilm.expire_date ");
    sb.append("   INTO lt_expire_date ");
    sb.append("   FROM ic_lots_mst ilm ");
    sb.append("   WHERE ilm.lot_no = :1 ");      // 発注明細.ロットNo
// 20080611 yoshimoto add Start ST不具合#72
    sb.append("   AND   ilm.item_id = :2; ");    // 発注明細.OPM品目ID
// 20080611 yoshimoto add End ST不具合#72

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
// 20080611 yoshimoto add Start ST不具合#72
/*
    sb.append("     AND rt.po_header_id          = :2 ");                      // 発注ヘッダID
    sb.append("     AND rt.po_line_id            = :3 ");                      // 発注明細ID
    sb.append("     AND rsl.attribute1           = :4; " );                    // 受入明細.取引ID

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
    sb.append("     ,:6 ");                                // 発注明細.ロットNo
    sb.append("     ,ABS(:7) ");                           // 訂正数量の絶対値
    sb.append("     ,SYSDATE ");
    sb.append("     ,lt_expire_date ");
    sb.append("     ,ABS(:8) ");                           // 訂正数量の絶対値
    sb.append("     ,l_item_id ");
    sb.append("     ,l_shipment_line_id ");
    sb.append("   ); ");

    sb.append("   :9 := '1'; ");
*/
    sb.append("     AND rt.po_header_id          = :3 ");                      // 発注ヘッダID
    sb.append("     AND rt.po_line_id            = :4 ");                      // 発注明細ID
    sb.append("     AND rsl.attribute1           = :5; " );                    // 受入明細.取引ID

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
    sb.append("     ,:7 ");                                // 発注明細.ロットNo
    sb.append("     ,ABS(:8) ");                           // 訂正数量の絶対値
    sb.append("     ,SYSDATE ");
    sb.append("     ,lt_expire_date ");
    sb.append("     ,ABS(:9) ");                           // 訂正数量の絶対値
    sb.append("     ,l_item_id ");
    sb.append("     ,l_shipment_line_id ");
    sb.append("   ); ");

    sb.append("   :10 := '1'; ");
// 20080611 yoshimoto add End ST不具合#72

    sb.append(" END; ");
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {

      // パラメータ設定(INパラメータ)
      cstmt.setString(1, lotNo);                                       // ロットNo
// 20080611 yoshimoto mod Start ST不具合#72
/*
      cstmt.setInt(2,    XxcmnUtility.intValue(headerId));             // 発注ヘッダID
      cstmt.setInt(3,    XxcmnUtility.intValue(lineId));               // 発注明細ID
      cstmt.setString(4, XxcmnUtility.stringValue(txnsId));            // 受入明細.取引ID
      cstmt.setInt(5, XxcmnUtility.intValue(interfaceTransactionId));  // INTERFACE_TRANSACTION_ID
      cstmt.setString(6, lotNo);                                       // ロットNo
      cstmt.setDouble(7, Double.parseDouble(quantity));                // 訂正数量
      cstmt.setDouble(8, Double.parseDouble(quantity));                // 訂正数量

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(9, Types.VARCHAR);   // リターンコード
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      retFlag = cstmt.getString(9); // リターンコード
*/
      cstmt.setInt(2,    XxcmnUtility.intValue(opmItemId));            // 発注明細.OPM品目ID
      cstmt.setInt(3,    XxcmnUtility.intValue(headerId));             // 発注ヘッダID
      cstmt.setInt(4,    XxcmnUtility.intValue(lineId));               // 発注明細ID
      cstmt.setString(5, XxcmnUtility.stringValue(txnsId));            // 受入明細.取引ID
      cstmt.setInt(6, XxcmnUtility.intValue(interfaceTransactionId));  // INTERFACE_TRANSACTION_ID
      cstmt.setString(7, lotNo);                                       // ロットNo
      cstmt.setDouble(8, Double.parseDouble(quantity));                // 訂正数量
      cstmt.setDouble(9, Double.parseDouble(quantity));                // 訂正数量

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(10, Types.VARCHAR);   // リターンコード
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      retFlag = cstmt.getString(10);                  // リターンコード
// 20080611 yoshimoto mod End ST不具合#72

      // 正常終了の場合
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // リターンコード：正常をセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {

      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //トークン生成
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                 XxpoConstants.TAB_RCV_LOTS_INTERFACE) };
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10007, 
                             tokens);
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
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // correctRcvLotsIf 

  /*****************************************************************************
   * 受注明細の受入数量/数量確定フラグを更新します。
   * @param trans トランザクション
   * @param poLineId 発注明細ID
   * @param receiptAmountTotal 合計受入数量
   * @throws OAException OA例外
   ****************************************************************************/
  public static void updateReceiptAmount(
    OADBTransaction trans,
    Number poLineId,
    double receiptAmountTotal
    ) throws OAException
  {
    String apiName = "updateReceiptAmount";

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" BEGIN "                                                         );
    sb.append("   UPDATE po_lines_all pla "                                     );
    sb.append("   SET pla.attribute7        = :1 "                              ); // 受入数量(合計値)
    sb.append("      ,pla.attribute13       = 'Y' "                             ); // 数量確定フラグ
    sb.append("      ,pla.last_updated_by   = FND_GLOBAL.USER_ID "              ); // 最終更新者
    sb.append("      ,pla.last_update_date  = SYSDATE "                         ); // 最終更新日
    sb.append("      ,pla.last_update_login = FND_GLOBAL.LOGIN_ID "             ); // 最終更新ログイン
    sb.append("   WHERE pla.po_line_id = :2; "                                  );
    sb.append(" END; "                                                          );
    
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setDouble(1, receiptAmountTotal);   // 受入数量
      cstmt.setInt(2,    XxcmnUtility.intValue(poLineId));     // 発注明細ID
      
      //PL/SQL実行
      cstmt.execute();
    
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateReceiptAmount

  /*****************************************************************************
   * OPMロットマスタTblにデータを更新します。(※更新対象を動的に変更できます)
   * @param trans トランザクション
   * @param params パラメータ用HashMap
   * @return String XxcmnConstants.RETURN_SUCCESS:1 正常
   *                  XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException OA例外
   ****************************************************************************/
  public static String updateIcLotsMstTxns2(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
  
    String apiName      = "updateIcLotsMstTxns2";
    int bindCount = 1;
    
    // *********************** //
    // * 検索条件を取得      * //
    // *********************** //
    // OPM品目ID
    Number itemId            = (Number)params.get("ItemId");
    // ロットNo
    String lotNo             = (String)params.get("LotNo");
    // 製造日
    Date productionDate      = (Date)params.get("ProductionDate");
    // 賞味期限
    Date useByDate           = (Date)params.get("UseByDate");
// 20080523 add yoshimoto Start
    // 入数
    String itemAmount        = (String)params.get("ItemAmount");
    // 明細摘要
    String description       = (String)params.get("Description");
// 20080523 add yoshimoto End

    // *********************** //
    // * 更新データを取得    * //
    // *********************** //
    String firstTimeDeliveryDate = (String)params.get("FirstTimeDeliveryDate"); // 納入日(初回)
    String finalDeliveryDate     = (String)params.get("FinalDeliveryDate");     // 納入日(最終)

    // OUTパラメータ用
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // 戻り値

    //PL/SQLの作成を行います
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

    // OPMロットマスタカーソル
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
    sb.append("          ,ilm.attribute1 "                          );  // 製造年月日
    sb.append("          ,ilm.attribute2 "                          );  // 固有記号
    sb.append("          ,ilm.attribute3 "                          );  // 賞味期限
    sb.append("          ,ilm.attribute4 "                          );  // 納入日（初回）
    sb.append("          ,ilm.attribute5 "                          );  // 納入日（最終）
    sb.append("          ,ilm.attribute6 "                          );  // 在庫入数
    sb.append("          ,ilm.attribute7 "                          );  // 在庫単価
    sb.append("          ,ilm.attribute8 "                          );  // 取引先
    sb.append("          ,ilm.attribute9 "                          );  // 仕入形態
    sb.append("          ,ilm.attribute10 "                         );  // 茶期区分
    sb.append("          ,ilm.attribute11 "                         );  // 年度
    sb.append("          ,ilm.attribute12 "                         );  // 産地
    sb.append("          ,ilm.attribute13 "                         );  // タイプ
    sb.append("          ,ilm.attribute14 "                         );  // ランク１
    sb.append("          ,ilm.attribute15 "                         );  // ランク２
    sb.append("          ,ilm.attribute16 "                         );  // 生産伝票区分
    sb.append("          ,ilm.attribute17 "                         );  // ライン№
    sb.append("          ,ilm.attribute18 "                         );  // 摘要
    sb.append("          ,ilm.attribute19 "                         );  // ランク３
    sb.append("          ,ilm.attribute20 "                         );  // 原料製造工場
    sb.append("          ,ilm.attribute22 "                         );  // 原料製造元ロット番号
    sb.append("          ,ilm.attribute21 "                         );  // 検査依頼No
    sb.append("          ,ilm.attribute23 "                         );  // ロットステータス
    sb.append("          ,ilm.attribute24 "                         );  // 作成区分
    sb.append("          ,ilm.attribute25 "                         );  // DFF項目25
    sb.append("          ,ilm.attribute26 "                         );  // DFF項目26
    sb.append("          ,ilm.attribute27 "                         );  // DFF項目27
    sb.append("          ,ilm.attribute28 "                         );  // DFF項目28
    sb.append("          ,ilm.attribute29 "                         );  // DFF項目29
    sb.append("          ,ilm.attribute30 "                         );  // DFF項目30
    sb.append("          ,ilm.attribute_category "                  );  // DFFカテゴリ
    sb.append("          ,ilm.odm_lot_number "                      );
    sb.append("    FROM ic_lots_mst ilm "                           );
    sb.append("    WHERE ilm.item_id = :" + (bindCount++)               );  // 品目ID
    sb.append("    AND   ilm.lot_no  = :" + (bindCount++) + "; "        );  // ロットNo
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
    sb.append("    WHERE ilc.item_id = :"+ (bindCount++)                );  // 品目ID
    sb.append("    AND   ilc.lot_id  = p_lot_id; "                  );  // ロットID
    sb.append("  p_lot_cpg_rec ic_lots_cpg%ROWTYPE; "               );

    sb.append("BEGIN "                                              );
    // GMI系APIグローバル定数の設定
    sb.append("  lb_setup_return_sts  :=  GMIGUTL.Setup(FND_GLOBAL.USER_NAME); ");  
    
    // OPMロットMSTカーソル OPEN
    sb.append("  OPEN p_lot_cur; "                                  );
    sb.append("  FETCH p_lot_cur INTO p_lot_rec; "                  );

    sb.append("  OPEN p_lot_cpg_cur(p_lot_rec.lot_id); "            );
    sb.append("  FETCH p_lot_cpg_cur INTO p_lot_cpg_rec; "          );

    // ******************************** //
    // * 更新データを設定(動的) 6～   * //
    // ******************************** //
    // 更新が発生する場合、更新データを格納 [Start]
    if (!XxcmnUtility.isBlankOrNull(firstTimeDeliveryDate))
    {
      sb.append("  p_lot_rec.attribute4        := :" + (bindCount++) + "; " );  // 納入日（初回）
    }
    if (!XxcmnUtility.isBlankOrNull(finalDeliveryDate))
    {
      sb.append("  p_lot_rec.attribute5        := :" + (bindCount++) + "; " );  // 納入日（最終）
    }
    if (!XxcmnUtility.isBlankOrNull(productionDate))
    {
      sb.append("  p_lot_rec.attribute1        := :" + (bindCount++) + "; " );  // 製造年月日
    }
    if (!XxcmnUtility.isBlankOrNull(useByDate))
    {
      sb.append("  p_lot_rec.attribute3        := :" + (bindCount++) + "; " );  // 賞味期限
    }
// 20080523 add yoshimoto Start
    if (!XxcmnUtility.isBlankOrNull(itemAmount))
    {
      sb.append("  p_lot_rec.attribute6        := :" + (bindCount++) + "; " );  // 入数
    }
    if (!XxcmnUtility.isBlankOrNull(description))
    {
      sb.append("  p_lot_rec.attribute18       := :" + (bindCount++) + "; " );  // 摘要
    }
// 20080523 add yoshimoto End
    // 更新が発生する場合、更新データを格納 [End]
    
    sb.append("  p_lot_rec.last_updated_by   := FND_GLOBAL.USER_ID; " );  // 最終更新者
    sb.append("  p_lot_rec.last_update_date  := SYSDATE; "            );  // 最終更新日

    // ロット更新API呼び出し
    sb.append("  GMI_LotUpdate_PUB.Update_Lot( "                                       );
    sb.append("                     p_api_version      => ln_api_version_number "      );  // IN  APIのバージョン番号
    sb.append("                    ,p_init_msg_list    => FND_API.G_FALSE "            );  // IN  メッセージ初期化フラグ
    sb.append("                    ,p_commit           => FND_API.G_FALSE "            );  // IN  処理確定フラグ
    sb.append("                    ,p_validation_level => FND_API.G_VALID_LEVEL_FULL " );  // IN  検証レベル
    sb.append("                    ,x_return_status    => lv_ret_status "              );  // OUT 終了ステータス('S'-正常終了,'E'-例外発生,'U'-システム例外発生)
    sb.append("                    ,x_msg_count        => ln_msg_cnt "                 );  // OUT メッセージ・スタック数
    sb.append("                    ,x_msg_data         => lv_msg_data "                );  // OUT メッセージ
    sb.append("                    ,p_lot_rec          => p_lot_rec "                  );  // IN  更新するロット情報を指定
    sb.append("                    ,p_lot_cpg_rec      => p_lot_cpg_rec); "            );  // IN  更新するロット情報を指定

    sb.append("  CLOSE p_lot_cur; "                );
    sb.append("  CLOSE p_lot_cpg_cur; "            );

    // エラーメッセージをFND_LOG_MESSAGESに出力
    sb.append("  IF (ln_msg_cnt > 0) THEN "        );
    sb.append("    xxcmn_common_pkg.put_api_log( " );
    sb.append("       ov_errbuf  => lv_errbuf "    );
    sb.append("      ,ov_retcode => lv_retcode "   );
    sb.append("      ,ov_errmsg  => lv_errmsg ); " );
    sb.append("  END IF; "                         );

    // OUTパラメータ出力
    sb.append("  :" + (bindCount++) + " := lv_ret_status; "            ); 
    sb.append("  :" + (bindCount++) + " := ln_msg_cnt; "               );
    sb.append("  :" + (bindCount++) + " := lv_msg_data; "              );

    sb.append("END; "                              );


    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {
      // ******************************* //
      // * パラメータを設定(固定)      * //
      // ******************************* //
      // パラメータ設定(INパラメータ)
      bindCount = 1;
      cstmt.setInt(bindCount++, XxcmnUtility.intValue(itemId)); // OPM品目ID
      cstmt.setString(bindCount++, lotNo);                      // ロットNo
      cstmt.setInt(bindCount++, XxcmnUtility.intValue(itemId)); // OPM品目ID

      // ****************************************** //
      // * パラメータ(更新データ)を設定(動的)     * //
      // ****************************************** //
      // 取得できる場合は設定(INパラメータ) Start
      // 納入日（初回）
      if (!XxcmnUtility.isBlankOrNull(firstTimeDeliveryDate))
      {
        cstmt.setString(bindCount++, firstTimeDeliveryDate);
      }
      // 納入日（最終）
      if (!XxcmnUtility.isBlankOrNull(finalDeliveryDate))
      {
        cstmt.setString(bindCount++, finalDeliveryDate);
      }
      // 製造年月日
      if (!XxcmnUtility.isBlankOrNull(productionDate))
      {
// 20080521 yoshimoto mod Start
        //cstmt.setString(bindCount++, productionDate.toString());
        cstmt.setString(bindCount++, XxcmnUtility.stringValue(productionDate));
// 20080521 yoshimoto mod End
      }
      // 賞味期限
      if (!XxcmnUtility.isBlankOrNull(useByDate))
      {
// 20080521 yoshimoto mod Start
        //cstmt.setString(bindCount++, useByDate.toString());
        cstmt.setString(bindCount++, XxcmnUtility.stringValue(useByDate));
// 20080521 yoshimoto mod End
      }
// 20080523 add yoshimoto Start
      // 入数
      if (!XxcmnUtility.isBlankOrNull(itemAmount))
      {
        cstmt.setString(bindCount++, itemAmount);
      }
      // 摘要
      if (!XxcmnUtility.isBlankOrNull(description))
      {
        cstmt.setString(bindCount++, description);
      }
// 20080523 add yoshimoto End
      // 取得できる場合は設定(INパラメータ) End


      // ******************************* //
      // * パラメータを設定(固定)      * //
      // ******************************* //
      // パラメータ設定(OUTパラメータ)
      int bindCount2 = bindCount; // OUTパラメータ用のカウント(INパラの最終番号+1)
      cstmt.registerOutParameter(bindCount2++, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(bindCount2++, Types.INTEGER);   // メッセージ数
      cstmt.registerOutParameter(bindCount2++, Types.VARCHAR);   // メッセージ

      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      bindCount2 = bindCount;     // OUTパラメータ用のカウントを再設定(INパラの最終番号+1)
      String retStatus = cstmt.getString(bindCount2++); // リターンコード
      int msgCnt      = cstmt.getInt(bindCount2++);    // メッセージ数
      String msgData   = cstmt.getString(bindCount2++); // メッセージ


      // 正常終了の場合、フラグを1:正常に。
      if (XxcmnConstants.API_STATUS_SUCCESS.equals(retStatus)) 
      {
        // リターンコード正常をセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;

      // 正常終了でない場合、エラー  
      } else
      {

        // APIエラーを出力する。
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              msgData,
                              6);

        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);

      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {

      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }

    // 正常に処理された場合、"SUCCESS"(1)を返却
    return XxcmnConstants.RETURN_SUCCESS;    
  } // updateIcLotsMstTxns2
  
  /*****************************************************************************
   * 発注ヘッダ.ステータスコードを更新します。
   * @param trans トランザクション
   * @param statusCode ステータスコード
   * @param headerId 発注ヘッダID
   * @return String XxcmnConstants.RETURN_SUCCESS:1 正常
   *                 XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String updateStatusCode(
    OADBTransaction trans,
    String statusCode,
    Number headerId
  ) throws OAException
  {
    String apiName = "updateStatusCode";
  
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                    );
    // 発注ヘッダ更新
    sb.append("  UPDATE po_headers_all pha "                              );
    sb.append("  SET    pha.attribute1            = :1 "                  ); // ステータスコード
    sb.append("        ,pha.last_updated_by       = FND_GLOBAL.USER_ID "  ); // 最終更新者
    sb.append("        ,pha.last_update_date      = SYSDATE "             ); // 最終更新日
    sb.append("        ,pha.last_update_login     = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン
    sb.append("  WHERE  pha.po_header_id          = :2;  "                ); // 発注ヘッダID
    sb.append("END; "                                                     );

    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, statusCode);                      // ステータスコード
      cstmt.setInt(2, XxcmnUtility.intValue(headerId));    // 発注ヘッダID

      //PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return XxcmnConstants.RETURN_SUCCESS;
  } // updateStatusCode

  /***************************************************************************
   * 全発注明細の数量確定済をチェックするメソッドです。
   * @param trans トランザクション
   * @param headerId 発注ヘッダID
   * @return retCode Y：全て数量確定済、N：数量確定済でない発注明細有り
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public static String chkAllFinDecisionAmountFlg(
    OADBTransaction trans,
    Number headerId
  )
  {
    String apiName = "chkAllFinDecisionAmountFlg";

    // 戻り値
    String retCode = null;
    
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);


    sb.append(" DECLARE "                           );
    sb.append("   ln_count1 NUMBER; "               );
    sb.append("   ln_count2 NUMBER; "               );
    sb.append(" BEGIN "                             );
    // 発注ヘッダIDに紐付く、発注明細の総数を取得
    sb.append("   SELECT COUNT(pla.po_header_id) "  );
    sb.append("   INTO ln_count1 "                  );
    sb.append("   FROM po_lines_all pla "           );
    sb.append("   WHERE pla.po_header_id = :1 "     );
// 2008-12-18 v1.18 T.Yoshimoto Add Start 本番#788
    sb.append("   AND   pla.cancel_flag  = 'N' "    );
// 2008-12-18 v1.18 T.Yoshimoto Add End 本番#788
    sb.append("   ORDER BY pla.po_header_id; "      );

    // 発注ヘッダIDに紐付き、数量確定フラグ(ATTRIBUTE13)が'Y'である、
    // 発注明細の総数を取得
    sb.append("   SELECT COUNT(pla.po_header_id) "  );
    sb.append("   INTO ln_count2 "                  );
    sb.append("   FROM po_lines_all pla "           );
    sb.append("   WHERE pla.po_header_id = :1 "     );
    sb.append("   AND   pla.attribute13 = 'Y' "     );
// 2008-12-18 v1.18 T.Yoshimoto Add Start 本番#788
    sb.append("   AND   pla.cancel_flag  = 'N' "    );
// 2008-12-18 v1.18 T.Yoshimoto Add End 本番#788
    sb.append("   ORDER BY pla.po_header_id; "      );

    // 発注明細の総数と、数量確定フラグ(ATTRIBUTE13)が'Y'である発注明細の総数が
    // 同数の場合は'Y'
    sb.append("   IF (ln_count1 = ln_count2) THEN " );
    sb.append("    :2 := 'Y'; "                     );
    sb.append("   ELSE "                            );
    sb.append("    :2 := 'N'; "                     );
    sb.append("   END IF; "                         );
    sb.append(" END; "                              );


    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1, XxcmnUtility.intValue(headerId));  // 発注ヘッダアドオンID
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(2, Types.VARCHAR);      // リターンコード
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      retCode = cstmt.getString(2); // リターンコード

    } catch (SQLException s) 
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
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
        // ロールバック
        rollBack(trans);
        // ログ出力
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
   * 在庫数量APIを起動します。
   * @param trans - トランザクション
   * @param params - パラメータ
   * @return HashMap
   * @throws OAException - OA例外
   ****************************************************************************/
  public static HashMap insertIcTranCmp(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "insertIcTranCmp"; // API名

    // INパラメータ取得
    String locationCode       = (String)params.get("LocationCode");       // 保管場所
    String itemNo             = (String)params.get("ItemNo");             // 品目
    String unitMeasLookupCode = (String)params.get("UnitMeasLookupCode"); // 品目基準単位
    String lotNo              = (String)params.get("LotNo");              // ロット
    String amount             = (String)params.get("Amount");             // 数量
    Date txnsDate             = (Date)params.get("TxnsDate");             // 取引日
    String reasonCode         = (String)params.get("ReasonCode");         // 事由コード
    Number txnsId             = (Number)params.get("TxnsId");             // 文書ソースID

    HashMap retHashMap = new HashMap(); // 戻り値
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

    //PL/SQLの作成を行います
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
    // GMI系APIグローバル定数の設定
    sb.append("   lb_setup_return_sts  :=  GMIGUTL.Setup(FND_GLOBAL.USER_NAME); "); 
    
    // 倉庫,組織,会社コードを取得
    sb.append("   SELECT xilv.whse_code "    );  // 倉庫コード
    sb.append("         ,iwm.orgn_code "     );  // 組織コード
    sb.append("         ,somb.co_code "      );  // 会社コード
    sb.append("   INTO   lt_whse_code "                    );
    sb.append("         ,lt_orgn_code "                    );
    sb.append("         ,lt_co_code "                      );
    sb.append("   FROM   xxcmn_item_locations_v  xilv "    );
    sb.append("         ,ic_whse_mst             iwm "     );
    sb.append("         ,sy_orgn_mst_b           somb "    );
    sb.append("   WHERE  xilv.whse_code = iwm.whse_code "  );
    sb.append("   AND    iwm.orgn_code  = somb.orgn_code " );
    sb.append("   AND    xilv.segment1  = :1; "            );
    
    
    // パラメータ作成
    sb.append("  lr_qty_in.trans_type          := 2; "                          ); // 取引タイプ(常に2:調整即時)
    sb.append("  lr_qty_in.item_no             := :2; "                         ); // 品目
    sb.append("  lr_qty_in.from_whse_code      := lt_whse_code; "               ); // 倉庫
    sb.append("  lr_qty_in.item_um             := :3; "                         ); // 単位
    sb.append("  lr_qty_in.lot_no              := :4; "                         ); // ロット
    sb.append("  lr_qty_in.from_location       := :5; "                         ); // 保管場所
    sb.append("  lr_qty_in.trans_qty           := :6; "                         ); // 数量
    sb.append("  lr_qty_in.co_code             := lt_co_code; "                 ); // 会社
    sb.append("  lr_qty_in.orgn_code           := lt_orgn_code; "               ); // 組織
    sb.append("  lr_qty_in.trans_date          := :7; "                         ); // 取引日
    sb.append("  lr_qty_in.reason_code         := FND_PROFILE.VALUE(:8); "      ); // 事由コード
    sb.append("  lr_qty_in.user_name           := FND_GLOBAL.USER_NAME; "       ); // ユーザ名
    sb.append("  lr_qty_in.attribute1          := :9; "                         ); // 文書ソースID

    // API:在庫数量API実行
    sb.append("  GMIPAPI.INVENTORY_POSTING( "                                   );
    sb.append("     p_api_version      => ln_api_version_number "               ); // IN:APIのバージョン番号
    sb.append("    ,p_init_msg_list    => FND_API.G_FALSE "                     ); // IN:メッセージ初期化フラグ
    sb.append("    ,p_commit           => FND_API.G_FALSE "                     ); // IN:処理確定フラグ
    sb.append("    ,p_validation_level => FND_API.G_VALID_LEVEL_FULL "          ); // IN:検証レベル
    sb.append("    ,p_qty_rec          => lr_qty_in "                           ); // IN:調整する在庫数量情報を指定
    sb.append("    ,x_ic_jrnl_mst_row  => lr_qty_out "                          ); // OUT:調整された在庫数量情報が返却
    sb.append("    ,x_ic_adjs_jnl_row1 => lr_adjs_out1 "                        ); // OUT:調整された在庫数量情報が返却
    sb.append("    ,x_ic_adjs_jnl_row2 => lr_adjs_out2 "                        ); // OUT:-
    sb.append("    ,x_return_status    => :10 "                                 ); // OUT:終了ステータス( 'S'-正常終了, 'E'-例外発生, 'U'-システム例外発生)
    sb.append("    ,x_msg_count        => :11 "                                 ); // OUT:メッセージ・スタック数
    sb.append("    ,x_msg_data         => :12); "                               ); // OUT:メッセージ   
    sb.append("END; "                                                           );
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, locationCode);                   // 保管場所コード
      cstmt.setString(2, itemNo);                         // 品目
      cstmt.setString(3, unitMeasLookupCode);             // 単位
      cstmt.setString(4, lotNo);                          // ロット
      cstmt.setString(5, locationCode);                   // 保管場所コード
      cstmt.setDouble(6, Double.parseDouble(amount));     // 数量
      cstmt.setDate(7, XxcmnUtility.dateValue(txnsDate)); // 取引日
      cstmt.setString(8, reasonCode);                     // 事由コード
      cstmt.setInt(9, XxcmnUtility.intValue(txnsId));     // 文書ソースID
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(10, Types.VARCHAR);  // リターンステータス
      cstmt.registerOutParameter(11, Types.INTEGER); // メッセージカウント
      cstmt.registerOutParameter(12, Types.VARCHAR); // メッセージ

      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      String retStatus = cstmt.getString(10);  // リターンステータス
      int msgCnt       = cstmt.getInt(11);    // メッセージカウント
      String msgData   = cstmt.getString(12);  // メッセージ

      // 正常終了の場合
      if (XxcmnConstants.API_STATUS_SUCCESS.equals(retStatus)) 
      {
        // ロットID、リターンコード正常をセット
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);

      // 正常終了でない場合、エラー  
      } else
      {
        // APIエラーを出力する。
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              msgData,
                              6);
        //トークン生成
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_INFO_NAME,
                                                   XxpoConstants.TAB_IC_LOTS_MST) };
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                               XxpoConstants.XXPO10007, 
                               tokens);
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
          rollBack(trans);
          XxcmnUtility.writeLog(trans,
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // insertIcTranCmp

  /*****************************************************************************
   * コンカレント：受入取引処理を発行します。
   * @param trans トランザクション
   * @param groupId グループID
   * @return HashMap 処理結果/要求ID
   * @throws OAException OA例外
   ****************************************************************************/
  public static HashMap doRVCTP(
    OADBTransaction trans,
    String groupId
  ) throws OAException
  {
    String apiName      = "doRVCTP";

    // OUTパラメータ用
    HashMap retHash = new HashMap();
    retHash.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE); // 戻り値

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "   );
    sb.append("  ln_request_id NUMBER; "                                       );
    sb.append("BEGIN "                                                         );
    // 受入取引処理(コンカレント)呼び出し
    sb.append("  ln_request_id := FND_REQUEST.SUBMIT_REQUEST( "                );
    sb.append("     application  => 'PO' "                                     ); // アプリケーション名
    sb.append("    ,program      => 'RVCTP' "                                  ); // プログラム短縮名
    sb.append("    ,argument1    => 'BATCH' "                                  ); // 取引処理モード
    sb.append("    ,argument2    => :1 ); "                                    ); // グループID
                 // 要求IDがある場合、正常
    sb.append("  IF ln_request_id > 0 THEN "                                   );
    sb.append("    :2 := '1'; "                                                ); // 1:正常終了
    sb.append("    :3 := ln_request_id; "                                      ); // 要求ID
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
      cstmt.setString(1, groupId);                    // グループID
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(2, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(3, Types.INTEGER);   // 要求ID

      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      String retFlag = cstmt.getString(2);    // リターンコード
      int requestId = cstmt.getInt(3); // 要求ID

      // 正常終了の場合
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // リターンコード正常をセット
        retHash.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);
        retHash.put("RequestId", new Integer(requestId));
        
      // 正常終了でない場合、エラー  
      } else
      {
        //トークン生成
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                   XxpoConstants.TOKEN_NAME_RVCTP) };
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                               XxpoConstants.XXPO10055, 
                               tokens);
      }
      
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }

    return retHash;
  } // doRVCTP. 

  /***************************************************************************
   * EBS標準.受入Tbl登録済チェックを行うメソッドです。
   * @param trans - トランザクション
   * @param txnsId - 取引ID
   * @return String - XxcmnConstants.STRING_N：未登録
   *                  XxcmnConstants.STRING_Y：登録済
   * @throws OAException OA例外
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
      // PL/SQLの作成を行います
      StringBuffer sb = new StringBuffer(1000);
      sb.append(" BEGIN "                                          );
      sb.append("   SELECT COUNT(rsl.attribute1) cnt "             );
      sb.append("   INTO :1 "                                      );
      sb.append("   FROM rcv_shipment_lines rsl"                   );
      sb.append("   WHERE rsl.attribute1 = TO_CHAR(:2); "          );
      sb.append(" END; "                                           );

      // PL/SQLの設定を行います
      cstmt = trans.createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);
      
      // PL/SQLを実行します
      int i = 1;
      cstmt.registerOutParameter(i++, Types.INTEGER);
      cstmt.setInt(i++, XxcmnUtility.intValue(txnsId));

      // SQL実行
      cstmt.execute();

      int count = cstmt.getInt(1);

      // 受入インタフェースに登録されていない場合
      if (count == 0) 
      {
        return XxcmnConstants.STRING_N;
      }
      
    // PL/SQL実行時例外の場合   
    } catch (SQLException s) 
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
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
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }

    // 受入インタフェースに登録済場合
    return XxcmnConstants.STRING_Y;

  } // chkRcvOifInput

  /*****************************************************************************
   * 受入返品実績(アドオン)にデータを更新します。
   * @param trans トランザクション
   * @param params パラメータ
   * @return String 処理結果   
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String updateRcvAndRtnTxns(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName      = "updateRcvAndRtnTxns";

    // INパラメータ取得
    // 取引ID
    Number txnsId    = (Number)params.get("TxnsId");
    // 数量
    String quantity  = (String)params.get("Quantity");
    // 受入返品数量
    String rcvRtnQuantity = (String)params.get("RcvRtnQuantity");
    // 明細摘要
    String lineDescription  = (String)params.get("LineDescription");

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" BEGIN "                                                         );
    sb.append("   UPDATE xxpo_rcv_and_rtn_txns rart "                           );
    sb.append("   SET rart.quantity          = :1 "                             );  // 数量  
    sb.append("      ,rart.rcv_rtn_quantity  = :2 "                             );  // 受入返品数量
    sb.append("      ,rart.line_description  = :3 "                             );  // 明細摘要
// 2008-10-22 H.Itou Del Start 変更要求＃217
//    sb.append("      ,rart.created_by        = FND_GLOBAL.USER_ID "             );  // 作成者          
//    sb.append("      ,rart.creation_date     = SYSDATE "                        );  // 作成日          
// 2008-10-22 H.Itou Del End
    sb.append("      ,rart.last_updated_by   = FND_GLOBAL.USER_ID"              );  // 最終更新者      
    sb.append("      ,rart.last_update_date  = SYSDATE "                        );  // 最終更新日      
    sb.append("      ,rart.last_update_login = FND_GLOBAL.LOGIN_ID "            );  // 最終更新ログイン
    sb.append("   WHERE rart.txns_id = :4; "                                    );  // 取引ID
    sb.append(" END; "                                                          );
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setDouble(1, Double.parseDouble(quantity));         // 数量
      cstmt.setDouble(2, Double.parseDouble(rcvRtnQuantity));   // 受入返品数量
      cstmt.setString(3, lineDescription);                      // 明細摘要
      cstmt.setInt(4, XxcmnUtility.intValue(txnsId));           // 取引先ID
      
      //PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {

      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
          rollBack(trans);
          XxcmnUtility.writeLog(trans,
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
    
    return XxcmnConstants.RETURN_SUCCESS;
    
  } // updateRcvAndRtnTxns

  /*****************************************************************************
   * 受注明細アドオンの明細行を論理削除します。
   * @param trans        - トランザクション
   * @param orderLineId  - 受注明細アドオンID
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void deleteOrderLine(
    OADBTransaction trans,
    Number orderLineId
    ) throws OAException
  {
    String apiName = "deleteOrderLine";
  
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    // 明細行の削除フラグを更新します。
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_lines_all xola   "); // 受注明細アドオン
    sb.append("  SET    xola.delete_flag       = 'Y' ");                 // 削除フラグ
    sb.append("        ,xola.last_updated_by   = FND_GLOBAL.USER_ID ");  // 最終更新者
    sb.append("        ,xola.last_update_date  = SYSDATE ");             // 最終更新日
    sb.append("        ,xola.last_update_login = FND_GLOBAL.LOGIN_ID "); // 最終更新ログイン
    sb.append("  WHERE  xola.order_Line_id   = :1;  ");                  // 発注明細アドオンID
    sb.append("END; ");
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1,  XxcmnUtility.intValue(orderLineId)); // 受注明細アドオンID
      //PL/SQL実行
      cstmt.execute();
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // deleteOrderLine

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
      if (cstmt.getInt(1) == 1) 
      {
        // ロールバック
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              "戻り値がエラーで返りました。",
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
      
      // 戻り値取得
      oprtnDate = new Date(cstmt.getDate(6));

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return oprtnDate;
  } // getOprtnDay

  /*****************************************************************************
   * 代表運送会社から運送業者の算出を行います。
   * @param trans - トランザクション
   * @param frequentMover - 代表運送会社
   * @param freightId     - 運送業者ID
   * @param freightCode   - 運送業者コード
   * @param freightName   - 運送業社名
   * @param originalDate  - 基準日(Nullの場合SYSDATE)
   * @return HashMap - 戻り値群
   * @throws OAException OA例外
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

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  SELECT xcv.party_id         party_id     "); // 運送業者ID(パーティーID)
    sb.append("        ,xcv.party_number     party_number "); // 運送業者コード(組織番号)
    sb.append("        ,xcv.party_short_name party_name   "); // 運送業者名(略称)
    sb.append("  INTO   :1 ");
    sb.append("        ,:2 ");
    sb.append("        ,:3 ");
    sb.append("  FROM   xxcmn_carriers2_v xcv "); // 運送業者情報VIEW
    sb.append("  WHERE  TRUNC(NVL(:4, SYSDATE)) BETWEEN xcv.start_date_active ");
    sb.append("                                 AND     xcv.end_date_active   ");
    sb.append("  AND    xcv.party_number = :5; ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      int i = 1;
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(i++, Types.INTEGER); // 運送業者ID
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 運送業者コード
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 運送業者名

      // パラメータ設定(INパラメータ)
      cstmt.setDate(i++, originalDate.dateValue());  // 基準日
      cstmt.setString(i++, frequentMover); // 代表運送会社

      // PL/SQL実行
      cstmt.execute();
      // 戻り値取得
      Number retFreightId   = new Number(cstmt.getInt(1));
      String retFreightCode = cstmt.getString(2);
      String retFreightName = cstmt.getString(3);
      HashMap paramsRet = new HashMap();
      paramsRet.put("freightId",   retFreightId); 
      paramsRet.put("freightCode", retFreightCode);
      paramsRet.put("freightName", retFreightName);
      return paramsRet;
      
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ログに出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーにせず戻り値にすべてnullをセットして戻す。
      HashMap paramsRet = new HashMap();
      paramsRet.put("freightId",   null); 
      paramsRet.put("freightCode", null);
      paramsRet.put("freightName", null);
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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getfreightData

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
// 2008-07-29 D.Nihei MOD START
//    // リーフ・重量の場合
//    sb.append("  IF (('1' = lv_prod_class) AND ('1' = lv_weight_capacity_class)) THEN ");
    // リーフの場合
    sb.append("  IF ( '1' = lv_prod_class ) THEN ");
// 2008-07-29 D.Nihei MOD END
    sb.append("    ln_deadweight := ln_leaf_deadweight; ");
// 2008-07-29 D.Nihei DEL START
//    // リーフ・容積の場合
//    sb.append("  ELSIF (('1' = lv_prod_class) AND ('2' = lv_weight_capacity_class)) THEN ");
// 2008-07-29 D.Nihei DEL END
    sb.append("    ln_loading_capacity := ln_leaf_loading_capacity; ");
// 2008-07-29 D.Nihei MOD START
//    // ドリンク・重量の場合
//    sb.append("  ELSIF (('2' = lv_prod_class) AND ('1' = lv_weight_capacity_class)) THEN ");
    // ドリンクの場合
    sb.append("  ELSIF ('2' = lv_prod_class ) THEN ");
// 2008-07-29 D.Nihei MOD END
    sb.append("    ln_deadweight := ln_drink_deadweight; ");
// 2008-07-29 D.Nihei DEL START
//    // ドリンク・容積の場合
//    sb.append("  ELSIF (('2' = lv_prod_class) AND ('2' = lv_weight_capacity_class)) THEN ");
// 2008-07-29 D.Nihei DEL END
    sb.append("    ln_loading_capacity := ln_leaf_loading_capacity; ");
    // それ以外
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
      cstmt.setDate(i++, originalDate.dateValue()); // 基準日

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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getMaxShipMethod

  /*****************************************************************************
   * 発生区分から発注自動作成区分を取得します。
   * @param trans - トランザクション
   * @param orderTypeId - 発生区分
   * @return String - 発注自動作成区分
   * @throws OAException OA例外
   ****************************************************************************/
  public static String getAutoCreatePoClass(
    OADBTransaction trans,
    Number orderTypeId
  ) throws OAException
  {
    String apiName   = "getAutoCreatePoClass";

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  SELECT xottv.auto_create_po_class "); // 発注自動作成区分
    sb.append("  INTO   :1 ");
    sb.append("  FROM   xxwsh_oe_transaction_types_v xottv "); // 受注タイプ情報VIEW
    sb.append("  WHERE  xottv.transaction_type_id = :2; ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      int i = 1;
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 発注自動作成区分

      // パラメータ設定(INパラメータ)
      cstmt.setInt(i++, orderTypeId.intValue());  // 発生区分

      // PL/SQL実行
      cstmt.execute();

      return cstmt.getString(1);
      
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログに出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getAutoCreatePoClass

  /*****************************************************************************
   * シーケンスから受注ヘッダアドオンIDを取得します。
   * @param trans - トランザクション
   * @return Number - 受注ヘッダアドオンID
   * @throws OAException OA例外
   ****************************************************************************/
  public static Number getOrderHeaderId(
    OADBTransaction trans
    ) throws OAException
  {

    return XxcmnUtility.getSeq(trans, XxpoConstants.XXWSH_ORDER_HEADERS_ALL_S1);

  } // getOrderHeaderId

  /*****************************************************************************
   * 配車関連情報を導出します。
   * @param trans - トランザクション
   * @param orderHeaderId - 受注ヘッダアドオンID
   * @return HashMap - 戻り値群
   * @throws OAException OA例外
   ****************************************************************************/
  public static HashMap getCarriersData(
    OADBTransaction trans,
    Number orderHeaderId
  ) throws OAException
  {
    String apiName   = "getCarriersData";

    // PL/SQLの作成を行います
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
    sb.append("               END)    small_quantity ");   // 小口個数
// 2008-07-29 D.Nihei Mod Start
//    sb.append("        ,TO_CHAR(SUM(xola.quantity),   'FM999,999,990.000') sum_quantity ");   // 合計数量
//    sb.append("        ,TO_CHAR(SUM(NVL(xola.weight  , 0)), 'FM9,999,990') sum_weight   ");   // 合計重量
//    sb.append("        ,TO_CHAR(SUM(NVL(xola.capacity, 0)), 'FM9,999,990') sum_capacity ");   // 合計容積
    sb.append("        ,TO_CHAR(SUM(xola.quantity))         sum_quantity ");   // 合計数量
    sb.append("        ,TO_CHAR(SUM(NVL(xola.weight  , 0))) sum_weight   ");   // 合計重量
    sb.append("        ,TO_CHAR(SUM(NVL(xola.capacity, 0))) sum_capacity ");   // 合計容積
// 2008-07-29 D.Nihei Mod End
    sb.append("  INTO   :1 "); 
    sb.append("        ,:2 "); 
    sb.append("        ,:3 "); 
    sb.append("        ,:4 "); 
    sb.append("  FROM   xxwsh_order_lines_all   xola ");  // 受注明細アドオン 
    sb.append("        ,xxcmn_item_mst_v        ximv ");  // OPM品目情報VIEW 
    sb.append("  WHERE xola.shipping_inventory_item_id = ximv.inventory_item_id "); 
    sb.append("  AND   xola.delete_flag                = 'N' "); 
    sb.append("  AND   xola.order_header_id            = :5  "); 
    sb.append("  GROUP BY xola.order_header_id; "); 
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      int i = 1;
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(i++, Types.NUMERIC); // 小口個数
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 合計数量
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 合計重量
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 合計容積

      // パラメータ設定(INパラメータ)
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId)); // 受注明細アドオンID

      // PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      Number smallQuantity = new Number(cstmt.getObject(1));
      String sumQuantity   = cstmt.getString(2);
      String sumWeight     = cstmt.getString(3);
      String sumCapacity   = cstmt.getString(4);

      HashMap paramsRet = new HashMap();
      paramsRet.put("smallQuantity", smallQuantity);
      paramsRet.put("labelQuantity", smallQuantity); // 小口個数と同値をセット
      paramsRet.put("sumQuantity",   sumQuantity);
      paramsRet.put("sumWeight",     sumWeight);
      paramsRet.put("sumCapacity",   sumCapacity);

      return paramsRet;
      
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ログに出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーにせず戻り値にすべてnullをセットして戻す。
      HashMap paramsRet = new HashMap();
      paramsRet.put("smallQuantity", null);
      paramsRet.put("labelQuantity", null);
      paramsRet.put("sumQuantity",   null);
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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getCarriersData

  /*****************************************************************************
   * 全数入出庫時の入出庫実績を作成します。
   * @param  trans - トランザクション
   * @param  orderHeaderId - 受注ヘッダアドオンID
   * @param  recordTypeCode - レコードタイプ(20：出庫実績、30：入庫実績) 
   * @param  actualDate - 実績日(入庫日・出庫日)
   * @return 処理フラグ true：処理実行、false：処理未実行
   * @throws OAException - OA例外
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

    //PL/SQLの作成を取得を行います
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN ");
    sb.append("  :1 := xxpo_common2_pkg.update_order_data( ");
    sb.append("           in_order_header_id   => :2    "); // 受注ヘッダアドオンID
    sb.append("          ,iv_record_type_code  => :3    "); // レコードタイプ(20：出庫実績、30：入庫実績) 
    sb.append("          ,id_actual_date       => :4    "); // 実績日(入庫日・出庫日)
    sb.append("          ,in_created_by        => FND_GLOBAL.USER_ID "); // 作成者
    sb.append("          ,id_creation_date     => SYSDATE "); // 作成日
    sb.append("          ,in_last_updated_by   => FND_GLOBAL.USER_ID "); // 最終更新者
    sb.append("          ,id_last_update_date  => SYSDATE "); // 最終更新日 
    sb.append("          ,in_last_update_login => FND_GLOBAL.LOGIN_ID "); // 最終更新ログイン 
    sb.append("        ); ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      //PL/SQLを実行します
      int i = 1;
      cstmt.registerOutParameter(i++, Types.INTEGER);
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));
      cstmt.setString(i++, recordTypeCode);
      cstmt.setDate(i++, XxcmnUtility.dateValue(actualDate));
      cstmt.execute();

      //戻り値の取得
      int retCode = cstmt.getInt(1);
      if (retCode == 0) 
      { // 正常終了の場合
        exeType = true;
      } else 
      { // 異常終了の場合
        // ロールバック
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              "異常終了",
                              6);
        //トークン生成
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                   "全数処理") };
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                               XxcmnConstants.XXCMN05002, 
                               tokens);
      }
    } catch(SQLException s)
    {
      // ロールバック
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
        //処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
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
   * 価格表から単価を取得します。
   * @param inventoryItemId - INV品目ID
   * @param listIdVendor - 取引先別価格表ID
   * @param listIdRepresent - 代表価格表ID
   * @param arrivalDate - 適用日(入庫日)
   * @param itemNo - 品目コード
   * @return Number - 単価 取得できない場合はNullを返却
   * @throws OAException - OA例外
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
    String apiName = "getUnitPrice";  // API名
    Integer unitPrice;                // 単価

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  ln_unit_price NUMBER; ");
    sb.append("BEGIN ");
    sb.append("  ln_unit_price := xxpo_common2_pkg.get_unit_price( ");
    sb.append("                     :1, :2, :3, :4); ");
    sb.append("  :5 := ln_unit_price; ");
    sb.append("END; ");

    // PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try 
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1, XxcmnUtility.intValue(inventoryItemId));  // INV品目ID
      cstmt.setString(2, listIdVendor);     // 取引先価格表ID
      cstmt.setString(3, listIdRepresent);  // 代表価格表ID
      cstmt.setDate(4, XxcmnUtility.dateValue(arrivalDate));    // 適用日(入庫日)

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(5, Types.NUMERIC);             // 単価

      // PL/SQL実行
      cstmt.execute();

      // 単価チェック
      if (XxcmnUtility.isBlankOrNull(cstmt.getObject(5))) 
      {
        return null;
      }

      // 単価返却
      return new Number(cstmt.getObject(5));

    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);

      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getUnitPrice

  /*****************************************************************************
   * 価格表の単価で受注明細アドオンの単価を更新します。
   * @param orderHeaderId - 受注ヘッダアドオンID
   * @param listIdVendor - 取引先別価格表ID
   * @param listIdRepresent - 代表価格表ID
   * @param arrivalDate - 適用日(入庫日)
   * @param returnFlag - 返品フラグ Y:返品、Null:返品以外
   * @param itemClassCode - 品目区分
   * @param itemNo - 品目コード
   * @return String - エラーメッセージ(品目No) 正常終了の場合はNull
   * @throws OAException - OA例外
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

    // PL/SQLの作成を行います。
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

    // PL/SQLの設定を行います。
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1, XxcmnUtility.intValue(orderHeaderId));    // 受注ヘッダアドオンID
      cstmt.setString(2, listIdVendor);     // 取引先別価格表ID
      cstmt.setString(3, listIdRepresent);  // 代表価格表ID
      cstmt.setDate(4, XxcmnUtility.dateValue(arrivalDate));    // 適用日(入庫日)
      cstmt.setString(5, returnFlag);                           // 返品フラグ
      cstmt.setString(6, itemClassCode);                        // 品目区分
      cstmt.setString(7, itemNo);                               // 品目コード

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter( 8, Types.VARCHAR, 1);         // ステータスコード
      cstmt.registerOutParameter( 9, Types.VARCHAR, 5000);      // エラーメッセージ
      cstmt.registerOutParameter(10, Types.VARCHAR, 5000);      // システムメッセージ

      // PL/SQL実行
      cstmt.execute();

      // 実行結果格納
      String retCode   = cstmt.getString(8);  //リターンコード
      String errMsg    = cstmt.getString(9);   //エラーメッセージ
      String systemMsg = cstmt.getString(10); //システムメッセージ

      if (XxcmnConstants.API_RETURN_ERROR.equals(retCode))
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(10),
                              6);
        // 更新失敗エラーメッセージ
        return errMsg;
      }

    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);

      }
    }
    return null;
  } // updateUnitPrice

  /*****************************************************************************
   * 移動ロット詳細のロットステータスチェックを行います。
   * @param requestNo - 依頼No
   * @throws OAException  - OA例外
   ****************************************************************************/
  public static boolean chkLotStatus(
    OADBTransaction trans,
    String requestNo
    ) throws OAException
  {
    String apiName = "chkLotStatus";
    boolean retFlag = false;

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "  );
    sb.append("  SELECT COUNT(1) ");
    sb.append("  INTO   :1 ");
    sb.append("  FROM   xxcmn_lot_status_v       xlsv "); // ロットステータス共通VIEW
    sb.append("        ,ic_lots_mst              ilm  "); // OPMロットマスタ
    sb.append("        ,xxwsh_order_headers_all  xoha "); // 受注ヘッダアドオン
    sb.append("        ,xxwsh_order_lines_all    xola "); // 受注明細アドオン
    sb.append("        ,xxinv_mov_lot_details    xmld "); // 移動ロット詳細(アドオン)
    sb.append("        ,xxcmn_item_categories5_v xicv "); // OPM品目カテゴリ情報VIEW5
    sb.append("  WHERE  xoha.request_no         = :2  ");
    sb.append("  AND    xola.order_header_id    = xoha.order_header_id ");
    sb.append("  AND    xmld.mov_line_id        = xola.order_line_id   ");
    sb.append("  AND    xicv.item_id            = xmld.item_id ");
    sb.append("  AND    xicv.item_class_code   IN ('1', '4', '5') "); // 原料、半製品、製品
    sb.append("  AND    xmld.document_type_code = '30'   "); // 支給指示
    sb.append("  AND    xmld.record_type_code   = '10'   "); // 指示
    sb.append("  AND    ilm.item_id             = xmld.item_id ");
    sb.append("  AND    ilm.lot_id              = xmld.lot_id ");
    sb.append("  AND    ilm.lot_no              = xmld.lot_no ");
    sb.append("  AND    xlsv.lot_status         = ilm.attribute23 ");
    sb.append("  AND    xlsv.prod_class_code    = xoha.prod_class ");
    sb.append("  AND    xlsv.pay_provision_rel  = 'N' ");
    sb.append("  AND    ROWNUM = 1;  ");
    sb.append("END; ");
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      //バインド変数に値をセット
      cstmt.registerOutParameter(1,Types.INTEGER);
      cstmt.setString(2, requestNo); // 依頼No
      //PL/SQL実行
      cstmt.execute();
      // パラメータの取得
      int cnt = cstmt.getInt(1);
      if(cnt == 0)
      {
        retFlag = true; 
      } 
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // chkLotStatus

  /*****************************************************************************
   * 自倉庫のカウントを取得します。
   * @param trans トランザクション
   * @return int 自倉庫のカウント
   * @throws OAException OA例外
   ****************************************************************************/
  public static int getWarehouseCount(
    OADBTransaction trans
  ) throws OAException
  {
    String apiName  = "getWarehouseCount"; // API名

    int warehouseCount = 0;  // 戻り値用

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" BEGIN "                                                          );
    sb.append("   SELECT COUNT(1) "                                              ); // 保管倉庫コード
    sb.append("   INTO   :1 "                                                    );
    sb.append("   FROM fnd_user      fu "                                        ); // ユーザマスタ
    sb.append("       ,per_all_people_f papf "                                   );
    sb.append("       ,xxcmn_item_locations_v xilv "                             ); // OPM保管場所情報VIEW
    sb.append("   WHERE fu.employee_id              = papf.person_id "            );
    sb.append("     AND fu.start_date <= TRUNC(SYSDATE) "                        ); // 適用開始日
    sb.append("     AND ((fu.end_date IS NULL) OR (fu.end_date >= TRUNC(SYSDATE))) " ); // 適用終了日
    sb.append("     AND papf.effective_start_date <= TRUNC(SYSDATE) "            ); // 適用開始日
    sb.append("     AND papf.effective_end_date   >= TRUNC(SYSDATE) "            ); // 適用終了日
    sb.append("     AND papf.ATTRIBUTE4 = xilv.PURCHASE_CODE "                   );
    sb.append("     AND fu.user_id                 = FND_GLOBAL.USER_ID; "       );
    sb.append(" END; "                                                           );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.INTEGER); // カウント
      
      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      warehouseCount = cstmt.getInt(1);

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {

      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
      rollBack(trans);
      // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return warehouseCount;
  } // getWarehouseCount

  /*****************************************************************************
   * 自倉庫情報を取得します。
   * @param trans トランザクション
   * @return HashMap 自倉庫情報
   * @throws OAException OA例外
   ****************************************************************************/
  public static HashMap getWarehouse(
    OADBTransaction trans
  ) throws OAException
  {
    String apiName  = "getWarehouse"; // API名

    HashMap retHashMap = new HashMap();  // 戻り値用

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" BEGIN "                                                          );
    sb.append("   SELECT xilv.segment1 "                                         ); // 保管倉庫コード
    sb.append("         ,xilv.description "                                      ); // 保管倉庫名
    sb.append("   INTO   :1 "                                                    );
    sb.append("         ,:2 "                                                    );
    sb.append("   FROM fnd_user      fu "                                        ); // ユーザマスタ
    sb.append("       ,per_all_people_f papf "                                   );
    sb.append("       ,xxcmn_item_locations_v xilv "                             ); // OPM保管場所情報VIEW
    sb.append("   WHERE fu.employee_id              = papf.person_id "            );   
    sb.append("     AND fu.start_date <= TRUNC(SYSDATE) "                        ); // 適用開始日
    sb.append("     AND ((fu.end_date IS NULL) OR (fu.end_date >= TRUNC(SYSDATE))) " ); // 適用終了日
    sb.append("     AND papf.effective_start_date <= TRUNC(SYSDATE) "            ); // 適用開始日
    sb.append("     AND papf.effective_end_date   >= TRUNC(SYSDATE) "            ); // 適用終了日  
    sb.append("     AND papf.attribute4 = xilv.purchase_code "                   );
    sb.append("     AND fu.user_id                 = FND_GLOBAL.USER_ID; "       );
    sb.append(" END; "                                                           );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR); // 保管倉庫コード
      cstmt.registerOutParameter(2, Types.VARCHAR); // 保管倉庫名
      
      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      retHashMap.put("LocationCode", cstmt.getString(1));
      retHashMap.put("LocationName", cstmt.getString(2));


    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
      rollBack(trans);
      // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // getWarehouse

  /*****************************************************************************
   * 受入実績(アドオン)に対する該当元文書番号/元文書明細番号の存在チェックを行います。
   * @param trans トランザクション
   * @param headerNumber 発注番号
   * @return String XxcmnConstants.STRING_N：データ無し
   *                 XxcmnConstants.STRING_Y：データ有り
   * @throws OAException OA例外
   ****************************************************************************/
  public static String chkRcvAndRtnTxnsInput(
    OADBTransaction trans,
    String headerNumber
  ) throws OAException
  {
    String apiName  = "chkRcvAndRtnTxnsInput"; // API名

    int rcvAndRtnTxnsCount = 0;  
    String checkFlag = XxcmnConstants.STRING_N; // 戻り値用

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" BEGIN "                                     );
    sb.append("   SELECT COUNT(1) "                         );
    sb.append("   INTO   :1 "                               );
    sb.append("   FROM xxpo_rcv_and_rtn_txns rart "         );
    sb.append("   WHERE rart.source_document_number = :2; " );
    sb.append(" END; "                                      );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.INTEGER); // カウント

      //バインド変数に値をセット
      cstmt.setString(2, headerNumber);             // 発注番号

      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      rcvAndRtnTxnsCount = cstmt.getInt(1);

      if (rcvAndRtnTxnsCount > 0)
      {
        checkFlag = XxcmnConstants.STRING_Y;
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {

      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
      rollBack(trans);
      // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return checkFlag;
  } // chkRcvAndRtnTxnsInput

  /*****************************************************************************
   * 支給指示からの発注自動作成関数を呼び出します。
   * @param reqNo   - 依頼No/移動番号
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void provAutoPurchaseOrders(
    OADBTransaction trans,
    String reqNo
  ) throws OAException
  {
    String apiName = "provAutoPurchaseOrders";  // API名

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  xxpo_common925_pkg.auto_purchase_orders(:1, :2, :3, :4, :5); ");
    sb.append("END; ");

    // PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try 
    {

      // パラメータ設定(INパラメータ)
      cstmt.setString(1, reqNo);   // 依頼No/移動番号

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(2, Types.VARCHAR); // リターン・コード
      cstmt.registerOutParameter(3, Types.NUMERIC); // バッチID
      cstmt.registerOutParameter(4, Types.VARCHAR); // エラー・メッセージ・コード
      cstmt.registerOutParameter(5, Types.VARCHAR); // ユーザー・エラー・メッセージ

      // PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      String retCode    = cstmt.getString(2);
      Object retBatchId = cstmt.getObject(3);
      
      // 戻り値が処理成功以外はログにエラーメッセージを出力
      if (XxcmnConstants.API_RETURN_NORMAL.equals(retCode) 
      && !XxcmnUtility.isBlankOrNull(retBatchId)) 
      {
        Number batchId = new Number(retBatchId);
        // コミット発行
        commit(trans);
        // 標準発注インポートを呼び出す
        provImportStandardPurchaseOrders(trans, batchId);

      } else
      {
        // ロールバック
        rollBack(trans);
        String errMsg = cstmt.getString(5);
        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              errMsg,
                              6);
        // エラーメッセージ出力
        XxcmnUtility.putErrorMessage("支給指示からの発注自動作成");

      }
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);

      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);

      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);

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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // provAutoPurchaseOrders

  /*****************************************************************************
   * 支給指示用コンカレント：標準発注インポートを発行します。
   * @param trans - トランザクション
   * @param batchId - バッチID
   * @return String - XxcmnConstants.RETURN_SUCCESS:1 正常
   *                  XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException - OA例外
   ****************************************************************************/
  public static void provImportStandardPurchaseOrders(
    OADBTransaction trans,
    Number batchId
  ) throws OAException
  {
    String apiName = "provImportStandardPurchaseOrders";

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "   );
    sb.append("  ln_request_id NUMBER; "                                             );
    sb.append("BEGIN "                                                               );
                 // 標準発注インポート(コンカレント)呼び出し
    sb.append("  ln_request_id := fnd_request.submit_request( "                      );
    sb.append("     application  => 'PO' "                                           ); // アプリケーション名
    sb.append("    ,program      => 'POXPOPDOI' "                                    ); // プログラム短縮名
    sb.append("    ,argument1    => NULL "                                           ); // 購買担当ID
    sb.append("    ,argument2    => 'STANDARD' "                                     ); // 文書タイプ
    sb.append("    ,argument3    => NULL "                                           ); // 文書サブタイプ
    sb.append("    ,argument4    => 'N' "                                            ); // 品目の作成 N:行わない
    sb.append("    ,argument5    => NULL "                                           ); // ソース・ルールの作成
    sb.append("    ,argument6    => 'APPROVED' "                                     ); // 承認ステータス APPROVAL:承認
    sb.append("    ,argument7    => NULL "                                           ); // リリース生成方法
    sb.append("    ,argument8    => TO_CHAR(:1) "                                    ); // バッチID
    sb.append("    ,argument9    => NULL "                                           ); // 営業単位
    sb.append("    ,argument10   => NULL); "                                         ); // グローバル契約
                 // 要求IDがある場合、正常
    sb.append("  IF ln_request_id > 0 THEN "                                         );
    sb.append("    :2 := '1'; "                                                      ); // 1:正常終了
    sb.append("    :3 := ln_request_id; "                                            ); // 要求ID
    sb.append("    COMMIT; "                                                         );
                 // 要求IDがない場合、異常
    sb.append("  ELSE "                                                              );
    sb.append("    :2 := '0'; "                                                      ); // 0:異常終了
    sb.append("    :3 := ln_request_id; "                                            ); // 要求ID
    sb.append("    ROLLBACK; "                                                       );
    sb.append("  END IF; "                                                           );
    sb.append("END; "                                                                );

    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setBigDecimal(1, XxcmnUtility.bigDecimalValue(batchId)); // バッチID
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(2, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(3, Types.INTEGER);   // 要求ID
      
      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      String retFlag = cstmt.getString(2); // リターンコード
      int requestId  = cstmt.getInt(3); // 要求ID

      // 正常終了の場合
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // リターンコード正常をセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        
      // 正常終了でない場合、エラー  
      } else
      {
        //トークン生成
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PRG_NAME,
                                                   "標準発注インポート") };
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10025, 
                              tokens);

      }
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
          rollBack(trans);
          XxcmnUtility.writeLog(trans,
                                XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
  } // provImportStandardPurchaseOrders 

  /*****************************************************************************
   * コンカレント：仕入実績作成処理を発行します。
   * @param trans トランザクション
   * @param headerNumber 発注番号
   * @return String XxcmnConstants.RETURN_SUCCESS:1 正常
   *                   XxcmnConstants.RETURN_NOT_EXE:0 異常
   * @throws OAException OA例外
   ****************************************************************************/
  public static String doStockResultMake(
    OADBTransaction trans,
    String headerNumber
  ) throws OAException
  {
    String apiName      = "doStockResultMake";


    // OUTパラメータ用
    String retFlag = XxcmnConstants.RETURN_NOT_EXE; // 戻り値

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "   );
    sb.append("  ln_request_id NUMBER; "                                       );
    sb.append("BEGIN "                                                         );
                 // 直送仕入・出荷実績作成処理(コンカレント)呼び出し
    sb.append("  ln_request_id := FND_REQUEST.SUBMIT_REQUEST( "                );
    sb.append("     application  => 'XXPO' "                                   ); // アプリケーション名
    sb.append("    ,program      => 'XXPO310001C' "                            ); // プログラム短縮名
    sb.append("    ,argument1    => :1 ); "                                    ); // 発注No.
                 // 要求IDがある場合、正常
    sb.append("  IF ln_request_id > 0 THEN "                                   );
    sb.append("    :2 := '1'; "                                                ); // 1:正常終了
    sb.append("    :3 := ln_request_id; "                                      ); // 要求ID
                 // 要求IDがない場合、異常
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
      cstmt.setString(1, headerNumber);               // 発注番号
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(2, Types.VARCHAR);   // リターンコード
      cstmt.registerOutParameter(3, Types.INTEGER);   // 要求ID

      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      retFlag = cstmt.getString(2); // リターンコード
      int requestId = cstmt.getInt(3); // 要求ID

      // 正常終了の場合
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // リターンコード正常をセット
        retFlag = XxcmnConstants.RETURN_SUCCESS;
        
      // 正常終了でない場合、エラー  
      } else
      {
        // リターンコード異常をセット
        retFlag = XxcmnConstants.RETURN_NOT_EXE;

      }
      
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }

    return retFlag;
  } // doStockResultMake.

  /*****************************************************************************
   * 受注ヘッダに紐付く明細が全て引当済かチェックを行います。
   * @param trans トランザクション
   * @param orderHeaderId - 受注ヘッダアドオンID
   * @return boolean - true：全て引当済。false:未引当有り
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean chkAllOrderReserved(
    OADBTransaction trans,
    Number orderHeaderId
  ) throws OAException
  {
    String apiName = "chkAllOrderReserved";
    boolean retFlag = false; // 戻り値
    
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("SELECT COUNT(1)  ");
    sb.append("INTO   :1 ");
    sb.append("FROM   xxwsh_order_lines_all  xola     "); // 受注明細アドオン
    sb.append("WHERE  xola.order_header_id   = :2     ");
    sb.append("AND    xola.reserved_quantity IS NULL  ");
    sb.append("AND    xola.delete_flag       = 'N'    ");
    sb.append("AND    ROWNUM = 1;  ");
    sb.append("END; ");
     
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

     try
    {
      //バインド変数に値をセット
      cstmt.registerOutParameter(1,Types.INTEGER);
      cstmt.setInt(2,XxcmnUtility.intValue(orderHeaderId));

      // PL/SQL実行
      cstmt.execute();

      // パラメータの取得
      int cnt = cstmt.getInt(1);
      if(cnt == 0)
      {
        retFlag = true; 
      } 

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retFlag;
  } // chkAllOrderReserved

  /*****************************************************************************
   * 合計数量・合計容積を算出します。
   * @param itemNo   - 品目コード
   * @param quantity - 数量
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
      String retCode   = cstmt.getString(3);  // リターンコード
      String errMsg    = cstmt.getString(4);  // エラーメッセージ
      String systemMsg = cstmt.getString(5);  // システムメッセージ
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
      retHashMap.put("sumWeight",       sumWeight);
      retHashMap.put("sumCapacity",     sumCapacity);
      retHashMap.put("sumPalletWeight", sumPalletWeight);

      // エラーの場合
      if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {
        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              errMsg + systemMsg,
                              6);
      }
      return retHashMap; 
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);

      }
    }
  } // calcTotalValue

  /*****************************************************************************
   * 受注明細の入数/適用を更新します。
   * @param trans トランザクション
   * @param params パラメータ
   * @throws OAException OA例外
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
    
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" BEGIN "                                                         );
    sb.append("   UPDATE po_lines_all pla "                                     );
    sb.append("   SET pla.attribute4        = :1 "                              ); // 在庫入数
    sb.append("      ,pla.attribute15       = :2 "                              ); // 摘要
    sb.append("      ,pla.last_updated_by   = FND_GLOBAL.USER_ID "              ); // 最終更新者
    sb.append("      ,pla.last_update_date  = SYSDATE "                         ); // 最終更新日
    sb.append("      ,pla.last_update_login = FND_GLOBAL.LOGIN_ID "             ); // 最終更新ログイン
    sb.append("   WHERE pla.po_line_id = :3; "                                  );
    sb.append(" END; "                                                          );
    
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, itemAmount);    // 在庫入数
      cstmt.setString(2, description);   // 摘要
      cstmt.setInt(3,    XxcmnUtility.intValue(lineId)); // 発注明細ID
      
      //PL/SQL実行
      cstmt.execute();
    
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }

  } // updateItemAmount
  /*****************************************************************************
   * 受注明細アドオンの各種数量、重量、容積をサマリーして返します。
   * @param orderHeaderId - 受注ヘッダアドオンID
   * @return HashMap  - 戻り値群
   * @throws OAException - OA例外
   ****************************************************************************/
  public static HashMap getSummaryDataOrderLine(
    OADBTransaction trans,
    Number orderHeaderId
  ) throws  OAException
  {
    String apiName = "getSummaryDataOrderLine";

    HashMap retHashMap = new HashMap(); // 戻り値

    // PL/SQLの作成を行います。
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  SELECT TO_CHAR(SUM(NVL(xola.quantity,0))) quantity"); // 数量
    sb.append("        ,TO_CHAR(SUM(NVL(xola.shipped_quantity,0))) shipped_quantity"); // 出荷実績数量
    sb.append("        ,TO_CHAR(SUM(NVL(xola.ship_to_quantity,0))) ship_to_quantity"); // 入庫実績数量
    sb.append("        ,TO_CHAR(SUM(NVL(xola.based_request_quantity,0))) based_request_quantity"); // 拠点依頼数量
    sb.append("        ,TO_CHAR(SUM(NVL(xola.weight,0))) weight"); // 重量
    sb.append("        ,TO_CHAR(SUM(NVL(xola.capacity,0))) capacity"); // 容積
    sb.append("        ,TO_CHAR(SUM(NVL(xola.pallet_quantity,0))) pallet_quantity"); // パレット数
    sb.append("        ,TO_CHAR(SUM(NVL(xola.layer_quantity,0))) layer_quantity"); // 段数
    sb.append("        ,TO_CHAR(SUM(NVL(xola.case_quantity,0))) case_quantity");  // ケース数
    sb.append("        ,TO_CHAR(SUM(NVL(xola.pallet_qty,0))) pallet_qty"); // パレット枚数
    sb.append("        ,TO_CHAR(SUM(NVL(xola.pallet_weight,0))) pallet_weight"); // パレット重量
    sb.append("        ,TO_CHAR(SUM(NVL(xola.reserved_quantity,0))) reserved_quantity"); // 引当数
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
    sb.append("  AND xola.delete_flag = 'N' ");                     // 削除フラグ(未削除)
    sb.append("  GROUP BY xola.request_no; ");
    sb.append("END; ");

    // PL/SQLの設定を行います。
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try 
    {
      int i = 1;

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // 数量
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // 出荷実績数量
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // 入庫実績数量
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // 拠点依頼数量
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // 重量
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // 容積
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // パレット数
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // 段数
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // ケース数
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // パレット枚数
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // パレット重量
      cstmt.registerOutParameter(i++, Types.VARCHAR);     // 引当数
      // パラメータ設定(INパラメータ)
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));

      // PL/SQL実行
      cstmt.execute();
      // 実行結果格納
      i = 1;
      String sumQuantity = cstmt.getString(i++);             // 数量
      String sumShippedQuantity = cstmt.getString(i++);      // 出荷実績数量
      String sumShipToQuantity = cstmt.getString(i++);       // 入庫実績数量
      String sumBasedRequestQuantity = cstmt.getString(i++); // 拠点依頼数量
      String sumWeight = cstmt.getString(i++);               // 重量
      String sumCapacity = cstmt.getString(i++);             // 容積
      String sumPalletQuantity = cstmt.getString(i++);       // パレット数
      String sumLayerQuantity = cstmt.getString(i++);        // 段数
      String sumCaseQuantity = cstmt.getString(i++);         // ケース数
      String sumPalletQty = cstmt.getString(i++);            // パレット枚数
      String sumPalletWeight = cstmt.getString(i++);         // パレット重量
      String sumReservedQuantity = cstmt.getString(i++);     // 引当数

      // 戻り値設定
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
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
        
      }
    }
  } // getSummaryDataOrderLine

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
   * @param checkFlag     - チェック実施フラグ true:実施、false:算出のみ
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
    boolean checkFlag
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
    sb.append("   ,iv_prod_class                 => FND_PROFILE.VALUE('XXCMN_ITEM_DIV_SECURITY') "); // 8.商品区分
    sb.append("   ,iv_auto_process_type          => null  "); // 9.自動配車対象区分
    sb.append("   ,id_standard_date              => :8  "); // 10.基準日(適用日基準日)
    sb.append("   ,ov_retcode                    => :9  "); // 11.リターンコード
    sb.append("   ,ov_errmsg_code                => :10 "); // 12.エラーメッセージコード
    sb.append("   ,ov_errmsg                     => :11 "); // 13.エラーメッセージ
    sb.append("   ,ov_loading_over_class         => :12 "); // 14.積載オーバー区分
    sb.append("   ,ov_ship_methods               => :13 "); // 15.出荷方法
    sb.append("   ,on_load_efficiency_weight     => ln_load_efficiency_weight "); // 16.重量積載効率
    sb.append("   ,on_load_efficiency_capacity   => ln_load_efficiency_capacity "); // 17.容積積載効率
    sb.append("   ,ov_mixed_ship_method          => :14 "); // 18.混載配送区分
    sb.append("   ); ");
    sb.append("  :15 := TO_CHAR(ln_load_efficiency_weight);   ");
    sb.append("  :16 := TO_CHAR(ln_load_efficiency_capacity); ");
    sb.append("END; ");

    // PL/SQLの設定を行います。
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      int i = 1;
      cstmt.setString(i++, XxcmnUtility.commaRemoval(sumWeight));    // 合計重量
      cstmt.setString(i++, XxcmnUtility.commaRemoval(sumCapacity));  // 合計容積
      cstmt.setString(i++, code1);        // コード区分１
      cstmt.setString(i++, whseCode1);    // 入出庫場所コード１
      cstmt.setString(i++, code2);        // コード区分２
      cstmt.setString(i++, whseCode2);    // 入出庫場所コード２
      cstmt.setString(i++, maxShipToCode); // 合計容積
      cstmt.setDate(i++, XxcmnUtility.dateValue(originalDate)); // 基準日

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1);         // ステータスコード
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);      // エラーメッセージ
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000);      // システムメッセージ
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);

      // PL/SQL実行
      cstmt.execute();

      // 実行結果格納
      String retCode   = cstmt.getString(9);   // リターンコード
      String errMsg    = cstmt.getString(10);  // エラーメッセージ
      String systemMsg = cstmt.getString(11);  // システムメッセージ
      String loadingOverClass = cstmt.getString(12);  // 積載オーバー区分
      String shipMethod       = cstmt.getString(13);  // 配送区分
      String mixedShipMethod  = cstmt.getString(14);  // 混載配送区分
      String loadEfficiencyWeight    = cstmt.getString(15);  // 重量積載効率
      String loadEfficiencyCapacity  = cstmt.getString(16);  // 容積積載効率

      // 戻り値取得
      retHashMap.put("loadingOverClass",       loadingOverClass);
      retHashMap.put("shipMethod",             shipMethod);
      retHashMap.put("mixedShipMethod",        mixedShipMethod);
      retHashMap.put("loadEfficiencyWeight",   loadEfficiencyWeight);
      retHashMap.put("loadEfficiencyCapacity", loadEfficiencyCapacity);

      // エラーの場合
      if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              errMsg + systemMsg,
                              6);
        // エラーメッセージ出力
        XxcmnUtility.putErrorMessage(XxpoConstants.TOKEN_NAME_CALC_LOAD_ERR);

      // 積載オーバーの場合
      } else if ("1".equals(loadingOverClass))
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              "積載オーバーエラー",
                              6);
                
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10120);
      }
      return retHashMap; 
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);

      }
    }
  } // calcLoadEfficiency
  /*****************************************************************************
   * 受注ヘッダアドオンの合計数量、積載重量合計、積載容積合計を更新します。
   * @param trans        - トランザクション
   * @param orderHeaderId  - 受注ヘッダアドオンID
   * @param sumQuantity - 合計数量
   * @param smallQuantity - 小口個数
   * @param labelQuantity - ラベル枚数
   * @param sumWeight - 積載重量合計
   * @param sumCapacity - 積載容積合計
   * @throws OAException - OA例外
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
  
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_headers_all xoha   ");                 // 受注ヘッダアドオン
    sb.append("  SET    xoha.sum_quantity      = TO_NUMBER(:1) ");         // 合計数量
    sb.append("        ,xoha.small_quantity    = TO_NUMBER(:2) " );        // 小口個数
    sb.append("        ,xoha.label_quantity    = TO_NUMBER(:3) " );        // ラベル枚数
    sb.append("        ,xoha.sum_weight        = TO_NUMBER(:4) ");         // 積載重量合計
    sb.append("        ,xoha.sum_capacity      = TO_NUMBER(:5) ");         // 積載容積合計
    sb.append("        ,xoha.last_updated_by   = FND_GLOBAL.USER_ID ");    // 最終更新者
    sb.append("        ,xoha.last_update_date  = SYSDATE ");               // 最終更新日
    sb.append("        ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID ");   // 最終更新ログイン
    sb.append("  WHERE  xoha.order_header_id   = :6;  ");                  // 発注明細アドオンID
    sb.append("END; ");
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, XxcmnUtility.commaRemoval(sumQuantity)); // 合計数量
      if (XxcmnUtility.isBlankOrNull(smallQuantity)) 
      {
        cstmt.setNull(2, Types.INTEGER);      // 小口個数
      } else 
      {
        cstmt.setInt(2, XxcmnUtility.intValue(smallQuantity));      // 小口個数
      }
      if (XxcmnUtility.isBlankOrNull(labelQuantity)) 
      {
        cstmt.setNull(3, Types.INTEGER);
      } else 
      {
        cstmt.setInt(3, XxcmnUtility.intValue(labelQuantity));      // ラベル枚数
      }
      cstmt.setString(4, XxcmnUtility.commaRemoval(sumWeight));   // 積載重量合計
      cstmt.setString(5, XxcmnUtility.commaRemoval(sumCapacity)); // 積載容積合計
      cstmt.setInt(6,  XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID
      //PL/SQL実行
      cstmt.execute();
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateSummaryInfo

  /*****************************************************************************
   * 出庫実績の存在チェックを行います。
   * @param trans トランザクション
   * @param headerNumber 発注番号
   * @return String XxcmnConstants.STRING_N：データ無し
   *                 XxcmnConstants.STRING_Y：データ有り
   * @throws OAException OA例外
   ****************************************************************************/
  public static String chkDeliveryResults(
    OADBTransaction trans,
    String headerNumber
  ) throws OAException
  {
    String apiName  = "chkDeliveryResults"; // API名

    int rcvAndRtnTxnsCount = 0;  
    String checkFlag = XxcmnConstants.STRING_N; // 戻り値用

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" BEGIN "                                        );
    sb.append("   SELECT COUNT(1) "                            );
    sb.append("   INTO   :1 "                                  );
    sb.append("   FROM po_headers_all pha "                    );   // 発注ヘッダ
    sb.append("       ,po_lines_all   pla "                    );   // 発注明細
    sb.append("   WHERE pha.po_header_id  = pla.po_header_id " );
    sb.append("     AND pla.attribute6 IS NOT NULL "           );   // 仕入先出荷数量
    sb.append("     AND pha.segment1      = :2; "              );
    sb.append(" END; "                                         );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.INTEGER); // カウント

      //バインド変数に値をセット
      cstmt.setString(2, headerNumber);             // 発注番号

      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      rcvAndRtnTxnsCount = cstmt.getInt(1);

      if (rcvAndRtnTxnsCount > 0)
      {
        checkFlag = XxcmnConstants.STRING_Y;
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {

      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
      rollBack(trans);
      // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return checkFlag;
  } // chkDeliveryResults

  /*****************************************************************************
   * 発注明細金額確定フラグを取得します。
   * @param trans トランザクション
   * @param headerNumber 発注番号
   * @return String XxcmnConstants.STRING_N：データ無し
   *                 XxcmnConstants.STRING_Y：データ有り
   * @throws OAException OA例外
   ****************************************************************************/
  public static String getMoneyDecisionFlag(
    OADBTransaction trans,
    String headerNumber
  ) throws OAException
  {
    String apiName  = "getMoneyDecisionFlag"; // API名

    int moneyDecisionFlagCount = 0;  
    String checkFlag = XxcmnConstants.STRING_N; // 戻り値用

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);

    sb.append(" BEGIN "                                        );
    sb.append("   SELECT COUNT(1) "                            );
    sb.append("   INTO   :1 "                                  );
    sb.append("   FROM po_headers_all pha "                    );   // 発注ヘッダ
    sb.append("       ,po_lines_all   pla "                    );   // 発注明細
    sb.append("   WHERE pha.po_header_id  = pla.po_header_id " );
    sb.append("     AND pla.attribute14   = 'Y' "              );   // 明細.金額確定フラグ
    sb.append("     AND pha.segment1      = :2; "              );
    sb.append(" END; "                                         );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.INTEGER); // 発注明細.金額確定済カウント

      //バインド変数に値をセット
      cstmt.setString(2, headerNumber);             // 発注番号

      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      moneyDecisionFlagCount = cstmt.getInt(1);

      if (moneyDecisionFlagCount > 0)
      {
        checkFlag = XxcmnConstants.STRING_Y;
      }
      
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {

      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
      rollBack(trans);
      // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    
    return checkFlag;
    
  } // getMoneyDecisionFlag

  /*****************************************************************************
   * ユーザー情報を取得します。(支給用)
   * @param trans    - トランザクション
   * @return HashMap - ユーザ情報
   * @throws OAException - OA例外
   ****************************************************************************/
  public static HashMap getProvUserData(
    OADBTransaction trans
    ) throws OAException
  {
    String apiName  = "getProvUserData"; // API名

    HashMap retHashMap = new HashMap();  // 戻り値用

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  SELECT papf.attribute3        people_code   "); // 従業員区分
    sb.append("        ,papf.attribute4        vendor_code   "); // 仕入先コード
    sb.append("        ,xvv.vendor_id          vendor_id     "); // 仕入先ID
    sb.append("        ,xvv.vendor_short_name  vendor_name   "); // 仕入先名
    sb.append("        ,xcav.party_id          customer_id   "); // 顧客ID(パーティーID)
    sb.append("        ,xcav.party_number      customer_code "); // 顧客コード(組織番号)
    sb.append("        ,xvv.spare2             price_list    "); // 取引先価格表ID
    sb.append("  INTO   :1 ");
    sb.append("        ,:2 ");
    sb.append("        ,:3 ");
    sb.append("        ,:4 ");
    sb.append("        ,:5 ");
    sb.append("        ,:6 ");
    sb.append("        ,:7 ");
    sb.append("  FROM   fnd_user              fu   ");  // ユーザーマスタ
    sb.append("        ,per_all_people_f      papf ");  // 従業員マスタ
    sb.append("        ,xxcmn_vendors_v       xvv  ");  // 仕入先情報V
    sb.append("        ,xxcmn_cust_accounts_v xcav ");  // 顧客情報VIEW
    sb.append("  WHERE  fu.employee_id             = papf.person_id      ");  // 従業員ID
    sb.append("  AND    papf.attribute4            = xvv.segment1        ");  // 仕入先コード
    sb.append("  AND    xvv.customer_num           = xcav.account_number ");  // 組織番号
    sb.append("  AND    fu.user_id                 = FND_GLOBAL.USER_ID  ");  // ユーザーID
    sb.append("  AND    papf.effective_start_date <= TRUNC(SYSDATE)      ");
    sb.append("  AND    papf.effective_end_date   >= TRUNC(SYSDATE)      ");
    sb.append("  AND    fu.start_date             <= TRUNC(SYSDATE)      ");
    sb.append("  AND    ((fu.end_date IS NULL) OR (fu.end_date >= TRUNC(SYSDATE)));");
    sb.append("EXCEPTION ");
    sb.append("  WHEN NO_DATA_FOUND THEN ");
    sb.append("    null; ");
    sb.append("END; ");

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(OUTパラメータ)
      int i = 1;
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 従業員区分
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 仕入先コード
      cstmt.registerOutParameter(i++, Types.INTEGER); // 仕入先ID
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 仕入先名
      cstmt.registerOutParameter(i++, Types.INTEGER); // 顧客ID
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 顧客コード
      cstmt.registerOutParameter(i++, Types.VARCHAR); // 取引先価格表ID
      
      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      retHashMap.put("PeopleCode",   cstmt.getObject(1)); // 従業員区分
      retHashMap.put("VendorCode",   cstmt.getObject(2)); // 仕入先コード
      retHashMap.put("VendorId",     cstmt.getObject(3)); // 仕入先ID
      retHashMap.put("VendorName",   cstmt.getObject(4)); // 仕入先名
      retHashMap.put("CustomerId",   cstmt.getObject(5)); // 顧客ID
      retHashMap.put("CustomerCode", cstmt.getObject(6)); // 顧客コード
      retHashMap.put("PriceList",    cstmt.getObject(7)); // 取引先価格表ID

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
      rollBack(trans);
      // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retHashMap;
  } // getProvUserData

// 2008-06-18 H.Itou ADD START
  /*****************************************************************************
   * 内訳合計を取得します。
   * @param trans            - トランザクション
   * @param params           - パラメータ
   * @return String          - 内訳合計
   * @throws OAException - OA例外
   ****************************************************************************/
  public static String getTotalAmount(
    OADBTransaction trans,
    HashMap params
  ) throws OAException
  {
    String apiName    = "getTotalAmount"; // API名
    String totalAmount = "";    // 内訳合計

    // パラメータ値取得
    String unitPriceCalcCode = (String)params.get("UnitPriceCalcCode");// 仕入単価導出日タイプ
    Number itemId            = (Number)params.get("ItemId");           // 品目ID
    Number vendorId          = (Number)params.get("VendorId");         // 取引先ID
    Number factoryId         = (Number)params.get("FactoryId");        // 工場ID
    Date   manufacturedDate  = (Date)params.get("ManufacturedDate");   // 生産日
    Date   productedDate     = (Date)params.get("ProductedDate");      // 製造日

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE "                                                 );
    sb.append("  lt_total_amount  xxpo_price_headers.total_amount%TYPE; ");
    sb.append("BEGIN "                                                   );
    sb.append("  SELECT xph.total_amount    total_amount "               ); // 内訳合計
    sb.append("  INTO   lt_total_amount "                                );
    sb.append("  FROM   xxpo_price_headers  xph "                        ); // 仕入･標準単価ヘッダ
    sb.append("  WHERE  xph.item_id             = :1 "                   ); // 品目ID
    sb.append("  AND    xph.vendor_id           = :2 "                   ); // 取引先ID
    sb.append("  AND    xph.factory_id          = :3 "                   ); // 工場ID
    sb.append("  AND    xph.futai_code          = '0' "                  ); // 付帯コード
    sb.append("  AND    xph.price_type          = '1' "                  ); // マスタ区分1:仕入
// 20080702 yoshimoto add Start
    sb.append("  AND    xph.supply_to_code IS NULL "                     ); // 支給先コード IS NULL
// 20080702 yoshimoto add End
    sb.append("  AND    (((:4                   = '1') "                 ); // 仕入単価導入日タイプが1:製造日の場合、条件が製造日
    sb.append("    AND  (xph.start_date_active <= :5) "                  ); // 適用開始日 <= 製造日
    sb.append("    AND  (xph.end_date_active   >= :5)) "                 ); // 適用終了日 >= 製造日
    sb.append("  OR     ((:4                    = '2') "                 ); // 仕入単価導入日タイプが2:納入日の場合、条件が生産日
    sb.append("    AND  (xph.start_date_active <= :6) "                  ); // 適用開始日 <= 生産日
    sb.append("    AND  (xph.end_date_active   >= :6))); "               ); // 適用終了日 >= 生産日
    sb.append("  :7 := TO_CHAR(lt_total_amount); "                       );
    sb.append("EXCEPTION "                                               );
    sb.append("  WHEN OTHERS THEN "                                      ); // データがない場合は0
    sb.append("    :7 := '0'; "                                          );
    sb.append("END; "                                                    );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1, XxcmnUtility.intValue(itemId));            // 品目ID
      cstmt.setInt(2, XxcmnUtility.intValue(vendorId));          // 取引先ID
      cstmt.setInt(3, XxcmnUtility.intValue(factoryId));         // 工場ID
      cstmt.setString(4, unitPriceCalcCode);                     // 仕入単価導入タイプ
      cstmt.setDate(5, XxcmnUtility.dateValue(productedDate));   // 製造日
      cstmt.setDate(6, XxcmnUtility.dateValue(manufacturedDate));// 生産日
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(7, Types.VARCHAR); // 内訳合計
      
      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      return cstmt.getString(7);

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getTotalAmount
// 2008-06-18 H.Itou ADD END

// 2008-10-22 T.Yoshimoto ADD START
  /***************************************************************************
   * 受注ヘッダ.有償金額確定済みを確認します
   * @param trans - トランザクション
   * @param requestNo - 依頼No
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public static boolean chkAmountFixClass(
    OADBTransaction trans, 
    String requestNo
    ) throws OAException
  {
    String apiName = "chkAmountFixClass";
    String plSqlRet;

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                               );
    sb.append("   SELECT xoha.amount_fix_class "                     ); // 有償金額確定区分(1:確定,2:未確定)
    sb.append("   INTO   :1 "                                        ); 
    sb.append("   FROM   po_headers_all pha "                        ); // 発注ヘッダ
    sb.append("         ,xxwsh_order_headers_all xoha "              ); // 受注ヘッダアドオン
    sb.append("   WHERE  pha.attribute9 = xoha.request_no "          ); // 依頼No
    sb.append("   AND    xoha.latest_external_flag = 'Y' "           ); // 最新フラグ
    sb.append("   AND    xoha.request_no = :2; "                     ); // 依頼No
    sb.append("END; "                                                );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(2, requestNo);  // 依頼No

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR); // ロットカウント数
      
      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      plSqlRet = cstmt.getString(1);

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
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
        // 処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
        XxpoUtility.rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    
    // PL/SQL戻り値が0の場合 false
    if ("1".equals(plSqlRet))
    {
      return true;
    
    // PL/SQL戻り値が0以外の場合 true
    } else
    {
      return false;
    }
  } // chkAmountFixClass 
// 2008-10-22 T.Yoshimoto ADD END

// 2009-01-16 v1.21 T.Yoshimoto Add Start
  /*****************************************************************************
   * コンカレント：要求セットで受入取引処理を発行します。
   * @param trans トランザクション
   * @param groupId グループID
   * @return HashMap 処理結果/要求ID
   * @throws OAException OA例外
   ****************************************************************************/
  public static HashMap doRVCTP2(
    OADBTransaction trans,
    String[] groupId
  ) throws OAException
  {
    String apiName      = "doRVCTP2";

    // OUTパラメータ用
    HashMap retHash = new HashMap();
    retHash.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE); // 戻り値

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    
    sb.append("DECLARE "                                                        );
    // ローカル変数
    sb.append("  ln_req_id                NUMBER; "                             );
    sb.append("  lv_rcv_stage    CONSTANT VARCHAR2(50) := 'STAGE10'; "          );
    sb.append("  lv_rcv_stage2   CONSTANT VARCHAR2(50) := 'STAGE20'; "          );
    sb.append("  lv_errbuf                VARCHAR2(5000); "                     );  // エラー・メッセージ
    sb.append("  lv_retcode               VARCHAR2(1); "                        );  // リターン・コード
    sb.append("  lv_errmsg                VARCHAR2(5000); "                     );  // ユーザー・エラー・メッセージ
    sb.append("  lb_ret                   BOOLEAN; "                            );
    // 処理部共通例外
    sb.append("  process_expt             EXCEPTION; "                          );
    sb.append("BEGIN "                                                          );
    // 要求セットの準備
    sb.append("  lb_ret := FND_SUBMIT.SET_REQUEST_SET('XXPO', 'XXPO320001Q'); " );

    sb.append("  IF (NOT lb_ret) THEN "                                         );
    sb.append("    RAISE process_expt; "                                        );
    sb.append("  END IF; "                                                      );

    // 受入取引処理起動(要求セット用訂正1)
    sb.append("  lb_ret := FND_SUBMIT.SUBMIT_PROGRAM('PO', "                    );
    sb.append("                                      'RVCTP', "                 );
    sb.append("                                      'STAGE10', "               );
    sb.append("                                      'BATCH', "                 );
    sb.append("                                      :1); "                     );

    sb.append("  IF (NOT lb_ret) THEN "                                         );
    sb.append("    RAISE process_expt; "                                        );
    sb.append("  END IF; "                                                      );

    // 受入取引処理起動(要求セット用訂正2)
    sb.append("  lb_ret := FND_SUBMIT.SUBMIT_PROGRAM('PO', "                    );
    sb.append("                                      'RVCTP', "                 );
    sb.append("                                      'STAGE20', "               );
    sb.append("                                      'BATCH', "                 );
    sb.append("                                      :2); "                     );

    sb.append("  IF (NOT lb_ret) THEN "                                         );
    sb.append("    RAISE process_expt; "                                        );
    sb.append("  END IF; "                                                      );

    // 要求セットの発行
    sb.append("  ln_req_id := FND_SUBMIT.SUBMIT_SET(null,FALSE); "              );

    // 処理失敗
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

    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {
    
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, groupId[0]);                    // グループID
      cstmt.setString(2, groupId[1]);                    // グループID

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(3, Types.VARCHAR);   // リターンコード

      //PL/SQL実行
      cstmt.execute();

      // 戻り値取得
      String retFlag = cstmt.getString(3);    // リターンコード

      // 正常終了の場合
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        // リターンコード正常をセット
        retHash.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);
        
      // 正常終了でない場合、エラー  
      } else
      {
        //トークン生成
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                   XxpoConstants.TOKEN_NAME_RVCTP) };
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                               XxpoConstants.XXPO10055, 
                               tokens);
      }
      
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
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
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }

    return retHash;
  } // doRVCTP2.
// 2009-01-16 v1.21 T.Yoshimoto Add End

// 2009-01-20 v1.22 T.Yoshimoto Add Start
  /***************************************************************************
   * 受注ヘッダアドオン.入庫実績日を確認します
   * @param trans - トランザクション
   * @param orderHeaderId - 受注ヘッダアドオンID
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public static Date chkArrivalDate(
    OADBTransaction trans, 
    Number orderHeaderId
    ) throws OAException
  {
    String apiName = "chkArrivalDate";
    Date plSqlRet;

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                               );
    sb.append("   SELECT xoha.arrival_date "                         ); // 入庫実績日
    sb.append("   INTO   :1 "                                        ); 
    sb.append("   FROM   xxwsh_order_headers_all xoha "              ); // 受注ヘッダアドオン
    sb.append("   WHERE  xoha.latest_external_flag = 'Y' "           ); // 最新フラグ
    sb.append("   AND    xoha.order_header_id = :2; "                ); // 受注ヘッダアドオンID
    sb.append("END; "                                                );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(orderHeaderId));  // 受注ヘッダアドオンID

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.DATE); // ロットカウント数
      
      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      if (XxcmnUtility.isBlankOrNull(cstmt.getDate(1))) 
      {
        return null;
      }
      
      plSqlRet = new Date(cstmt.getDate(1));

      return plSqlRet;

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
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
        // 処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
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
   * 受注ヘッダアドオンの入庫実績日を更新します。
   * @param trans         - トランザクション
   * @param orderHeaderId - 受注ヘッダアドオンID
   * @param arrivalDate - 入庫実績日
   * @throws OAException  - OA例外
   ****************************************************************************/
  public static void updArrivalDate(
    OADBTransaction trans,
    Number orderHeaderId,
    Date arrivalDate
    ) throws OAException
  {
    String apiName = "updArrivalDate";
  
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                );
    sb.append("  UPDATE xxwsh_order_headers_all xoha "                );  // 受注ヘッダアドオン
    sb.append("  SET    xoha.arrival_date = :1 "                      );  // 入庫実績日
    sb.append("        ,xoha.last_updated_by   = FND_GLOBAL.USER_ID  ");  // 最終更新者
    sb.append("        ,xoha.last_update_date  = SYSDATE             ");  // 最終更新日
    sb.append("        ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID ");  // 最終更新ログイン
    sb.append("  WHERE  xoha.order_header_id   = :2; "                );  // 受注ヘッダアドオンID
    sb.append("END; ");
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setDate(1, XxcmnUtility.dateValue(arrivalDate));  // 入庫実績日
      cstmt.setInt(2,  XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID

      //PL/SQL実行
      cstmt.execute();
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
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
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updArrivalDate 
// 2009-01-20 v1.22 T.Yoshimoto Add End
// 2011-06-01 v1.28 K.Kubo Add Start
  /*****************************************************************************
   * 仕入実績情報をチェックします。
   * @param OADBTransaction  - トランザクション
   * @param Number           - 発注ヘッダID
   * @return String          - チェック結果
   * @throws OAException     - OA例外
   ****************************************************************************/
  public static String chkStockResult(
    OADBTransaction trans,   // トランザクション
    Number poHeaderId        // 発注ヘッダID
  ) throws OAException
  {
    String apiName  = "chkStockResult"; // API名
    String retCode;   // リターンコード
    
    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                       );
    sb.append("  :1 := xxpo_common3_pkg.check_result( "      ); // (OUT)チェック結果
    sb.append("          in_po_header_id  => TO_NUMBER(:2) " ); // (IN) 発注ヘッダID
    sb.append("        );  "                                 );
    sb.append("END; "                                        );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(poHeaderId)); // 発注ヘッダID
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR);        // 戻り値
      
      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      retCode  = cstmt.getString(1); // リターンコード
      
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //トークン生成
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                 XxpoConstants.TOKEN_NAME_CHK_STOCK_RESULT_MANE) };
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                             XxcmnConstants.XXCMN05002, 
                             tokens);
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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retCode;
  } // chkStockResult

  /*****************************************************************************
   * 仕入実績情報を登録します。
   * @param OADBTransaction  - トランザクション
   * @param Number           - 発注ヘッダID
   * @param String           - 発注番号
   * @throws OAException     - OA例外
   ****************************************************************************/
  public static String insStockResult(
    OADBTransaction trans    // トランザクション
   ,Number headerId          // 発注ヘッダID
   ,String headerNumber      // 発注番号
  ) throws OAException
  {
    String apiName  = "insStockResult"; // API名
    String retCode;   // リターンコード
    
    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                                 );
    sb.append("  :1 := xxpo_common3_pkg.insert_result( "               ); // (OUT)チェック結果
    sb.append("          in_po_header_id      => TO_NUMBER(:2) "       ); // (IN) 発注ヘッダID
    sb.append("         ,iv_po_header_number  => TO_CHAR(:3) "         ); // (IN) 発注番号
    sb.append("         ,in_created_by        => FND_GLOBAL.USER_ID "  ); // (IN) 作成者
    sb.append("         ,id_creation_date     => SYSDATE "             ); // (IN) 作成日
    sb.append("         ,in_last_updated_by   => FND_GLOBAL.USER_ID "  ); // (IN) 最終更新者
    sb.append("         ,id_last_update_date  => SYSDATE "             ); // (IN) 最終更新日
    sb.append("         ,in_last_update_login => FND_GLOBAL.LOGIN_ID " ); // (IN) 最終更新ログイン
    sb.append("        );  "                                     );
    sb.append("END; "                                            );

    //PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(2, XxcmnUtility.intValue(headerId));             // 発注ヘッダID
      cstmt.setString(3, headerNumber);                             // 発注番号
      
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.VARCHAR);        // 戻り値
      
      //PL/SQL実行
      cstmt.execute();
      
      // 戻り値取得
      retCode  = cstmt.getString(1); // リターンコード
      
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      //トークン生成
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                 XxpoConstants.TOKEN_NAME_STOCK_RESULT_MANEGEMENT) };
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                             XxcmnConstants.XXCMN05002, 
                             tokens);
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
                              XxpoConstants.CLASS_XXPO_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return retCode;
  } // insStockResult

// 2011-06-01 v1.28 K.Kubo Add End
}