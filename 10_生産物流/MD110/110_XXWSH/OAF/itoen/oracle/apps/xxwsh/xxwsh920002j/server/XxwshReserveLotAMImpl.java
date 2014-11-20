/*============================================================================
* ファイル名 : XxwshReserveLotAMImpl
* 概要説明   : 引当ロット入力:登録アプリケーションモジュール
* バージョン : 1.11
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-17 1.0  北寒寺正夫     新規作成
* 2008-08-07 1.1  二瓶　大輔     内部変更要求#166,#173
* 2008-10-07 1.2  伊藤ひとみ     統合テスト指摘240対応
* 2008-10-22 1.3  二瓶　大輔     統合テスト指摘194対応
* 2008-10-24 1.4  二瓶　大輔     TE080_BPO_600 No22
* 2008-12-10 1.5  伊藤ひとみ     本番障害#587対応
* 2008-12-11 1.6  伊藤ひとみ     本番障害#675対応
* 2008-12-25 1.7  二瓶　大輔     本番障害#771対応
* 2009-01-22 1.8  伊藤ひとみ     本番障害#1000対応
* 2009-01-26 1.9  伊藤ひとみ     本番障害#936対応
* 2009-02-17 1.10 二瓶　大輔     本番障害#863対応
*                                本番障害#1034対応
* 2009-12-04 1.11 伊藤ひとみ     本稼動障害#11対応
*============================================================================
*/
package itoen.oracle.apps.xxwsh.xxwsh920002j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxwsh.util.XxwshConstants;
import itoen.oracle.apps.xxwsh.util.XxwshUtility;

import java.math.BigDecimal;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.AttributeDef;
import oracle.jbo.Row;
import oracle.jbo.RowSetIterator;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

/***************************************************************************
 * 仮引当ロット入力画面のアプリケーションモジュールクラスです。
 * @author  ORACLE 北寒寺 正夫
 * @version 1.11
 ***************************************************************************
 */
 
