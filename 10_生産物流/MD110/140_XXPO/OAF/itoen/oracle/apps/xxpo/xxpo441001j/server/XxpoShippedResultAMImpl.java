/*============================================================================
* ファイル名 : XxpoShippedResultAMImpl
* 概要説明   : 出庫実績要約アプリケーションモジュール
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-25 1.0  山本恭久     新規作成
* 2008-06-30 1.1  二瓶大輔     内部変更要求対応#146,#149,ST不具合#248対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo441001j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxpo.util.XxpoUtility;
import itoen.oracle.apps.xxpo.util.server.XxpoProvSearchVOImpl;
import itoen.oracle.apps.xxwsh.util.XxwshConstants;
import itoen.oracle.apps.xxwsh.util.XxwshUtility;

import java.sql.CallableStatement;
import java.sql.SQLException;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.Row;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
/***************************************************************************
 * 出庫実績要約画面のアプリケーションモジュールクラスです。
 * @author  ORACLE 山本恭久
 * @version 1.1
 ***************************************************************************
 */
public class XxpoShippedResultAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoShippedResultAMImpl()
  {
  }

  /***************************************************************************
   * 出庫実績要約画面の初期化処理を行うメソッドです。
   * @param exeType - 起動タイプ
   ***************************************************************************
   */
  public void initializeList(
    String exeType
    )
  {
    // 支給依頼要約検索VO
    OAViewObject vo = getXxpoProvSearchVO1();
    // 1行もない場合、空行作成
    if (!vo.isPreparedForExecution())
    {
      vo.setMaxFetchSize(0);
      vo.insertRow(vo.createRow());
      OARow row = (OARow)vo.first();
      row.setNewRowState(OARow.STATUS_INITIALIZED);
      row.setAttribute("RowKey", new Number(1));
      row.setAttribute("ExeType", exeType);
    }
  } // initializeList
  
  /***************************************************************************
   * 出庫実績要約画面の検索処理を行うメソッドです。
   * @param exeType - 起動タイプ
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doSearchList(
    String exeType
    ) throws OAException
  {
    // 支給要約共通検索VO取得
    XxpoProvSearchVOImpl svo = getXxpoProvSearchVO1();
    // 検索条件設定
    OARow shRow = (OARow)svo.first();
    HashMap shParams = new HashMap();
    shParams.put("orderType",    shRow.getAttribute("OrderType"));       // 発生区分
    shParams.put("vendorCode",   shRow.getAttribute("VendorCode"));      // 取引先
    shParams.put("shipToCode",   shRow.getAttribute("ShipToCode"));      // 配送先
    shParams.put("reqNo",        shRow.getAttribute("ReqNo"));           // 依頼No
    shParams.put("shipToNo",     shRow.getAttribute("ShipToNo"));        // 配送No
    shParams.put("transStatus",  shRow.getAttribute("TransStatusCode")); // ステータス
    shParams.put("notifStatus",  shRow.getAttribute("NotifStatusCode")); // 通知ステータス
    shParams.put("shipDateFrom", shRow.getAttribute("ShipDateFrom"));    // 出庫日From
    shParams.put("shipDateTo",   shRow.getAttribute("ShipDateTo"));      // 出庫日To
    shParams.put("arvlDateFrom", shRow.getAttribute("ArvlDateFrom"));    // 入庫日From
    shParams.put("arvlDateTo",   shRow.getAttribute("ArvlDateTo"));      // 入庫日To
    shParams.put("reqDeptCode",  shRow.getAttribute("ReqDeptCode"));     // 依頼部署
    shParams.put("instDeptCode", shRow.getAttribute("InstDeptCode"));    // 指示部署
    shParams.put("shipWhseCode", shRow.getAttribute("ShipWhseCode"));    // 出庫倉庫

    shParams.put("exeType", exeType);

    // 出庫実績結果VO取得
    XxpoShippedResultVOImpl vo = getXxpoShippedResultVO1();
    // 検索を実行します。
    vo.initQuery(shParams);
  } // doSearchList

  /***************************************************************************
   * 出庫実績要約画面の全数出庫処理前の未選択チェックを行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkBeforeDecision() throws OAException
  {
    // 入庫実績結果VO取得
    XxpoShippedResultVOImpl vo = getXxpoShippedResultVO1();
    
    // 選択されたレコードを取得
    Row[] rows   = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // 未選択チェックを行います。
    chkNonChoice(rows);
    
  } // chkBeforeDecision

  /***************************************************************************
   * 未選択チェックを行うメソッドです。
   * @param rows - 行オブジェクト配列
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkNonChoice(
    Row[] rows
    ) throws OAException
  {
    // 未選択チェックを行います。
    if ((rows == null) || (rows.length == 0)) 
    {
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10144);
    }
  } // chkNonChoice
  
  /***************************************************************************
   * ロック・排他処理を行うメソッドです。
   * @param vo - ビューオブジェクト
   * @param row - 行オブジェクト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public boolean chkLockAndExclusive(
    OAViewObject vo,
    OARow row
    ) throws OAException
  {
    // ロックを取得します。
    Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID
    Number orderType     = (Number)row.getAttribute("OrderTypeId");   // 発生区分
    if (!XxpoUtility.getXxwshOrderLock(getOADBTransaction(), orderHeaderId)) 
    {
      XxpoUtility.rollBack(getOADBTransaction());
      // ロックエラーメッセージ
      throw new OAAttrValException(OAAttrValException.TYP_VIEW_OBJECT,          
                                   vo.getName(),
                                   row.getKey(),
                                   "OrderTypeId",
                                   orderType,
                                   XxcmnConstants.APPL_XXPO, 
                                   XxpoConstants.XXPO10138);
    }
    // 排他チェックを行います。
    String xohaLastUpdateDate = (String)row.getAttribute("XohaLastUpdateDate"); // 最終更新日（受注ヘッダ）
    String xolaLastUpdateDate = (String)row.getAttribute("XolaLastUpdateDate"); // 最終更新日（受注明細）
    if (!XxpoUtility.chkExclusiveXxwshOrder(getOADBTransaction(),
                                            orderHeaderId,
                                            xohaLastUpdateDate,
                                            xolaLastUpdateDate)) 
    {
      XxpoUtility.rollBack(getOADBTransaction());
      // 排他エラーメッセージ
      throw new OAAttrValException(OAAttrValException.TYP_VIEW_OBJECT,          
                                   vo.getName(),
                                   row.getKey(),
                                   "OrderTypeId",
                                   orderType,
                                   XxcmnConstants.APPL_XXCMN, 
                                   XxcmnConstants.XXCMN10147);
     // 排他チェックOK
    } else
    {
      return true;
    }
  } // chkLockAndExclusive

  /***************************************************************************
   * ページングの際にチェックボックスをOFFにします。
   ***************************************************************************
   */
  public void checkBoxOff()
  {
    // 処理対象を取得します。
    XxpoShippedResultVOImpl vo = getXxpoShippedResultVO1();
    Row[] rows = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // 未選択チェックを行います。
    if ((rows != null) || (rows.length != 0)) 
    {
      OARow row = null;
      for (int i = 0; i < rows.length; i++)
      {
        // i番目の行を取得
        row = (OARow)rows[i];
        row.setAttribute("MultiSelect", XxcmnConstants.STRING_N);
      }
    }
  } // checkBoxOff

  /***************************************************************************
   * 出庫実績要約画面の全数出庫処理を行うメソッドです。
   * @param exeType - 起動タイプ
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doDecisionList(
    String exeType
    ) throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    boolean exeFlag = false;

    // 処理対象を取得
    OAViewObject vo = getXxpoShippedResultVO1();
    Row[] rows = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);

    // 未選択チェック
    if ((rows == null) || (rows.length == 0))
    {
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10144);
    } else 
    {
      OARow row = null;
      // 選択伝票loop
      for (int i = 0; i < rows.length; i++) 
      {
        // i番目の行を取得
        row = (OARow)rows[i];
        // 排他チェック
        if(chkLockAndExclusive(vo, row))
        {
           // エラーチェック
          if(chkInputAll(vo,row,exceptions))
          {
            // 全数出庫の実績登録処理
            Number orderHeader = (Number)row.getAttribute("OrderHeaderId");
            Date shipDate = (Date)row.getAttribute("ShippedDate");
            if((XxpoUtility.updateOrderExecute(getOADBTransaction(),
                                               orderHeader,
                                               XxpoConstants.REC_TYPE_20,
                                               shipDate)))
            {
              exeFlag = true;
            } else
            {
              // トークン生成
              MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                         "全数処理") };
              // エラーメッセージ出力
              throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                    XxcmnConstants.XXCMN05002, 
                                    tokens);
            }

            // 出庫処理
            String requestNo = (String)row.getAttribute("RequestNo");
            XxwshUtility.doShipRequestAndResultEntry(getOADBTransaction(), requestNo);
            // エラーがあった場合エラーをスローします。
            if (exceptions.size() > 0)
            {
              //トークン生成
              MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_CONC_NAME,
                                                         XxwshConstants.TOKEN_NAME_PGM_NAME_420001C) };
              // エラーメッセージ出力
              throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                    XxpoConstants.XXPO10024, 
                                    tokens);
            }
          }
        }    
      }
      // エラーがあった場合エラーをスローします。
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }
      // 更新完了メッセージ
      if (exeFlag) 
      {
        // コミット発行
        XxpoUtility.commit(getOADBTransaction());
        // 再検索を行います。
        doSearchList(exeType);
        // 更新完了メッセージ
        XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_ALL_SHIPPED);
      } else
      {
        // ロールバックします。
        XxpoUtility.rollBack(getOADBTransaction());
      }
    }
  } // doDecisionList

  /***************************************************************************
   * 依頼Noごとに全数出庫チェックを行うメソッドです。
   * @param vo - ビューオブジェクト
   * @param row - 行オブジェクト
   * @param exceptions - エラーメッセージ格納用配列
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public boolean chkInputAll(
    OAViewObject vo,
    OARow row,
    ArrayList exceptions
    ) throws OAException
  {
    boolean retFlag = true;
    
    // 在庫会計期間クローズチェック
    Date shippedDate = (Date)row.getAttribute("ShippedDate"); // 出庫日
    if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                  shippedDate))
    {
      // 出荷日の年月≦直近にクローズした在庫会計期間年月の場合はエラー。
      exceptions.add(new OAAttrValException(OAAttrValException.TYP_VIEW_OBJECT,
                                            vo.getName(),
                                            row.getKey(),
                                            "ShippedDate",
                                            shippedDate,
                                            XxcmnConstants.APPL_XXPO,
                                            XxpoConstants.XXPO10119));
    }

    // 実績未入力チェックを行います。
    Number orderHeader = (Number)row.getAttribute("OrderHeaderId");
    if(!(XxpoUtility.chkOrderResult(getOADBTransaction(),
                                    orderHeader,XxpoConstants.REC_TYPE_20)))
    {
      exceptions.add( new OAAttrValException(OAAttrValException.TYP_VIEW_OBJECT,          
                                             vo.getName(),
                                             row.getKey(),
                                             "OrderHeaderId",
                                             orderHeader,
                                             XxcmnConstants.APPL_XXPO, 
                                             XxpoConstants.XXPO10130));
    }

    // ロットステータスチェックを行います。
    String requestNo = (String)row.getAttribute("RequestNo");
    if(!(XxpoUtility.chkLotStatus(getOADBTransaction(),
                                  requestNo)))
    {
      exceptions.add( new OAAttrValException(OAAttrValException.TYP_VIEW_OBJECT,          
                                             vo.getName(),
                                             row.getKey(),
                                             "RequestNo",
                                             requestNo,
                                             XxcmnConstants.APPL_XXPO, 
                                             XxpoConstants.XXPO10202));
    }

    if(exceptions.size() > 0 )
    {
      retFlag = false;
    }
    return retFlag;
  } // chkInputAll

  /***************************************************************************
   * 出庫実績要約画面の指示受領処理を行うメソッドです。
   * @param exeType - 起動タイプ
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doRcvList(
    String exeType
    ) throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    boolean exeFlag = false;

    // 処理対象を取得
    XxpoShippedResultVOImpl vo = getXxpoShippedResultVO1();
    Row[] rows = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);

    // 未選択チェック
    if ((rows == null) || (rows.length == 0))
    {
      //エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10144);
    } else 
    {
      OARow row = null;
      // 選択伝票loop
      for (int i = 0; i < rows.length; i++) 
      {
        // i番目の行を取得
        row = (OARow)rows[i];
        // 排他チェック
        if(chkLockAndExclusive(vo, row))
        {
          // エラーチェック
          if(chkRcvAll(vo, row, exceptions))
          {
            // 指示受領更新処理
            Number orderHeader = (Number)row.getAttribute("OrderHeaderId");
            if((updateInstRcvClass(getOADBTransaction(),
                                   orderHeader)))
            {
              exeFlag = true;
            } else
            {
              // トークン生成
              MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                         "指示受領") };
              // エラーメッセージ出力
              throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                    XxcmnConstants.XXCMN05002, 
                                    tokens);
            }
          }
        }    
      }
      // エラーがあった場合エラーをスローします。
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }
      // 更新完了メッセージ
      if (exeFlag) 
      {
        // コミット発行
        XxpoUtility.commit(getOADBTransaction());
        // 再検索を行います。
        doSearchList(exeType);
        // 更新完了メッセージ
        throw new OAException(XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO30042, 
                              null, 
                              OAException.INFORMATION, 
                              null);
      } else
      {
        // ロールバックします。
        XxpoUtility.rollBack(getOADBTransaction());
      }
    }
  } // doRcvList

  /***************************************************************************
   * 依頼Noごとに指示受領チェックを行うメソッドです。
   * @param vo - ビューオブジェクト
   * @param row - 行オブジェクト
   * @param exceptions - エラーメッセージ格納用配列
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public boolean chkRcvAll(
    OAViewObject vo,
    OARow row,
    ArrayList exceptions
    ) throws OAException
  {
    boolean retFlag = true;
    
    // 在庫会計期間クローズチェック
    Date shippedDate = (Date)row.getAttribute("ShippedDate"); // 出庫日
    if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                  shippedDate))
    {
      // 出荷日の年月≦直近にクローズした在庫会計期間年月の場合はエラー。
      exceptions.add(new OAAttrValException(OAAttrValException.TYP_VIEW_OBJECT,
                                            vo.getName(),
                                            row.getKey(),
                                            "ShippedDate",
                                            shippedDate,
                                            XxcmnConstants.APPL_XXPO,
                                            XxpoConstants.XXPO10119));
    }

    // 金額確定済みチェック
    String fixClass = (String)row.getAttribute("FixClass"); // 金額確定区分
    if (XxpoConstants.FIX_CLASS_ON.equals(fixClass)) 
    {
      // エラーメッセージは発生区分欄に表示
      Number orderType = (Number)row.getAttribute("OrderTypeId"); // 発生区分
      // 金額確定済(1)の場合はエラー。
      exceptions.add(new OAAttrValException(OAAttrValException.TYP_VIEW_OBJECT,
                                            vo.getName(),
                                            row.getKey(),
                                            "OrderTypeId",
                                            orderType,
                                            XxcmnConstants.APPL_XXPO,
                                            XxpoConstants.XXPO10125));
    }

    if(exceptions.size() > 0 )
    {
      retFlag = false;
    }
    return retFlag;
  } // chkRcvAll

  /*****************************************************************************
   * 受注ヘッダアドオンの支給指示受領区分を更新します。
   * @param trans - トランザクション
   * @param orderHeaderId - 受注ヘッダアドオンID
   * @throws OAException  - OA例外
   ****************************************************************************/
  public boolean updateInstRcvClass(
    OADBTransaction trans,
    Number orderHeaderId
    ) throws OAException
  {
    boolean retFlag = true;

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "  );
    sb.append("  UPDATE xxwsh_order_headers_all xoha ");                  // 受注ヘッダアドオン
    sb.append("  SET    xoha.shikyu_inst_rcv_class  = '1'  ");            // 支給指示受領区分
    sb.append("        ,xoha.last_updated_by   = FND_GLOBAL.USER_ID  ");  // 最終更新者
    sb.append("        ,xoha.last_update_date  = SYSDATE             ");  // 最終更新日
    sb.append("        ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID ");  // 最終更新ログイン
    sb.append("  WHERE  xoha.order_header_id   = :1;  ");                 // 発注ヘッダアドオンID
    sb.append("END; ");
    
    // PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(sb.toString(),
                                                            OADBTransaction.DEFAULT);
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setInt(1, XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID
      // PL/SQL実行
      cstmt.execute();
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
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
        retFlag = false;
      }
    }
    return retFlag;
  } // updateInstRcvClass

  /***************************************************************************
   * 出庫実績要約画面のコミット・再検索処理を行うメソッドです。
   * @param exeType - 起動タイプ
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doCommitList(
    String exeType
    ) throws OAException
  {
    // コミット発行
    XxpoUtility.commit(getOADBTransaction());
    // 再検索を行います。
    doSearchList(exeType);
    // 更新完了メッセージ
    throw new OAException(XxcmnConstants.APPL_XXPO,
                          XxpoConstants.XXPO30042,
                          null,
                          OAException.INFORMATION,
                          null);
  } //doCommitList

  /***************************************************************************
   * 出庫実績入力ヘッダ画面の初期化処理を行うメソッドです。
   * @param exeType - 起動タイプ
   * @param reqNo   - 依頼No
   ***************************************************************************
   */
  public void initializeHdr(
    String exeType,
    String reqNo
    )
  {
    // 支給依頼要約検索VO
    OAViewObject svo = getXxpoProvSearchVO1();
    if (svo.getFetchedRowCount() == 0)
    {
      svo.setMaxFetchSize(0);
      svo.insertRow(svo.createRow());
      OARow srow = (OARow)svo.first();
      srow.setNewRowState(OARow.STATUS_INITIALIZED);
      srow.setAttribute("RowKey", new Number(1));
      srow.setAttribute("ExeType", exeType);
    }
    // 出庫実績入力ヘッダPVO
    XxpoShippedMakeHeaderPVOImpl pvo = getXxpoShippedMakeHeaderPVO1();
    // 1行もない場合、空行作成
    OARow prow = null;
    if (pvo.getFetchedRowCount() == 0)
    {
      pvo.setMaxFetchSize(0);
      pvo.insertRow(pvo.createRow());
      prow = (OARow)pvo.first();
      prow.setNewRowState(OARow.STATUS_INITIALIZED);
      prow.setAttribute("RowKey", new Number(1));
    } else
    {
      prow = (OARow)pvo.first();

      // 初期化
      handleEventAllOnHdr(prow);
    }

    // 依頼Noで検索を実行
    doSearchHdr(reqNo);
    // 出庫実績入力ヘッダVO取得
    XxpoShippedMakeHeaderVOImpl vo = getXxpoShippedMakeHeaderVO1();
    OARow row = (OARow)vo.first();
    // 更新時項目制御
    handleEventUpdHdr(exeType, prow, row);

    // 明細行の検索
    doSearchLine(exeType);

  } // initializeHdr

  /***************************************************************************
   * 出庫実績入力ヘッダ画面の検索処理を行うメソッドです。
   * @param  reqNo - 依頼No
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doSearchHdr(
    String reqNo
    ) throws OAException
  {
    // 出庫実績入力ヘッダVO取得
    XxpoShippedMakeHeaderVOImpl vo = getXxpoShippedMakeHeaderVO1();
    // 検索を実行します。
    vo.initQuery(reqNo);
    vo.first();
    // 対象データを取得できない場合エラー
    if ((vo == null) || (vo.getFetchedRowCount() == 0)) 
    {
      // 出庫実績入力ヘッダPVO
      XxpoShippedMakeHeaderPVOImpl pvo = getXxpoShippedMakeHeaderPVO1();
      OARow prow = (OARow)pvo.first();
      // 参照のみ
      handleEventAllOffHdr(prow);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10500);
    }
  } // doSearchHdr

  /***************************************************************************
     * 出庫実績入力ヘッダ画面の次へ処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doNext() throws OAException
  {
    // 出庫実績入力ヘッダVO取得
    OAViewObject vo = getXxpoShippedMakeHeaderVO1();
    OARow row   = (OARow)vo.first();
    // 次へ処理チェック
    chkNext(vo, row);
  } // doNext

  /***************************************************************************
   * 出庫実績入力明細画面の初期化処理を行うメソッドです。
   * @param exeType - 起動タイプ
   ***************************************************************************
   */
  public void initializeLine(
    String exeType
    )
  {
    // 出庫実績入力ヘッダVO取得
    XxpoShippedMakeHeaderVOImpl hdrVvo = getXxpoShippedMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVvo.first();
    // 出庫実績入力明細PVO
    XxpoShippedMakeLinePVOImpl pvo = getXxpoShippedMakeLinePVO1();
    // 1行もない場合、空行作成
    OARow prow = null;
    if (pvo.getFetchedRowCount() == 0)
    {
      pvo.setMaxFetchSize(0);
      pvo.insertRow(pvo.createRow());
      prow = (OARow)pvo.first();
      prow.setNewRowState(OARow.STATUS_INITIALIZED);
      prow.setAttribute("RowKey", new Number(1));
    } else
    {
      prow = (OARow)pvo.first();
    }
    String fixClass = (String)hdrRow.getAttribute("FixClass");    // 金額確定済区分
    // 金額確定区分が「金額確定済」の場合
    if (XxpoConstants.FIX_CLASS_ON.equals(fixClass)) 
    {
      // 押下可
      prow.setAttribute("ApplyBtnReject", Boolean.TRUE);
    } else
    {
      // 押下不可
      prow.setAttribute("ApplyBtnReject", Boolean.FALSE);
    }
  } // initializeLine

  /***************************************************************************
   * 出庫実績入力明細画面の検索処理を行うメソッドです。
   * @param  exeType - 起動タイプ
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doSearchLine(
    String exeType
    ) throws OAException
  {
    // 出庫実績入力ヘッダVO取得
    XxpoShippedMakeHeaderVOImpl hdrVo = getXxpoShippedMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    // 受注ヘッダアドオンIDを取得します。
    Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID
    // 出庫実績入力ヘッダVO取得
    XxpoShippedMakeLineVOImpl vo = getXxpoShippedMakeLineVO1();
    // 検索を実行します。
    vo.initQuery(exeType, orderHeaderId);
    vo.first();
    // 対象データを取得できない場合エラー
    if ((vo == null) || (vo.getFetchedRowCount() == 0)) 
    {
      // 出庫実績入力明細PVO
      XxpoShippedMakeLinePVOImpl pvo = getXxpoShippedMakeLinePVO1();
      OARow prow = (OARow)pvo.first();
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10500);
    }

    // 出庫実績入力合計VO取得
    XxpoShippedMakeTotalVOImpl totalVo = getXxpoShippedMakeTotalVO1();
    // 検索を実行します。
    totalVo.initQuery(orderHeaderId);

  } // doSearchLine

  /***************************************************************************
   * 出庫実績作成ヘッダ画面の項目を全てFALSEにするメソッドです。
   * @param prow    - PVO行クラス
   ***************************************************************************
   */
  public void handleEventAllOnHdr(OARow prow)
  {
    prow.setAttribute("ShippedDateReadOnly"          , Boolean.FALSE); // 出庫日
    prow.setAttribute("ShippingInstructionsReadOnly" , Boolean.FALSE); // 摘要
    prow.setAttribute("RcvClassReadOnly"             , Boolean.FALSE); // 指示受領

  } // handleEventAllOnHdr

  /***************************************************************************
   * 出庫実績作成ヘッダ画面の項目を全てTRUEにするメソッドです。
   * @param prow    - PVO行クラス
   ***************************************************************************
   */
  public void handleEventAllOffHdr(OARow prow)
  {
    prow.setAttribute("ShippedDateReadOnly"          , Boolean.TRUE); // 出庫日
    prow.setAttribute("ShippingInstructionsReadOnly" , Boolean.TRUE); // 摘要
    prow.setAttribute("RcvClassReadOnly"             , Boolean.TRUE); // 指示受領

  } // handleEventAllOffHdr

  /***************************************************************************
   * 出庫実績入力ヘッダ画面の更新時の項目制御処理を行うメソッドです。
   * @param exeType - 起動タイプ
   * @param prow    - PVO行クラス
   * @param row     - VO行クラス
   ***************************************************************************
   */
  public void handleEventUpdHdr(
    String exeType,
    OARow prow,
    OARow row
    )
  {
    // 各種情報取得
    String notifStatus = (String)row.getAttribute("NotifStatus"); // 通知ステータス
    String transStatus = (String)row.getAttribute("TransStatus"); // ステータス
    String fixClass    = (String)row.getAttribute("FixClass");    // 金額確定済区分

    if (XxpoConstants.FIX_CLASS_ON.equals(fixClass)) 
    {
      // 参照のみ
      handleEventAllOffHdr(prow);
    } else 
    {
      // 通知ステータスが「確定通知済」の場合
      if ((XxpoConstants.NOTIF_STATUS_KTZ.equals(notifStatus))
       && (   XxpoConstants.PROV_STATUS_ZRZ.equals(transStatus) 
           || XxpoConstants.PROV_STATUS_SJK.equals(transStatus)))
      {
        // 入力可
        handleEventAllOnHdr(prow);
        String freightClass = (String)row.getAttribute("FreightChargeClass"); // 運賃区分
        // 運賃区分が「ON」の場合は出庫日制御不可
        if (XxcmnConstants.STRING_ONE.equals(freightClass)) 
        {
          prow.setAttribute("ShippedDateReadOnly", Boolean.TRUE);  
        }
        
      } else
      {
        // 参照のみ
        handleEventAllOffHdr(prow);
      }
    }
  } //  handleEventUpdHdr

  /***************************************************************************
   * 出庫実績入力明細画面の適用処理を行うメソッドです。
   * @param  exeType - 起動タイプ
   * @return HashMap - 戻り値群
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public HashMap doApply(
    String exeType
    ) throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    boolean exeFlag = false;
    // 出庫実績ヘッダVO取得
    XxpoShippedMakeHeaderVOImpl hdrVo = getXxpoShippedMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    // チェック処理
    // 在庫会計期間クローズチェックを行います。
    Date shippedDate = (Date)hdrRow.getAttribute("ShippedDate"); // 出庫日
    if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                  shippedDate))
    {
      exceptions.add( new OAAttrValException(OAAttrValException.TYP_VIEW_OBJECT,          
                                             hdrVo.getName(),
                                             hdrRow.getKey(),
                                             "ShippedDate",
                                             shippedDate,
                                             XxcmnConstants.APPL_XXPO, 
                                             XxpoConstants.XXPO10119));
    }

    // 排他チェック
    String reqNo   = (String)hdrRow.getAttribute("RequestNo"); // 依頼No
    String tokenName = null;
    chkLockAndExclusive(hdrVo, hdrRow);
    tokenName = XxpoConstants.TOKEN_NAME_UPD;

    // 追加・更新処理
    if (doExecute(hdrRow)) 
    {
      // コミット処理
      XxpoUtility.commit(getOADBTransaction());
      if (XxpoConstants.TOKEN_NAME_UPD.equals(tokenName)) 
      {
        // 初期化
        initializeHdr(exeType, reqNo);
        initializeLine(exeType);
      }
    } else
    {
      // ロールバック処理
      XxpoUtility.rollBack(getOADBTransaction());
      tokenName = null;
    }
    HashMap retParams = new HashMap();
    retParams.put("tokenName", tokenName);
    retParams.put("reqNo", reqNo);
    return retParams;
  } // doApply

  /***************************************************************************
   * 次へボタン押下時のチェックを行うメソッドです。
   * @param vo - ビューオブジェクト
   * @param row - 行オブジェクト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkNext(
    OAViewObject vo,
    OARow row
    ) throws OAException
  {
    ArrayList exceptions = new ArrayList(10);
    // 出庫日
    Date shippedDate = (Date)row.getAttribute("ShippedDate");
    // 入庫日
    Date arrivalDate = (Date)row.getAttribute("ArrivalDate");
    // システム日付を取得
    Date currentDate = getOADBTransaction().getCurrentDBDate();
    // 必須チェック
    if (XxcmnUtility.isBlankOrNull(shippedDate))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShippedDate",
                            shippedDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));
    // 出庫日が未来日の場合
    } else if (!XxcmnUtility.chkCompareDate(2, currentDate, (Date)shippedDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShippedDate",
                            shippedDate,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10244));
    // 出庫日＞入庫日の場合
    } else if (XxcmnUtility.chkCompareDate(1, shippedDate, arrivalDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShippedDate",
                            shippedDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10118));

    // 在庫会計期間クローズチェック
    } else if (XxpoUtility.chkStockClose(getOADBTransaction(), shippedDate))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShippedDate",
                            shippedDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10119));
    }
    // エラーがあった場合エラーをスローします。
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
  } // chkNext

  /***************************************************************************
   * 更新処理の追加・更新処理を行うメソッドです。
   * @param hdrRow - ヘッダ行オブジェクト
   * @return boolean - 戻り値群
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public boolean doExecute(
    OARow hdrRow
    ) throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    // 出庫実績明細VO
    XxpoShippedMakeLineVOImpl vo = getXxpoShippedMakeLineVO1();
    boolean lineExeFlag = false;
    boolean hdrExeFlag  = false;
    boolean shippedExeFlag  = false;

    // ヘッダ更新処理
    hdrExeFlag = executeOrderHeader(hdrRow);

    // 明細更新行取得
    Row[] lineRows = vo.getFilteredRows("RecordType", XxcmnConstants.STRING_N);
    if ((lineRows != null) || (lineRows.length > 0)) 
    {
      OARow lineRow = null;
      for (int i = 0; i < lineRows.length; i++)
      {
        // i番目の行を取得
        lineRow = (OARow)lineRows[i];

        // 明細更新処理
        if (executeOrderLine(hdrRow, lineRow)) 
        {
          // 明細実行フラグをtrueに変更
          lineExeFlag = true;
        }
      }
    }

    // 出庫処理
    // ステータスが「出荷実績計上済」で出庫日が変更されていた場合
    if ( XxcmnUtility.isEquals(hdrRow.getAttribute("TransStatus"), XxpoConstants.PROV_STATUS_SJK)
     && !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippedDate"), hdrRow.getAttribute("DbShippedDate")))
    {

      // 出庫処理
      String requestNo = (String)hdrRow.getAttribute("RequestNo");
      XxwshUtility.doShipRequestAndResultEntry(getOADBTransaction(), requestNo);
      shippedExeFlag = true;
      // エラーがあった場合エラーをスローします。
      if (exceptions.size() > 0)
      {
        //トークン生成
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_CONC_NAME,
                                                   XxwshConstants.TOKEN_NAME_PGM_NAME_420001C) };
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxpoConstants.XXPO10024, 
                              tokens);
      }
    }
    
    if (hdrExeFlag || lineExeFlag || shippedExeFlag) 
    {
      return true;
    } else
    {
      return false;
    }
  } // doExecute

  /***************************************************************************
   * 受注ヘッダアドオンのデータを更新します。
   * @param hdrRow - 更新対象行
   * @return boolean - 更新実行
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public boolean executeOrderHeader(
    OARow hdrRow
    ) throws OAException
  {
    String apiName      = "executeOrderHeader";
    boolean hdrExeFlag  = false;

    // 出庫日、摘要、指示受領が変更された場合
    if (!XxcmnUtility.isEquals(hdrRow.getAttribute("ShippedDate"),          
                               hdrRow.getAttribute("DbShippedDate")) 
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippingInstructions"),           
                               hdrRow.getAttribute("DbShippingInstructions"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("RcvClass"),                       
                               hdrRow.getAttribute("DbRcvClass")))
    {
      // 出庫日が変更されていた場合
      if (!XxcmnUtility.isEquals(hdrRow.getAttribute("ShippedDate"),            
                                 hdrRow.getAttribute("DbShippedDate")))
      {
        // ステータスが「出荷実績計上済」の場合
        if (XxcmnUtility.isEquals(hdrRow.getAttribute("TransStatus"), XxpoConstants.PROV_STATUS_SJK))
        {
          // ヘッダ実績変更処理
          orderHeaderInsUpd(hdrRow);
          hdrExeFlag  = true;
        } else 
        {
          // ヘッダの更新
          updateOrderHeader(hdrRow);
          // 移動ロット詳細の更新
          updateMovLotDetails(hdrRow);
          hdrExeFlag  = true;
        }
      } else
      {
        // ヘッダの更新
        updateOrderHeader(hdrRow);
        hdrExeFlag  = true;
      }
    }
    return hdrExeFlag;
  } // executeOrderHeader

  /***************************************************************************
   * 受注明細アドオンのデータを更新します。
   * @param hdrRow  - 更新対象ヘッダ行
   * @param lineRow - 更新対象明細行
   * @return boolean - 更新実行
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public boolean executeOrderLine(
    OARow hdrRow,
    OARow lineRow
    ) throws OAException
  {
    String apiName      = "executeOrderLine";
    boolean lineExeFlag = false;

    // ステータスが「出荷実績計上済」で出庫日が変更されていた場合
    if ( XxcmnUtility.isEquals(hdrRow.getAttribute("TransStatus"), XxpoConstants.PROV_STATUS_SJK)
     && !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippedDate"), hdrRow.getAttribute("DbShippedDate")))
    {

      // 受注明細アドオンIDのシーケンス取得
      Number newOrderLineId = getOrderLineId(getOADBTransaction());

      // 明細実績変更処理(新規受注明細作成)
      insertOrderLine(lineRow, newOrderLineId);
      // 明細実績変更処理(新規移動ロット明細作成)
      insertMovLotDetails(hdrRow, lineRow, newOrderLineId);
      lineExeFlag = true;
    } else
    {
      // 明細の以下の項目が更新された場合
      // ・備考
      if (!XxcmnUtility.isEquals(lineRow.getAttribute("LineDescription"), 
                                 lineRow.getAttribute("DbLineDescription")))
      {
        // 明細行の更新
        updateOrderLine(lineRow);
        lineExeFlag = true;
      }
    }
    return lineExeFlag;
  } // executeOrderLine 

  /***************************************************************************
   * 受注ヘッダアドオンの実績変更処理を行います。
   * @param updRow - 更新対象行
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void orderHeaderInsUpd(
    OARow updRow
    ) throws OAException
  {
    String apiName = "orderHeaderInsUpd";
    
    // 新ヘッダの作成
    insertOrderHeader(updRow);
    // 旧ヘッダの更新
    updateOldOrderHeader(updRow);

  } // orderHeaderInsUpd

  /***************************************************************************
   * 受注ヘッダアドオンにデータを追加します。
   * @param hdrRow - ヘッダ行
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void insertOrderHeader(
    OARow hdrRow
    ) throws OAException
  {
    String apiName = "insertOrderHeader";

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  INSERT INTO xxwsh_order_headers_all(");
    sb.append("    order_header_id                  "); // 受注ヘッダアドオンID
    sb.append("   ,order_type_id                    "); // 受注タイプID
    sb.append("   ,organization_id                  "); // 組織ID
    sb.append("   ,latest_external_flag             "); // 最新フラグ
    sb.append("   ,ordered_date                     "); // 受注日
    sb.append("   ,customer_id                      "); // 顧客ID
    sb.append("   ,customer_code                    "); // 顧客
    sb.append("   ,deliver_to_id                    "); // 出荷先ID
    sb.append("   ,deliver_to                       "); // 出荷先
    sb.append("   ,shipping_instructions            "); // 出荷指示
    sb.append("   ,career_id                        "); // 運送業者ID
    sb.append("   ,freight_carrier_code             "); // 運送業者
    sb.append("   ,shipping_method_code             "); // 配送区分
    sb.append("   ,cust_po_number                   "); // 顧客発注
    sb.append("   ,price_list_id                    "); // 価格表
    sb.append("   ,request_no                       "); // 依頼No
    sb.append("   ,req_status                       "); // ステータス
    sb.append("   ,delivery_no                      "); // 配送No
    sb.append("   ,prev_delivery_no                 "); // 前回配送No
    sb.append("   ,schedule_ship_date               "); // 出荷予定日
    sb.append("   ,schedule_arrival_date            "); // 着荷予定日
    sb.append("   ,mixed_no                         "); // 混載元No
    sb.append("   ,collected_pallet_qty             "); // パレット回収枚数
    sb.append("   ,confirm_request_class            "); // 物流担当確認依頼区分
    sb.append("   ,freight_charge_class             "); // 運賃区分
    sb.append("   ,shikyu_instruction_class         "); // 支給出庫指示区分
    sb.append("   ,shikyu_inst_rcv_class            "); // 支給指示受領区分
    sb.append("   ,amount_fix_class                 "); // 有償金額確定区分
    sb.append("   ,takeback_class                   "); // 引取区分
    sb.append("   ,deliver_from_id                  "); // 出荷元ID
    sb.append("   ,deliver_from                     "); // 出荷元保管場所
    sb.append("   ,head_sales_branch                "); // 管轄拠点
    sb.append("   ,input_sales_branch               "); // 入力拠点
    sb.append("   ,po_no                            "); // 発注No
    sb.append("   ,prod_class                       "); // 商品区分
    sb.append("   ,item_class                       "); // 品目区分
    sb.append("   ,no_cont_freight_class            "); // 契約外運賃区分
    sb.append("   ,arrival_time_from                "); // 着荷時間FROM
    sb.append("   ,arrival_time_to                  "); // 着荷時間TO
    sb.append("   ,designated_item_id               "); // 製造品目ID
    sb.append("   ,designated_item_code             "); // 製造品目
    sb.append("   ,designated_production_date       "); // 製造日
    sb.append("   ,designated_branch_no             "); // 製造枝番
    sb.append("   ,slip_number                      "); // 送り状No
    sb.append("   ,sum_quantity                     "); // 合計数量
    sb.append("   ,small_quantity                   "); // 小口個数
    sb.append("   ,label_quantity                   "); // ラベル枚数
    sb.append("   ,loading_efficiency_weight        "); // 重量積載効率
    sb.append("   ,loading_efficiency_capacity      "); // 容積積載効率
    sb.append("   ,based_weight                     "); // 基本重量
    sb.append("   ,based_capacity                   "); // 基本容積
    sb.append("   ,sum_weight                       "); // 積載重量合計
    sb.append("   ,sum_capacity                     "); // 積載容積合計
    sb.append("   ,mixed_ratio                      "); // 混載率
    sb.append("   ,pallet_sum_quantity              "); // パレット合計枚数
    sb.append("   ,real_pallet_quantity             "); // パレット実績枚数
    sb.append("   ,sum_pallet_weight                "); // 合計パレット重量
    sb.append("   ,order_source_ref                 "); // 受注ソース参照
    sb.append("   ,result_freight_carrier_id        "); // 運送業者_実績ID
    sb.append("   ,result_freight_carrier_code      "); // 運送業者_実績
    sb.append("   ,result_shipping_method_code      "); // 配送区分_実績
    sb.append("   ,result_deliver_to_id             "); // 出荷先_実績ID
    sb.append("   ,result_deliver_to                "); // 出荷先_実績
    sb.append("   ,shipped_date                     "); // 出荷日
    sb.append("   ,arrival_date                     "); // 着荷日
    sb.append("   ,weight_capacity_class            "); // 重量容積区分
    sb.append("   ,actual_confirm_class             "); // 実績計上済区分
    sb.append("   ,notif_status                     "); // 通知ステータス
    sb.append("   ,prev_notif_status                "); // 前回通知ステータス
    sb.append("   ,notif_date                       "); // 確定通知実施日時
    sb.append("   ,new_modify_flg                   "); // 新規修正フラグ
    sb.append("   ,process_status                   "); // 処理経過ステータス
    sb.append("   ,performance_management_dept      "); // 成績管理部署
    sb.append("   ,instruction_dept                 "); // 指示部署
    sb.append("   ,transfer_location_id             "); // 振替先ID
    sb.append("   ,transfer_location_code           "); // 振替先
    sb.append("   ,mixed_sign                       "); // 混載記号
    sb.append("   ,screen_update_date               "); // 画面更新日時
    sb.append("   ,screen_update_by                 "); // 画面更新者
    sb.append("   ,tightening_date                  "); // 出荷依頼締め日時
    sb.append("   ,vendor_id                        "); // 取引先ID
    sb.append("   ,vendor_code                      "); // 取引先
    sb.append("   ,vendor_site_id                   "); // 取引先サイトID
    sb.append("   ,vendor_site_code                 "); // 取引先サイト
    sb.append("   ,registered_sequence              "); // 登録順序
    sb.append("   ,tightening_program_id            "); // 締めコンカレントID
    sb.append("   ,corrected_tighten_class          "); // 締め後修正区分
    sb.append("   ,created_by                       "); // 作成者
    sb.append("   ,creation_date                    "); // 作成日
    sb.append("   ,last_updated_by                  "); // 最終更新者
    sb.append("   ,last_update_date                 "); // 最終更新日
    sb.append("   ,last_update_login )              "); // 最終更新ログイン
    sb.append("  SELECT ");
    sb.append("    :1                               "); // 受注ヘッダアドオンID
    sb.append("   ,xoha.order_type_id               "); // 受注タイプID
    sb.append("   ,xoha.organization_id             "); // 組織ID
    sb.append("   ,'Y'                              "); // 最新フラグ
    sb.append("   ,xoha.ordered_date                "); // 受注日
    sb.append("   ,xoha.customer_id                 "); // 顧客ID
    sb.append("   ,xoha.customer_code               "); // 顧客
    sb.append("   ,xoha.deliver_to_id               "); // 出荷先ID
    sb.append("   ,xoha.deliver_to                  "); // 出荷先
    sb.append("   ,:2                               "); // 出荷指示
    sb.append("   ,xoha.career_id                   "); // 運送業者ID
    sb.append("   ,xoha.freight_carrier_code        "); // 運送業者
    sb.append("   ,xoha.shipping_method_code        "); // 配送区分
    sb.append("   ,xoha.cust_po_number              "); // 顧客発注
    sb.append("   ,xoha.price_list_id               "); // 価格表
    sb.append("   ,xoha.request_no                  "); // 依頼No
    sb.append("   ,xoha.req_status                  "); // ステータス
    sb.append("   ,xoha.delivery_no                 "); // 配送No
    sb.append("   ,xoha.prev_delivery_no            "); // 前回配送No
    sb.append("   ,xoha.schedule_ship_date          "); // 出荷予定日
    sb.append("   ,xoha.schedule_arrival_date       "); // 着荷予定日
    sb.append("   ,xoha.mixed_no                    "); // 混載元No
    sb.append("   ,xoha.collected_pallet_qty        "); // パレット回収枚数
    sb.append("   ,xoha.confirm_request_class       "); // 物流担当確認依頼区分
    sb.append("   ,xoha.freight_charge_class        "); // 運賃区分
    sb.append("   ,xoha.shikyu_instruction_class    "); // 支給出庫指示区分
    sb.append("   ,:3                               "); // 支給指示受領区分
    sb.append("   ,xoha.amount_fix_class            "); // 有償金額確定区分
    sb.append("   ,xoha.takeback_class              "); // 引取区分
    sb.append("   ,xoha.deliver_from_id             "); // 出荷元ID
    sb.append("   ,xoha.deliver_from                "); // 出荷元保管場所
    sb.append("   ,xoha.head_sales_branch           "); // 管轄拠点
    sb.append("   ,xoha.input_sales_branch          "); // 入力拠点
    sb.append("   ,xoha.po_no                       "); // 発注No
    sb.append("   ,xoha.prod_class                  "); // 商品区分
    sb.append("   ,xoha.item_class                  "); // 品目区分
    sb.append("   ,xoha.no_cont_freight_class       "); // 契約外運賃区分
    sb.append("   ,xoha.arrival_time_from           "); // 着荷時間FROM
    sb.append("   ,xoha.arrival_time_to             "); // 着荷時間TO
    sb.append("   ,xoha.designated_item_id          "); // 製造品目ID
    sb.append("   ,xoha.designated_item_code        "); // 製造品目
    sb.append("   ,xoha.designated_production_date  "); // 製造日
    sb.append("   ,xoha.designated_branch_no        "); // 製造枝番
    sb.append("   ,xoha.slip_number                 "); // 送り状No
    sb.append("   ,xoha.sum_quantity                "); // 合計数量
    sb.append("   ,xoha.small_quantity              "); // 小口個数
    sb.append("   ,xoha.label_quantity              "); // ラベル枚数
    sb.append("   ,xoha.loading_efficiency_weight   "); // 重量積載効率
    sb.append("   ,xoha.loading_efficiency_capacity "); // 容積積載効率
    sb.append("   ,xoha.based_weight                "); // 基本重量
    sb.append("   ,xoha.based_capacity              "); // 基本容積
    sb.append("   ,xoha.sum_weight                  "); // 積載重量合計
    sb.append("   ,xoha.sum_capacity                "); // 積載容積合計
    sb.append("   ,xoha.mixed_ratio                 "); // 混載率
    sb.append("   ,xoha.pallet_sum_quantity         "); // パレット合計枚数
    sb.append("   ,xoha.real_pallet_quantity        "); // パレット実績枚数
    sb.append("   ,xoha.sum_pallet_weight           "); // 合計パレット重量
    sb.append("   ,xoha.order_source_ref            "); // 受注ソース参照
    sb.append("   ,xoha.result_freight_carrier_id   "); // 運送業者_実績ID
    sb.append("   ,xoha.result_freight_carrier_code "); // 運送業者_実績
    sb.append("   ,xoha.result_shipping_method_code "); // 配送区分_実績
    sb.append("   ,xoha.result_deliver_to_id        "); // 出荷先_実績ID
    sb.append("   ,xoha.result_deliver_to           "); // 出荷先_実績
    sb.append("   ,:4                               "); // 出荷日
    sb.append("   ,xoha.arrival_date                "); // 着荷日
    sb.append("   ,xoha.weight_capacity_class       "); // 重量容積区分
    sb.append("   ,'N'                              "); // 実績計上済区分
    sb.append("   ,xoha.notif_status                "); // 通知ステータス
    sb.append("   ,xoha.prev_notif_status           "); // 前回通知ステータス
    sb.append("   ,xoha.notif_date                  "); // 確定通知実施日時
    sb.append("   ,xoha.new_modify_flg              "); // 新規修正フラグ
    sb.append("   ,xoha.process_status              "); // 処理経過ステータス
    sb.append("   ,xoha.performance_management_dept "); // 成績管理部署
    sb.append("   ,xoha.instruction_dept            "); // 指示部署
    sb.append("   ,xoha.transfer_location_id        "); // 振替先ID
    sb.append("   ,xoha.transfer_location_code      "); // 振替先
    sb.append("   ,xoha.mixed_sign                  "); // 混載記号
    sb.append("   ,xoha.screen_update_date          "); // 画面更新日時
    sb.append("   ,xoha.screen_update_by            "); // 画面更新者
    sb.append("   ,xoha.tightening_date             "); // 出荷依頼締め日時
    sb.append("   ,xoha.vendor_id                   "); // 取引先ID
    sb.append("   ,xoha.vendor_code                 "); // 取引先
    sb.append("   ,xoha.vendor_site_id              "); // 取引先サイトID
    sb.append("   ,xoha.vendor_site_code            "); // 取引先サイト
    sb.append("   ,xoha.registered_sequence         "); // 登録順序
    sb.append("   ,xoha.tightening_program_id       "); // 締めコンカレントID
    sb.append("   ,xoha.corrected_tighten_class     "); // 締め後修正区分
    sb.append("   ,FND_GLOBAL.USER_ID               "); // 作成者
    sb.append("   ,SYSDATE                          "); // 作成日
    sb.append("   ,FND_GLOBAL.USER_ID               "); // 最終更新者
    sb.append("   ,SYSDATE                          "); // 最終更新日
    sb.append("   ,FND_GLOBAL.LOGIN_ID              "); // 最終更新ログイン
    sb.append("  FROM  xxwsh_order_headers_all xoha "); // 受注ヘッダアドオン
    sb.append("  WHERE xoha.order_header_id = :5 ;  "); // 受注ヘッダアドオンID(既存)
    sb.append("END; ");

    // PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(sb.toString(),
                                                                           OADBTransaction.DEFAULT);
    try
    {
      // 受注ヘッダアドオンIDのシーケンス取得
      Number newOrderHeaderId = XxpoUtility.getOrderHeaderId(getOADBTransaction());

      // 情報を取得
      String shippingInstructions  = (String)hdrRow.getAttribute("ShippingInstructions"); // 出荷指示
      String shikyuInstRcvClass    = (String)hdrRow.getAttribute("RcvClass");             // 支給指示受領区分
      Date   shippedDate           = (Date)hdrRow.getAttribute("ShippedDate");            // 出荷日
      Number oldOrderHeaderId      = (Number)hdrRow.getAttribute("OrderHeaderId");        // 受注ヘッダアドオンID

      int i = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setInt(i++, XxcmnUtility.intValue(newOrderHeaderId));                         // 受注ヘッダアドオンID
      cstmt.setString(i++, shippingInstructions);                                         // 出荷指示
      cstmt.setString(i++, shikyuInstRcvClass);                                           // 支給指示受領区分
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));                            // 出荷日
      cstmt.setInt(i++, XxcmnUtility.intValue(oldOrderHeaderId));                         // 受注ヘッダアドオンID
     
      // PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
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
        XxpoUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // insertOrderHeader 

  /***************************************************************************
   * 旧受注ヘッダアドオンのデータを更新します。
   * @param hdrRow - ヘッダ行
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void updateOldOrderHeader(
    OARow hdrRow
    ) throws OAException
  {
    String apiName = "updateOldOrderHeader";

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_headers_all xoha ");
    sb.append("  SET   xoha.latest_external_flag = 'N' " );                // 最新フラグ
    sb.append("       ,xoha.last_updated_by      = FND_GLOBAL.USER_ID  "); // 最終更新者
    sb.append("       ,xoha.last_update_date     = SYSDATE ");             // 最終更新日
    sb.append("       ,xoha.last_update_login    = FND_GLOBAL.LOGIN_ID "); // 最終更新ログイン
    sb.append("  WHERE xoha.order_header_id      = :1 ;                "); // 受注ヘッダアドオンID
    sb.append("END; ");

    // PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(sb.toString(),
                                                                           OADBTransaction.DEFAULT);
    try
    {
      // 情報を取得
      Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID

      int i = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID
     
      // PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
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
        XxpoUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateOldOrderHeader 

  /***************************************************************************
   * 受注ヘッダアドオンのデータを更新します。
   * @param hdrRow - ヘッダ行
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void updateOrderHeader(
    OARow hdrRow
    ) throws OAException
  {
    String apiName = "updateOrderHeader";

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_headers_all xoha ");
    sb.append("  SET    xoha.shipped_date          = :1 ");                  // 出荷日
    sb.append("        ,xoha.shipping_instructions = :2 ");                  // 出荷指示
    sb.append("        ,xoha.shikyu_inst_rcv_class = :3 ");                  // 支給指示受領区分
    sb.append("        ,xoha.result_freight_carrier_id   = NVL(xoha.result_freight_carrier_id, xoha.career_id) " );              // 運送業者_実績ID
    sb.append("        ,xoha.result_freight_carrier_code = NVL(xoha.result_freight_carrier_code, xoha.freight_carrier_code) " ); // 運送業者_実績
    sb.append("        ,xoha.result_shipping_method_code = NVL(xoha.result_shipping_method_code, xoha.shipping_method_code) " ); // 配送区分_実績
    sb.append("        ,xoha.last_updated_by       = FND_GLOBAL.USER_ID  "); // 最終更新者
    sb.append("        ,xoha.last_update_date      = SYSDATE ");             // 最終更新日
    sb.append("        ,xoha.last_update_login     = FND_GLOBAL.LOGIN_ID "); // 最終更新ログイン
    sb.append("  WHERE  xoha.order_header_id       = :4 ;                "); // 受注ヘッダアドオンID
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(sb.toString(),
                                                                           OADBTransaction.DEFAULT);
    try
    {
      // 情報を取得
      Date   shippedDate          = (Date)hdrRow.getAttribute("ShippedDate");            // 出荷日
      String shippingInstructions = (String)hdrRow.getAttribute("ShippingInstructions"); // 出荷指示
      String shikyuInstRcvClass   = (String)hdrRow.getAttribute("RcvClass");             // 支給指示受領区分
      Number orderHeaderId        = (Number)hdrRow.getAttribute("OrderHeaderId");        // 受注ヘッダアドオンID

      int i = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));                           // 出荷日
      cstmt.setString(i++, shippingInstructions);                                        // 出荷指示
      cstmt.setString(i++, shikyuInstRcvClass);                                          // 支給指示受領区分
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));                           // 受注ヘッダアドオンID
     
      // PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
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
        XxpoUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateOrderHeader 

  /***************************************************************************
   * 移動ロット詳細のデータを更新します。
   * @param hdrRow - ヘッダ行
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void updateMovLotDetails(
    OARow hdrRow
    ) throws OAException
  {
    String apiName = "updateMovLotDetails";

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxinv_mov_lot_details xmld ");
    sb.append("  SET   xmld.actual_date       = :1 " );                 // 実績日
    sb.append("       ,xmld.last_updated_by   = FND_GLOBAL.USER_ID  "); // 最終更新者
    sb.append("       ,xmld.last_update_date  = SYSDATE ");             // 最終更新日
    sb.append("       ,xmld.last_update_login = FND_GLOBAL.LOGIN_ID "); // 最終更新ログイン
    sb.append("  WHERE xmld.mov_line_id IN ( SELECT xola.order_line_id  " ); // 明細ID
    sb.append("                              FROM   xxwsh_order_lines_all xola "); // 受注明細アドオン
    sb.append("                              WHERE  xola.order_header_id = :2 ");  // 受注ヘッダアドオンID
    sb.append("                            )  ");
    sb.append("  AND   xmld.record_type_code   = '20'  "); // レコードタイプ：出庫
    sb.append("  AND   xmld.document_type_code = '30'; "); // 文書タイプ：支給指示
    sb.append("END; ");

    // PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(sb.toString(),
                                                                           OADBTransaction.DEFAULT);
    try
    {
      // 情報を取得
      Date   actualDate     = (Date)hdrRow.getAttribute("ShippedDate");     // 出荷日
      Number orderHeaderId  = (Number)hdrRow.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID

      int i = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setDate(i++, XxcmnUtility.dateValue(actualDate));  // 出荷日
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID
     
      // PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
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
        XxpoUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateMovLotDetails 

  /***************************************************************************
   * 受注明細アドオンにデータを追加します。
   * @param lineRow - 明細行
   * @param newOrderLineID   - 受注明細アドオンID(新規採番)
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void insertOrderLine(
    OARow lineRow,
    Number newOrderLineID
    ) throws OAException
  {
    String apiName = "insertOrderLine";

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  INSERT INTO xxwsh_order_lines_all(");
    sb.append("    order_line_id                   "); // 受注明細アドオンID
    sb.append("   ,order_header_id                 "); // 受注ヘッダアドオンID
    sb.append("   ,order_line_number               "); // 明細番号
    sb.append("   ,request_no                      "); // 依頼No
    sb.append("   ,shipping_inventory_item_id      "); // 出荷品目ID
    sb.append("   ,shipping_item_code              "); // 出荷品目
    sb.append("   ,quantity                        "); // 数量
    sb.append("   ,uom_code                        "); // 単位
    sb.append("   ,unit_price                      "); // 単価
    sb.append("   ,shipped_quantity                "); // 出荷実績数量
    sb.append("   ,designated_production_date      "); // 指定製造日
    sb.append("   ,based_request_quantity          "); // 拠点依頼数量
    sb.append("   ,request_item_id                 "); // 依頼品目ID
    sb.append("   ,request_item_code               "); // 依頼品目
    sb.append("   ,ship_to_quantity                "); // 入庫実績数量
    sb.append("   ,futai_code                      "); // 付帯コード
    sb.append("   ,designated_date                 "); // 指定日付（リーフ）
    sb.append("   ,move_number                     "); // 移動No
    sb.append("   ,po_number                       "); // 発注No
    sb.append("   ,cust_po_number                  "); // 顧客発注
    sb.append("   ,pallet_quantity                 "); // パレット数
    sb.append("   ,layer_quantity                  "); // 段数
    sb.append("   ,case_quantity                   "); // ケース数
    sb.append("   ,weight                          "); // 重量
    sb.append("   ,capacity                        "); // 容積
    sb.append("   ,pallet_qty                      "); // パレット枚数
    sb.append("   ,pallet_weight                   "); // パレット重量
    sb.append("   ,reserved_quantity               "); // 引当数
    sb.append("   ,automanual_reserve_class        "); // 自動手動引当区分
    sb.append("   ,delete_flag                     "); // 削除フラグ
    sb.append("   ,warning_class                   "); // 警告区分
    sb.append("   ,warning_date                    "); // 警告日付
    sb.append("   ,line_description                "); // 摘要
    sb.append("   ,rm_if_flg                       "); // 倉替返品インタフェース済フラグ
    sb.append("   ,shipping_request_if_flg         "); // 出荷依頼インタフェース済フラグ
    sb.append("   ,shipping_result_if_flg          "); // 出荷実績インタフェース済フラグ
    sb.append("   ,created_by                      "); // 作成者
    sb.append("   ,creation_date                   "); // 作成日
    sb.append("   ,last_updated_by                 "); // 最終更新者
    sb.append("   ,last_update_date                "); // 最終更新日
    sb.append("   ,last_update_login )             "); // 最終更新ログイン
    sb.append("  SELECT ");
    sb.append("    :1                              "); // 受注明細アドオンID
    sb.append("   ,xohan.order_header_id           "); // 受注ヘッダアドオンID
    sb.append("   ,xola.order_line_number          "); // 明細番号
    sb.append("   ,xola.request_no                 "); // 依頼No
    sb.append("   ,xola.shipping_inventory_item_id "); // 出荷品目ID
    sb.append("   ,xola.shipping_item_code         "); // 出荷品目
    sb.append("   ,xola.quantity                   "); // 数量
    sb.append("   ,xola.uom_code                   "); // 単位
    sb.append("   ,xola.unit_price                 "); // 単価
    sb.append("   ,xola.shipped_quantity           "); // 出荷実績数量
    sb.append("   ,xola.designated_production_date "); // 指定製造日
    sb.append("   ,xola.based_request_quantity     "); // 拠点依頼数量
    sb.append("   ,xola.request_item_id            "); // 依頼品目ID
    sb.append("   ,xola.request_item_code          "); // 依頼品目
    sb.append("   ,xola.ship_to_quantity           "); // 入庫実績数量
    sb.append("   ,xola.futai_code                 "); // 付帯コード
    sb.append("   ,xola.designated_date            "); // 指定日付（リーフ）
    sb.append("   ,xola.move_number                "); // 移動No
    sb.append("   ,xola.po_number                  "); // 発注No
    sb.append("   ,xola.cust_po_number             "); // 顧客発注
    sb.append("   ,xola.pallet_quantity            "); // パレット数
    sb.append("   ,xola.layer_quantity             "); // 段数
    sb.append("   ,xola.case_quantity              "); // ケース数
    sb.append("   ,xola.weight                     "); // 重量
    sb.append("   ,xola.capacity                   "); // 容積
    sb.append("   ,xola.pallet_qty                 "); // パレット枚数
    sb.append("   ,xola.pallet_weight              "); // パレット重量
    sb.append("   ,xola.reserved_quantity          "); // 引当数
    sb.append("   ,xola.automanual_reserve_class   "); // 自動手動引当区分
    sb.append("   ,xola.delete_flag                "); // 削除フラグ
    sb.append("   ,xola.warning_class              "); // 警告区分
    sb.append("   ,xola.warning_date               "); // 警告日付
    sb.append("   ,:2                              "); // 摘要
    sb.append("   ,xola.rm_if_flg                  "); // 倉替返品インタフェース済フラグ
    sb.append("   ,xola.shipping_request_if_flg    "); // 出荷依頼インタフェース済フラグ
    sb.append("   ,xola.shipping_result_if_flg     "); // 出荷実績インタフェース済フラグ
    sb.append("   ,FND_GLOBAL.USER_ID              "); // 作成者
    sb.append("   ,SYSDATE                         "); // 作成日
    sb.append("   ,FND_GLOBAL.USER_ID              "); // 最終更新者
    sb.append("   ,SYSDATE                         "); // 最終更新日
    sb.append("   ,FND_GLOBAL.LOGIN_ID             "); // 最終更新ログイン
    sb.append("  FROM  xxwsh_order_lines_all  xola "); // 受注明細アドオン
    sb.append("       ,xxwsh_order_headers_all xohao "); // 受注ヘッダアドオン(既存)
    sb.append("       ,xxwsh_order_headers_all xohan "); // 受注ヘッダアドオン(新規)
    sb.append("  WHERE xola.order_line_id   = :3   "); // 受注明細アドオンID(既存)
    sb.append("  AND   xola.order_header_id = :4   "); // 受注ヘッダアドオンID(既存)
    sb.append("  AND   xohao.order_header_id = xola.order_header_id   "); // 受注ヘッダアドオン(既存)を取得
    sb.append("  AND   xohan.request_no      = xohao.request_no   ");     // 受注ヘッダアドオン(既存)の依頼Noで受注ヘッダアドオン(新規)を取得
    sb.append("  AND   xohan.latest_external_flag = 'Y' ; ");             // 最新フラグが'Y'のデータ
    sb.append("END; ");

    // PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(sb.toString(),
                                                                           OADBTransaction.DEFAULT);
    try
    {
      // 情報を取得
      Number newOrderLineId    = (Number)newOrderLineID;                          // 受注明細アドオンID
      String lineDescription   = (String)lineRow.getAttribute("LineDescription"); // 摘要
      Number oldOrderLineId    = (Number)lineRow.getAttribute("OrderLineId");     // 受注明細アドオンID
      Number oldOrderHeaderId  = (Number)lineRow.getAttribute("OrderHeaderId");   // 受注ヘッダアドオンID

      int i = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setInt(i++, XxcmnUtility.intValue(newOrderLineId));   // 受注明細アドオンID
      cstmt.setString(i++, lineDescription);                      // 摘要
      cstmt.setInt(i++, XxcmnUtility.intValue(oldOrderLineId));   // 受注明細アドオンID
      cstmt.setInt(i++, XxcmnUtility.intValue(oldOrderHeaderId)); // 受注ヘッダアドオンID
     
      // PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
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
        XxpoUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // insertOrderLine 

  /***************************************************************************
   * 移動ロット明細にデータを追加します。
   * @param hdrRow - ヘッダ行
   * @param lineRow - 明細行
   * @param newOrderLineID - 明細ID(新規採番)
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void insertMovLotDetails(
    OARow hdrRow,
    OARow lineRow,
    Number newOrderLineID
    ) throws OAException
  {
    String apiName      = "insertMovLotDetails";

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  INSERT INTO xxinv_mov_lot_details                            "); // 移動ロット詳細
    sb.append("            ( mov_lot_dtl_id                                   "); // ロット詳細ID
    sb.append("             ,mov_line_id                                      "); // 明細ID
    sb.append("             ,document_type_code                               "); // 文書タイプ
    sb.append("             ,record_type_code                                 "); // レコードタイプ
    sb.append("             ,item_id                                          "); // OPM品目ID
    sb.append("             ,item_code                                        "); // 品目
    sb.append("             ,lot_id                                           "); // ロットID
    sb.append("             ,lot_no                                           "); // ロットNo
    sb.append("             ,actual_date                                      "); // 実績日
    sb.append("             ,actual_quantity                                  "); // 実績数量
    sb.append("             ,automanual_reserve_class                         "); // 自動手動引当区分
    sb.append("             ,created_by                                       "); // 作成者
    sb.append("             ,creation_date                                    "); // 作成日
    sb.append("             ,last_updated_by                                  "); // 最終更新者
    sb.append("             ,last_update_date                                 "); // 最終更新日
    sb.append("             ,last_update_login )                              "); // 最終更新ログイン
    sb.append("      SELECT  xxinv_mov_lot_s1.NEXTVAL                         "); // 移動ロット詳細識別用
    sb.append("             ,:1                                               "); // 明細ID(新規採番)
    sb.append("             ,xmld.document_type_code                          "); // 文書タイプ
    sb.append("             ,xmld.record_type_code                            "); // レコードタイプ
    sb.append("             ,xmld.item_id                                     "); // OPM品目ID
    sb.append("             ,xmld.item_code                                   "); // 品目
    sb.append("             ,xmld.lot_id                                      "); // ロットID
    sb.append("             ,xmld.lot_no                                      "); // ロットNo
    sb.append("             ,CASE                                             "); // 実績日
    sb.append("                WHEN  xmld.record_type_code = '20' THEN        "); //   レコードタイプ20：出庫実績の場合、出荷日洗い替え
    sb.append("                    :2                                         ");
    sb.append("                ELSE                                           "); //   それ以外の場合、出荷日洗い替えは行わない。
    sb.append("                    xmld.actual_date                           ");
    sb.append("              END                                              ");
    sb.append("             ,xmld.actual_quantity                             "); // 実績数量
    sb.append("             ,xmld.automanual_reserve_class                    "); // 自動手動引当区分
    sb.append("             ,FND_GLOBAL.USER_ID                               "); // 作成者
    sb.append("             ,SYSDATE                                          "); // 作成日
    sb.append("             ,FND_GLOBAL.USER_ID                               "); // 最終更新者
    sb.append("             ,SYSDATE                                          "); // 最終更新日
    sb.append("             ,FND_GLOBAL.LOGIN_ID                              "); // 最終更新ログイン
    sb.append("      FROM    xxinv_mov_lot_details xmld                       "); // 移動ロット詳細
    sb.append("      WHERE   xmld.mov_line_id    = :3 ;                       "); // 受注明細アドオンID(既存)
    sb.append("END; ");

    // PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(sb.toString(),
                                                                           OADBTransaction.DEFAULT);
    try
    {
      // 情報を取得
      Number orderLineId       = (Number)newOrderLineID;                      // 受注明細アドオンID(新規採番)
      Date   actualDate        = (Date)hdrRow.getAttribute("ShippedDate");    // 出荷日
      Number oldOrderLineID    = (Number)lineRow.getAttribute("OrderLineId"); // 受注明細アドオンID(既存)

      int i = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setInt(i++, XxcmnUtility.intValue(orderLineId));    // 受注明細アドオンID(新規採番)
      cstmt.setDate(i++, XxcmnUtility.dateValue(actualDate));   // 出荷日
      cstmt.setInt(i++, XxcmnUtility.intValue(oldOrderLineID)); // 受注明細アドオンID(既存)
     
      // PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
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
        XxpoUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // insertMovLotDetails 

  /***************************************************************************
   * 受注明細アドオンのデータを更新します。
   * @param updRow - 更新対象行
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void updateOrderLine(
    OARow updRow
    ) throws OAException
  {
    String apiName      = "updateOrderLine";

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_lines_all xola ");
    sb.append("  SET    xola.line_description  = :1 " ); // 摘要
    sb.append("        ,xola.last_updated_by   = FND_GLOBAL.USER_ID  "); // 最終更新者
    sb.append("        ,xola.last_update_date  = SYSDATE "            ); // 最終更新日
    sb.append("        ,xola.last_update_login = FND_GLOBAL.LOGIN_ID "); // 最終更新ログイン
    sb.append("  WHERE  xola.order_line_id     = :2 ;                "); // 受注明細アドオンID
    sb.append("END; ");

    // PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(sb.toString(),
                                                                           OADBTransaction.DEFAULT);
    try
    {
      // 情報を取得
      String lineDescription = (String)updRow.getAttribute("LineDescription"); // 摘要
      Number orderLineId     = (Number)updRow.getAttribute("OrderLineId");     // 受注明細アドオンID
      
      int i = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setString(i++, lineDescription);                 // 摘要
      cstmt.setInt(i++, XxcmnUtility.intValue(orderLineId)); // 受注明細アドオンID
     
      // PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
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
        XxpoUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateOrderLine 

  /***************************************************************************
   * シーケンスから受注明細アドオンIDを取得します。
   * @param trans - トランザクション
   * @return Number - 受注ヘッダアドオンID
   * @throws OAException OA例外
   ***************************************************************************
   */
  public static Number getOrderLineId(
    OADBTransaction trans
    ) throws OAException
  {
    String apiName   = "getOrderLineId";

    return XxcmnUtility.getSeq(trans, XxpoConstants.XXWSH_ORDER_LINES_ALL_S1);

  } // getOrderLineId

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxpo.xxpo441001j.server", "XxpoShippedResultAMLocal");
  }

  /**
   * 
   * Container's getter for OrderTypeVO1
   */
  public OAViewObjectImpl getOrderTypeVO1()
  {
    return (OAViewObjectImpl)findViewObject("OrderTypeVO1");
  }

  /**
   * 
   * Container's getter for NotifStatusVO1
   */
  public OAViewObjectImpl getNotifStatusVO1()
  {
    return (OAViewObjectImpl)findViewObject("NotifStatusVO1");
  }

  /**
   * 
   * Container's getter for TransStatusVO1
   */
  public OAViewObjectImpl getTransStatusVO1()
  {
    return (OAViewObjectImpl)findViewObject("TransStatusVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvSearchVO1
   */
  public XxpoProvSearchVOImpl getXxpoProvSearchVO1()
  {
    return (XxpoProvSearchVOImpl)findViewObject("XxpoProvSearchVO1");
  }

  /**
   * 
   * Container's getter for XxpoShippedMakeHeaderVO1
   */
  public XxpoShippedMakeHeaderVOImpl getXxpoShippedMakeHeaderVO1()
  {
    return (XxpoShippedMakeHeaderVOImpl)findViewObject("XxpoShippedMakeHeaderVO1");
  }

  /**
   * 
   * Container's getter for XxpoShippedMakeHeaderPVO1
   */
  public XxpoShippedMakeHeaderPVOImpl getXxpoShippedMakeHeaderPVO1()
  {
    return (XxpoShippedMakeHeaderPVOImpl)findViewObject("XxpoShippedMakeHeaderPVO1");
  }

  /**
   * 
   * Container's getter for XxpoShippedMakeLinePVO1
   */
  public XxpoShippedMakeLinePVOImpl getXxpoShippedMakeLinePVO1()
  {
    return (XxpoShippedMakeLinePVOImpl)findViewObject("XxpoShippedMakeLinePVO1");
  }

  /**
   * 
   * Container's getter for XxpoShippedMakeLineVO1
   */
  public XxpoShippedMakeLineVOImpl getXxpoShippedMakeLineVO1()
  {
    return (XxpoShippedMakeLineVOImpl)findViewObject("XxpoShippedMakeLineVO1");
  }

  /**
   * 
   * Container's getter for XxpoShippedMakeTotalVO1
   */
  public XxpoShippedMakeTotalVOImpl getXxpoShippedMakeTotalVO1()
  {
    return (XxpoShippedMakeTotalVOImpl)findViewObject("XxpoShippedMakeTotalVO1");
  }

  /**
   * 
   * Container's getter for XxpoShippedResultVO1
   */
  public XxpoShippedResultVOImpl getXxpoShippedResultVO1()
  {
    return (XxpoShippedResultVOImpl)findViewObject("XxpoShippedResultVO1");
  }
}