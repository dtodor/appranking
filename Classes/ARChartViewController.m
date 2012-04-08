/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import "ARChartViewController.h"
#import "ARRankEntry.h"
#import "ARStorageManager.h"
#import "ARGoogleChart.h"
#import "ARColor.h"


@interface ARChartViewController()

@property (nonatomic, strong) NSArray *chartCountries;
@property (nonatomic, strong) NSArray *timeFrameChoices;

@property (nonatomic, weak) IBOutlet id <ARChartViewControllerDelegate> delegate;
@property (nonatomic, strong) NSNumber *selectedTimeFrame;
@property (nonatomic, strong) NSDate *fromDate;
@property (nonatomic, strong) NSDate *untilDate;

@end


@implementation ARChartViewController

@synthesize chartCountries = _chartCountries;
@synthesize allCountries = _allCountries;
@synthesize application = _application;
@synthesize category = _category;
@synthesize delegate = _delegate;
@synthesize timeFrameChoices = _timeFrameChoices;
@synthesize selectedTimeFrame = _selectedTimeFrame;
@synthesize fromDate = _fromDate;
@synthesize untilDate = _untilDate;
@synthesize enabled = _enabled;

- (void)dealloc 
{
	[self removeObserver:self forKeyPath:@"allCountries"];
	[self removeObserver:self forKeyPath:@"selectedTimeFrame"];
}

#define HOUR 3600
#define DAY 24*HOUR

- (void)awakeFromNib 
{
	[self addObserver:self forKeyPath:@"selectedTimeFrame" options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:@"allCountries" options:NSKeyValueObservingOptionNew context:NULL];

	self.timeFrameChoices = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:7*DAY], @"value", @"Last 7 days", @"name", nil],
							 [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:30*DAY], @"value", @"Last 30 days", @"name", nil],
							 [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:90*DAY], @"value", @"Last 90 days", @"name", nil],
							 [NSDictionary dictionaryWithObjectsAndKeys:[NSNull null], @"value", @"Custom", @"name", nil],
							 nil];
	self.selectedTimeFrame = [[self.timeFrameChoices objectAtIndex:0] objectForKey:@"value"];
}

- (void)updateCountriesData 
{
	NSMutableArray *countriesForChart = [NSMutableArray array];
	if (self.allCountries) {
		[self.allCountries enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
			NSDictionary *countryData = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"value", object, @"title", nil];
			[countryData addObserver:self forKeyPath:@"value" options:NSKeyValueObservingOptionNew context:NULL];
			[countriesForChart addObject:countryData];
		}];
	}
	self.chartCountries = countriesForChart;
    if (self.delegate) {
        [self.delegate chartViewController:self didUpdateData:nil sorted:NO];
    }
}

- (void)updateTimeSpan 
{
	if ([self.selectedTimeFrame isKindOfClass:[NSNumber class]]) {
		self.fromDate = [NSDate dateWithTimeIntervalSinceNow:-[self.selectedTimeFrame doubleValue]];
		self.untilDate = [NSDate date];
	}
}

- (void)reloadChart 
{
	NSMutableArray *countries = [NSMutableArray array];
	for (NSDictionary *data in self.chartCountries) {
		if ([[data objectForKey:@"value"] boolValue]) {
			[countries addObject:[data objectForKey:@"title"]];
		}
	}
    NSArray *entries = nil;
	if ([countries count] > 0) {
		NSError *error = nil;
		entries = [[ARStorageManager sharedARStorageManager] rankEntriesForApplication:self.application 
																					 inCategory:self.category 
																					  countries:countries 
																						   from:self.fromDate
																						  until:self.untilDate
																						  error:&error];
		if (!entries) {
			[self presentError:error];
		}
	}
    if (self.delegate) {
        [self.delegate chartViewController:self didUpdateData:entries sorted:YES];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context 
{
	if ([keyPath isEqualToString:@"allCountries"]) {
		[self updateCountriesData];
		[self updateTimeSpan];
	} else if ([keyPath isEqualToString:@"selectedTimeFrame"]) {
		[self updateTimeSpan];
		[self reloadChart];
	} else if ([keyPath isEqualToString:@"value"]) {
		[self updateTimeSpan];
		[self reloadChart];
	}
}

#pragma mark -
#pragma mark NSTableViewDelegate

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row 
{
	NSDictionary *data = [self.chartCountries objectAtIndex:row];
	NSString *country = [data objectForKey:@"title"];
	[cell setTitle:country];
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								[ARColor colorForCountry:country].color, NSForegroundColorAttributeName,
								[NSFont boldSystemFontOfSize:14.0], NSFontAttributeName, nil];
	NSAttributedString *altTitle = [[NSAttributedString alloc] initWithString:country 
																	attributes:attributes];
	[cell setAttributedAlternateTitle:altTitle];
}

- (BOOL)tableView:(NSTableView *)tableView shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row 
{
	return YES;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row 
{
	return NO;
}

@end