public class XxwshReserveLotAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwshReserveLotAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxwsh.xxwsh920002j.server", "XxwshReserveLotAMLocal");
  }

  /***************************************************************************
   * 初期化処理を行うメソッドです。
   * @param params 検索パラメータ用HashMap
   ***************************************************************************
   */
  public void initialize(
    HashMap params
  )
  {

    // ******************************************* //
    // * ページレイアウトリージョンPVO 空行取得  * //
    // ******************************************* //
    OAViewObject PVO = getXxwshPageLayoutPVO1();
    OARow pvoRow     = null;
    // 1行もない場合、空行作成
    if (PVO.getFetchedRowCount() == 0)
    {    
      PVO.setMaxFetchSize(0);
      // 1行目を作成
      PVO.insertRow(PVO.createRow());
      // 1行目を取得
      pvoRow = (OARow)PVO.first();
      // キーに値をセット
      pvoRow.setAttribute("RowKey", new Number(1));
    }
    // PVO1行目を取得
    pvoRow = (OARow)PVO.first();
    // *********************** //
    // *  パラメータチェック * //
    // *********************** //
    checkParams(params);

    // *********************** //
    // *  項目制御            * //
    // *********************** //
    itemControl(XxcmnConstants.STRING_N, params);

    // **************************************** //
    // * 検索条件表示リージョンデータ取得処理 * //
    // *****************************************//
    getSearchData(params);
    
    // *********************************************** //
    // * 手持数量引当可能数一覧リージョンVO 検索処理 * //
    // *********************************************** //
    // 検索条件表示リージョンを取得
    OAViewObject hvo = getXxwshSearchVO1();
    // 検索条件表示リージョンの一行目を取得
    OARow hRow       = (OARow)hvo.first();
    // 明細情報リージョンを取得
    OAViewObject lvo = getXxwshLineVO();
    // 明細情報リージョンの一行目を取得
    OARow lRow       = (OARow)lvo.first();
    HashMap data     = new HashMap();
    // 検索に必要な項目をセット
    data.put("ItemId",                    hRow.getAttribute("ItemId"));                     // 品目ID
    data.put("InputInventoryLocationId"  ,lRow.getAttribute("InputInventoryLocationId"));   // 保管倉庫ID
// 2008-12-25 D.Nihei Add Start
    data.put("InputInventoryLocationCode",lRow.getAttribute("InputInventoryLocationCode")); // 保管倉庫コード
// 2008-12-25 D.Nihei Add End
    data.put("DocumentTypeCode",          lRow.getAttribute("DocumentTypeCode"));           // 文書タイプ
    data.put("LocationRelCode",           lRow.getAttribute("LocationRelCode"));            // 拠点実績有無区分
    data.put("ConvUnitUseKbn",            hRow.getAttribute("ConvUnitUseKbn"));             // 入出庫換算単位使用区分
    data.put("CallPictureKbn",            hRow.getAttribute("CallPictureKbn"));             // 呼出画面区分
    data.put("LotCtl",                    hRow.getAttribute("LotCtl"));                     // ロット管理品
    data.put("DesignatedProductionDate",  lRow.getAttribute("DesignatedProductionDate"));   // 指定製造日
    data.put("LineId",                    lRow.getAttribute("LineId"));                     // 明細ID
    data.put("ScheduleShipDate",          lRow.getAttribute("ScheduleShipDate"));           // 出荷予定日
    data.put("ProdClass",                 hRow.getAttribute("ProdClass"));                  // 商品区分
    data.put("ItemClass",                 hRow.getAttribute("ItemClass"));                  // 品目区分
    data.put("NumOfCases",                hRow.getAttribute("NumOfCases"));                 // ケース入数
// 2008-12-25 D.Nihei Add Start
    data.put("FrequentWhseCode",          lRow.getAttribute("FrequentWhseCode"));           // 代表倉庫
    data.put("MasterOrgId",               getOADBTransaction().getProfile("XXCMN_MASTER_ORG_ID"));        // 在庫組織ID
    data.put("MaxDate",                   getOADBTransaction().getProfile("XXCMN_MAX_DATE"));             // 最大日付
    data.put("DummyFrequentWhse",         getOADBTransaction().getProfile("XXCMN_DUMMY_FREQUENT_WHSE"));  // ダミー倉庫
// 2008-12-25 D.Nihei Add End
// 2009-12-04 H.Itou Add Start 本稼動障害#11
    data.put("OpenDate",                  XxwshUtility.getOpenDate(getOADBTransaction()));  // オープン日付
// 2009-12-04 H.Itou Add End 本稼動障害#11
    XxwshStockCanEncQtyVOImpl vo = getXxwshStockCanEncQtyVO1();
// 2008-12-25 D.Nihei Add Start
    // 1行もない場合、空行作成
    if (vo.getFetchedRowCount() == 0)
    {
      vo.setMaxFetchSize(0);
    } else
    {
      vo.first();
      OARow row = null;
      while (vo.getCurrentRow() != null)
      {
        row = (OARow)vo.getCurrentRow();
        row.remove();
        vo.next();
      }
    }
// 2008-12-25 D.Nihei Add End
    // 手持在庫数・引当可能数一覧リージョン検索実施
// 2008-12-25 D.Nihei Mod Start
//    vo.initQuery(data);
    // ロット管理品の場合
    if (XxcmnUtility.isEquals(new Number(1), hRow.getAttribute("LotCtl"))) 
    {
      XxwshReserveLotVOImpl lotVo = getXxwshReserveLotVO1();
      lotVo.initQuery(data);
// 2009-12-04 H.Itou Add Start lm.demsup_qty、lm.stock_qtyを抽出するたびに引当可能数・手持在庫関数を呼ぶので、問い合わせ実行後に計算する。
      lotVo.first();
      while (lotVo.getCurrentRow() != null)
      {
        OARow lotRow = (OARow)lotVo.getCurrentRow();

        Number demsupQty = (Number)lotRow.getAttribute("CanEncQty"); // 引当可能数
        Number stockQty  = (Number)lotRow.getAttribute("StockQty");  // 手持在庫数

        // 表示用引当可能数、手持在庫数取得
        HashMap ret = getShowQty(demsupQty, stockQty);
        Number canEncQty     = (Number)ret.get("canEncQty");     // 引当可能数＋手持在庫
        String showCanEncQty = (String)ret.get("showCanEncQty"); // 引当可能数＋手持在庫数(表示用)
        String showStockQty  = (String)ret.get("showStockQty");  // 手持在庫数(表示用)

        // VOにセット
        lotRow.setAttribute("CanEncQty", canEncQty);
        lotRow.setAttribute("ShowCanEncQty", showCanEncQty);
        lotRow.setAttribute("ShowStockQty", showStockQty);
        
        lotVo.next();
      }
// 2009-12-04 H.Itou Add End
      copyRows(lotVo, vo);
      
    // ロット管理品外の場合
    } else 
    {
      XxwshReserveUnLotVOImpl unLotVo = getXxwshReserveUnLotVO1();
      unLotVo.initQuery(data);
      copyRows(unLotVo, vo);
      
    }
// 2008-12-25 D.Nihei Mod End
    // 手持在庫数・引当可能数一覧リージョンの件数が0件の場合
// 2008-12-25 D.Nihei Mod Start
//    if ( vo.getRowCount() == 0)
    if ( vo.getFetchedRowCount() == 0 )
// 2008-12-25 D.Nihei Mod End
    {
      // 支給指示が画面へ戻るボタン以外を非表示&無効化
      pvoRow.setAttribute("CancelRendered", Boolean.FALSE); // 一括解除：非表示
      pvoRow.setAttribute("CalcRendered",   Boolean.FALSE); // 計算：非表示
      pvoRow.setAttribute("ApplyDisabled",  Boolean.TRUE);  // 適用：無効      
    // 手持在庫数・引当可能数一覧リージョンの件数が一件以上の場合
    } else
    {
      // 手持在庫数・引当可能数一覧リージョンにSQLでセットできない項目をセット
      setStockCanEncQty();
    }
  }

  /***************************************************************************
   * 対象となる明細情報リージョンのビューオブジェクトを返すメソッドです。
   * @return OAViewObject 対象となる明細情報リージョンのビューオブジェクト
   ***************************************************************************
   */
  public OAViewObject getXxwshLineVO()
  {
    
    // *********************************************** //
    // * 手持数量引当可能数一覧リージョンVO 検索処理 * //
    // *********************************************** //
    // 検索条件表示リージョンを取得
    OAViewObject hvo      = getXxwshSearchVO1();
    // 検索条件表示リージョンの一行目を取得
    OARow hRow            = (OARow)hvo.first();
    String callPictureKbn = (String)hRow.getAttribute("CallPictureKbn"); // 呼出画面区分

    // 呼出画面区分が出荷依頼入力画面起動の場合
    if ( XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn))
    {
      return getXxwshLineShipVO1();

    // 呼出画面区分が支給指示作成画面起動の場合
    } else if ( XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
    {
      return getXxwshLineProdVO1();

    // 呼出画面区分が移動依頼/指示入力画面起動の場合
    } else if ( XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
    {
      return getXxwshLineMoveVO1();
    } else
    {
      return null;
    }
  }
  
  /***************************************************************************
   * パラメータチェックを行うメソッドです。
   * @param  params - パラメータ
   * @throws OAException   - OA例外
   ***************************************************************************
   */
  public void checkParams(
    HashMap params
    ) throws OAException
  {
    // パラメータ取得
    String callPictureKbn   = (String)params.get("callPictureKbn");   // 呼出画面区分
    String lineId           = (String)params.get("LineId");           // 明細ID
    String headerUpdateDate = (String)params.get("headerUpdateDate"); // ヘッダ更新日時
    String lineUpdateDate   = (String)params.get("lineUpdateDate");   // 明細更新日時
    String exeKbn           = (String)params.get("exeKbn");           // 起動区分   

    // 呼出画面区分が設定されていない場合
    if (XxcmnUtility.isBlankOrNull(callPictureKbn))
    {
      // 項目制御(戻るボタン以外非表示
      itemControl(XxcmnConstants.STRING_Y, params);
      
      // トークン生成
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME,
                                XxwshConstants.TOKEN_NAME_CALL_PICTURE_KBN) };
      // エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH12904, 
        tokens);        
    }

    // 明細IDが設定されていない場合
    if (XxcmnUtility.isBlankOrNull(lineId))
    {
      // 項目制御(戻るボタン以外非表示
      itemControl(XxcmnConstants.STRING_Y, params);
      
      // トークン生成
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME,
                                XxwshConstants.TOKEN_NAME_LINE_ID) };
      // エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH12904, 
        tokens);        
    }

    // 明細更新日時が設定されていない場合
    if (XxcmnUtility.isBlankOrNull(lineUpdateDate))
    {
      // 項目制御(戻るボタン以外非表示
      itemControl(XxcmnConstants.STRING_Y, params);
      
      // トークン生成
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME,
                                XxwshConstants.TOKEN_NAME_LINE_UPDATE_DATE) };
      // エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH12904, 
        tokens);        
    }

    // ヘッダ更新日時が設定されていない場合
    if (XxcmnUtility.isBlankOrNull(headerUpdateDate))
    {
      // 項目制御(戻るボタン以外非表示
      itemControl(XxcmnConstants.STRING_Y, params);
      
      // トークン生成
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME,
                                XxwshConstants.TOKEN_NAME_HEADER_UPDATE_DATE) };
      // エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH12904, 
        tokens);        
    }
    // 明細更新日時の書式がYYYY/MM/DD HH24:MI:SSでない場合
    if (!XxcmnUtility.chkDateFormat(
      getOADBTransaction(),
      lineUpdateDate,
      XxwshConstants.DATE_FORMAT))
    {
      // 項目制御(戻るボタン以外非表示
      itemControl(XxcmnConstants.STRING_Y, params);
      
      // トークン生成
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME,
                                XxwshConstants.TOKEN_NAME_LINE_UPDATE_DATE) };
      // エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH12903, 
        tokens);     
    }
    
    // ヘッダ更新日時の書式がYYYY/MM/DD HH24:MI:SSでない場合
    if(!XxcmnUtility.chkDateFormat(
      getOADBTransaction(),
      headerUpdateDate,
      XxwshConstants.DATE_FORMAT))
    {
      // 項目制御(戻るボタン以外非表示
      itemControl(XxcmnConstants.STRING_Y, params);
      
      // トークン生成
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME,
                                XxwshConstants.TOKEN_NAME_HEADER_UPDATE_DATE) };
      // エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH12903, 
        tokens);     
    }

    // 呼出画面区分が2:支給指示作成画面で、起動区分が設定されていない場合
    if (XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn)
      && XxcmnUtility.isBlankOrNull(exeKbn))
    {
      // 項目制御(戻るボタン以外非表示
      itemControl(XxcmnConstants.STRING_Y, params);

      // トークン生成
      MessageToken[] tokens = { new MessageToken(
                                XxwshConstants.TOKEN_PARM_NAME,
                                XxwshConstants.TOKEN_NAME_EXE_KBN) };
      // エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH12904, 
        tokens);        
    }
  }

  /***************************************************************************
   * 項目制御を行うメソッドです。
   * @param  errFlag   - Y:エラーの場合(戻るボタン以外不能)
   *                          - N:正常
   * @param  params    - 入力パラメータ
   * @throws OAException      - OA例外
   ***************************************************************************
   */
  public void itemControl(
    String errFlag,
    HashMap params
    ) throws OAException
  {
    // PVO取得
    OAViewObject pvo = getXxwshPageLayoutPVO1();   
    // PVO1行目を取得
    OARow pvoRow = (OARow)pvo.first();
    // デフォルト値設定
    pvoRow.setAttribute("ReturnRendered",  Boolean.TRUE);  // 支給支持画面へ戻る：表示
    pvoRow.setAttribute("CancelRendered",  Boolean.TRUE);  // 一括解除：表示
    pvoRow.setAttribute("CalcRendered",    Boolean.TRUE);  // 計算：表示
    pvoRow.setAttribute("ApplyDisabled",   Boolean.FALSE); // 適用：有効

    // エラーの場合(戻るボタン以外制御不能)
    if (XxcmnConstants.STRING_Y.equals(errFlag))
    {
      pvoRow.setAttribute("ReturnRendered", Boolean.FALSE); // 支給支持画面へ戻る：非表示
      pvoRow.setAttribute("CancelRendered", Boolean.FALSE); // 一括解除：非表示
      pvoRow.setAttribute("CalcRendered",   Boolean.FALSE); // 計算：非表示
      pvoRow.setAttribute("ApplyDisabled",  Boolean.TRUE);  // 適用：無効

    // エラーでない場合      
    } else
    {
      // 呼出画面区分を取得
      String callPictureKbn  = (String)params.get("callPictureKbn");   // 呼出画面区分
      //呼出画面区分が2:支給指示作成画面以外の場合
      if (!XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
      {
        pvoRow.setAttribute("ReturnRendered", Boolean.FALSE); // 支給支持画面へ戻る：非表示     
      }
    }
  }

  /***************************************************************************
   * 検索情報表示リージョンに値を取得しセットするメソッドです
   * @param  params - 入力パラメータ
   * @throws OAException   - OAエラー
   ***************************************************************************
   */
  public void getSearchData(
    HashMap params
    ) throws OAException
  {
    // 入力パラメータ取得
    String callPictureKbn   = (String)params.get("callPictureKbn");   // 呼出画面区分
    String lineId           = (String)params.get("LineId");           // 明細ID
    String headerUpdateDate = (String)params.get("headerUpdateDate"); // ヘッダ更新日時
    String lineUpdateDate   = (String)params.get("lineUpdateDate");   // 明細更新日時
    String exeKbn           = (String)params.get("exeKbn");           // 起動区分   
    // 明細情報リージョンレコード取得用
    OARow lrow              = null;

    // 呼出画面区分が出荷依頼入力画面起動の場合
    if ( XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn))
    {
      // 明細情報リージョン(出荷)を取得
      XxwshLineShipVOImpl lvo  = getXxwshLineShipVO1();
      // 検索実施
      lvo.initQuery(lineId);

      // 明細情報リージョンを取得できなかった場合
      if (lvo.getRowCount() == 0)
      {
        // 項目制御(戻るボタン以外非表示
        itemControl(XxcmnConstants.STRING_Y,params);
      
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN,
          XxcmnConstants.XXCMN10500); 
      }
      // 一行目を取得
      lrow = (OARow)lvo.first();
    // 呼出画面区分が支給指示作成画面起動の場合
    } else if ( XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
    {
      // 明細情報リージョン(支給)を取得
      XxwshLineProdVOImpl lvo  = getXxwshLineProdVO1();
      // 検索実施
      lvo.initQuery(lineId);
      // 明細情報リージョンを取得できなかった場合
      if (lvo.getRowCount() == 0)
      {
        // 項目制御(戻るボタン以外非表示
        itemControl(XxcmnConstants.STRING_Y,params);
      
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN,
          XxcmnConstants.XXCMN10500); 
      }
      // 一行目を取得
      lrow = (OARow)lvo.first();

    // 呼出画面区分が移動依頼/指示入力画面起動の場合
    } else if ( XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
    {
      // 明細情報リージョン(移動)を取得
      XxwshLineMoveVOImpl lvo  = getXxwshLineMoveVO1();
      // 検索実施
      lvo.initQuery(lineId);
      // 明細情報リージョンを取得できなかった場合
      if (lvo.getRowCount() == 0)
      {
        // 項目制御(戻るボタン以外非表示
        itemControl(XxcmnConstants.STRING_Y,params);
      
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN,
          XxcmnConstants.XXCMN10500); 
      }
      // 一行目を取得
      lrow = (OARow)lvo.first();
    }

    // 検索に必要な項目を取得
    String itemCode                = (String)lrow.getAttribute("ItemCode");                // 品目コード
    Date scheduleShipDate          = (Date)lrow.getAttribute("ScheduleShipDate");          // 出庫予定日
    String sumReservedQuantityItem = (String)lrow.getAttribute("SumReservedQuantityItem"); // 引当数量(品目単位)
    String instructQty             = (String)lrow.getAttribute("InstructQty");             // 指示数量(品目単位)


    // 検索条件表示リージョンを取得
    XxwshSearchVOImpl hvo   = getXxwshSearchVO1();
    // 検索実施
    hvo.initQuery(
      itemCode,
      scheduleShipDate,
      callPictureKbn,
      instructQty,
      sumReservedQuantityItem);
    // 検索条件表示リージョンを取得できなかった場合
    if ( hvo.getRowCount() == 0)
    {
      // 項目制御(戻るボタン以外非表示
      itemControl(XxcmnConstants.STRING_Y, params);

      // エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXCMN,
        XxcmnConstants.XXCMN10500); 
    }
    // 1行目を取得
    OARow hrow = (OARow)hvo.first();

    // 入力項目を検索条件表示リージョンにセット
    hrow.setAttribute("LineId",           lineId);           // 明細ID
    hrow.setAttribute("CallPictureKbn",   callPictureKbn);   // 呼出画面区分
    hrow.setAttribute("HeaderUpdateDate", headerUpdateDate); // ヘッダ最終更新日
    hrow.setAttribute("LineUpdateDate",   lineUpdateDate);   // 明細最終更新日
    hrow.setAttribute("ExeKbn",           exeKbn);           // 起動区分

    // 明細情報表示リージョンで画面表示に必要な項目を検索条件表示リージョンにセット
    hrow.setAttribute("DesignatedProductionDate", lrow.getAttribute("DesignatedProductionDate")); // 指定製造日
    hrow.setAttribute("RequestNo",                lrow.getAttribute("RequestNo"));                // 伝票No
    hrow.setAttribute("SumReservedQuantityItem",  lrow.getAttribute("SumReservedQuantityItem"));  // 引当数量合計(品目単位)
    hrow.setAttribute("ItemCode",                 itemCode);                                      // 伝票No

  }
  
  /***************************************************************************
   * 手持在庫数・引当可能数一覧リージョンの各項目に値をセットします。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void setStockCanEncQty() throws OAException
  {
    // 手持在庫数・引当可能数一覧リージョン取得
    OAViewObject vo = getXxwshStockCanEncQtyVO1();
    // 手持在庫数・引当可能数一覧リージョンを取得する変数を宣言
    OARow row       = null;
    // 手持在庫数・引当可能数一覧リージョンの1行目をセット
    vo.first();
    // 全件ループ
    while (vo.getCurrentRow() != null )
    {
      // 処理対象行を取得
      row = (OARow)vo.getCurrentRow();

      // 引当数量(換算後)表示時保存用に引当数量(換算後)の値をセット
      row.setAttribute(
        "ShowActualQuantityBk",
        row.getAttribute(
          "ShowActualQuantity"));

      // 引当数量表示時保存用に引当数量の値をセット
      row.setAttribute(
        "ActualQuantityBk",
        row.getAttribute(
          "ActualQuantity"));

      // 次のレコードへ
      vo.next();
    }
  }

  /***************************************************************************
   * 計算処理を行うメソッドです。
   * @throws OAException -OA例外
   ***************************************************************************
  */
  public void calcProcess() throws OAException
  {
    // 検索条件表示リージョンを取得
    OAViewObject hvo              = getXxwshSearchVO1();
    // 検索条件表示リージョンの一行目を取得
    OARow hrow                    = (OARow)hvo.first();
    String convUnitUseKbn         = (String)hrow.getAttribute("ConvUnitUseKbn"); // 入出庫換算単位使用区分
    String numOfCases             = (String)hrow.getAttribute("NumOfCases");     // ケース入数
    // 手持在庫数・引当可能数一覧リージョン取得
    OAViewObject vo               = getXxwshStockCanEncQtyVO1();
    // 手持在庫数・引当可能数一覧リージョンのレコードをセットするための変数を宣言
    OARow row                     = null;
    String showActualQuantity     = null;                                        // 引当数量(換算後)
    BigDecimal setActualQuantity  = null;                                        // 引当数量(VOセット用)
// 2008-12-10 H.Itou Mod Start
//    double actualQuantity        = 0;                                            // 引当数量
//    double sumActualQuantity     = 0;                                            // 引当数量合計(換算後)
//    double sumActualQuantityItem = 0;                                            // 引当数量合計
    BigDecimal actualQuantity        = new BigDecimal(0);                        // 引当数量
    BigDecimal sumActualQuantity     = new BigDecimal(0);                        // 引当数量合計(換算後)
    BigDecimal sumActualQuantityItem = new BigDecimal(0);                        // 引当数量合計
//
    ArrayList exceptions          = new ArrayList(100);                          // エラーメッセージ格納配列

    // 手持在庫数・引当可能数一覧リージョン1行目を取得
    vo.first();
    // 全件ループ
    while (vo.getCurrentRow() != null )
    {
      // 処理対象行を取得
      row                = (OARow)vo.getCurrentRow();
      showActualQuantity = (String)row.getAttribute("ShowActualQuantity"); // 引当数量(換算後)

      // 値が設定されていない場合
      if (XxcmnUtility.isBlankOrNull(showActualQuantity))
      {
        // エラーメッセージ配列に必須エラーメッセージを格納
        exceptions.add( 
          new OAAttrValException(
            OAAttrValException.TYP_VIEW_OBJECT,          
            vo.getName(),
            row.getKey(),
            "ShowActualQuantity",
            showActualQuantity,
            XxcmnConstants.APPL_XXWSH,         
            XxwshConstants.XXWSH12911));
      // 数値(999999999.999)でない場合はエラー
      } else if (!XxcmnUtility.chkNumeric(showActualQuantity, 9, 3)) 
      {
        // エラーメッセージ配列に書式エラーメッセージを格納
        exceptions.add( 
          new OAAttrValException(
            OAAttrValException.TYP_VIEW_OBJECT,          
            vo.getName(),
            row.getKey(),
            "ShowActualQuantity",
            showActualQuantity,
            XxcmnConstants.APPL_XXWSH,         
            XxwshConstants.XXWSH12902));
      // マイナス値はエラー
      } else if (!XxcmnUtility.chkCompareNumeric(2, showActualQuantity, "0"))
      {
        // エラーメッセージ配列にマイナスエラーメッセージを格納
        exceptions.add( 
          new OAAttrValException(
            OAAttrValException.TYP_VIEW_OBJECT,          
            vo.getName(),
            row.getKey(),
            "ShowActualQuantity",
            showActualQuantity,
            XxcmnConstants.APPL_XXWSH,         
            XxwshConstants.XXWSH12905));
      } else
      {

        // 換算対象の場合換算解除する
        if (XxwshConstants.CONV_UNIT_USE_KBN_INCLUDE.equals(convUnitUseKbn))
        {
          // 引当数量に引当数量(換算後) * ケース入数をセット
// 2008-12-10 H.Itou Mod Start
//          actualQuantity = Double.parseDouble(showActualQuantity) * Double.parseDouble(numOfCases);
          actualQuantity = XxcmnUtility.bigDecimalValue(showActualQuantity); // 引当数量
          actualQuantity = actualQuantity.multiply(XxcmnUtility.bigDecimalValue(numOfCases));
// 2008-12-10 H.Itou Mod End
        } else
        {
          // 引当数量に引当数量(換算後)をセット
// 2008-12-10 H.Itou Mod Start
//          actualQuantity = Double.parseDouble(showActualQuantity);
          actualQuantity = XxcmnUtility.bigDecimalValue(showActualQuantity); // 引当数量
// 2008-12-10 H.Itou Mod End
        }
// 2008-12-10 H.Itou Mod Start
//        // 手持在庫数・引当可能数一覧リージョンに換算解除した値をセットするため、BigDecimalに一時的にセット
//        setActualQuantity =  new BigDecimal(String.valueOf(actualQuantity));
        // 手持在庫数・引当可能数一覧リージョン.引当数量にセット
//        row.setAttribute("ActualQuantity",setActualQuantity);
        row.setAttribute("ActualQuantity",actualQuantity);
// 2008-12-10 H.Itou Mod Start
        // 引当数量(換算後)の合計値を算出
// 2008-12-10 H.Itou Mod Start
//        sumActualQuantity     = sumActualQuantity + Double.parseDouble(showActualQuantity);
        sumActualQuantity = sumActualQuantity.add(XxcmnUtility.bigDecimalValue(showActualQuantity));
// 2008-12-10 H.Itou Mod End
        // 引当数量の合計値を算出
// 2008-12-10 H.Itou Mod Start
//        sumActualQuantityItem = sumActualQuantityItem + actualQuantity;
        sumActualQuantityItem = sumActualQuantityItem.add(actualQuantity);
// 2008-12-10 H.Itou Mod End
      }
      // 次の行に移動
      vo.next();
    }

    //エラーがある場合メッセージを出力
    if (exceptions.size() > 0)
    {
      // エラーメッセージを画面に出力
      OAException.raiseBundledOAException(exceptions);

    //エラーがない場合加算した値を検索条件表示リージョンにセット
    } else
    {
      // 検索条件表示リージョンに引当数量合計(換算後)をセット
// 2008-12-10 H.Itou Mod Start
//      hrow.setAttribute("SumReservedQuantity",    XxcmnUtility.formConvNumber(new Double(sumActualQuantity), 9, 3, true));
      hrow.setAttribute("SumReservedQuantity",  String.valueOf(sumActualQuantity));
// 2008-12-10 H.Itou Mod End
      // 検索条件表示リージョンに引当数量合計をセット
      hrow.setAttribute("SumReservedQuantityItem",String.valueOf(sumActualQuantityItem));
    }
  }

  /***************************************************************************
   * 計算ボタン押下時の処理を行うメソッドです。
   * @throws OAException -OA例外
   ***************************************************************************
  */
  public void calcBtn() throws OAException
  {
    // 計算処理を呼び出す
    calcProcess();
  }

  /***************************************************************************
   * 一括解除処理を行うメソッドです。
   * 
   ***************************************************************************
  */
  public void cancelBtn()
  {
    // 手持在庫数・引当可能数一覧リージョン取得
    OAViewObject vo = getXxwshStockCanEncQtyVO1();
    OARow row       = null;
    String showActualQuantity = null;
    // 1行目
    vo.first();
    // 全件ループ
    while (vo.getCurrentRow() != null )
    {
      // 処理対象行を取得
      row = (OARow)vo.getCurrentRow();
      // 引当数量に0.000をセット
      row.setAttribute("ShowActualQuantity", "0.000");
      // 次の行に移動
      vo.next();
    }
    // 検索条件表示リージョンを取得
    OAViewObject hvo = getXxwshSearchVO1();
    // 検索条件表示リージョンの1行目を取得
    OARow hrow       = (OARow)hvo.first();
    // 引当数量合計に0.000をセット
    hrow.setAttribute("SumReservedQuantity", "0.000");
    // 一括解除ボタン押下フラグに"1"(押下済)をセット
    hrow.setAttribute("PackageLiftFlag", XxwshConstants.PACKAGE_LIFT_FLAG_INCLUDE);
  }

  /***************************************************************************
   * 適用ボタン押下時の処理を行うメソッドです
   * @throws OAException -OA例外
   ***************************************************************************
   */
  public void applyBtn() throws OAException
  {
    // 検索条件表示リージョンを取得
    XxwshSearchVOImpl hvo = getXxwshSearchVO1();
    // 検索条件表示リージョンの一行目を取得
    OARow hrow            = (OARow)hvo.first();

    // 使用する下記項目をクリアします。
    hrow.setAttribute("WarningClass",              null); // 警告区分
    hrow.setAttribute("WarningDate",               null); // 警告日付
    hrow.setAttribute("InstructQtyUpdFlag",        null); // 指示数量更新フラグ
    hrow.setAttribute("Weight",                    null); // 重量
    hrow.setAttribute("Capacity",                  null); // 容積
    hrow.setAttribute("SumWeight",                 null); // 積載重量合計
    hrow.setAttribute("SumCapacity",               null); // 積載容積合計
    hrow.setAttribute("LoadingEfficiencyWeight",   null); // 積載率（重量)
    hrow.setAttribute("LoadingEfficiencyCapacity", null); // 積載率(容積)
    hrow.setAttribute("SumQuantity",               null); // 合計数量
    hrow.setAttribute("SmallQuantity",             null); // 小口個数
    hrow.setAttribute("LabelQuantity",             null); // ラベル枚数
    hrow.setAttribute("PalletWeight",              null); // パレット重量
    hrow.setAttribute("SumPalletWeight",           null); // 合計パレット重量

    //計算処理を行います。
    calcProcess();

// 2009-02-17 D.Nihei Del Start 本番障害#1034対応
//    //テーブルのロック・排他制御を行います。
//    getLockAndChkExclusive();
// 2009-02-17 D.Nihei Del End

    //引当可能数が0より大きいレコードの引当可能数が画面表示時と変更がないかチェックします。
    chkCanEncQty();
    // ***************************************** //
    // *    指示数量更新判断                   * //
    // ***************************************** //
    Number lotCtl                  = (Number)hrow.getAttribute("LotCtl");                     // ロット管理
    Number sumReservedQuantityItem = (Number)hrow.getAttribute("SumReservedQuantityItem");    // 引当数量合計
    String packageLiftFlag         = (String)hrow.getAttribute("PackageLiftFlag");            // 一括解除ボタン押下フラグ
    String callPictureKbn          = (String)hrow.getAttribute("CallPictureKbn");             // 呼出画面区分
    String itemClass               = (String)hrow.getAttribute("ItemClass");                  // 品目区分
    String instructQtyUpdFlag      = null;                                                    // 指示数量更新フラグ

    // 明細情報リージョンを取得
    OAViewObject lvo               = getXxwshLineVO();
    // 明細情報リージョンの一行目を取得
    OARow lrow                     = (OARow)lvo.first();  
    String instructQty             = (String)lrow.getAttribute("InstructQty");                // 指示数量

    // 指示数量と引当数量合計が一致する場合
    if (instructQty.equals(sumReservedQuantityItem.toString()))
    {
      // 指示数量更新フラグに"0"(更新しない)をセット
      instructQtyUpdFlag = XxwshConstants.INSTRUCT_QTY_UPD_FLAG_EXCLUD;
    // 一括解除ボタン押下フラグが"1"(押下済)で引当数量合計が0の場合
    } else if (XxwshConstants.PACKAGE_LIFT_FLAG_INCLUDE.equals(packageLiftFlag)
      && (sumReservedQuantityItem.doubleValue() == 0))
    {
      // 指示数量更新フラグに"0"(更新しない)をセット
      instructQtyUpdFlag = XxwshConstants.INSTRUCT_QTY_UPD_FLAG_EXCLUD;
    // 上記の条件以外の場合
    } else
    {
      // 指示数量更新フラグに"1"(更新する)をセット
      instructQtyUpdFlag = XxwshConstants.INSTRUCT_QTY_UPD_FLAG_INCLUDE;
    }
    // 指示数量更新フラグを検索条件表示リージョンにセット
    hrow.setAttribute("InstructQtyUpdFlag",instructQtyUpdFlag);

    //指示数量更新フラグが"1"(更新する）場合
    if (XxwshConstants.INSTRUCT_QTY_UPD_FLAG_INCLUDE.equals(instructQtyUpdFlag))
    {
      // ***************************************** //
      // *    指示数量更新チェック               * //
      // ***************************************** //
      // 呼出画面区分が'1'(出荷依頼入力画面起動の場合)
      if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn))
      {                                  
        // ロック解除
        XxcmnUtility.rollBack(getOADBTransaction());
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12901);  

      // 呼出画面区分が'3'(移動依頼/指示入力画面起動)で品目区分が'5'(製品)の場合
      } else if (XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn)
        && XxwshConstants.ITEM_TYPE_PROD.equals(itemClass))
      {
        // ロック解除
        XxcmnUtility.rollBack(getOADBTransaction());
        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12901);  
      }

      // ***************************************** //
      // *    配車関連情報取得処理               * //
      // ***************************************** //
      getDeliveryInfo();
    }

    // 警告チェック処理はpageContextを使用するためCoで行う
  }
  
  
 /*****************************************************************************
  * ロックを取得し、排他チェックを行うメソッドです。
  * @throws OAException - OA例外
  ****************************************************************************/
  public void getLockAndChkExclusive() throws OAException
  {
    // 検索条件表示リージョンを取得
    OAViewObject hvo          = getXxwshSearchVO1();
    // 検索条件表示リージョンの一行目を取得
    OARow hrow                = (OARow)hvo.first();

    // 明細情報リージョンを取得
    OAViewObject lvo          = getXxwshLineVO();
    // 明細情報リージョンの一行目を取得
    OARow lrow                = (OARow)lvo.first();

    Number headerId           = (Number)lrow.getAttribute("HeaderId");         // ヘッダID
    Number lineId             = (Number)lrow.getAttribute("LineId");           // 明細ID
    String documentTypeCode   = (String)lrow.getAttribute("DocumentTypeCode"); // 文書タイプ
    String headerUpdateDate   = (String)hrow.getAttribute("HeaderUpdateDate"); // ヘッダ更新日時
    String lineUpdateDate     = (String)hrow.getAttribute("LineUpdateDate");   // 明細更新日時
    String callPictureKbn     = (String)hrow.getAttribute("CallPictureKbn");   // 呼出画面区分
    String exeKbn             = (String)hrow.getAttribute("ExeKbn");           // 起動区分
    String retCode            = null;                                          // エラーコード
    String headerUpdateDateDb = null;                                          // ヘッダ最終更新日
    String lineUpdateDateDb   = null;                                          // 明細最終更新日

    //呼出画面区分が移動の場合
    if (XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
    {
      // ***************************************** //
      // *   移動依頼/指示ヘッダ(アドオン)ロック * //
      // ***************************************** //
      HashMap movHeaderRet = XxwshUtility.getXxinvMovHeadersLock(
                               getOADBTransaction(),
                               headerId);                                // ヘッダID
      retCode              = (String)movHeaderRet.get("retCode");        // 戻り値
      headerUpdateDateDb   = (String)movHeaderRet.get("lastUpdateDate"); // 最終更新日
      // ロックエラーの場合
      if (XxcmnConstants.RETURN_ERR1.equals(retCode))
      {
        // ロックエラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12908);
      }

      // *************************************** //
      // *   移動依頼/指示明細(アドオン)ロック * //
      // *************************************** //
      HashMap movLineRet = XxwshUtility.getXxinvMovLinesLock(
                             getOADBTransaction(),
                             headerId);                              // ヘッダID
      retCode            = (String)movLineRet.get("retCode");        // 戻り値
      lineUpdateDateDb   = (String)movLineRet.get("lastUpdateDate"); // 最終更新日
      // ロックエラーの場合
      if (XxcmnConstants.RETURN_ERR1.equals(retCode))
      {
        // ロック解除
        XxcmnUtility.rollBack(getOADBTransaction());
        // ロックエラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12908);
      }
    } else
    {
      // ******************************** //
      // *   受注ヘッダアドオンロック   * //
      // ******************************** //
      HashMap orderHeaderRet = XxwshUtility.getXxwshOrderHeadersAllLock(
                                 getOADBTransaction(),
                                 headerId);                                  // ヘッダID
      retCode                = (String)orderHeaderRet.get("retFlag");        // 戻り値
      headerUpdateDateDb     = (String)orderHeaderRet.get("lastUpdateDate"); // 最終更新日

      // ロックエラーの場合
      if (XxcmnConstants.RETURN_ERR1.equals(retCode))
      {
        // ロックエラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12908);
      }

      // ******************************** //
      // *   受注明細アドオンロック     * //
      // ******************************** //
      HashMap orderLineRet = XxwshUtility.getXxwshOrderLinesAllLock(
                               getOADBTransaction(),
                               headerId);                                // ヘッダID
      retCode              = (String)orderLineRet.get("retFlag");        // 戻り値
      lineUpdateDateDb     = (String)orderLineRet.get("lastUpdateDate"); // 最終更新日

      // ロックエラーの場合
      if (XxcmnConstants.RETURN_ERR1.equals(retCode))
      {
        // ロック解除
        XxcmnUtility.rollBack(getOADBTransaction());
        // ロックエラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12908);
      }
    }

    // *********************************** //
    // *  移動ロット詳細アドオンロック   * //
    // *********************************** //
    retCode = XxwshUtility.getXxinvMovLotDetailsLock(
                getOADBTransaction(),
                lineId,                           // 明細ID
                documentTypeCode,                 // 文書タイプ
                XxwshConstants.RECORD_TYPE_DELI); // レコードタイプ
    // ロックエラーの場合
    if (XxcmnConstants.RETURN_ERR1.equals(retCode))
    {
      // ロック解除
      XxcmnUtility.rollBack(getOADBTransaction());
      // ロックエラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH12908);
    }

    // ******************************** //
    // *  ヘッダ排他チェック          * //
    // ******************************** //
    // ロック時に取得した最終更新日と比較
    if (!headerUpdateDateDb.equals(headerUpdateDate))
    {
      //ロック解除
      XxcmnUtility.rollBack(getOADBTransaction());
      // ******************** // 
      // *  再表示          * //
      // ******************** //  
      HashMap params = new HashMap();
      params.put("LineId", lineId.toString());
      params.put("callPictureKbn",   callPictureKbn);
      params.put("headerUpdateDate", headerUpdateDateDb);
      params.put("lineUpdateDate",   lineUpdateDateDb);
      params.put("exeKbn",           exeKbn);
      initialize(params);
      // 排他エラーメッセージ出力

      // 呼出画面区分が移動の場合
      if (XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
      {
        // トークン生成
        MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_TABLE,
                                  XxwshConstants.TABLE_NAME_MOV_HEADERS) };
        // エラーメッセージを表示
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12907,
          tokens);
      // 呼出画面区分が移動以外の場合
      } else
      {
        // トークン生成
        MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_TABLE,
                                  XxwshConstants.TABLE_NAME_ORDER_HEADERS) };
        // エラーメッセージを表示
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12907,
          tokens);
      }
    }

    // ******************************** //
    // *   明細排他チェック           * //
    // ******************************** //
    // ロック時に取得した最終更新日と比較
    if (!lineUpdateDateDb.equals(lineUpdateDate))
    {
      //ロック解除
      XxcmnUtility.rollBack(getOADBTransaction());
      // ******************** // 
      // *  再表示          * //
      // ******************** //  
      HashMap params = new HashMap();
      params.put("LineId", lineId.toString());
      params.put("callPictureKbn",   callPictureKbn);
      params.put("headerUpdateDate", headerUpdateDateDb);
      params.put("lineUpdateDate",   lineUpdateDateDb);
      params.put("exeKbn",           exeKbn);
      initialize(params);
      // 排他エラーメッセージ出力
      // 呼出画面区分が移動の場合
      if (XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
      {
        // トークン生成
        MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_TABLE,
                                  XxwshConstants.TABLE_NAME_MOV_LINES) };
        // エラーメッセージを表示
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12907,
          tokens);
      // 呼出画面区分が移動以外の場合
      } else
      {
        // トークン生成
        MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_TABLE,
                                  XxwshConstants.TABLE_NAME_ORDER_LINES) };
        // エラーメッセージを表示
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12907,
          tokens);
      }
    }    
  }

  /***************************************************************************
   * 手持在庫数・引当可能数一覧リージョンの引当可能数が画面表示時と変更がないか調査します。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkCanEncQty() throws OAException
  {

    // 検索条件表示リージョン取得
    XxwshSearchVOImpl hvo           = getXxwshSearchVO1();
    // 検索条件表示リージョン一行目を取得
    OARow hrow                      = (OARow)hvo.first();
    // 明細情報リージョンを取得
    OAViewObject lvo               = getXxwshLineVO();
    // 明細情報リージョンの一行目を取得
    OARow lrow                     = (OARow)lvo.first();

    // 検索条件表示リージョン、明細情報リージョンの項目を取得
    Number lotCtl                   = (Number)hrow.getAttribute("LotCtl");                     // ロット管理品
    Number itemId                   = (Number)hrow.getAttribute("ItemId");                     // 品目ID
    Number inputInventoryLocationId = (Number)lrow.getAttribute("InputInventoryLocationId");   // 入力保管倉庫ID
    Date scheduleShipDate           = (Date)lrow.getAttribute("ScheduleShipDate");             // 出庫予定日
    String inventoryLocationName    = (String)lrow.getAttribute("InputInventoryLocationName"); // 保管倉庫名
    String itemCode                 = (String)hrow.getAttribute("ItemCode");                   // 品目コード
    String lineId                   = (String)hrow.getAttribute("LineId");                     // 明細ID
    String headerUpdateDate         = (String)hrow.getAttribute("HeaderUpdateDate");           // ヘッダ更新日時
    String lineUpdateDate           = (String)hrow.getAttribute("LineUpdateDate");             // 明細更新日時
    String callPictureKbn           = (String)hrow.getAttribute("CallPictureKbn");             // 呼出画面区分
    String exeKbn                   = (String)hrow.getAttribute("ExeKbn");                     // 起動区分
    String convUnitUseKbn           = (String)hrow.getAttribute("ConvUnitUseKbn");             // 入出庫換算単位使用区分
    String numOfCases               = (String)hrow.getAttribute("NumOfCases");                 // ケース入数

    // 手持在庫数・引当可能数一覧リージョン取得
    OAViewObject vo                 = getXxwshStockCanEncQtyVO1();
    // 手持在庫数・引当可能数一覧リージョンのデータ格納用変数
    OARow row                       = null;
    Number canEncQty                = null;                                                    // 画面表示時引当可能数
    Number nowCanEncQty             = null;                                                    // 取得した引当可能数
    Number lotId                    = null;                                                    // ロットID
    Number actualQuantity           = null;                                                    // 引当数量(換算後)
    Number actualQuantityBk         = null;                                                    // 画面表示時引当数量(換算後)
    String showLotNo                = null;                                                    // 表示用ロットNo
    String showCanEncQty            = null;                                                    // 画面表示時引当可能数(換算後)
    Double setCanEncQty             = null;
    ArrayList exceptions            = new ArrayList(100);                                      // エラーメッセージ格納用配列

    // 手持在庫数・引当可能数一覧リージョンの一行目をセット
    vo.first();
    // 全件ループ
    while (vo.getCurrentRow() != null )
    {
      // 処理対象行を取得
      row = (OARow)vo.getCurrentRow();

      canEncQty        = (Number)row.getAttribute("CanEncQty");        // 画面表示時引当可能数
      lotId            = (Number)row.getAttribute("LotId");            // ロットID
      actualQuantity   = (Number)row.getAttribute("ActualQuantity");   // 引当数量
      actualQuantityBk = (Number)row.getAttribute("ActualQuantityBk"); // 画面表示時引当数量
      showLotNo        = (String)row.getAttribute("ShowLotNo");        // 表示用ロットNo
      showCanEncQty    = (String)row.getAttribute("ShowCanEncQty");    // 画面表示時引当可能数(換算後)
      //引当数量が変更されている場合もしくは0より大きい場合にチェックを行う
      if (!actualQuantityBk.equals(actualQuantity)
        || (actualQuantity.doubleValue() > 0))
      {
        // ************************* // 
        // * 引当可能数算出API実行 * //
        // ************************* //
        nowCanEncQty = XxwshUtility.getCanEncQty(
                         getOADBTransaction(),
                         inputInventoryLocationId, // 入力保管倉庫ID
                         itemId,                   // 品目ID
                         lotId,                    // ロットID
                         lotCtl.toString(),        // ロット管理
                         scheduleShipDate);        // 有効日
        // 取得した引当可能数が画面表示時引当可能数と一致しない場合
        if (!nowCanEncQty.equals(canEncQty))
        {
          // トークンを宣言しセット
          MessageToken[] tokens = new MessageToken[2];
          
          tokens[0] = new MessageToken(
                            XxwshConstants.TOKEN_LOCATION,
                            inventoryLocationName);
          tokens[1] = new MessageToken(
                            XxwshConstants.TOKEN_LOT,
                            showLotNo);

          // 換算対象の場合取得した引当数量を換算する
          if (XxwshConstants.CONV_UNIT_USE_KBN_INCLUDE.equals(convUnitUseKbn))
          {
            setCanEncQty = new Double(nowCanEncQty.doubleValue() / Double.parseDouble(numOfCases));
          } else 
          {
            setCanEncQty = new Double(nowCanEncQty.doubleValue());
          }
          // エラーメッセージを追加
          exceptions.add( 
            new OAAttrValException(
                OAAttrValException.TYP_VIEW_OBJECT,          
                vo.getName(),
                row.getKey(),
                "ShowCanEncQty",
                XxcmnUtility.formConvNumber(setCanEncQty, 9, 3, true),
                XxcmnConstants.APPL_XXWSH,         
                XxwshConstants.XXWSH12906,
                tokens));
        }
      }
      // 次のレコードへ
      vo.next();
    }
    //エラーがある場合メッセージを出力
    if(exceptions.size() > 0)
    {
      // ロック解除
      XxcmnUtility.rollBack(getOADBTransaction());
      // ******************** // 
      // *  再表示          * //
      // ******************** // 
      HashMap params = new HashMap();
      params.put("LineId",           lineId);
      params.put("callPictureKbn",   callPictureKbn);
      params.put("headerUpdateDate", headerUpdateDate);
      params.put("lineUpdateDate",   lineUpdateDate);
      params.put("exeKbn",           exeKbn);
      initialize(params);
      // エラーメッセージを出力
      OAException.raiseBundledOAException(exceptions);
    }

  }

  /***************************************************************************
   * 明細とヘッダの配車関連情報を算出します。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void getDeliveryInfo() throws OAException
  {

    // 検索条件表示リージョン取得
    OAViewObject hvo                 = getXxwshSearchVO1();
    // 検索条件表示リージョン一行目を取得
    OARow hrow                       = (OARow)hvo.first();

    // 検索条件表示リージョンの項目を取得
    String itemCode                  = (String)hrow.getAttribute("ItemCode");                // 品目コード
// 2008-12-10 H.Itou Mod Start
//    Number sumReservedQuantityItem   = (Number)hrow.getAttribute("SumReservedQuantityItem"); // 引当数量合計(品目単位)
    BigDecimal sumReservedQuantityItem = XxcmnUtility.bigDecimalValue(XxcmnUtility.stringValue((Number)hrow.getAttribute("SumReservedQuantityItem"))); // 引当数量合計(品目単位)
// 2008-12-10 H.Itou Mod End
    String callPictureKbn            = (String)hrow.getAttribute("CallPictureKbn");          // 呼出画面区分
    String numOfCases                = (String)hrow.getAttribute("NumOfCases");              // ケース入数
    String numOfDeliver              = (String)hrow.getAttribute("NumOfDeliver");            // 出荷入数

    // 明細情報リージョンを取得
    OAViewObject lvo                 = getXxwshLineVO();
    // 明細情報リージョンの一行目を取得
    OARow lrow                       = (OARow)lvo.first();  

    // 明細情報リージョンの項目を取得
    Number headerId                   = (Number)lrow.getAttribute("HeaderId");                   // ヘッダID
    Number lineId                     = (Number)lrow.getAttribute("LineId");                     // 明細ID
    Date scheduleShipDate             = (Date)lrow.getAttribute("ScheduleShipDate");             // 出庫予定日
    String headerProdClass            = (String)lrow.getAttribute("HeaderProdClass");            // 商品区分
    String weightCapacityClass        = (String)lrow.getAttribute("WeightCapacityClass");        // 重量容積区分
    String deliverTo                  = (String)lrow.getAttribute("DeliverTo");                  // 出庫先
    String inputInventoryLocationCode = (String)lrow.getAttribute("InputInventoryLocationCode"); // 出庫元
    String freightChargeClass         = (String)lrow.getAttribute("FreightChargeClass");         // 運賃区分

    // 配車関連情報を格納する変数を宣言
// 2008-12-10 H.Itou Mod Start
//    double weight                    = 0;     // 重量
//    double capacity                  = 0;     // 容積
//    double sumWeight                 = 0;     // 積載重量合計
//    double sumCapacity               = 0;     // 積載容積合計
//    double loadingEfficiencyWeight   = 0;     // 積載効率(重量)
//    double loadingEfficiencyCapacity = 0;     // 積載効率(容積)
//    double sumQuantity               = 0;     // 合計数量
//    double smallQuantity             = 0;     // 小口個数
//    double labelQuantity             = 0;     // ラベル枚数
//    double palletWeight              = 0;     // パレット重量
//    double sumPalletWeight           = 0;     // 合計パレット重量
//
    BigDecimal weight                    = new BigDecimal(0);     // 重量
    BigDecimal capacity                  = new BigDecimal(0);     // 容積
    BigDecimal sumWeight                 = new BigDecimal(0);     // 積載重量合計
    BigDecimal sumCapacity               = new BigDecimal(0);     // 積載容積合計
    BigDecimal loadingEfficiencyWeight   = new BigDecimal(0);     // 積載効率(重量)
    BigDecimal loadingEfficiencyCapacity = new BigDecimal(0);     // 積載効率(容積)
    BigDecimal sumQuantity               = new BigDecimal(0);     // 合計数量
    BigDecimal smallQuantity             = new BigDecimal(0);     // 小口個数
    BigDecimal labelQuantity             = new BigDecimal(0);     // ラベル枚数
    BigDecimal palletWeight              = new BigDecimal(0);     // パレット重量
    BigDecimal sumPalletWeight           = new BigDecimal(0);     // 合計パレット重量
// 2008-12-10 H.Itou Mod End
    String retCode                    = null; // リターンコード
    String errMsg                     = null; // エラーメッセージ
    String systemMsg                  = null; // システムエラーメッセージ
    String loadingOverClass           = null; // 積載オーバー区分
    String shipMethod                 = null; // 配送区分
    String loadEfficiencyWeight       = null; // 重量積載効率
    String loadEfficiencyCapacity     = null; // 容積積載効率
    String mixedShipMethod            = null; // 混載配送区分
    String smallAmountClass           = null; // 小口区分
    // ************************************************* // 
    // *  画面で対象となっている明細の重量と容積を取得 * //
    // ************************************************* // 
    HashMap paramsRet = XxwshUtility.calcTotalValue(
                          getOADBTransaction(),
                          itemCode,
                          sumReservedQuantityItem.toString(),
// 2008-10-07 H.Itou Add Start 統合テスト指摘240
                          scheduleShipDate
// 2008-10-07 H.Itou Add End
                          );
    // 取得した重量がNULL以外の場合
    if (!XxcmnUtility.isBlankOrNull((String)paramsRet.get("sumWeight")))
    {
// 2008-12-10 H.Itou Mod Start
//      // 重量をセット
//      weight                 = Double.parseDouble((String)paramsRet.get("sumWeight"));
//      // 検索条件表示リージョンにセットするため型変換
//      BigDecimal setWeigtht  = new BigDecimal(String.valueOf(weight));
//      // 明細の更新に使用するため検索条件表示リージョンにセット
//      hrow.setAttribute("Weight", XxcmnUtility.stringValue(setWeigtht));
//      // ヘッダにセットする合計重量に加算
//      sumWeight              = sumWeight + weight;
      // 重量をセット
      weight = XxcmnUtility.bigDecimalValue((String)paramsRet.get("sumWeight"));
      // 明細の更新に使用するため検索条件表示リージョンにセット
      hrow.setAttribute("Weight", (String)paramsRet.get("sumWeight"));
      // ヘッダにセットする合計重量に加算
      sumWeight = sumWeight.add(weight);
// 2008-12-10 H.Itou Mod End
    }

    // 取得した容積がNULL以外の場合
    if (!XxcmnUtility.isBlankOrNull((String)paramsRet.get("sumCapacity")))
    {
// 2008-12-10 H.Itou Mod Start
//      // 容積をセット
//      capacity                = Double.parseDouble((String)paramsRet.get("sumCapacity"));
//      // 検索条件表示リージョンにセットするため型変換
//      BigDecimal setCapacity  = new BigDecimal(String.valueOf(capacity));
//      // 明細の更新に使用するため検索条件表示リージョンにセット
//      hrow.setAttribute("Capacity",XxcmnUtility.stringValue(setCapacity));
//      // ヘッダにセットする合計容積に加算
//      sumCapacity             = sumCapacity + capacity;
      // 容積をセット
      capacity = XxcmnUtility.bigDecimalValue((String)paramsRet.get("sumCapacity"));
      // 明細の更新に使用するため検索条件表示リージョンにセット
      hrow.setAttribute("Capacity", (String)paramsRet.get("sumCapacity"));
      // ヘッダにセットする合計容積に加算
      sumCapacity = sumCapacity.add(capacity);
// 2008-12-10 H.Itou Mod End
    }

    // 取得したパレット重量がNULL以外で呼出画面区分が支給指示作成画面起動以外の場合
    if (!XxcmnUtility.isBlankOrNull((String)paramsRet.get("sumPalletWeigh"))
      && !XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
    {
// 2008-12-10 H.Itou Mod Start
//      // パレット重量をセット
//      palletWeight                = Double.parseDouble((String)paramsRet.get("sumPalletWeigh"));
//      // 検索条件表示リージョンにセットするため型変換
//      BigDecimal setPalletWeight  = new BigDecimal(String.valueOf(palletWeight));
//      // 明細の更新に使用するため検索条件表示リージョンにセット
//      hrow.setAttribute("PalletWeight",XxcmnUtility.stringValue(setPalletWeight));
//      // ヘッダにセットする合計パレット重量に加算
//      sumPalletWeight             = sumPalletWeight + palletWeight;
      // パレット重量をセット
      palletWeight = XxcmnUtility.bigDecimalValue((String)paramsRet.get("sumPalletWeigh"));
      // 明細の更新に使用するため検索条件表示リージョンにセット
      hrow.setAttribute("PalletWeight", (String)paramsRet.get("sumPalletWeigh"));
      // ヘッダにセットする合計パレット重量に加算
      sumPalletWeight = sumPalletWeight.add(palletWeight);
// 2008-12-10 H.Itou Mod End
    }
    // 合計数量に明細の数量を加算します。
// 2008-12-10 H.Itou Mod Start
//    sumQuantity = sumQuantity + sumReservedQuantityItem.doubleValue();
    sumQuantity = sumQuantity.add(sumReservedQuantityItem);
// 2008-12-10 H.Itou Mod End
    if (sumReservedQuantityItem.doubleValue() == 0 )
    {
      // 処理を行いません。

    // 出荷入数が設定されている場合
    } else if (!XxcmnUtility.isBlankOrNull(numOfDeliver))
    {
      // 小口個数に引当数量合計を出荷入数で割った値を加算します。
// 2008-12-10 H.Itou Mod Start
//// 2008/08/07 D.Nihei Mod Start
////      smallQuantity = smallQuantity + Math.round((sumReservedQuantityItem.doubleValue() / Double.parseDouble(numOfDeliver)));
//      smallQuantity = smallQuantity + Math.ceil(sumReservedQuantityItem.doubleValue() / Double.parseDouble(numOfDeliver));
//// 2008/08/07 D.Nihei Mod End
      smallQuantity = smallQuantity.add(sumReservedQuantityItem.divide(XxcmnUtility.bigDecimalValue(numOfDeliver), 0, BigDecimal.ROUND_CEILING));
// 2008-12-10 H.Itou Mod End
      // ラベル枚数に引当数量合計を出荷入数で割った値を加算します。
// 2008-12-10 H.Itou Mod Start
//// 2008/08/07 D.Nihei Mod Start
////      labelQuantity = labelQuantity + Math.round((sumReservedQuantityItem.doubleValue() / Double.parseDouble(numOfDeliver)));
//      labelQuantity = labelQuantity + Math.ceil(sumReservedQuantityItem.doubleValue() / Double.parseDouble(numOfDeliver));
//// 2008/08/07 D.Nihei Mod End
      labelQuantity = labelQuantity.add(sumReservedQuantityItem.divide(XxcmnUtility.bigDecimalValue(numOfDeliver), 0, BigDecimal.ROUND_CEILING));
// 2008-12-10 H.Itou Mod End

    // ケース入数が設定されている場合
    } else if (!XxcmnUtility.isBlankOrNull(numOfCases))
    {
      // 小口個数に引当数量合計をケース入数で割った値を加算します。
// 2008-12-10 H.Itou Mod Start
//// 2008/08/07 D.Nihei Mod Start
////      smallQuantity = smallQuantity + Math.round((sumReservedQuantityItem.doubleValue() / Double.parseDouble(numOfCases)));
//      smallQuantity = smallQuantity + Math.ceil(sumReservedQuantityItem.doubleValue() / Double.parseDouble(numOfCases));
//// 2008/08/07 D.Nihei Mod End
      smallQuantity = smallQuantity.add(sumReservedQuantityItem.divide(XxcmnUtility.bigDecimalValue(numOfCases), 0, BigDecimal.ROUND_CEILING));
// 2008-12-10 H.Itou Mod End
      // ラベル枚数に引当数量合計をケース入数で割った値を加算します。
// 2008-12-10 H.Itou Mod Start
//// 2008/08/07 D.Nihei Mod Start
////      labelQuantity = labelQuantity + Math.round((sumReservedQuantityItem.doubleValue() / Double.parseDouble(numOfCases)));
//      labelQuantity = labelQuantity + Math.ceil(sumReservedQuantityItem.doubleValue() / Double.parseDouble(numOfCases));
//// 2008/08/07 D.Nihei Mod End
      labelQuantity = labelQuantity.add(sumReservedQuantityItem.divide(XxcmnUtility.bigDecimalValue(numOfCases), 0, BigDecimal.ROUND_CEILING));
// 2008-12-10 H.Itou Mod End
    // 上記以外の場合
    } else
    {
      // 小口個数に引当数量合計を加算します。
// 2008-12-10 H.Itou Mod Start
//// 2008/08/07 D.Nihei Mod Start
////      smallQuantity = smallQuantity + sumReservedQuantityItem.doubleValue();
//      smallQuantity = smallQuantity + Math.ceil(sumReservedQuantityItem.doubleValue());
//// 2008/08/07 D.Nihei Mod End
      smallQuantity = smallQuantity.add(sumReservedQuantityItem.divide(new BigDecimal(1), 0, BigDecimal.ROUND_CEILING));
// 2008-12-10 H.Itou Mod Start
      // ラベル枚数に引当数量合計を加算します。
// 2008-12-10 H.Itou Mod Start
//// 2008/08/07 D.Nihei Mod Start
////      labelQuantity = labelQuantity + sumReservedQuantityItem.doubleValue();
//      labelQuantity = labelQuantity + Math.ceil(sumReservedQuantityItem.doubleValue());
//// 2008/08/07 D.Nihei Mod End
      labelQuantity = labelQuantity.add(sumReservedQuantityItem.divide(new BigDecimal(1), 0, BigDecimal.ROUND_CEILING));
// 2008-12-10 H.Itou Mod End
    }

    // ******************************************************************* //
    // *  画面で対象となっている明細と同じヘッダの数量、重量、容積を取得 * //
    // ******************************************************************* //
    HashMap lineParams = null;
    // 呼出画面区分が移動依頼/指示入力画面起動の場合
    if(XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
    {
      lineParams = XxwshUtility.getDeliverSummaryMoveLine(
                     getOADBTransaction(),
                     headerId,
                     lineId,
                     scheduleShipDate);
    // 呼出画面区分が移動依頼/指示入力画面起動以外の場合
    } else
    {
      lineParams = XxwshUtility.getDeliverSummaryOrderLine(
                     getOADBTransaction(),
                     headerId,
                     lineId,
                     scheduleShipDate);
    }
    String returnSumQty             = (String)lineParams.get("sumQuantity");       // 数量
    String returnSumWeight          = (String)lineParams.get("sumWeight");         // 重量
    String returnSumCapacity        = (String)lineParams.get("sumCapacity");       // 容積
    String returnSumPalletWeight    = (String)lineParams.get("sumPalletWeight");   // パレット重量
    String returnSumSmallQuantity   = (String)lineParams.get("sumSmallQuantity");  // 小口個数
    String returnSumLabelQuantity   = (String)lineParams.get("sumLabelQuantity");  // ラベル枚数

    // 取得した数量がNULL以外の場合
    if (!XxcmnUtility.isBlankOrNull(returnSumQty))
    {
      // 取得した数量を合計数量に加算
// 2008-12-10 H.Itou Mod Start
//      sumQuantity      = sumQuantity + Double.parseDouble(returnSumQty);
      sumQuantity      = sumQuantity.add(XxcmnUtility.bigDecimalValue(returnSumQty));
// 2008-12-10 H.Itou Mod End
    }
    // 取得した重量がNULL以外の場合
    if (!XxcmnUtility.isBlankOrNull(returnSumWeight))
    {
      // 取得した重量を合計重量に加算
// 2008-12-10 H.Itou Mod Start
//      sumWeight        = sumWeight + Double.parseDouble(returnSumWeight);
      sumWeight        = sumWeight.add(XxcmnUtility.bigDecimalValue(returnSumWeight));
// 2008-12-10 H.Itou Mod End
    }
    // 取得した容積がNULL以外の場合
    if (!XxcmnUtility.isBlankOrNull(returnSumCapacity))
    {
      // 取得した容積を合計容積に加算
// 2008-12-10 H.Itou Mod Start
//      sumCapacity      = sumCapacity + Double.parseDouble(returnSumCapacity);
      sumCapacity        = sumCapacity.add(XxcmnUtility.bigDecimalValue(returnSumCapacity));
// 2008-12-10 H.Itou Mod End
    }
    // 取得したパレット重量がNULL以外の場合
    if (!XxcmnUtility.isBlankOrNull(returnSumPalletWeight))
    {
      // 取得したパレット重量を合計パレット重量に加算
// 2008-12-10 H.Itou Mod Start
//      sumPalletWeight  = sumPalletWeight + Double.parseDouble(returnSumPalletWeight);
      sumPalletWeight  = sumPalletWeight.add(XxcmnUtility.bigDecimalValue(returnSumPalletWeight));
// 2008-12-10 H.Itou Mod End
    }
    // 取得した小口個数がNULL以外の場合
    if (!XxcmnUtility.isBlankOrNull(returnSumSmallQuantity))
    {
// 2008-12-10 H.Itou Mod Start
      // 取得した小口個数を小口個数に加算
//      smallQuantity    = smallQuantity + Double.parseDouble(returnSumSmallQuantity);
      smallQuantity    = smallQuantity.add(XxcmnUtility.bigDecimalValue(returnSumSmallQuantity).divide(new BigDecimal(1), 0, BigDecimal.ROUND_CEILING));
// 2008-12-10 H.Itou Mod End
    }
    // 取得したラベル枚数がNULL以外の場合
    if (!XxcmnUtility.isBlankOrNull(returnSumLabelQuantity))
    {
      // 取得したラベル枚数をラベル枚数に加算
// 2008-12-10 H.Itou Mod Start
//      labelQuantity    = labelQuantity + Double.parseDouble(returnSumLabelQuantity);
      labelQuantity    = labelQuantity.add(XxcmnUtility.bigDecimalValue(returnSumLabelQuantity).divide(new BigDecimal(1), 0, BigDecimal.ROUND_CEILING));
// 2008-12-10 H.Itou Mod End
    }

    // 検索条件表示リージョンにセットするため一時的に型変換
// 2008-12-10 H.Itou Mod Start
//    BigDecimal setSumQuantity     = new BigDecimal(String.valueOf(sumQuantity));      // 合計数量
//    BigDecimal setSumWeight       = new BigDecimal(String.valueOf(sumWeight));        // 合計重量
//    BigDecimal setSumCapacity     = new BigDecimal(String.valueOf(sumCapacity));      // 合計容積
//    BigDecimal setSumPalletWeight = new BigDecimal(String.valueOf(sumPalletWeight));  // 合計パレット重量
//    BigDecimal setSmallQuantity   = new BigDecimal(String.valueOf(smallQuantity));    // 小口個数
//    BigDecimal setLabelQuantity   = new BigDecimal(String.valueOf(labelQuantity));    // ラベル枚数
    BigDecimal setSumQuantity     = sumQuantity;      // 合計数量
    BigDecimal setSumWeight       = sumWeight;        // 合計重量
    BigDecimal setSumCapacity     = sumCapacity;      // 合計容積
    BigDecimal setSumPalletWeight = sumPalletWeight;  // 合計パレット重量
    BigDecimal setSmallQuantity   = smallQuantity;    // 小口個数
    BigDecimal setLabelQuantity   = labelQuantity;    // ラベル枚数
// 2008-12-10 H.Itou Mod End

    // ヘッダの更新に使用するため検索条件表示リージョンにセット
    hrow.setAttribute("SumQuantity"    ,XxcmnUtility.stringValue(setSumQuantity));     // 合計数量
    hrow.setAttribute("SumWeight"      ,XxcmnUtility.stringValue(setSumWeight));       // 合計重量
    hrow.setAttribute("SumCapacity"    ,XxcmnUtility.stringValue(setSumCapacity));     // 合計容積
    hrow.setAttribute("SumPalletWeight",XxcmnUtility.stringValue(setSumPalletWeight)); // 合計パレット重量
    hrow.setAttribute("SmallQuantity"  ,XxcmnUtility.stringValue(setSmallQuantity));   // 小口個数
    hrow.setAttribute("LabelQuantity"  ,XxcmnUtility.stringValue(setLabelQuantity));   // ラベル枚数

    // 運賃区分を使用する場合
    if (XxwshConstants.INCLUDE_EXCLUD_INCLUDE.equals(freightChargeClass))
    {
      // ***************************** //
      // *  最大配送区分を算出         * //
      // ***************************** //
      // 最大配送区分に使用する変数を宣言
      String codeClass1 = XxwshConstants.CODE_KBN_4; // コードクラス1
      String codeClass2 = null;                      // コードクラス2

      // 出荷依頼入力画面起動の場合
      if(XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn))
      {
        codeClass2 = XxwshConstants.CODE_KBN_9; // コードクラス2

      // 支給指示作成画面起動の場合    
      } else if (XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
      {
        codeClass2 = XxwshConstants.CODE_KBN_11; // コードクラス2

      // 移動依頼/指示入力画面起動の場合
      } else if (XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
      {
        codeClass2 = XxwshConstants.CODE_KBN_4; // コードクラス2
      }
    
      // 最大配送区分を取得
      HashMap shipParams = XxwshUtility.getMaxShipMethod(
                             getOADBTransaction(),
                             codeClass1,                 // コード区分1
                             inputInventoryLocationCode, // 出庫元
                             codeClass2,                 // コード区分2
                             deliverTo,                  // 出庫先
                             weightCapacityClass,        // 重量容積区分
                             headerProdClass,            // ヘッダ商品区分
                             null,                       // 自動配車対象区分
                             scheduleShipDate);          // 出庫予定日
      String maxShipMethods  = (String)shipParams.get("maxShipMethods");  // 最大配送区分
      String paletteMaxQty   = (String)shipParams.get("paletteMaxQty");   // パレット最大枚数
      String deadWeight      = (String)shipParams.get("deadWeight");      // 積載重量
      String loadingCapacity = (String)shipParams.get("loadingCapacity"); // 積載容積

      // 最大配送区分がNULLの場合
      if (XxcmnUtility.isBlankOrNull(maxShipMethods))
      {
        // ロック解除
        XxcmnUtility.rollBack(getOADBTransaction());
        // トークンを作成
        MessageToken[] tokens = new MessageToken[6];
        tokens[0] = new MessageToken(
                      XxwshConstants.TOKEN_CODE_KBN1,
                      codeClass1);
        tokens[1] = new MessageToken(
                      XxwshConstants.TOKEN_SHIP_FROM,
                      inputInventoryLocationCode);
        tokens[2] = new MessageToken(
                      XxwshConstants.TOKEN_CODE_KBN2,
                      codeClass2);
        tokens[3] = new MessageToken(
                      XxwshConstants.TOKEN_SHIP_TO,
                      deliverTo);
        tokens[4] = new MessageToken(
                      XxwshConstants.TOKEN_PROD_CLASS,
                      headerProdClass);
        tokens[5] = new MessageToken(
                      XxwshConstants.TOKEN_SHIP_DATE,
                      XxcmnUtility.stringValue(scheduleShipDate));
                                     
        // エラーメッセージを表示
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12910,
          tokens);
      }
      // 最大配送区分の小口区分取得
      smallAmountClass = XxwshUtility.getSmallKbn(
                           getOADBTransaction(),
                           maxShipMethods,
                           scheduleShipDate);      
      // ************************************ //
      // *  最大配送区分での積載効率チェック* //
      // ************************************ //
      // 重量容積区分が重量の場合
      if (XxwshConstants.WGHT_CAPA_CLASS_WEIGHT.equals(weightCapacityClass))
      {
        // 呼出画面区分が支給の場合
        if (XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
        {
// 2008-12-10 H.Itou Mod Start
//          setSumWeight = new BigDecimal(String.valueOf(sumWeight)); // 合計重量
          setSumWeight = sumWeight; // 合計重量
// 2008-12-10 H.Itou Mod End

        // 小口区分が対象の場合
        } else if (XxwshConstants.INCLUDE_EXCLUD_INCLUDE.equals(smallAmountClass))
        {
// 2008-12-10 H.Itou Mod Start
//          setSumWeight = new BigDecimal(String.valueOf(sumWeight)); // 合計重量
          setSumWeight = sumWeight; // 合計重量
// 2008-12-10 H.Itou Mod End

        } else
        {
// 2008-12-10 H.Itou Mod Start
//          setSumWeight = new BigDecimal(String.valueOf(sumWeight + sumPalletWeight)); // 合計重量 + パレット重量    
          setSumWeight = sumWeight.add(sumPalletWeight); // 合計重量 + パレット重量    
// 2008-12-10 H.Itou Mod End
        }

        setSumCapacity = null; // 合計容積はNULLをセット
      // 重量容積区分が容積の場合      
      } else if (XxwshConstants.WGHT_CAPA_CLASS_CAPACITY.equals(weightCapacityClass))
      {
// 2008-12-10 H.Itou Mod Start
//        setSumCapacity = new BigDecimal(String.valueOf(sumCapacity)); // 合計容積
        setSumCapacity = sumCapacity; // 合計容積
// 2008-12-10 H.Itou Mod End
        setSumWeight = null; // 合計
      }
      // 最大積載効率チェック
      HashMap maxParams = XxwshUtility.calcLoadEfficiency(
                            getOADBTransaction(),
                            XxcmnUtility.stringValue(setSumWeight),
                            XxcmnUtility.stringValue(setSumCapacity),
                            codeClass1,
                            inputInventoryLocationCode,
                            codeClass2,
                            deliverTo,
                            maxShipMethods,
                            scheduleShipDate,
                            headerProdClass);
      // 戻り値を取得
      retCode                = (String)maxParams.get("retCode");                // リターンコード
      errMsg                 = (String)maxParams.get("retCode");                // エラーメッセージ
      systemMsg              = (String)maxParams.get("systemMsg");              // システムエラーメッセージ
      loadingOverClass       = (String)maxParams.get("loadingOverClass");       // システムエラーメッセージ
      shipMethod             = (String)maxParams.get("shipMethod");             // 配送区分
      loadEfficiencyWeight   = (String)maxParams.get("loadEfficiencyWeight");   // 重量積載効率
      loadEfficiencyCapacity = (String)maxParams.get("loadEfficiencyCapacity"); // 容積積載効率
      mixedShipMethod        = (String)maxParams.get("mixedShipMethod");        // 混載配送区分
      
      // 積載オーバの場合
      if (XxwshConstants.LOADING_OVER_CLASS_OVER.equals(loadingOverClass))
      {
        String kubunName         = null; // 区分名称
        String loadingEfficiency = null; // 積載効率
        // 重量容積区分が重量の場合
        if (XxwshConstants.WGHT_CAPA_CLASS_WEIGHT.equals(weightCapacityClass))
        {
          kubunName         = XxwshConstants.TOKEN_NAME_WEIGHT; // 重量
          loadingEfficiency = loadEfficiencyWeight;             // 重量積載効率
        } else if (XxwshConstants.WGHT_CAPA_CLASS_CAPACITY.equals(weightCapacityClass))
        {
          kubunName         = XxwshConstants.TOKEN_NAME_CAPACITY; // 容積
          loadingEfficiency = loadEfficiencyCapacity;             // 容積積載効率
        }
        // ロック解除
        XxcmnUtility.rollBack(getOADBTransaction());
        // トークンを作成
        MessageToken[] tokens = new MessageToken[2];
        tokens[0] = new MessageToken(
                      XxwshConstants.TOKEN_KUBUN,
                      kubunName);
        tokens[1] = new MessageToken(
                      XxwshConstants.TOKEN_LOADING_EFFICIENCY,
                      loadingEfficiency);
                                     
        // エラーメッセージを表示
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12909,
          tokens);

      }

      // ******************************************* //
      // * ヘッダにセットするための積載効率を算出  * //
      // ******************************************* //

      // ヘッダの小口区分、配送区分を取得
      String shipMethodMeaning = (String)lrow.getAttribute("ShipMethodMeaning"); // 配送区分
      smallAmountClass         = (String)lrow.getAttribute("SmallAmountClass");  // 小口区分
// 2008/08/07 D.Nihei Del Start
//      // 合計重量が0より大きい場合
//      if (sumWeight > 0 )
//      {
// 2008/08/07 D.Nihei Del End
      // 呼出画面区分が支給の場合
      if (XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
      {
// 2008-12-10 H.Itou Mod Start
//        setSumWeight = new BigDecimal(String.valueOf(sumWeight)); // 合計重量
        setSumWeight = sumWeight; // 合計重量
// 2008-12-10 H.Itou Mod End

      // 小口区分が対象の場合
      } else if (XxwshConstants.INCLUDE_EXCLUD_INCLUDE.equals(smallAmountClass))
      {
// 2008-12-10 H.Itou Mod Start
//        setSumWeight = new BigDecimal(String.valueOf(sumWeight)); // 合計重量
        setSumWeight = sumWeight; // 合計重量
// 2008-12-10 H.Itou Mod End
      } else
      {
// 2008-12-10 H.Itou Mod Start
//        setSumWeight = new BigDecimal(String.valueOf(sumWeight + sumPalletWeight)); // 合計重量 + パレット重量    
        setSumWeight = sumWeight.add(sumPalletWeight); // 合計重量 + パレット重量    
// 2008-12-10 H.Itou Mod End 
      }

      setSumCapacity = null; // 合計容積はNULLをセット
      // 最大積載効率チェック
      HashMap weightParams = XxwshUtility.calcLoadEfficiency(
                               getOADBTransaction(),
                               XxcmnUtility.stringValue(setSumWeight),
                               XxcmnUtility.stringValue(setSumCapacity),
                               codeClass1,
                               inputInventoryLocationCode,
                               codeClass2,
                               deliverTo,
                               shipMethodMeaning,
                               scheduleShipDate,
                               headerProdClass);
      // 戻り値を取得
      retCode                = (String)weightParams.get("retCode");                // リターンコード
      errMsg                 = (String)weightParams.get("retCode");                // エラーメッセージ
      systemMsg              = (String)weightParams.get("systemMsg");              // システムエラーメッセージ
      loadingOverClass       = (String)weightParams.get("loadingOverClass");       // システムエラーメッセージ
      shipMethod             = (String)weightParams.get("shipMethod");             // 配送区分
      loadEfficiencyWeight   = (String)weightParams.get("loadEfficiencyWeight");   // 重量積載効率
      loadEfficiencyCapacity = (String)weightParams.get("loadEfficiencyCapacity"); // 容積積載効率
      mixedShipMethod        = (String)weightParams.get("mixedShipMethod");        // 混載配送区分

      // 取得した重量積載効率を検索条件表示リージョンにセット
      hrow.setAttribute("LoadingEfficiencyWeight" ,loadEfficiencyWeight.toString());
        
// 2008/08/07 D.Nihei Del Start
//      }
//      // 合計容積が0より大きい場合
//      if (sumCapacity > 0)
//      {
// 2008/08/07 D.Nihei Del End
// 2008-12-10 H.Itou Mod Start
//      setSumCapacity = new BigDecimal(String.valueOf(sumCapacity)); // 合計容積
      setSumCapacity = sumCapacity; // 合計容積
// 2008-12-10 H.Itou Mod End
      setSumWeight = null; // 重量合計
      // 最大積載効率チェック
      HashMap capParams = XxwshUtility.calcLoadEfficiency(
                            getOADBTransaction(),
                            XxcmnUtility.stringValue(setSumWeight),
                            XxcmnUtility.stringValue(setSumCapacity),
                            codeClass1,
                            inputInventoryLocationCode,
                            codeClass2,
                            deliverTo,
                            shipMethodMeaning,
                            scheduleShipDate,
                            headerProdClass);
      // 戻り値を取得
      retCode                = (String)capParams.get("retCode");                // リターンコード
      errMsg                 = (String)capParams.get("retCode");                // エラーメッセージ
      systemMsg              = (String)capParams.get("systemMsg");              // システムエラーメッセージ
      loadingOverClass       = (String)capParams.get("loadingOverClass");       // システムエラーメッセージ
      shipMethod             = (String)capParams.get("shipMethod");             // 配送区分
      loadEfficiencyWeight   = (String)capParams.get("loadEfficiencyWeight");   // 重量積載効率
      loadEfficiencyCapacity = (String)capParams.get("loadEfficiencyCapacity"); // 容積積載効率
      mixedShipMethod        = (String)capParams.get("mixedShipMethod");        // 混載配送区分

      // 取得した容積積載効率を検索条件表示リージョンにセット
      hrow.setAttribute("LoadingEfficiencyCapacity" ,loadEfficiencyCapacity.toString());
// 2008/08/07 D.Nihei Del Start
//      }
// 2008/08/07 D.Nihei Del End
    }
  }

  /***************************************************************************
   * 警告チェックを行うメソッドです。
   * @return HashMap     - 警告エラー情報
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public HashMap checkWarning() throws OAException
  {
    HashMap msg = new HashMap();
    // 検索条件表示リージョン取得
    OAViewObject hvo                 = getXxwshSearchVO1();
    // 検索条件表示リージョン一行目を取得
    OARow hrow                       = (OARow)hvo.first();

    // 検索条件表示リージョンの項目を取得
    String itemCode                  = (String)hrow.getAttribute("ItemCode");                // 品目コード
    String callPictureKbn            = (String)hrow.getAttribute("CallPictureKbn");          // 呼出画面区分
    Number lotCtl                    = (Number)hrow.getAttribute("LotCtl");                  // ロット管理    
    String prodClass                 = (String)hrow.getAttribute("ProdClass");               // 商品区分
    String itemClass                 = (String)hrow.getAttribute("ItemClass");               // 品目区分
    Number itemId                    = (Number)hrow.getAttribute("ItemId");                  // 品目ID
    String itemShortName             = (String)hrow.getAttribute("ItemShortName");           // 品目略称
// 2009-01-22 H.Itou Add Start 本番#1000対応
    String requestNo                 = (String)hrow.getAttribute("RequestNo");               // 依頼No
// 2009-01-22 H.Itou Add End
    // 検索条件表示リージョン格納用変数
    String warningClass              = null;                                                 // 警告区分
    Date   warningDate               = null;                                                 // 警告日付

    // 明細情報リージョンを取得
    OAViewObject lvo                 = getXxwshLineVO();
    // 明細情報リージョンの一行目を取得
    OARow lrow                       = (OARow)lvo.first();

    // 明細情報リージョンの項目を取得
    Number deliverToId               = (Number)lrow.getAttribute("DeliverToId");                // 出庫先ID
    String deliverTo                 = (String)lrow.getAttribute("DeliverTo");                  // 出庫先(コード)
    Date scheduleArrivalDate         = (Date)lrow.getAttribute("ScheduleArrivalDate");          // 入庫予定日
    Date scheduleShipDate            = (Date)lrow.getAttribute("ScheduleShipDate");             // 出庫予定日
    Number inventoryLocationId       = (Number)lrow.getAttribute("InputInventoryLocationId");   // 保管倉庫ID
    String locationName              = (String)lrow.getAttribute("InputInventoryLocationName"); // 出庫元保管場所
// 2008-10-22 D.Nihei Add Start 統合テスト指摘194対応
    String deliverToName             = (String)lrow.getAttribute("DeliverToName");              // 入庫先保管場所
// 2008-10-22 D.Nihei Add End

   // 手持在庫数・引当可能数一覧リージョン取得
    OAViewObject vo                  = getXxwshStockCanEncQtyVO1();
    // 手持在庫数・引当可能数一覧リージョンのデータ格納用変数
    OARow row                        = null;
    double canEncQty                 = 0;                                                    // 画面表示時引当可能数
// 2008-12-10 H.Itou Add Start
    BigDecimal canEncQtyBigD         = new BigDecimal(0);                                    // 画面表示時引当可能数
// 2008-12-10 H.Itou Add End
    Number lotId                     = null;                                                 // ロットID
    double actualQuantity            = 0;                                                    // 引当数量(換算後)
    double actualQuantityBk          = 0;                                                    // 画面表示時引当数量(換算後)
// 2008-12-10 H.Itou Add Start
    BigDecimal actualQuantityBigD    = new BigDecimal(0);                                    // 引当数量(換算後)
    BigDecimal actualQuantityBkBigD  = new BigDecimal(0);                                    // 画面表示時引当数量(換算後)
// 2008-12-10 H.Itou Add End
    String showLotNo                 = null;                                                 // 表示用ロットNo
    String productionDate            = null;                                                 // 製造年月日

    // 警告情報格納用
    String[]  lotRevErrFlgRow   = new String[vo.getRowCount()]; // ロット逆転防止チェックエラーフラグ
    String[]  freshErrFlgRow    = new String[vo.getRowCount()]; // 鮮度条件チェックエラーフラグ
    String[]  shortageErrFlgRow = new String[vo.getRowCount()]; // 引当可能在庫数不足チェックエラーフラグ   
    String[]  exceedErrFlgRow   = new String[vo.getRowCount()]; // 引当可能在庫数超過チェックエラーフラグ   
    String[]  lotNoRow          = new String[vo.getRowCount()]; // ロットNo
    Date[]    revDateRow        = new Date[vo.getRowCount()];   // 逆転日付
    Date[]    standardDateRow   = new Date[vo.getRowCount()];   // 基準日
    String[]  shipTypeRow       = new String[vo.getRowCount()]; // ShipType
    String[]  itemShortNameRow  = new String[vo.getRowCount()]; // 品目略称
    String[]  deliverToRow      = new String[vo.getRowCount()]; // 出庫先
    String[]  locationNameRow   = new String[vo.getRowCount()]; // 出庫元保管場所
// 2008-10-22 D.Nihei Add Start 統合テスト指摘194対応
    String[]  deliverToNameRow  = new String[vo.getRowCount()]; // 入庫先保管場所
// 2008-10-22 D.Nihei Add End

    // チェックで複数回使用する変数を宣言
    HashMap data              = null;                         // 戻り値格納用
    Number result             = null;                         // 処理結果
    Date   revDate            = null;                         // 逆転日付
    Date   standardDate       = null;                         // 基準日
    Number shipToCanEncQty    = null;                         // 入庫先引当可能数
// 2009-01-26 H.Itou Add Start 本番障害＃936対応
    String getFreshRetCode    = null;                         // 鮮度条件合格製造日リターンコード

    // 以下のすべてを満たす場合、鮮度チェックを行うため、鮮度条件合格製造日を取得する。
    // ・呼出画面区分が出荷
    // ・ロット管理品
    // ・品目区分が製品の場合または、商品区分がリーフで品目区分が半製品の場合
    if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn)
      && XxwshConstants.LOT_CTL_Y.equals(lotCtl.toString())
      && (XxwshConstants.ITEM_TYPE_PROD.equals(itemClass)
        || XxwshConstants.PROD_CLASS_CODE_LEAF.equals(prodClass)
          && XxwshConstants.ITEM_TYPE_HALF.equals(itemClass)))
    {
      // 鮮度条件合格製造日
      HashMap retHash = XxwshUtility.getFreshPassDate(
                          getOADBTransaction(),
                          deliverToId,
                          itemCode,
                          scheduleArrivalDate,
                          scheduleShipDate);
      getFreshRetCode = (String)retHash.get("retCode");       // 鮮度条件合格製造日リターンコード
      standardDate    = (Date)retHash.get("manufactureDate"); // 鮮度条件合格製造日
    }
// 2009-01-26 H.Itou Add End

    // 手持在庫数・引当可能数一覧リージョンの一行目をセット
    vo.first();
    // 全件ループ
    while (vo.getCurrentRow() != null )
    {
      // 処理対象行を取得
      row = (OARow)vo.getCurrentRow();

      // 手持在庫数・引当可能数一覧リージョンの現在のデータを取得
      canEncQty            = ((Number)row.getAttribute("CanEncQty")).doubleValue();                       // 画面表示時引当可能数
// 2008-12-10 H.Itou Mod Start
      canEncQtyBigD        = XxcmnUtility.bigDecimalValue((Number)row.getAttribute("CanEncQty"));         // 画面表示時引当可能数
// 2008-12-10 H.Itou Mod End
      lotId                = (Number)row.getAttribute("LotId");                                           // ロットID
// 2008-12-10 H.Itou Mod Start
      actualQuantity       = ((Number)row.getAttribute("ActualQuantity")).doubleValue();                  // 引当数量
      actualQuantityBk     = ((Number)row.getAttribute("ActualQuantityBk")).doubleValue();                // 画面表示時引当数量
      actualQuantityBigD   = XxcmnUtility.bigDecimalValue((Number)row.getAttribute("ActualQuantity"));    // 引当数量
      actualQuantityBkBigD = XxcmnUtility.bigDecimalValue((Number)row.getAttribute("ActualQuantityBk"));  // 画面表示時引当数量
// 2008-12-10 H.Itou Mod End
      showLotNo            = (String)row.getAttribute("ShowLotNo");                                       // 表示用ロットNo
      productionDate       = (String)row.getAttribute("ProductionDate");                                  // 製造年月日

      // 警告情報格納用配列に初期値をセット
      lotRevErrFlgRow[vo.getCurrentRowIndex()]   = XxcmnConstants.STRING_N; // ロット逆転防止チェックエラーフラグ
      freshErrFlgRow[vo.getCurrentRowIndex()]    = XxcmnConstants.STRING_N; // 鮮度条件チェックエラーフラグ
      shortageErrFlgRow[vo.getCurrentRowIndex()] = XxcmnConstants.STRING_N; // 引当可能在庫数減数チェックエラーフラグ   
      exceedErrFlgRow[vo.getCurrentRowIndex()]   = XxcmnConstants.STRING_N; // 引当可能在庫数超過チェックエラーフラグ   
      lotNoRow[vo.getCurrentRowIndex()]          = showLotNo;               // ロットNo
      revDateRow[vo.getCurrentRowIndex()]        = null;                    // 逆転日付
      standardDateRow[vo.getCurrentRowIndex()]   = null;                    // 基準日
      shipTypeRow[vo.getCurrentRowIndex()]       = null;
      deliverToRow[vo.getCurrentRowIndex()]      = deliverTo;               // 出庫先
      itemShortNameRow[vo.getCurrentRowIndex()]  = itemShortName;           // 品目名
      locationNameRow[vo.getCurrentRowIndex()]   = locationName;            // 出庫元
// 2008-10-22 D.Nihei Add Start 統合テスト指摘194対応
      deliverToNameRow[vo.getCurrentRowIndex()]  = deliverToName;           // 入庫先
// 2008-10-22 D.Nihei Add End
      // 引当数量が変更されている場合もしくは0より大きい場合にチェックを行う
      if ((actualQuantityBk != actualQuantity) || (actualQuantity > 0))
      {

        // ロット管理品で引当数量が0より大きく製造年月日が設定されている場合のみロット逆転防止チェック、鮮度条件チェックを行う
        if ((XxwshConstants.LOT_CTL_Y.equals(lotCtl.toString()))
         && (actualQuantity > 0)
         && (!XxcmnUtility.isBlankOrNull(productionDate)))
        {
          // 呼出画面区分が出荷で品目区分が製品の場合もしくは商品区分がリーフで品目区分が半製品の場合
          if ((XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn))
           && (   (XxwshConstants.ITEM_TYPE_PROD.equals(itemClass))
               || (   XxwshConstants.PROD_CLASS_CODE_LEAF.equals(prodClass)
                   && XxwshConstants.ITEM_TYPE_HALF.equals(itemClass))))
          {
            // ロット逆転防止チェックを実行
            data = XxwshUtility.doCheckLotReversalMov(
                     getOADBTransaction(),
                     XxwshConstants.LOT_BIZ_CLASS_SHIP_INS,
                     itemCode,
                     showLotNo,
                     deliverToId,
                     scheduleArrivalDate,
// 2009-01-22 H.Itou Mod Start 本番#1000対応
//                     scheduleShipDate);
                     scheduleShipDate,
                     requestNo
                     );
// 2009-01-22 H.Itou Mod End

            result  = (Number)data.get("result");  // 処理結果
            revDate = (Date)data.get("revDate");   // 逆転日付

            // API実行結果が1:エラーの場合
            if (!XxwshConstants.RETURN_SUCCESS.equals(result))
            {
              // ロット逆転防止エラーフラグをYに設定
              lotRevErrFlgRow[vo.getCurrentRowIndex()]     = XxcmnConstants.STRING_Y;
              revDateRow[vo.getCurrentRowIndex()]          = revDate; // 逆転日付
              // 警告メッセージで使用するShipTypeを設定(出荷)
              shipTypeRow[vo.getCurrentRowIndex()]         = XxwshConstants.TOKEN_NAME_DELIVER_TO;

              // 警告日付がNULLの場合
              if (XxcmnUtility.isBlankOrNull(warningDate))
              {
                // 警告日付と警告区分に値をセットします。
                warningClass = XxwshConstants.WARNING_CLASS_LOT;   // 警告区分
                warningDate  = revDate;                            // 警告日付
                  
              // 警告日付が逆転日付より小さい日付の場合
              } else if (XxcmnUtility.chkCompareDate(1, revDate, warningDate))
              {
                // 警告日付と警告区分に値をセットします。
                warningClass = XxwshConstants.WARNING_CLASS_LOT;   // 警告区分
                warningDate  = revDate;                            // 警告日付
              }
            }
// 2009-01-26 H.Itou Mod Start 本番障害＃936対応
//            // 鮮度条件チェックを実行
//            data = XxwshUtility.doCheckFreshCondition(
//                     getOADBTransaction(),
//                     deliverToId,
//                     lotId,
//                     scheduleArrivalDate,
//                     scheduleShipDate);
//
//            result       = (Number)data.get("result");     // 処理結果
//            standardDate = (Date)data.get("standardDate"); // 基準日
//
//            // API実行結果が1:エラーの場合
//            if (!XxwshConstants.RETURN_SUCCESS.equals(result))
            // 以下の場合、鮮度条件警告
            // ・鮮度条件合格製造日リターンコードが0(リターンコード1は賞味期間が0の場合なので、鮮度条件チェックを行わない。)
            // ・製造日が鮮度条件合格製造日より古い
            if (XxcmnConstants.API_RETURN_NORMAL.equals(getFreshRetCode)
             && XxcmnUtility.chkCompareDate(1, standardDate, new Date(productionDate.replaceAll("/", "-"))))
// 2009-01-26 H.Itou Mod End
            {
              // 鮮度条件チェックエラーフラグをYに設定
              freshErrFlgRow[vo.getCurrentRowIndex()]      = XxcmnConstants.STRING_Y;
              standardDateRow[vo.getCurrentRowIndex()]     = standardDate; // 基準日

              // 警告日付がNULLの場合
              if (XxcmnUtility.isBlankOrNull(warningDate))
              {
                // 警告日付と警告区分に値をセットします。
                warningClass = XxwshConstants.WARNING_CLASS_FRESH;   // 警告区分
                warningDate  = standardDate;                         // 警告日付
                  
              // 警告日付が鮮度条件合格製造日より小さい日付の場合
              } else if (XxcmnUtility.chkCompareDate(1, standardDate, warningDate))
              {
                // 警告日付と警告区分に値をセットします。
                warningClass = XxwshConstants.WARNING_CLASS_FRESH;   // 警告区分
                warningDate  = standardDate;                         // 警告日付
              }
            }            
          // 呼出画面区分が移動で商品区分がドリンクで品目区分が製品の場合
          } else if (   XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn)
                     && XxwshConstants.PROD_CLASS_CODE_DRINK.equals(prodClass)
                     && XxwshConstants.ITEM_TYPE_PROD.equals(itemClass))
          {
            // ロット逆転防止チェックを実行
            data = XxwshUtility.doCheckLotReversalMov(
                     getOADBTransaction(),
                     XxwshConstants.LOT_BIZ_CLASS_MOVE_INS,
                     itemCode,
                     showLotNo,
                     deliverToId,
                     scheduleArrivalDate,
// 2009-01-22 H.Itou Mod Start 本番#1000対応
//                     scheduleShipDate);
                     scheduleShipDate,
                     requestNo
                     );
// 2009-01-22 H.Itou Mod End

            result  = (Number)data.get("result");  // 処理結果
            revDate = (Date)data.get("revDate");   // 逆転日付

            // API実行結果が1:エラーの場合
            if (!XxwshConstants.RETURN_SUCCESS.equals(result))
            {
              // ロット逆転防止エラーフラグをYに設定
              lotRevErrFlgRow[vo.getCurrentRowIndex()]     = XxcmnConstants.STRING_Y;
              revDateRow[vo.getCurrentRowIndex()]          = revDate; // 逆転日付
              // 警告メッセージで使用するShipTypeを設定(移動)
              shipTypeRow[vo.getCurrentRowIndex()]         = XxwshConstants.TOKEN_NAME_SHIP_TO;

              // 警告日付がNULLの場合
              if (XxcmnUtility.isBlankOrNull(warningDate))
              {
                // 警告日付と警告区分に値をセットします。
                warningClass = XxwshConstants.WARNING_CLASS_LOT;   // 警告区分
                warningDate  = revDate;                            // 警告日付
                  
              // 警告日付が逆転日付より小さい日付の場合
              } else if (XxcmnUtility.chkCompareDate(1, revDate, warningDate))
              {
                // 警告日付と警告区分に値をセットします。
                warningClass = XxwshConstants.WARNING_CLASS_LOT;   // 警告区分
                warningDate  = revDate;                            // 警告日付
              }
            }
          } // 呼出画面区分、商品区分、品目区分によりロット逆転防止チェック、鮮度条件チェック判断
        } // ロット管理品で製造年月日が設定されている場合のみロット逆転防止チェック、鮮度条件チェックを行う
        
        // *********************** // 
        // * 引当可能数減数チェック  *//
        // *********************** //

        // 呼出画面区分が移動の場合
        if (XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
        {
          // 入庫先引当可能数を取得
          shipToCanEncQty = XxwshUtility.getCanEncQty(
                              getOADBTransaction(),
                              deliverToId,              // 入庫先ID
                              itemId,                   // 品目ID
                              lotId,                    // ロットID
                              lotCtl.toString(),        // ロット管理
                              scheduleArrivalDate);     // 着荷予定日
// 2008-12-10 H.Itou Add Start
          BigDecimal temp = XxcmnUtility.bigDecimalValue(shipToCanEncQty);
          // 入庫先引当可能数 - (画面表示時引当数 - 引当数)
// 2008-12-11 H.Itou Add Start
//          temp = temp.subtract(actualQuantityBkBigD).subtract(actualQuantityBigD);
          temp = temp.subtract(actualQuantityBkBigD).add(actualQuantityBigD);
// 2008-12-11 H.Itou Add End
// 2008-12-10 H.Itou Add End
          // 入庫先引当可能数 - (画面表示時引当数 - 引当数) < 0 の場合
// 2008-12-10 H.Itou Mod Start
//          if ((shipToCanEncQty.doubleValue() - (actualQuantityBk - actualQuantity)) < 0)
          if (temp.compareTo(new BigDecimal(0)) == -1)
// 2008-12-10 H.Itou Mod End
          {
            // 引当可能数減数チェックエラーフラグをYに設定
            shortageErrFlgRow[vo.getCurrentRowIndex()]  = XxcmnConstants.STRING_Y;
          }
        } // 減数チェック
        // *********************** // 
        // * 引当可能数超過チェック  *//
        // *********************** //
        // 引当可能数 + 画面表示時引当数 < 引当数の場合
// 2008-12-10 H.Itou Add Start
          // 引当可能数 + 画面表示時引当数
          BigDecimal temp2 = canEncQtyBigD.add(actualQuantityBkBigD);
// 2008-12-10 H.Itou Add End
// 2008-12-10 H.Itou Mod Start
//        if ((canEncQty + actualQuantityBk) < actualQuantity)
        if (temp2.compareTo(actualQuantityBigD) == -1)
// 2008-12-10 H.Itou Mod End
        {
          // 引当可能数超過チェックエラーフラグをYに設定
          exceedErrFlgRow[vo.getCurrentRowIndex()]  = XxcmnConstants.STRING_Y;
        }
      } // 引当数量が変更されている場合もしくは0より大きい場合にチェックを行う
      // 次のレコードへ
      vo.next();
    } // 全件ループ

    // 警告区分、警告日付をセット
    hrow.setAttribute("WarningClass",warningClass);
    hrow.setAttribute("WarningDate",warningDate);
    
    // 戻り値をセット
    msg.put("lotRevErrFlg",     (String[])lotRevErrFlgRow);   // ロット逆転防止チェックエラーフラグ
    msg.put("freshErrFlg",      (String[])freshErrFlgRow);    // 鮮度条件チェックエラーフラグ
    msg.put("shortageErrFlg",   (String[])shortageErrFlgRow); // 引当可能在庫数減数チェックエラーフラグ
    msg.put("exceedErrFlg",     (String[])exceedErrFlgRow);   // 引当可能在庫数超過チェックエラーフラグ
    msg.put("lotNo",            (String[])lotNoRow);          // ロットNo
    msg.put("revDate",          (Date[])revDateRow);          // 逆転日付
    msg.put("standardDate",     (Date[])standardDateRow);     // 基準日
    msg.put("shipType",         (String[])shipTypeRow);       // ShipType
    msg.put("deliverTo",        (String[])deliverToRow);      // 出庫先
    msg.put("itemShortName",    (String[])itemShortNameRow);  // 品目名
    msg.put("locationName",     (String[])locationNameRow);   // 出庫元
