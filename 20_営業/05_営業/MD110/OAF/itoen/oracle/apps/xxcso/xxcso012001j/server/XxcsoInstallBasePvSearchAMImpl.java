/*============================================================================
* ファイル名 : XxcsoInstallBasePvSearchAMImpl
* 概要説明   : 物件情報汎用検索画面アプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-22 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

import java.util.List;
import java.util.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso012001j.util.XxcsoPvCommonConstants;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.domain.Number;
import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVORowImpl;


/*******************************************************************************
 * 物件情報汎用検索画面アプリケーション・モジュールクラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInstallBasePvSearchAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInstallBasePvSearchAMImpl()
  {
  }

  /*****************************************************************************
   * 出力メッセージ
   *****************************************************************************
   */
  private OAException mMessage = null;

  /*****************************************************************************
   * メッセージを取得します。
   * @return mMessage
   *****************************************************************************
   */
  public OAException getMessage()
  {
    return mMessage;
  }

  /*****************************************************************************
   * 初期表示処理
   *****************************************************************************
   */
  public void initDetails()
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // 汎用検索テーブル ビュー名取得用VO
    XxcsoInstallBasePvDesignVOImpl pvDesignVo = getInstallBasePvDesignVO();
    if ( pvDesignVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoInstallBasePvDesignVOImpl");
    }
    pvDesignVo.executeQuery();


    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * 初期表示(検索)
   * @param viewId ビューID
   *****************************************************************************
   */
  public void initQueryDetails(String viewId)
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // 汎用検索テーブル ビュー名取得用VO
    // 表示用にプルダウンの値を設定する
    XxcsoInstallBasePvDesignVOImpl pvDesignVo = getInstallBasePvDesignVO();
    if ( pvDesignVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoInstallBasePvDesignVOImpl");
    }
    pvDesignVo.executeQuery();

    XxcsoInstallBasePvDesignVORowImpl pvDesignVoRow
      = (XxcsoInstallBasePvDesignVORowImpl) pvDesignVo.first();
    if (pvDesignVoRow == null)
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoInstallBasePvDesignVORowImpl"
        );
    }
    
    pvDesignVoRow.setSelectView(new Number(Integer.parseInt(viewId)));

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * 進むボタン押下時処理
   * @return ポップリストで選択されたビューID
   * @throw OAException
   *****************************************************************************
   */
  public String handleForwardButton()
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // ビュー名選択チェック処理
    String viewId = this.chkViewName(true);

    XxcsoUtils.debug(txt, "[END]");

    return viewId;

  }

  /*****************************************************************************
   * パーソナライズボタン押下時処理
   * @return ポップリストで選択されたビューID
   * @throw OAException
   *****************************************************************************
   */
  public String handlePersonalizeButton()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // ビュー名選択チェック処理
    String viewId = this.chkViewName(false);

    XxcsoUtils.debug(txt, "[END]");

    return viewId;
  }

  /*****************************************************************************
   * 物件情報汎用検索 表示情報取得処理
   * @param viewId        ビューID
   * @param pvDisplayMode 汎用検索表示区分
   *****************************************************************************
   */
  public List getInstallBaseData(
    String viewId
   ,String pvDisplayMode
  )
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // プロファイル FND:ビュー・オブジェクト最大フェッチサイズの取得
    String maxFetchSize = txt.getProfile(XxcsoConstants.VO_MAX_FETCH_SIZE);
    if ( maxFetchSize == null || "".equals(maxFetchSize.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoConstants.VO_MAX_FETCH_SIZE
        );
    }

    // 抽出条件の取得
    String extractTerm = this.getExtractTerm(viewId, pvDisplayMode);
    // ソート設定条件の取得
    String sortColumn = this.getSortColumn(viewId, pvDisplayMode);
    // 表示列の取得
    List viewList = this.getViewColumnList(viewId, pvDisplayMode);

    // **********************************
    // 抽出条件、ソート条件を用いて物件汎用検索VOの実行
    // **********************************
    XxcsoInstallBasePvSumVOImpl instBaseVo = getInstallBasePvSumVO();
    if ( instBaseVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoInstallBasePvSumVOImpl");
    }
    // 初期化処理実行
    instBaseVo.initQuery(
      extractTerm
     ,sortColumn
    );
    int searchSize = instBaseVo.getRowCount();

    // プロファイルの最大フェッチサイズと検索結果の比較
    if ( searchSize > Integer.parseInt(maxFetchSize) )
    {
      // 超えている場合は警告メッセージを設定する
      mMessage
        = XxcsoMessage.createWarningMessage(
             XxcsoConstants.APP_XXCSO1_00479
            ,XxcsoConstants.TOKEN_MAX_SIZE
            ,maxFetchSize
          );
    }

    XxcsoUtils.debug(txt, "[END]");

    return viewList;

  }

  /*****************************************************************************
   * 表示行数取得処理
   * @param viewId        ビューID
   *****************************************************************************
   */
  public String getViewSize(String viewId)
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    XxcsoInstallBaseViewSizeVOImpl viewSizeVo = getInstallBaseViewSizeVO();
    if (viewSizeVo == null)
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoInstallBaseViewSizeVOImpl"
        );
    }
    viewSizeVo.initQuery(viewId);

    XxcsoInstallBaseViewSizeVORowImpl viewSizeVoRow
      = (XxcsoInstallBaseViewSizeVORowImpl) viewSizeVo.first();
    if (viewSizeVoRow == null)
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoInstallBaseViewSizeVORowImpl"
        );
    }
    XxcsoUtils.debug(txt, "[END]");

    return viewSizeVoRow.getViewSize();
  }

  /*****************************************************************************
   * ビュー名チェック処理
   * @param isChecked ビュー名選択チェック有無 true:有 false:無
   * @return viewId
   *****************************************************************************
   */
  private String chkViewName(boolean isChecked)
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    String retViewId = "";

    // 汎用検索テーブル ビュー名取得用VO
    XxcsoInstallBasePvDesignVOImpl pvDesignVo = getInstallBasePvDesignVO();
    if ( pvDesignVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoInstallBasePvDesignVOImpl");
    }

    XxcsoInstallBasePvDesignVORowImpl pvDesignVoRow
      = (XxcsoInstallBasePvDesignVORowImpl) pvDesignVo.first();
    if (pvDesignVoRow == null)
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoInstallBasePvDesignVORowImpl"
        );
    }

    // 選択されたビューIDを取得
      Number selectView = pvDesignVoRow.getSelectView();

    if ( isChecked )
    {
      if ( selectView == null )
      {
        // ビュー未選択エラー
        throw
          XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00133
           ,XxcsoConstants.TOKEN_ENTRY
           ,XxcsoPvCommonConstants.MSG_VIEW
          );
      }
      retViewId = selectView.toString();
    } else {
      if ( selectView == null )
      {
        retViewId = "";
      } else {
        retViewId = selectView.toString();
      }
    }

    return retViewId;

  }

  /*****************************************************************************
   * 抽出条件取得処理
   * @param viewId        ビューID
   * @param pvDisplayMode 汎用検索表示区分
   * @return ソート順SQL文を成形した文字列
   *****************************************************************************
   */
  private String getExtractTerm(
    String viewId
   ,String pvDisplayMode
  )
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    StringBuffer sbExt = new StringBuffer();

    // ビューIDがシードデータ以外の場合
    if ( !this.isSeedData(viewId) )
    {
      XxcsoInstallBaseExtractTermVOImpl extractTermVo
        = getInstallBaseExtractTermVO();
      if (extractTermVo == null) 
      {
        throw
          XxcsoMessage.createInstanceLostError(
            "XxcsoInstallBaseExtractTermVOImpl"
          );
      }
      extractTermVo.initQuery(viewId, pvDisplayMode);

      XxcsoInstallBaseExtractTermVORowImpl extractTermVoRow
        = (XxcsoInstallBaseExtractTermVORowImpl) extractTermVo.first();
      if (extractTermVoRow == null)
      {
        throw
          XxcsoMessage.createInstanceLostError(
            "XxcsoInstallBaseExtractTermVORowImpl"
          );
      }

      int rowCnt = 0;
      while (extractTermVoRow != null)
      {
        // 使用可能フラグ="1"か判別
        this.chkEnableFlag(extractTermVoRow.getEnableFlag());

        // テンプレートを取得し、値の語句を置換する
        String termDef    = extractTermVoRow.getExtractTermDef();
        String termType   = extractTermVoRow.getExtractTermType();
        String termMethod = extractTermVoRow.getExtractMethodCode();
        String termValue  = "";
        if(XxcsoPvCommonConstants.EXTRACT_TYPE_VARCHAR2.equals(termType))
        {
          termValue
            = this.getTextString(
                termMethod
               ,extractTermVoRow.getExtractTermText()
              );
        }
        else if (XxcsoPvCommonConstants.EXTRACT_TYPE_NUMBER.equals(termType))
        {
          termValue
            = extractTermVoRow.getExtractTermNumber().toString();
        }
        else if (XxcsoPvCommonConstants.EXTRACT_TYPE_DATE.equals(termType))
        {
          termValue
            = this.getDateString(
                extractTermVoRow.getExtractTermDate().dateValue().toString()
              );
        }

        termDef
          = termDef.replaceAll(XxcsoPvCommonConstants.REPLACE_WORD ,termValue);

        // 1項目目についてはAND/ORを先頭に付加しない
        if (rowCnt != 0)
        {
          sbExt.append( XxcsoPvCommonConstants.SPACE );
          sbExt.append( extractTermVoRow.getExtractPattern() );
          sbExt.append( XxcsoPvCommonConstants.SPACE );
        }
        sbExt.append( termDef );

        rowCnt++;
        extractTermVoRow
          = (XxcsoInstallBaseExtractTermVORowImpl) extractTermVo.next();
      }

    }
    // ビューIDがシードデータの場合
    else
    {
      XxcsoLookupListVOImpl seedExtractTermVo = getSeedExtractTermVO();
      if ( seedExtractTermVo == null )
      {
        throw
          XxcsoMessage.createInstanceLostError("XxcsoLookupListVOImpl");
      }
      seedExtractTermVo.initQuery(
        "XXCSO1_IB_PV_WHERE_000"
        ,null
        ,"1"
      );
      seedExtractTermVo.executeQuery();

      XxcsoLookupListVORowImpl seedExtractTermVoRow
        = (XxcsoLookupListVORowImpl) seedExtractTermVo.first();
      if ( seedExtractTermVoRow == null )
      {
        throw
          XxcsoMessage.createInstanceLostError("XxcsoLookupListVORowImpl");
      }

      // シードデータ用抽出条件テンプレートを取得
      String termDef = seedExtractTermVoRow.getDescription();

      // テンプレートの置換語句を自拠点コードに置換
      termDef
        = termDef.replaceAll(
            XxcsoPvCommonConstants.REPLACE_WORD
           ,this.getTextString(null, this.getSelfBaseCode())
          );
      sbExt.append(termDef);
    }

    XxcsoUtils.debug(txt, "[END]");

    return new String(sbExt);
  }

  /*****************************************************************************
   * ソート条件取得処理
   * @param viewId        ビューID
   * @param pvDisplayMode 汎用検索表示区分
   * @return ソート順SQL文を成形した文字列
   *****************************************************************************
   */
  private String getSortColumn(
    String viewId
   ,String pvDisplayMode
  )
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    XxcsoInstallBaseSortColumnVOImpl sortColumnVo
      = getInstallBaseSortColumnVO();
    if ( sortColumnVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoInstallBaseSortColumnVOImpl"
        );
    }
    sortColumnVo.initQuery(viewId, pvDisplayMode);

    XxcsoInstallBaseSortColumnVORowImpl sortColumnVoRow
      = (XxcsoInstallBaseSortColumnVORowImpl) sortColumnVo.first();
    if ( sortColumnVoRow == null )
    {
      // rowが存在しない場合はソート条件なしとみなし終了
      return "";
    }

    StringBuffer sbSort = new StringBuffer();
    while ( sortColumnVoRow != null )
    {
      // 使用可能フラグ="1"か判別
      this.chkEnableFlag(sortColumnVoRow.getEnableFlag());

      sbSort.append( sortColumnVoRow.getSortColumn() );
      sbSort.append( XxcsoPvCommonConstants.SPACE );
      sbSort.append( sortColumnVoRow.getSortDirection() );
      sbSort.append( XxcsoPvCommonConstants.COMMA );
      sortColumnVoRow
        = (XxcsoInstallBaseSortColumnVORowImpl) sortColumnVo.next();
    }
    // 文字列最後のカンマを除去
    sbSort.deleteCharAt(sbSort.length() - 1);

    XxcsoUtils.debug(txt, "[END]");

    return new String( sbSort );
  }


  /*****************************************************************************
   * 表示列取得処理
   * @param viewId        ビューID
   * @param pvDisplayMode 汎用検索表示区分
   * @return 表示列情報を格納したList->Map
   *****************************************************************************
   */
  private List getViewColumnList(
    String viewId
   ,String pvDisplayMode
  )
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    List list = new ArrayList();

    // ビューIDがシードデータ以外の場合
    if ( !this.isSeedData(viewId) )
    {
      XxcsoInstallBaseViewColumnVOImpl viewColumnVo
        = getInstallBaseViewColumnVO();
      if (viewColumnVo == null)
      {
        throw
          XxcsoMessage.createInstanceLostError(
            "XxcsoInstallBaseViewColumnVOImpl"
          );
      }
      viewColumnVo.initQuery(viewId, pvDisplayMode);

      XxcsoInstallBaseViewColumnVORowImpl viewColumnVoRow
        = (XxcsoInstallBaseViewColumnVORowImpl) viewColumnVo.first();

      // VoRowが存在しない=表示列未設定とみなし、エラーとする
      if (viewColumnVoRow == null)
      {
        // 表示列未設定エラー
        throw
          XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00494);
      }

      while ( viewColumnVoRow != null )
      {
        HashMap map
          = this.createViewColumnMap(
              viewColumnVoRow.getViewColumnId()
             ,viewColumnVoRow.getViewColumnName()
             ,viewColumnVoRow.getViewColumnId()
             ,viewColumnVoRow.getViewDataType()
            );

        list.add(map);

        viewColumnVoRow
          = (XxcsoInstallBaseViewColumnVORowImpl) viewColumnVo.next();
      }
    }
    // ビューIDがシードデータの場合
    else
    {
      XxcsoLookupListVOImpl seedViewColumnVo = getSeedViewColumnLookupVO();
      if ( seedViewColumnVo == null )
      {
        throw
          XxcsoMessage.createInstanceLostError("XxcsoLookupListVOImpl");
      }
      StringBuffer sbWhere = new StringBuffer(50);
      sbWhere
        .append("      SUBSTRB(attribute1, ").append(pvDisplayMode)
        .append(", 1) = '1'")
        .append("AND   SUBSTRB(attribute2, ").append(pvDisplayMode)
        .append(", 1) = '1'")
      ;
      seedViewColumnVo.initQuery(
        "XXCSO1_IB_PV_COLUMN_DEF"
        ,new String(sbWhere)
        ,"1"
      );
      seedViewColumnVo.executeQuery();

      XxcsoLookupListVORowImpl seedViewColumnVoRow
        = (XxcsoLookupListVORowImpl) seedViewColumnVo.first();
      if ( seedViewColumnVoRow == null )
      {
        throw
          XxcsoMessage.createInstanceLostError("XxcsoLookupListVORowImpl");
      }

      while ( seedViewColumnVoRow != null )
      {
        HashMap map
          = this.createViewColumnMap(
              seedViewColumnVoRow.getAttribute7()
             ,seedViewColumnVoRow.getDescription()
             ,seedViewColumnVoRow.getAttribute7()
             ,seedViewColumnVoRow.getAttribute4()
            );
        list.add(map);
        seedViewColumnVoRow
          = (XxcsoLookupListVORowImpl) seedViewColumnVo.next();
      }
    }

    XxcsoUtils.debug(txt, "[END]");

    return list;
  }

  /*****************************************************************************
   * 使用可能フラグチェック処理
   * @param enableFlag 
   * @throw OAException ビュー定義更新エラー
   *****************************************************************************
   */
  private void chkEnableFlag(String enableFlag)
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // 使用可能フラグ="1"か判別
    if ( ! XxcsoPvCommonConstants.FLAG_ENABLE.equals(enableFlag) )
    {
      // ビュー定義更新エラー
      throw XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00520);
    }

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * テキスト文字列取得処理
   * @param methodCode
   * @param termText
   * @return 検索用の文字列
   *****************************************************************************
   */
  private String getTextString(
    String methodCode
   ,String termText
  )
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    StringBuffer sb = new StringBuffer();
    sb.append(XxcsoPvCommonConstants.SINGLE_QUOTE);
    // 含む
    if ( XxcsoPvCommonConstants.METHOD_CONTAIN.equals(methodCode) )
    {
      sb.append("%").append(termText).append("%");
    }
    // で始まる
    else if ( XxcsoPvCommonConstants.METHOD_START.equals(methodCode) )
    {
      sb.append(termText).append("%");
    }
    // で終わる
    else if ( XxcsoPvCommonConstants.METHOD_END.equals(methodCode) )
    {
      sb.append("%").append(termText);
    }
    // 上記以外
    else
    {
      sb.append(termText);
    }
    sb.append(XxcsoPvCommonConstants.SINGLE_QUOTE);

    XxcsoUtils.debug(txt, "[END]");

    return new String(sb);
  }

  /*****************************************************************************
   * 日付文字列取得処理
   * @param termDate
   * @return 検索用の文字列
   *****************************************************************************
   */
  private String getDateString(String termDate)
  {
    StringBuffer sbDate = new StringBuffer();
    sbDate.append("TO_DATE(").append(XxcsoPvCommonConstants.SINGLE_QUOTE);
    sbDate.append(termDate);
    sbDate.append(XxcsoPvCommonConstants.SINGLE_QUOTE).append(")");
    return new String(sbDate);
  }

  /*****************************************************************************
   * シードデータ判定処理
   * @param viewId
   * @return true:シードデータ、false:シードデータ以外
   *****************************************************************************
   */
  private boolean isSeedData(String viewId)
  {
    if (XxcsoPvCommonConstants.VIEW_ID_SEED == Integer.parseInt(viewId))
    {
      return true;
    }
    return false;
  }

  /*****************************************************************************
   * 自拠点コード取得処理
   * @return  自拠点コード
   * @throw   OAException
   *****************************************************************************
   */
  private String getSelfBaseCode()
  {
    XxcsoPvExtractDispInitVOImpl extDispInitVo = getPvExtractDispInitVO();
    if ( extDispInitVo == null)
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractDispInitVOImpl");
    }
    extDispInitVo.executeQuery();

    XxcsoPvExtractDispInitVORowImpl extDispInitVoRow
      = (XxcsoPvExtractDispInitVORowImpl) extDispInitVo.first();
    if ( extDispInitVoRow == null)
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractDispInitVORowImpl");
    }
    return extDispInitVoRow.getBaseCode();
    
  }

  /*****************************************************************************
   * 物件情報汎用検索表示用map作成
   * @param id       Tableリージョン 項目ID
   * @param name     Tableリージョン 項目名
   * @param attr     Tableリージョン ViewAttribute
   * @param dataTyep Tableリージョン 項目型
   * @return URLに引き渡すパラメータ(HashMap)
   *****************************************************************************
   */
  private HashMap createViewColumnMap(
    String id
   ,String name
   ,String attrName
   ,String dataType
  )
  {
    HashMap map = new HashMap(4);
    map.put(XxcsoPvCommonConstants.KEY_ID,        id);
    map.put(XxcsoPvCommonConstants.KEY_NAME,      name);
    map.put(XxcsoPvCommonConstants.KEY_ATTR_NAME, attrName);
    map.put(XxcsoPvCommonConstants.KEY_DATA_TYPE, dataType);
    return map;
  }
   

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso012001j.server", "XxcsoInstallBasePvSearchAMLocal");
  }

  /**
   * 
   * Container's getter for InstallBasePvDesignVO
   */
  public XxcsoInstallBasePvDesignVOImpl getInstallBasePvDesignVO()
  {
    return (XxcsoInstallBasePvDesignVOImpl)findViewObject("InstallBasePvDesignVO");
  }

  /**
   * 
   * Container's getter for InstallBaseExtractTermVO
   */
  public XxcsoInstallBaseExtractTermVOImpl getInstallBaseExtractTermVO()
  {
    return (XxcsoInstallBaseExtractTermVOImpl)findViewObject("InstallBaseExtractTermVO");
  }

  /**
   * 
   * Container's getter for InstallBaseSortColumnVO
   */
  public XxcsoInstallBaseSortColumnVOImpl getInstallBaseSortColumnVO()
  {
    return (XxcsoInstallBaseSortColumnVOImpl)findViewObject("InstallBaseSortColumnVO");
  }

  /**
   * 
   * Container's getter for InstallBaseViewColumnVO
   */
  public XxcsoInstallBaseViewColumnVOImpl getInstallBaseViewColumnVO()
  {
    return (XxcsoInstallBaseViewColumnVOImpl)findViewObject("InstallBaseViewColumnVO");
  }

  /**
   * 
   * Container's getter for SeedViewColumnLookupVO
   */
  public XxcsoLookupListVOImpl getSeedViewColumnLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("SeedViewColumnLookupVO");
  }

  /**
   * 
   * Container's getter for InstallBasePvSumVO
   */
  public XxcsoInstallBasePvSumVOImpl getInstallBasePvSumVO()
  {
    return (XxcsoInstallBasePvSumVOImpl)findViewObject("InstallBasePvSumVO");
  }

  /**
   * 
   * Container's getter for InstallBaseViewSizeVO
   */
  public XxcsoInstallBaseViewSizeVOImpl getInstallBaseViewSizeVO()
  {
    return (XxcsoInstallBaseViewSizeVOImpl)findViewObject("InstallBaseViewSizeVO");
  }

  /**
   * 
   * Container's getter for InstallBasePvChoiceVO
   */
  public XxcsoInstallBasePvChoiceVOImpl getInstallBasePvChoiceVO()
  {
    return (XxcsoInstallBasePvChoiceVOImpl)findViewObject("InstallBasePvChoiceVO");
  }

  /**
   * 
   * Container's getter for SeedExtractTermVO
   */
  public XxcsoLookupListVOImpl getSeedExtractTermVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("SeedExtractTermVO");
  }

  /**
   * 
   * Container's getter for PvExtractDispInitVO
   */
  public XxcsoPvExtractDispInitVOImpl getPvExtractDispInitVO()
  {
    return (XxcsoPvExtractDispInitVOImpl)findViewObject("PvExtractDispInitVO");
  }





}