// 2008-10-22 D.Nihei Add Start 統合テスト指摘194対応
    msg.put("deliverToName",    (String[])deliverToNameRow);   // 入庫先
// 2008-10-22 D.Nihei Add End

    return msg;
  }

  /***************************************************************************
   * ダイアログでNoボタン押下時に処理を行うメソッドです。
   * 
   ***************************************************************************
  */
  public void noBtn()
  {
    // ロック解除のためロールバックを行います。
    XxcmnUtility.rollBack(getOADBTransaction());
  }

  /***************************************************************************
   * ダイアログでYesボタン押下時に処理を行うメソッドです。
   * 
   ***************************************************************************
  */
  public void yesBtn()
  {
    // 検索条件表示リージョン取得
    OAViewObject hvo                 = getXxwshSearchVO1();
    // 検索条件表示リージョン一行目を取得
    OARow hrow                       = (OARow)hvo.first();

    // 検索条件表示リージョンの項目を取得
    String callPictureKbn            = (String)hrow.getAttribute("CallPictureKbn");           // 呼出画面区分
    String requestNo                 = (String)hrow.getAttribute("RequestNo");                // 依頼No
    String instructQtyUpdFlag        = (String)hrow.getAttribute("InstructQtyUpdFlag");       // 指示数量更新フラグ
    Number itemId                    = (Number)hrow.getAttribute("ItemId");                   // 品目ID
    Number sumReservedQuantityItem   = (Number)hrow.getAttribute("SumReservedQuantityItem");  // 引当数量合計
    String warningClass              = (String)hrow.getAttribute("WarningClass");             // 警告区分
    Date   warningDate               = (Date)hrow.getAttribute("WarningDate");                // 警告日付
    String weight                    = (String)hrow.getAttribute("Weight");                   // 重量
    String capacity                  = (String)hrow.getAttribute("Capacity");                 // 容積
    String sumQuantity               = (String)hrow.getAttribute("SumQuantity");              // 合計数量
    String sumWeight                 = (String)hrow.getAttribute("SumWeight");                // 積載重量合計
    String sumCapacity               = (String)hrow.getAttribute("SumCapacity");              // 積載容積合計
    String loadingEfficiencyWeight   = (String)hrow.getAttribute("LoadingEfficiencyWeight");  // 積載率(重量)
    String loadingEfficiencyCapacity = (String)hrow.getAttribute("LoadingEfficiencyCapacity");// 積載率(容積)
    String smallQuantity             = (String)hrow.getAttribute("SmallQuantity");            // 小口個数
    String labelQuantity             = (String)hrow.getAttribute("LabelQuantity");            // ラベル枚数
    String exeKbn                    = (String)hrow.getAttribute("ExeKbn");                   // 起動区分
    String packageLiftFlag           = (String)hrow.getAttribute("PackageLiftFlag");          // 一括解除ボタン押下フラグ

    // 明細情報リージョンを取得
    OAViewObject lvo                 = getXxwshLineVO();
    // 明細情報リージョンの一行目を取得
    OARow lrow                       = (OARow)lvo.first();

    // 明細情報リージョンの項目を取得
    Number lineId                    = (Number)lrow.getAttribute("LineId");                   // 明細ID
    Number headerId                  = (Number)lrow.getAttribute("HeaderId");                 // ヘッダID
    String documentTypeCode          = (String)lrow.getAttribute("DocumentTypeCode");         // 文書タイプ
    String itemCode                  = (String)lrow.getAttribute("ItemCode");                 // 品目コード

   // 手持在庫数・引当可能数一覧リージョン取得
    OAViewObject vo                  = getXxwshStockCanEncQtyVO1();
    // 手持在庫数・引当可能数一覧リージョンのデータ格納用変数
    OARow row                        = null;

    // 手持在庫数・引当可能数一覧リージョンの項目取得用変数を定義
    Number movLotDtlId               = null;                                                // 移動ロット詳細ID
    Number actualQuantity            = null;                                                // 引当数量
    Number lotId                     = null;                                                // ロットID
    String showLotNo                 = null;                                                // ロットNo(表示用)

    // 処理で使用する変数を定義
    String automanualReserveClass    = null;                                                // 自動手動引当区分
    String reservedQuantity          = null;                                                // 引当数量
    HashMap data                     = new HashMap();                                       // 処理用配列
    HashMap lparam                   = new HashMap();                                       // 明細配列
    HashMap hparam                   = new HashMap();                                       // ヘッダ配列
// 2008-10-24 D.Nihei Add Start TE080_BPO_600 No22
    boolean updNotifStatusFlag      = false;                                                // 通知ステータス更新フラグ
// 2008-10-24 D.Nihei Add End
// 2009-02-17 D.Nihei Add Start 本番障害#1034対応
    //テーブルのロック・排他制御を行います。
    getLockAndChkExclusive();
// 2009-02-17 D.Nihei Add End
    // ********************************** // 
    // * 移動ロット詳細登録・更新・削除処理   *//
    // ********************************** //
        
    // 手持在庫数・引当可能数一覧リージョンの一行目をセット
    vo.first();
    // 全件ループ
    while ( vo.getCurrentRow() != null )
    {
      // 処理対象行を取得
      row = (OARow)vo.getCurrentRow();

      // 処理対象行で使用するデータを取得
      movLotDtlId       = (Number)row.getAttribute("MovLotDtlId");      // 移動ロット詳細ID
      actualQuantity    = (Number)row.getAttribute("ActualQuantity");   // 引当数量
      lotId             = (Number)row.getAttribute("LotId");            // ロットID
      showLotNo         = (String)row.getAttribute("ShowLotNo");        // ロットNo

      // パラメータをセット
      data.put("orderLineId",            lineId);                              // 明細ID
      data.put("documentTypeCode",       documentTypeCode);                    // 文書タイプ
      data.put("recordTypeCode",         XxwshConstants.RECORD_TYPE_INST);     // レコードタイプ
      data.put("itemId",                 itemId);                              // 品目ID
      data.put("itemCode",               itemCode);                            // 品目コード
      data.put("lotId",                  lotId);                               // ロットID
      data.put("lotNo",                  showLotNo);                           // ロットNo
      data.put("actualQuantity",         actualQuantity.toString());           // 実績数量
      data.put("actualDate",             null);                                // 実績日
      data.put("automanualReserveClass", XxwshConstants.AM_RESERVE_CLASS_MAN); // 自動手動引当区分
      data.put("movLotDtlId",            movLotDtlId);                         // 移動ロット詳細ID
    
      // 引当数量が0で移動ロット詳細IDが設定されている場合
      if ((actualQuantity.doubleValue() == 0)
        && !XxcmnUtility.isBlankOrNull(movLotDtlId))
      {
        // 移動ロット詳細削除処理を実行
        XxwshUtility.deleteActualQuantity(
          getOADBTransaction(),
          movLotDtlId);

      // 引当数量が0以外で移動ロット詳細IDが設定されていない場合
      } else if (   (actualQuantity.doubleValue() != 0)
                 && (XxcmnUtility.isBlankOrNull(movLotDtlId)))
      {
        // 移動ロット詳細登録処理を実行
        XxwshUtility.insXxinvMovLotDetails(
          getOADBTransaction(),
          data);
      // 引当数量が0以外で移動ロット詳細IDが設定されている場合
      } else if (   (actualQuantity.doubleValue() != 0)
                 && (!XxcmnUtility.isBlankOrNull(movLotDtlId)))
      {
        // 移動ロット詳細更新処理を実行
        XxwshUtility.updActualQuantity(
          getOADBTransaction(),
          data);
      }
// 2008-10-24 D.Nihei Add Start TE080_BPO_600 No22
      // DB引当数量と引当数量を比較し変更がある場合
      Number actualQtyBk = (Number)row.getAttribute("ActualQuantityBk");
      Number actualQty   = (Number)row.getAttribute("ActualQuantity");
      if (!XxcmnUtility.isEquals(actualQtyBk, actualQty)) 
      {
        // 通知ステータス更新フラグをONにする
        updNotifStatusFlag = true;
      }
// 2008-10-24 D.Nihei Add End
      
      // 次のレコードへ
      vo.next();
    } // 全件ループ

    // 引当数量が0の場合
    if (sumReservedQuantityItem.doubleValue() == 0)
    {
      reservedQuantity       = null;
      automanualReserveClass = null;
    // 引当数量が0以外の場合
    } else
    {
      reservedQuantity       = sumReservedQuantityItem.toString();
      automanualReserveClass = XxwshConstants.AM_RESERVE_CLASS_MAN;
    }

    // ********************************** // 
    // * 明細・ヘッダ更新処理              *//
    // ********************************** //

    // 呼出画面区分が移動の場合
    if (XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
    {
      // 指示数量更新フラグが更新対象(1)の場合
      if (XxwshConstants.INSTRUCT_QTY_UPD_FLAG_INCLUDE.equals(instructQtyUpdFlag))
      {
        // 明細更新用パラメータをセット
        lparam.put("movLineId",              lineId);                             // 明細ID
        lparam.put("reservedQuantity",       reservedQuantity);                   // 引当数量
        lparam.put("warningClass",           warningClass);                       // 警告区分
        lparam.put("warningDate",            warningDate);                        // 警告日付
        lparam.put("automanualReserveClass", automanualReserveClass);             // 自動手動引当区分
        lparam.put("instructQty",            sumReservedQuantityItem.toString()); // 指示数量
        lparam.put("weight",                 weight);                             // 重量
        lparam.put("capacity",               capacity);                           // 容積

        // 移動依頼/指示明細指示数量更新処理
        XxwshUtility.updMoveLineInstructQty(
          getOADBTransaction(),
          lparam);

        // ヘッダ更新用パラメータをセット
        hparam.put("movHdrId",                 headerId);                  // ヘッダID
        hparam.put("sumQuantity",              sumQuantity);               // 合計数量
        hparam.put("smallQuantity",            smallQuantity);             // 小口個数
        hparam.put("labelQuantity",            labelQuantity);             // ラベル枚数
        hparam.put("loadingEfficiencyWeight",  loadingEfficiencyWeight);   // 重量積載効率
        hparam.put("loadingEfficiencyCapacity",loadingEfficiencyCapacity); // 容積積載効率
        hparam.put("sumWeight",                sumWeight);                 // 合計重量
        hparam.put("sumCapacity",              sumCapacity);               // 合計容積

        // 移動依頼/指示ヘッダ配車項目更新処理
        XxwshUtility.updMoveHeaderDelivery(
          getOADBTransaction(),
          hparam);

      // 指示数量更新フラグが更新対象(1)以外の場合
      } else
      {
        // 明細更新用パラメータをセット
        lparam.put("movLineId",              lineId);                             // 明細ID
        lparam.put("reservedQuantity",       reservedQuantity);                   // 引当数量
        lparam.put("warningClass",           warningClass);                       // 警告区分
        lparam.put("warningDate",            warningDate);                        // 警告日付
        lparam.put("automanualReserveClass", automanualReserveClass);             // 自動手動引当区分

        // 移動依頼/指示明細引当数量更新処理
        XxwshUtility.updMoveLineReservedQty(
          getOADBTransaction(),
          lparam);

        // 移動依頼/指示ヘッダ画面更新情報更新処理
        XxwshUtility.updMoveHeaderScreen(
          getOADBTransaction(),
          headerId);
      }
    // 呼出画面区分が移動以外の場合
    } else
    {
      // 指示数量更新フラグが更新対象(1)の場合
      if (XxwshConstants.INSTRUCT_QTY_UPD_FLAG_INCLUDE.equals(instructQtyUpdFlag))
      {
        // 明細更新用パラメータをセット
        lparam.put("orderLineId",            lineId);                             // 明細ID
        lparam.put("reservedQuantity",       reservedQuantity);                   // 引当数量
        lparam.put("warningClass",           warningClass);                       // 警告区分
        lparam.put("warningDate",            warningDate);                        // 警告日付
        lparam.put("automanualReserveClass", automanualReserveClass);             // 自動手動引当区分
        lparam.put("instructQty",            sumReservedQuantityItem.toString()); // 指示数量
        lparam.put("weight",                 weight);                             // 重量
        lparam.put("capacity",               capacity);                           // 容積

        // 受注明細指示数量更新処理
        XxwshUtility.updOrderLineInstructQty(
          getOADBTransaction(),
          lparam);

        // ヘッダ更新用パラメータをセット
        hparam.put("orderHeaderId",             headerId);                  // ヘッダID
        hparam.put("sumQuantity",               sumQuantity);               // 合計数量
        hparam.put("smallQuantity",             smallQuantity);             // 小口個数
        hparam.put("labelQuantity",             labelQuantity);             // ラベル枚数
        hparam.put("loadingEfficiencyWeight",   loadingEfficiencyWeight);   // 重量積載効率
        hparam.put("loadingEfficiencyCapacity", loadingEfficiencyCapacity); // 容積積載効率
        hparam.put("sumWeight",                 sumWeight);                 // 合計重量
        hparam.put("sumCapacity",               sumCapacity);               // 合計容積

        // 受注ヘッダ配車項目更新処理
        XxwshUtility.updOrderHeaderDelivery(
          getOADBTransaction(),
          hparam);

      // 指示数量更新フラグが更新対象(1)以外の場合
      } else
      {
        // 明細更新用パラメータをセット
        lparam.put("orderLineId",            lineId);                             // 明細ID
        lparam.put("reservedQuantity",       reservedQuantity);                   // 引当数量
        lparam.put("warningClass",           warningClass);                       // 警告区分
        lparam.put("warningDate",            warningDate);                        // 警告日付
        lparam.put("automanualReserveClass", automanualReserveClass);             // 自動手動引当区分

        // 受注明細引当数量更新処理
        XxwshUtility.updOrderLineReservedQty(
          getOADBTransaction(),
          lparam);

        // 受注ヘッダ画面更新情報更新処理
        XxwshUtility.updOrderHeaderScreen(
          getOADBTransaction(),
          headerId);
      }
    }
// 2008-10-24 D.Nihei Mod Start TE080_BPO_600 No22
//    // 指示数量更新フラグが更新対象(1)の場合もしくは一括解除ボタン押下フラグが'1'で
//    // 引当数量が0の場合
//    if (XxwshConstants.INSTRUCT_QTY_UPD_FLAG_INCLUDE.equals(instructQtyUpdFlag)
//      || (XxwshConstants.PACKAGE_LIFT_FLAG_INCLUDE.equals(packageLiftFlag)
//        && sumReservedQuantityItem.doubleValue() == 0 ))
    // 指示数量更新フラグが更新対象(1)の場合
    if (XxwshConstants.INSTRUCT_QTY_UPD_FLAG_INCLUDE.equals(instructQtyUpdFlag))
// 2008-10-24 D.Nihei Mod End
    {
// 2009-02-17 D.Nihei Mod Start 本番障害#863対応
//      // 配車解除関数を起動
//      XxwshUtility.doCancelCareersSchedule(
//        getOADBTransaction(),
//        callPictureKbn,
//        requestNo);
      /******************
       * 配車解除処理
       ******************/
      String retCode = XxwshUtility.careerCancelOrUpd(
                         getOADBTransaction(),
                         callPictureKbn,
                         requestNo);
      // パラメータチェックエラーの場合
      if (XxcmnConstants.API_PARAM_ERROR.equals(retCode)) 
      {
        // 予期せぬエラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123
                              );
            
      // 配車処理失敗の場合
      } else if (XxcmnConstants.API_CANCEL_CARRER_ERROR.equals(retCode)) 
      {
        XxcmnUtility.putErrorMessage(XxpoConstants.TOKEN_NAME_CAN_CAREERS);

      }
// 2009-02-17 D.Nihei Mod End
// 2008-10-24 D.Nihei Add Start TE080_BPO_600 No22
    // 通知ステータス更新フラグがONの場合
    } else if (updNotifStatusFlag) 
    {
      // 通知ステータス更新関数を起動
      XxwshUtility.updateNotifStatus(
        getOADBTransaction(),
        callPictureKbn,
        requestNo);
// 2008-10-24 D.Nihei Add End
    }
    // コミット処理
    XxwshUtility.commit(getOADBTransaction());
    // ******************** // 
    // *  最終更新日入替    * //
    // ******************** //
    String headerUpdateDate = null;
    String lineUpdateDate   = null;
    // 呼出画面区分が移動の場合
    if (XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
    {
      // 移動ヘッダ最終更新日取得
      headerUpdateDate = XxwshUtility.getMoveHeaderUpdateDate(
                           getOADBTransaction(),
                           headerId);
      // 移動明細最終更新日取得
      lineUpdateDate   = XxwshUtility.getMoveLineUpdateDate(
                           getOADBTransaction(),
                           headerId);
    // 呼出画面区分が移動以外の場合
    } else
    {
      // 受注ヘッダ最終更新日取得
      headerUpdateDate = XxwshUtility.getOrderHeaderUpdateDate(
                           getOADBTransaction(),
                           headerId);
      // 受注明細最終更新日取得
      lineUpdateDate   = XxwshUtility.getOrderLineUpdateDate(
                           getOADBTransaction(),
                           headerId);
    }
    // ******************** // 
    // *  最新の情報を再表示 * //
    // ******************** //
    HashMap params = new HashMap();
    params.put("LineId",           lineId.toString());
    params.put("callPictureKbn",   callPictureKbn);
    params.put("headerUpdateDate", headerUpdateDate);
    params.put("lineUpdateDate",   lineUpdateDate);
    params.put("exeKbn",           exeKbn);
    initialize(params);

    // 指示数量更新フラグが更新対象の場合
    if (XxwshConstants.INSTRUCT_QTY_UPD_FLAG_INCLUDE.equals(instructQtyUpdFlag))
    {
      throw new OAException(
        XxcmnConstants.APPL_XXWSH,
        XxwshConstants.XXWSH32903, 
        null, 
        OAException.INFORMATION, 
        null);

    // 指示数量更新フラグが更新対象以外の場合
    } else 
    {
      throw new OAException(
        XxcmnConstants.APPL_XXWSH,
        XxwshConstants.XXWSH32904, 
        null, 
        OAException.INFORMATION, 
        null);
    }
  }

  /***************************************************************************
   * 依頼Noを取得するメソッドです。
   * @throws OAException
   ***************************************************************************
   */
  public String getReqNo() throws OAException
  {
    // 明細情報リージョンを取得
    OAViewObject lvo                 = getXxwshLineVO();
    // 明細情報リージョンの一行目を取得
    OARow lrow                       = (OARow)lvo.first();
    // 明細情報リージョンの依頼Noを返す
    return (String)lrow.getAttribute("RequestNo");
  }

// 2008-12-25 D.Nihei Add Start
  /***************************************************************************
   * 明細行コピー処理を行うメソッドです。
   * @param orgVo  - コピー元VO
   * @param destVo - コピー先VO
   ***************************************************************************
   */
  public static void copyRows(OAViewObjectImpl orgVo, OAViewObjectImpl destVo)
  {
    // どちらかのVOがnullの場合は処理終了
    if (orgVo == null || destVo == null)
    {
      return;
    }

    // コピー元のVOの属性を取得
    AttributeDef[] attrDefs = orgVo.getAttributeDefs();
    int attrCount = (attrDefs == null) ? 0 : attrDefs.length;
    // 属性が取得できない場合は処理終了
    if (attrCount == 0)
    {
      return;
    }
    // コピー用イテレータを取得します。
    RowSetIterator copyIter = orgVo.findRowSetIterator("copyIter");
    // コピー用イテレータがnullの場合
    if (copyIter == null)
    {
      // イテレータを作成します。
      copyIter = orgVo.createRowSetIterator("copyIter");
    }

    boolean rowInserted = false; // 挿入フラグ
    int lineNum = 1;             // 組織番号
    
    // コピーループ
    while (copyIter.hasNext())
    {
      // 行を取得
      Row sourceRow = copyIter.next();

      // 行を一行でも挿入した場合
      if (rowInserted)
      {
        // コピー先行を次行へ移動します。
        destVo.next();
      }
      // コピー先行を作成
      Row destRow = destVo.createRow();

      // 属性を全てコピー
      for (int i = 0; i < attrCount; i++)
      {
        byte attrKind = attrDefs[i].getAttributeKind();

        if (!(attrKind == AttributeDef.ATTR_ASSOCIATED_ROW ||
              attrKind == AttributeDef.ATTR_ASSOCIATED_ROWITERATOR ||
              attrKind == AttributeDef.ATTR_DYNAMIC))

        {

          String attrName = attrDefs[i].getName();
          if (destVo.lookupAttributeDef(attrName) != null)
          {

            Object attrVal = sourceRow.getAttribute(attrName);

            if (attrVal != null)
            {

              destRow.setAttribute(attrName, attrVal);
            }
          }
        }
      }
      // コピー先を一行挿入します。
      destVo.insertRow(destRow);
      // 挿入フラグをtrue
      rowInserted = true;
    }
    // コピー用イテレータをクローズ
    copyIter.closeRowSetIterator();
    // コピー先VOをリセットします。
    destVo.reset();

  } // copyRows
// 2008-12-25 D.Nihei Add End
// 2009-12-04 H.Itou Add Start 本稼動障害#11
  /*****************************************************************************
   * 引当可能数、手持在庫数を画面表示用にフォーマットします。
   * @param demsupQty    - 引当可能数
   * @param stockQty     - 手持在庫数
   * @return HashMap     - 戻り値群(canEncQty 引当可能数＋手持在庫数,showCanEncQty 引当可能数＋手持在庫数(表示用), showStockQty 手持在庫数(表示用))
   * @throws OAException - OA例外
   ****************************************************************************/
  public HashMap getShowQty(
    Number demsupQty,
    Number stockQty
  ) throws OAException
  {
    String apiName = "getShowQty";  // API名
    HashMap ret = new HashMap();
    OADBTransaction trans = getOADBTransaction();

    // バインド変数
    int paramBind  = 1;
    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE                                                                         ");
    sb.append("  ln_demsup_qty        NUMBER;                                                  ");
    sb.append("  ln_stock_qty         NUMBER;                                                  ");
    sb.append("  lv_conv_unit_use_kbn VARCHAR2(1);                                             ");
    sb.append("  ln_num_of_cases      NUMBER;                                                  ");
    sb.append("  ln_can_enc_qty       NUMBER;                                                  ");
    sb.append("  lv_show_can_enc_qty  VARCHAR2(100);                                           ");
    sb.append("  lv_show_stock_qty    VARCHAR2(100);                                           ");
    sb.append("BEGIN                                                                           ");
                 // INパラメータ
    sb.append("  ln_demsup_qty        := :" + paramBind++ + ";                                 ");
    sb.append("  ln_stock_qty         := :" + paramBind++ + ";                                 ");
    sb.append("  lv_conv_unit_use_kbn := :" + paramBind++ + ";                                 ");
    sb.append("  ln_num_of_cases      := TO_NUMBER(:" + paramBind++ + ");                      ");
    sb.append("  SELECT NVL((ln_stock_qty + ln_demsup_qty),0)   can_enc_qty                    "); // 引当可能数＋手持在庫数
    sb.append("        ,TO_CHAR((CASE lv_conv_unit_use_kbn                                     ");
    sb.append("                WHEN '1' THEN (ln_stock_qty + ln_demsup_qty) / ln_num_of_cases  ");
    sb.append("                         ELSE (ln_stock_qty + ln_demsup_qty)                    ");
    sb.append("                END),'FM999,999,990.000') show_can_enc_qty                      "); // 引当可能数＋手持在庫数(表示用)
    sb.append("        ,TO_CHAR((CASE lv_conv_unit_use_kbn                                     ");
    sb.append("                WHEN '1' THEN ln_stock_qty / ln_num_of_cases                    ");
    sb.append("                         ELSE ln_stock_qty                                      ");
    sb.append("                END),'FM999,999,990.000') show_stock_qty                        "); // 手持在庫数(表示用)
    sb.append("  INTO   ln_can_enc_qty                                                         ");
    sb.append("        ,lv_show_can_enc_qty                                                    ");
    sb.append("        ,lv_show_stock_qty                                                      ");
    sb.append("  FROM   DUAL;                                                                  ");
                 // OUTパラメータ
    sb.append("  :" + paramBind++ + " := ln_can_enc_qty;                                       ");
    sb.append("  :" + paramBind++ + " := lv_show_can_enc_qty;                                  ");
    sb.append("  :" + paramBind++ + " := lv_show_stock_qty;                                    ");
    sb.append("END;                                                                            ");

    // PL/SQL設定
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    // 検索条件表示リージョンを取得
    OAViewObject hvo = getXxwshSearchVO1();
    // 検索条件表示リージョンの一行目を取得
    OARow hRow       = (OARow)hvo.first();
    String convUnitUseKbn = (String)hRow.getAttribute("ConvUnitUseKbn"); // 入出庫換算単位使用区分
    String numOfCases     = (String)hRow.getAttribute("NumOfCases");     // ケース入数

    try 
    {
      // INパラメータ設定
      paramBind  = 1;
      cstmt.setDouble(paramBind++, XxcmnUtility.doubleValue(demsupQty));  // IN:引当可能数
      cstmt.setDouble(paramBind++, XxcmnUtility.doubleValue(stockQty));   // IN:手持在庫数
      cstmt.setString(paramBind++, convUnitUseKbn);                       // IN:入出庫換算単位使用区分
      cstmt.setString(paramBind++, numOfCases);                           // IN:ケース入数

      // OUTパラメータ設定
      int outParamStart = paramBind; // OUTパラメータ開始を保持。
      cstmt.registerOutParameter(paramBind++, Types.DOUBLE);  // OUT:引当可能数＋手持在庫
      cstmt.registerOutParameter(paramBind++, Types.VARCHAR); // OUT:引当可能数＋手持在庫数(表示用)
      cstmt.registerOutParameter(paramBind++, Types.VARCHAR); // OUT:手持在庫数(表示用)

      // PL/SQL実行
      cstmt.execute();

      // OUTパラメータ取得
      paramBind  = outParamStart;
      Number canEncQty     = new Number(cstmt.getDouble(paramBind++)); // OUT:引当可能数＋手持在庫
      String showCanEncQty = cstmt.getString(paramBind++);             // OUT:引当可能数＋手持在庫数(表示用)
      String showStockQty  = cstmt.getString(paramBind++);             // OUT:手持在庫数(表示用)

      ret.put("canEncQty",     canEncQty);         // OUT:引当可能数＋手持在庫
      ret.put("showCanEncQty", showCanEncQty);     // OUT:引当可能数＋手持在庫数(表示用)
      ret.put("showStockQty",  showStockQty);      // OUT:手持在庫数(表示用)

      // 戻り値返却
      return ret;

    } catch(SQLException s)
    {
      // ロールバック
      XxwshUtility.rollBack(trans);

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
        XxwshUtility.rollBack(trans);

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
  } // getShowQty
// 2009-12-04 H.Itou Add End

  /**
   * 
   * Container's getter for XxwshPageLayoutPVO1
   */
  public XxwshPageLayoutPVOImpl getXxwshPageLayoutPVO1()
  {
    return (XxwshPageLayoutPVOImpl)findViewObject("XxwshPageLayoutPVO1");
  }

  /**
   * 
   * Container's getter for XxwshSearchVO1
   */
  public XxwshSearchVOImpl getXxwshSearchVO1()
  {
    return (XxwshSearchVOImpl)findViewObject("XxwshSearchVO1");
  }

  /**
   * 
   * Container's getter for XxwshStockCanEncQtyVO1
   */
  public XxwshStockCanEncQtyVOImpl getXxwshStockCanEncQtyVO1()
  {
    return (XxwshStockCanEncQtyVOImpl)findViewObject("XxwshStockCanEncQtyVO1");
  }

  /**
   * 
   * Container's getter for XxwshLineShipVO1
   */
  public XxwshLineShipVOImpl getXxwshLineShipVO1()
  {
    return (XxwshLineShipVOImpl)findViewObject("XxwshLineShipVO1");
  }

  /**
   * 
   * Container's getter for XxwshLineProdVO1
   */
  public XxwshLineProdVOImpl getXxwshLineProdVO1()
  {
    return (XxwshLineProdVOImpl)findViewObject("XxwshLineProdVO1");
  }

  /**
   * 
   * Container's getter for XxwshLineMoveVO1
   */
  public XxwshLineMoveVOImpl getXxwshLineMoveVO1()
  {
    return (XxwshLineMoveVOImpl)findViewObject("XxwshLineMoveVO1");
  }  

  /**
   * 
   * Container's getter for XxwshReserveUnLotVO1
   */
  public XxwshReserveUnLotVOImpl getXxwshReserveUnLotVO1()
  {
    return (XxwshReserveUnLotVOImpl)findViewObject("XxwshReserveUnLotVO1");
  }

  /**
   * 
   * Container's getter for XxwshReserveLotVO1
   */
  public XxwshReserveLotVOImpl getXxwshReserveLotVO1()
  {
    return (XxwshReserveLotVOImpl)findViewObject("XxwshReserveLotVO1");
  }

}